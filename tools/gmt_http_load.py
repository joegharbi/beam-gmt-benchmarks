import argparse
import os
import time
from concurrent.futures import ThreadPoolExecutor
from threading import Lock

import requests


def wait_for_http_200(url: str, startup_wait: int, retries: int, delay: int) -> None:
    time.sleep(startup_wait)
    for _ in range(retries):
        try:
            if requests.get(url, timeout=10).status_code == 200:
                return
        except requests.exceptions.RequestException:
            pass
        time.sleep(delay)
    raise RuntimeError(f"Server did not return HTTP 200 at {url}")


def main() -> None:
    parser = argparse.ArgumentParser(description="GMT HTTP load generator (BEAM-comparable: health wait + parallel GETs)")
    parser.add_argument("--url", required=True)
    parser.add_argument("--num_requests", required=True, type=int)
    parser.add_argument("--timeout", type=float, default=5.0)
    args = parser.parse_args()

    startup_wait = int(os.environ.get("MEASURE_STARTUP_WAIT", "15"))
    retries = int(os.environ.get("MEASURE_HEALTH_RETRIES", "25"))
    delay = int(os.environ.get("MEASURE_HEALTH_DELAY", "2"))
    wait_for_http_200(args.url, startup_wait, retries, delay)
    time.sleep(3)

    lock = Lock()
    totals = {"success": 0, "failure": 0, "total": 0}

    def send_one(_n: int) -> None:
        try:
            resp = requests.get(args.url, timeout=args.timeout)
            ok = 200 <= resp.status_code < 300
        except requests.exceptions.RequestException:
            ok = False
        with lock:
            totals["total"] += 1
            if ok:
                totals["success"] += 1
            else:
                totals["failure"] += 1

    start = time.time()
    with ThreadPoolExecutor() as executor:
        list(executor.map(send_one, range(args.num_requests)))
    runtime_s = time.time() - start
    rps = totals["total"] / runtime_s if runtime_s > 0 else 0.0

    print(
        "GMT_HTTP_LOAD_SUMMARY "
        f"total={totals['total']} success={totals['success']} failure={totals['failure']} runtime_s={runtime_s:.3f} rps={rps:.2f}"
    )


if __name__ == "__main__":
    main()

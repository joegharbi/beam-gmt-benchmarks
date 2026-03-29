import argparse
import os
import time
from concurrent.futures import ThreadPoolExecutor
from threading import Lock

import requests

# Keep in sync with scripts/beam_gmt_http_constants.sh BEAM_GMT_HTTP_FULL_COUNTS
# and BEAM-web-server-benchmarks/scripts/run_benchmarks.sh full_http_requests.
BEAM_HTTP_FULL_COUNTS = (
    100,
    1000,
    5000,
    8000,
    10000,
    15000,
    20000,
    30000,
    40000,
    50000,
    60000,
    70000,
    80000,
)


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


def run_load(url: str, num_requests: int, timeout: float, *, skip_health: bool) -> None:
    startup_wait = int(os.environ.get("MEASURE_STARTUP_WAIT", "15"))
    retries = int(os.environ.get("MEASURE_HEALTH_RETRIES", "25"))
    delay = int(os.environ.get("MEASURE_HEALTH_DELAY", "2"))
    if not skip_health:
        wait_for_http_200(url, startup_wait, retries, delay)
        time.sleep(3)

    lock = Lock()
    totals = {"success": 0, "failure": 0, "total": 0}

    def send_one(_n: int) -> None:
        try:
            resp = requests.get(url, timeout=timeout)
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
        list(executor.map(send_one, range(num_requests)))
    runtime_s = time.time() - start
    rps = totals["total"] / runtime_s if runtime_s > 0 else 0.0

    print(
        "GMT_HTTP_LOAD_SUMMARY "
        f"num_requests={num_requests} "
        f"total={totals['total']} success={totals['success']} failure={totals['failure']} "
        f"runtime_s={runtime_s:.3f} rps={rps:.2f}"
    )


def main() -> None:
    parser = argparse.ArgumentParser(description="GMT HTTP load generator (BEAM-comparable: health wait + parallel GETs)")
    parser.add_argument("--url", required=True)
    parser.add_argument(
        "--num_requests",
        type=int,
        default=None,
        help="Total parallel GETs (ignored if --sweep).",
    )
    parser.add_argument(
        "--sweep",
        action="store_true",
        help=f"Run BEAM HTTP load list in one process (default: {list(BEAM_HTTP_FULL_COUNTS)}). Health wait once, then each count.",
    )
    parser.add_argument(
        "--counts",
        default=None,
        metavar="N,N,...",
        help="With --sweep only: comma-separated request counts (overrides default full BEAM list).",
    )
    parser.add_argument("--timeout", type=float, default=5.0)
    args = parser.parse_args()

    if args.sweep and args.num_requests is not None:
        parser.error("Do not pass --num_requests with --sweep")
    if not args.sweep and args.num_requests is None:
        parser.error("--num_requests is required unless --sweep")
    if not args.sweep and args.counts is not None:
        parser.error("--counts is only valid with --sweep")

    if args.sweep:
        if args.counts is not None:
            parts = [p.strip() for p in args.counts.split(",") if p.strip()]
            if not parts:
                parser.error("--counts must list at least one integer")
            try:
                counts = tuple(int(p) for p in parts)
            except ValueError:
                parser.error("--counts must be comma-separated integers")
            if any(n < 1 for n in counts):
                parser.error("--counts values must be positive")
        else:
            counts = BEAM_HTTP_FULL_COUNTS
        for i, n in enumerate(counts):
            run_load(args.url, n, args.timeout, skip_health=i > 0)
    else:
        run_load(args.url, args.num_requests, args.timeout, skip_health=False)


if __name__ == "__main__":
    main()

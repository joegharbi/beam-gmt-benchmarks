# HTTP request-count sweep (parity with BEAM)

In **BEAM-web-server-benchmarks**, static and dynamic HTTP benchmarks use a fixed list of `--num_requests` values per container. The full list is the same 13 points from **100** through **80000** (see `scripts/run_benchmarks.sh`: `full_http_requests`). Quick modes use three counts or one count.

Green Metrics Tool does **not** append multiple load points into one CSV row inside a single scenario file. Each `runner.py` run is one **measurement** (one lifecycle, one row in GMT’s database / one stats page). Parity with BEAM is therefore:

**one GMT run per (image, num_requests)** — implemented by `scripts/run_gmt_http_sweep.sh`.

## Is it hard?

No. It is **orchestration only**: the same `usage_scenario.yml` and variables as a single run, repeated in a loop. The cost is **operational**: full runs are slow and multiply by `containers × request_counts` (e.g. 20 images × 13 counts = 260 separate GMT measurements for a full sweep).

## Request-count presets (aligned with BEAM)

| Mode | Counts |
|------|--------|
| Default (full) | `100 1000 5000 8000 10000 15000 20000 30000 40000 50000 60000 70000 80000` |
| `--quick` | `1000 5000 10000` |
| `--super-quick` | `1000` |

## Examples

Discover all **static** containers from your BEAM repo and run the **full** sweep (build all images first). With the default sibling layout, **BEAM_ROOT** is auto-detected; otherwise set it in `env.local` ([PATHS_AND_ENV.md](PATHS_AND_ENV.md)).

```bash
./scripts/run_gmt_http_sweep.sh static
```

All **dynamic** containers, quick counts:

```bash
./scripts/run_gmt_http_sweep.sh dynamic --quick
```

Static **and** dynamic (warning: very many runs):

```bash
./scripts/run_gmt_http_sweep.sh all --quick
```

Explicit images only (no `BEAM_ROOT`):

```bash
./scripts/run_gmt_http_sweep.sh st-erlang-index-27 st-erlang-cowboy-27
```

Dry run (print `runner.py` invocations):

```bash
GMT_SWEEP_DRY_RUN=1 ./scripts/run_gmt_http_sweep.sh st-erlang-index-27 --super-quick
```

Continue after a failed measurement:

```bash
GMT_SWEEP_CONTINUE_ON_ERROR=1 ./scripts/run_gmt_http_sweep.sh static --quick
```

## WebSocket

`ws-*` benchmarks in BEAM use `measure_websocket.py`, not HTTP GET counts. They are **not** included in this sweep. Add a separate GMT scenario and script when you need WebSocket parity.

## Comparing to BEAM CSVs

BEAM writes **one CSV per container** with **one row per request count**. GMT gives **one measurement ID per (image, count)**. To compare numerically you export or query GMT metrics per run and join on image name + `n` (encoded in the run name: `BEAM-HTTP-<image>-n<count>`).

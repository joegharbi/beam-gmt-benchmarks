# HTTP orchestration (BEAM → GMT)

In **BEAM-web-server-benchmarks**, static and dynamic HTTP benchmarks use a fixed list of `--num_requests` values per container. The full list is 13 points from **100** through **80000** (`scripts/run_benchmarks.sh`: `full_http_requests`).

Green Metrics Tool records **one measurement per `runner.py` invocation**. Parity with BEAM is:

**one GMT run per (image, num_requests)** — orchestrated by **`scripts/run_beam_gmt_http.sh`**.

### All 13 loads in **one** measurement (same containers)

Yes. You can run the full BEAM count list **inside the same `loadgen` container** and still use **one** `runner.py` invocation — useful when a **hosted quota** counts jobs, not HTTP rounds.

- **`tools/gmt_http_load.py --sweep`** — waits for HTTP 200 **once**, then runs the 13 counts **in order** (same tuple as `scripts/beam_gmt_http_constants.sh`).
- Scenario file: **`usage_scenario_full_sweep.yml`** (internally passes the container image and optional extra CLI for `gmt_http_load.py` — you normally only use **`run_local_full_sweep.sh`** or the hosted variable form in [CLUSTER_AND_GITHUB.md](CLUSTER_AND_GITHUB.md)).

**Tradeoffs vs 13 separate GMT runs:** loads are **back-to-back** in one session (shared thermal state, no cool-down between “official” runs). Energy and latency are still usable for exploration or hosted sanity checks; for paper-grade isolation, prefer **`run_beam_gmt_http.sh`** (one run per count).

### `run_local_full_sweep.sh` — three knobs

There are **no extra environment variables** you must learn for daily use. Everything is flags, plus **preset image lists at the top of the script**.

| Knob | Meaning |
|------|--------|
| **Containers** | **`-c NAME`** (repeatable) = only these images. **No `-c`** = use **`FULL_SWEEP_STATIC_CONTAINERS`** and **`FULL_SWEEP_DYNAMIC_CONTAINERS`** defined at the top of **`scripts/run_local_full_sweep.sh`** (edit that file to change the default list). |
| **Workload** | **`-l N`** (repeatable) = only these request counts, in order. **No `-l`** = full BEAM sweep **13** steps (**100** through **80000**). |
| **Static / dynamic** | **`--scope all`** (default) = static preset list, then dynamic preset list. **`--scope static`** / **`--scope dynamic`** = only that half of the presets. **Ignored if you passed `-c`.** |

Optional debugging only: **`--dry-run`**, **`--continue-on-error`**.

Logs: `logs/gmt_beam_full_sweep_<timestamp>.log`

Examples:

```bash
cd /path/to/beam-gmt-benchmarks

# One container by name, all 13 load steps in one GMT run:
./scripts/run_local_full_sweep.sh -c st-erlang-index-27

# Default presets in the script (static list); full 13 steps:
./scripts/run_local_full_sweep.sh --scope static

# One container, only two load sizes:
./scripts/run_local_full_sweep.sh -c st-erlang-index-27 -l 100 -l 1000
```

Equivalent manual `runner.py` (full default sweep; empty sweep extra):

```bash
cd "${BEAM_GMT_BENCHMARKS_ROOT}"
"${GMT_PYTHON:-${GMT_ROOT}/.venv/bin/python3}" "${GMT_ROOT}/runner.py" \
  --uri "${BEAM_GMT_BENCHMARKS_ROOT}" \
  --filename usage_scenario_full_sweep.yml \
  --name "BEAM-HTTP-full-sweep-st-erlang-index-27" \
  --variable "__GMT_VAR_BEAM_IMAGE__=st-erlang-index-27" \
  --variable "__GMT_VAR_SWEEP_EXTRA__="
```

### Erlang vs Elixir (static `index` — comparable pair)

BEAM uses the same workload shape (static HTTP `index`); the Docker image names differ by language. Fair default pair for language comparison:

| Language | Static index image |
|----------|-------------------|
| Erlang   | `st-erlang-index-27` |
| Elixir   | `st-elixir-index-1-16` |

Build both from **BEAM-web-server-benchmarks** (from the repo root):

```bash
cd /path/to/BEAM-web-server-benchmarks
docker build -t st-erlang-index-27 ./benchmarks/static/erlang/index/st-erlang-index-27
docker build -t st-elixir-index-1-16 ./benchmarks/static/elixir/index/st-elixir-index-1-16
```

Then from **beam-gmt-benchmarks**:

**A — 13 separate GMT measurements** (one run per load; same style as `run_beam_gmt_http.sh` for Erlang):

```bash
cd /path/to/beam-gmt-benchmarks
./scripts/run_beam_gmt_http.sh -c st-elixir-index-1-16
```

**B — one GMT measurement** (all 13 loads chained in `loadgen`; same style as full sweep for Erlang):

```bash
./scripts/run_local_full_sweep.sh -c st-elixir-index-1-16
```

Run the same pair of commands with `-c st-erlang-index-27` to collect Erlang numbers for comparison. Expect **13 stats IDs** for (A) vs **one stats ID** per image for (B).

## Main script: `run_beam_gmt_http.sh`

| Invocation | Behaviour |
|------------|-----------|
| *(no arguments)* | Discover **all** images under `benchmarks/static` **and** `benchmarks/dynamic`, run **full** 13-count list per image. |
| `--static-only` / `--dynamic-only` | Restrict discovery to one tree. |
| `-c NAME` / `--container NAME` | Run only named image(s) (repeatable). No discovery; **`BEAM_ROOT` not required**. |
| `-l N` / `--load N` | Use only these request counts (repeatable). Cannot mix with `--quick` / `--super-quick`. |
| `--quick` / `--super-quick` | Three counts or one count (same as BEAM quick modes). |
| `--dry-run` | Print `runner.py` commands (also **`GMT_SWEEP_DRY_RUN=1`**). |
| `--continue-on-error` | Keep going after a failed run (**`GMT_SWEEP_CONTINUE_ON_ERROR=1`**). |

Logs: `logs/gmt_beam_http_<timestamp>.log`

### Constants and preset list

- **`scripts/beam_gmt_http_constants.sh`** — count arrays and optional **`BEAM_GMT_HTTP_PRESET_CONTAINERS`**.  
  If that array is **non-empty** and you do **not** pass `-c`, those names are used instead of filesystem discovery (ordered subset for a study).

### Examples

```bash
# Full static + dynamic × full loads (very many GMT runs — validate with --dry-run first)
./scripts/run_beam_gmt_http.sh --dry-run | tail -5

# Single container, single load (good smoke test)
./scripts/run_beam_gmt_http.sh -c st-erlang-index-27 -l 100

# Several containers, BEAM “quick” counts
./scripts/run_beam_gmt_http.sh -c st-erlang-index-27 -c st-erlang-cowboy-27 --quick

# Static discovery only, super-quick
./scripts/run_beam_gmt_http.sh --static-only --super-quick
```

### Legacy wrapper

`scripts/run_gmt_http_sweep.sh` forwards to `run_beam_gmt_http.sh` (old `static` / `dynamic` / `all` / bare image names). Prefer the new script and flags.

## Request-count presets (aligned with BEAM)

| Mode | Counts |
|------|--------|
| Default (full) | `100 1000 5000 8000 10000 15000 20000 30000 40000 50000 60000 70000 80000` |
| `--quick` | `1000 5000 10000` |
| `--super-quick` | `1000` |

## Operational cost

Full runs scale as **`containers × request_counts`**. A dry-run header prints `Total GMT runs:` before you commit to real measurements.

## WebSocket

`ws-*` workloads are **not** included. Add a separate scenario and tooling later.

## Comparing to BEAM CSVs

BEAM: one CSV per container, one row per request count. GMT: one measurement ID per `(image, count)`; run names look like `BEAM-HTTP-<image>-n<count>`.

## First real measurement (validation)

`runner.py` may invoke **`sudo`** (hardware / system checks). Run from a terminal where sudo works, or follow GMT’s install notes for non-interactive use. If sudo fails without a TTY, the run can stop early — fix sudo/SSH before expecting saved results in the GMT UI.

**`git status` / “not a git repository”:** Green Metrics Tool’s `check_gmt_dir_dirty` runs `git status` in the **process current directory**, not inside `--uri`. `run_beam_gmt_http.sh` and `run_local_production.sh` **`cd` into this repo** before starting `runner.py` so you can call them from `~` or any path. This repository must still be a git checkout (`git init` + commit if needed).

Single-container check:

```bash
./scripts/run_beam_gmt_http.sh -c st-erlang-index-27 -l 1000
```

Then open your GMT **`stats.html`** (or API) and locate the run name **`BEAM-HTTP-st-erlang-index-27-n1000`**.

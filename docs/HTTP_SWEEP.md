# HTTP orchestration (BEAM → GMT)

In **BEAM-web-server-benchmarks**, static and dynamic HTTP benchmarks use a fixed list of `--num_requests` values per container. The full list is 13 points from **100** through **80000** (`scripts/run_benchmarks.sh`: `full_http_requests`).

Green Metrics Tool records **one measurement per `runner.py` invocation**. Parity with BEAM is:

**one GMT run per (image, num_requests)** — orchestrated by **`scripts/run_beam_gmt_http.sh`**.

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

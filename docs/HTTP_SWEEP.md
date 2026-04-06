# HTTP orchestration (BEAM → GMT)

**Local laptop:** if every GMT run stops with **`RAPL energy filtering is active`**, put this in **`env.local`** (copy from `env.example`) or run once per terminal:

```bash
export GMT_IGNORE_RAPL_ENERGY_FILTERING_CHECK=1
```

Then rerun `./scripts/run_beam_gmt_http.sh …`. Details: [ENERGY_METRICS.md](ENERGY_METRICS.md).

---

In **BEAM-web-server-benchmarks**, static and dynamic HTTP benchmarks use a fixed list of `--num_requests` values per container. The full list is 13 points from **100** through **80000** (`scripts/run_benchmarks.sh`: `full_http_requests`).

Green Metrics Tool records **one measurement per `runner.py` invocation**.

**Single orchestrator:** **`scripts/run_beam_gmt_http.sh`**

| Mode | Flag | Meaning |
|------|------|--------|
| **Separate** | *(default)* | One GMT run per **(image × load)** — like BEAM’s one CSV row per count. **`usage_scenario.yml`**. |
| **Together** | **`--together`** · **`--all-in-one`** · **`--altogether`** | One GMT run per **image**; loads run in sequence in `loadgen` (`gmt_http_load.py --sweep`). **`usage_scenario_full_sweep.yml`**. Fewer jobs (e.g. hosted quota). |

The same **`-c`**, **`-l`**, **`--quick`**, **`--static-only`**, **`--dynamic-only`**, **`--dry-run`**, **`--continue-on-error`** apply in both modes. Default image list when you omit **`-c`**: **`BEAM_GMT_HTTP_PRESET_CONTAINERS`** in **`scripts/beam_gmt_http_constants.sh`**, else discovery under **`BEAM_ROOT`**.

**Together** tradeoff: loads are **back-to-back** (shared thermal state). For stricter isolation, use **separate** mode.

**`scripts/run_local_full_sweep.sh`** remains as a thin wrapper (**`run_beam_gmt_http.sh --together`**) and maps legacy **`--scope static|dynamic|all`** to **`--static-only` / `--dynamic-only`**.

```bash
# Separate (13 runs for one image, full list)
./scripts/run_beam_gmt_http.sh -c st-erlang-index-27

# Together (1 run, chained loads)
./scripts/run_beam_gmt_http.sh --together -c st-erlang-index-27
```

Logs for both: **`logs/gmt_beam_http_<timestamp>.log`**

Hosted / manual **`runner.py`** for together mode: [CLUSTER_AND_GITHUB.md](CLUSTER_AND_GITHUB.md) (`__GMT_VAR_BEAM_IMAGE__`, `__GMT_VAR_SWEEP_EXTRA__`).

### Explicit hosted full-sweep files

When hosted variable injection is not available, submit explicit full-sweep files directly:

- `usage_scenario_full_sweep.st-erlang-index-27.yml`
- `usage_scenario_full_sweep.st-elixir-index-1-16.yml`
- `usage_scenario_full_sweep.dy-erlang-index-27.yml`
- `usage_scenario_full_sweep.dy-elixir-index-1-16.yml`

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

**B — one GMT measurement** (all loads chained in `loadgen`):

```bash
./scripts/run_beam_gmt_http.sh --together -c st-elixir-index-1-16
```

Run the same pair of commands with `-c st-erlang-index-27` to collect Erlang numbers for comparison. Expect **13 stats IDs** for (A) vs **one stats ID** per image for (B).

## Main script: `run_beam_gmt_http.sh`

Run **`run_beam_gmt_http.sh --help`** for the full flag list.

| Invocation | Behaviour |
|------------|-----------|
| *(default, no mode flag)* | **Separate** measurements: one GMT run per (image × load). |
| `--together` (or `--all-in-one` / `--altogether`) | **Together**: one GMT run per image, chain loads with **`--sweep`**. |
| `--separate` | Force separate mode if you want to be explicit. |
| *(no arguments)* | Discover **all** images under `benchmarks/static` **and** `benchmarks/dynamic`, run full count list per image (13 by default in each mode). |
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

# One image, chained quick counts (single GMT run)
./scripts/run_beam_gmt_http.sh --together -c st-erlang-index-27 --quick
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

**Separate** mode: cost scales as **`containers × request_counts`**. **Together** mode: **`containers`** only (each run still executes every selected count in one go). A dry-run header prints **`Total GMT runs:`** first.

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

# beam-gmt-benchmarks

Green Metrics Tool (GMT) usage scenarios for **BEAM** web servers, aligned with the naming and HTTP load semantics of **BEAM-web-server-benchmarks** (same image names, health wait + parallel GETs). Use this repository **standalone on GitHub** for local runs or for [Green Coding’s hosted measurements](https://docs.green-coding.io/docs/measuring/measuring-service/).

## Contents

| Path | Purpose |
|------|---------|
| `usage_scenario.yml` | Root scenario GMT expects; one **beam-server** + **loadgen**; image and request count are GMT variables. |
| `tools/gmt_http_load.py` | Load generator (BEAM-comparable: env-based health wait, then `ThreadPoolExecutor` GETs). |
| `scripts/_lib_env.sh` | Shared path setup: loads `env.local` / `BEAM_GMT_ENV_FILE`, sets **`GMT_ROOT`**, **`BEAM_GMT_BENCHMARKS_ROOT`**, **`RUNNER`**. |
| `scripts/run_local_production.sh` | **Production-style** local run: no `--dev-*`, no `--skip-optimizations`, no `--skip-download-dependencies`. |
| `scripts/run_gmt_http_sweep.sh` | **BEAM-style sweep**: same HTTP request-count lists as BEAM (`100`…`80000`, plus `--quick` / `--super-quick`); one GMT run per (image × count). |
| `docs/LOCAL_PRODUCTION.md` | Full local checklist, env vars, troubleshooting. |
| `docs/HTTP_SWEEP.md` | Why sweeps are separate GMT runs; examples; `GMT_SWEEP_*` env vars. |
| `docs/CLUSTER_AND_GITHUB.md` | Hosted service, cluster machine types, image registry notes. |
| `docs/ADDING_SCENARIOS.md` | How to add more images following BEAM’s structure. |
| `env.example` | Template for `env.local` — define **`GMT_ROOT`** and optional **`BEAM_ROOT`** / **`BEAM_GMT_BENCHMARKS_ROOT`**. |
| `docs/PATHS_AND_ENV.md` | How roots are resolved; moving GMT or this repo without editing scripts. |

## Quick start (local, production-style)

1. Install and configure **Green Metrics Tool** on Linux (official docs).  
2. **`cp env.example env.local`** and set **`GMT_ROOT`** to the directory that contains `runner.py` (when you relocate GMT, change only `env.local` or your profile).  
3. Build the default BEAM image **`st-erlang-index-27`** in your BEAM-web-server-benchmarks checkout (`make build` or `docker build`). Set **`BEAM_ROOT`** in `env.local` if you use the HTTP sweep with `static` / `dynamic` / `all`.  
4. Initialize git here if needed: `git init && git add -A && git commit -m "Initial benchmark scenario"`.  
5. Run:

   ```bash
   ./scripts/run_local_production.sh
   ```

Defaults: `GMT_VAR_BEAM_IMAGE=st-erlang-index-27`, `GMT_VAR_NUM_REQUESTS=10000`. Override with environment variables before calling the script.

### Full static/dynamic sweep (like BEAM `make run`)

BEAM runs 13 request counts per HTTP container by default. Here, each count is a **separate** GMT measurement. See [docs/HTTP_SWEEP.md](docs/HTTP_SWEEP.md).

```bash
# With BEAM_ROOT and GMT_ROOT in env.local:
./scripts/run_gmt_http_sweep.sh static              # all static images × full count list
./scripts/run_gmt_http_sweep.sh dynamic --quick     # all dynamic × three counts
./scripts/run_gmt_http_sweep.sh st-erlang-index-27  # one image × full count list (no BEAM_ROOT)
```

## GMT variables (scenario)

| Placeholder in `usage_scenario.yml` | Set via `--variable` or hosted UI |
|-----------------------------------|-----------------------------------|
| `__GMT_VAR_BEAM_IMAGE__` | Docker image for the server (e.g. `st-erlang-cowboy-27` or `ghcr.io/org/st-erlang-index-27:tag`). |
| `__GMT_VAR_NUM_REQUESTS__` | Integer; total HTTP GETs issued in parallel (same role as request counts in BEAM HTTP runs). |

Variable names must match GMT’s pattern `__GMT_VAR_<NAME>__` (see GMT `runner.py`).

## Hosted cluster / metrics.green-coding.io

- Request runs: [metrics.green-coding.io/request.html](https://metrics.green-coding.io/request.html)  
- Cluster hardware context: [Measurement cluster](https://docs.green-coding.io/docs/measuring/measurement-cluster/)  
- Details: [docs/CLUSTER_AND_GITHUB.md](docs/CLUSTER_AND_GITHUB.md)

Your server image must be **pullable** on the worker (public registry or arranged access). This repo does not vendor BEAM Dockerfiles.

## Differences from `gmt-intro`

The sibling learning repo under the same paper workspace uses **dev-oriented** runner flags for a quick path to charts. **This** repository is intended for **final, comparable** numbers: full system checks, optimization phase, dependency download as GMT recommends, and documentation aimed at GitHub + cluster reuse.

## License

Specify a license when you publish (e.g. MIT to match BEAM-web-server-benchmarks).

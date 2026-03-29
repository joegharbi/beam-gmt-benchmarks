# beam-gmt-benchmarks

Green Metrics Tool (GMT) usage scenarios for **BEAM** web servers, aligned with the naming and HTTP load semantics of **BEAM-web-server-benchmarks** (same image names, health wait + parallel GETs). Use this repository **standalone on GitHub** for local runs or for [Green Coding’s hosted measurements](https://docs.green-coding.io/docs/measuring/measuring-service/).

## Contents

| Path | Purpose |
|------|---------|
| `usage_scenario.yml` | Root scenario GMT expects; one **beam-server** + **loadgen**; image and request count are GMT variables. |
| `tools/gmt_http_load.py` | Load generator (BEAM-comparable: env-based health wait, then `ThreadPoolExecutor` GETs). |
| `scripts/_lib_env.sh` | Shared path setup: auto-finds GMT + BEAM sibling checkouts, optional `env.local` overrides. |
| `scripts/run_local_production.sh` | **Single** production-style GMT run (default image + load via env vars). |
| `scripts/run_beam_gmt_http.sh` | **HTTP orchestrator**: default = all BEAM static+dynamic × full loads; optional `-c` / `-l` / `--quick` / scope flags. |
| `scripts/beam_gmt_http_constants.sh` | Preset request-count arrays and optional **`BEAM_GMT_HTTP_PRESET_CONTAINERS`**. |
| `scripts/run_gmt_http_sweep.sh` | Legacy wrapper → `run_beam_gmt_http.sh`. |
| `docs/LOCAL_PRODUCTION.md` | Full local checklist, env vars, troubleshooting. |
| `docs/HTTP_SWEEP.md` | Why sweeps are separate GMT runs; examples; `GMT_SWEEP_*` env vars. |
| `docs/CLUSTER_AND_GITHUB.md` | Hosted service, cluster machine types, image registry notes. |
| `docs/ADDING_SCENARIOS.md` | How to add more images following BEAM’s structure. |
| `env.example` | Optional **`env.local`** template — only if auto-discovery fails. |
| `docs/PATHS_AND_ENV.md` | Default “sibling folders” layout; overrides when needed. |
| `docs/ENERGY_METRICS.md` | Enable RAPL (or PSU on cluster) in GMT `config.yml` so stats show energy. |

## Quick start (local, production-style)

1. Install and configure **Green Metrics Tool** on Linux (official docs).  
2. Place **`green-metrics-tool`**, **`BEAM-web-server-benchmarks`**, and **`beam-gmt-benchmarks`** as **siblings** in one parent folder (see [docs/PATHS_AND_ENV.md](docs/PATHS_AND_ENV.md)) — then **no exports and no `env.local`** are required; paths are auto-detected.  
3. Build the default BEAM image **`st-erlang-index-27`** (`make build` or `docker build` in the BEAM repo).  
4. Initialize git here if needed: `git init && git add -A && git commit -m "Initial benchmark scenario"`.  
5. Run:

   ```bash
   ./scripts/run_local_production.sh
   ```

Defaults: `GMT_VAR_BEAM_IMAGE=st-erlang-index-27`, `GMT_VAR_NUM_REQUESTS=10000`. Override with environment variables before calling the script.

### Orchestrated HTTP measurements (like BEAM `make run`)

See [docs/HTTP_SWEEP.md](docs/HTTP_SWEEP.md). Quick examples:

```bash
./scripts/run_beam_gmt_http.sh --dry-run | tail -3   # preview total runs
./scripts/run_beam_gmt_http.sh                       # default: all static + dynamic × 13 loads
./scripts/run_beam_gmt_http.sh --static-only --quick
./scripts/run_beam_gmt_http.sh -c st-erlang-index-27 -l 1000
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

# Local production-style measurements

This document describes how to run **full** Green Metrics Tool (GMT) measurements against this repository on your own Linux host. The goal is **comparable, persisted results** in the GMT UI (PostgreSQL-backed runs, optimization phase, standard metric providers)—not the shortened “intro” path that uses `--dev-*` or `--skip-optimizations`.

## What “production-style” means here

| Practice | Production-style (this repo) | Intro / dev shortcuts (avoid for final numbers) |
|----------|------------------------------|--------------------------------------------------|
| Runner flags | Default runner behavior; **no** `--dev-no-system-checks`, **no** `--dev-no-save`, **no** `--skip-optimizations`, **no** `--skip-download-dependencies` | `--dev-no-system-checks`, `--skip-optimizations`, etc. |
| Results | Saved to your GMT database; visible in `stats.html` / API | `--dev-no-save` skips persistence |
| System checks | Hardware / environment checks run as GMT expects | Bypassed in dev mode |
| Optimizations | GMT runs its optimization pass (needs API + Python deps on the measurement host) | `--skip-optimizations` avoids that phase |

Follow GMT’s own installation and configuration guides for your distribution. The authoritative entry points are the [Green Metrics Tool documentation](https://docs.green-coding.io/) and the `README.md` in your GMT checkout.

## Prerequisites

1. **Green Metrics Tool** installed and configured (PostgreSQL, Redis, `config.yml`, nginx/API stack as in the official install). Use a **venv** that includes GMT’s application dependencies (including those under `docker/requirements.txt` if the optimization step imports FastAPI and related packages).
2. **Docker** with sufficient disk and permissions for GMT’s build/run flow.
3. **Git**: `runner.py --uri` must point at a **git repository** (this folder after `git init` and at least one commit).
4. **BEAM benchmark image** built locally (or pulled from a registry) using the same naming as **BEAM-web-server-benchmarks**: directory name under `benchmarks/` = Docker image name. The default scenario uses **`st-erlang-index-27`** (static Erlang “index” on OTP 27). Build it from your BEAM repo, for example:

   ```bash
   cd /path/to/BEAM-web-server-benchmarks
   make build
   # or docker build -t st-erlang-index-27 ./benchmarks/static/erlang/index/st-erlang-index-27
   ```

   Adjust the path if your layout differs; the image name must match `GMT_VAR_BEAM_IMAGE`.

5. **Port 80 inside the scenario network**: The workload calls `http://beam-server:80/`. BEAM Dockerfiles are expected to **EXPOSE 80** and serve HTTP on `/` (same assumption as the BEAM suite).

## Environment variables (health timing, optional)

The load script `tools/gmt_http_load.py` mirrors BEAM’s “wait for 200, then blast GETs” pattern. Timing is controlled by the same style of variables documented in BEAM:

| Variable | Default | Role |
|----------|---------|------|
| `MEASURE_STARTUP_WAIT` | `15` | Seconds to sleep before first health check |
| `MEASURE_HEALTH_RETRIES` | `25` | Health check attempts |
| `MEASURE_HEALTH_DELAY` | `2` | Seconds between attempts |

Set them in the **host** environment if GMT propagates them into the loadgen container, or document overrides in a fork if your runner injects env differently. For slow BEAM cold starts, increase wait/retries before filing failures.

## Run script

From this repository:

```bash
export GMT_ROOT=/path/to/green-metrics-tool
export GMT_VAR_BEAM_IMAGE=st-erlang-index-27      # optional; this is the default
export GMT_VAR_NUM_REQUESTS=10000                   # optional; default 10000
export GMT_RUN_NAME="BEAM static HTTP — st-erlang-index-27"

./scripts/run_local_production.sh
```

`GMT_PYTHON` can point to another interpreter if you do not use `$GMT_ROOT/.venv/bin/python3`.

## Manual `runner.py` invocation

Equivalent to the script:

```bash
cd /path/to/beam-gmt-benchmarks
python3 /path/to/green-metrics-tool/runner.py \
  --uri "$(pwd)" \
  --filename usage_scenario.yml \
  --name "BEAM static HTTP (GMT)" \
  --variable "__GMT_VAR_BEAM_IMAGE__=st-erlang-index-27" \
  --variable "__GMT_VAR_NUM_REQUESTS__=10000"
```

## Troubleshooting

- **“Not a git repository”**: Run `git init && git add -A && git commit -m "init"` in this repo.
- **Variable / substitution errors**: Names in YAML must match `__GMT_VAR_NAME__` and `--variable "__GMT_VAR_NAME__=value"` exactly (see GMT `runner.py` validation).
- **Optimization / FastAPI import errors**: Install GMT’s `docker/requirements.txt` into the same venv you use for `runner.py`.
- **Image not found**: Build or pull `GMT_VAR_BEAM_IMAGE` before starting the run.

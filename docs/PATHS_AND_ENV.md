# Root paths and environment variables

All local tooling resolves directories through **root variables**, not hardcoded install paths. If you move **Green Metrics Tool** or clone **beam-gmt-benchmarks** elsewhere, update one place (`env.local` or your shell profile) instead of editing scripts.

## Variables

| Variable | Required | Meaning |
|----------|----------|---------|
| `GMT_ROOT` | **Yes** (for local scripts) | Root directory of the GMT checkout — the folder that contains `runner.py`. |
| `BEAM_GMT_BENCHMARKS_ROOT` | No | Root of **this** repository (where `usage_scenario.yml` lives). Default: parent of `scripts/` relative to the script you run. Set this if your layout is unusual. |
| `BEAM_ROOT` | For sweep discovery only | Root of **BEAM-web-server-benchmarks** — the folder that contains `benchmarks/static`, `benchmarks/dynamic`. |
| `GMT_PYTHON` | No | Interpreter for `runner.py`. Default: `${GMT_ROOT}/.venv/bin/python3`, then `python3`. |
| `BEAM_GMT_ENV_FILE` | No | If set to a file path, that file is sourced **before** `env.local` (useful to keep secrets or machine paths outside the repo). |

Scripts build derived paths only from these roots, for example:

- `${GMT_ROOT}/runner.py`
- `${BEAM_GMT_BENCHMARKS_ROOT}/usage_scenario.yml` (via `REPO_ROOT` inside scripts)
- `${BEAM_ROOT}/benchmarks/static`

Trailing slashes on roots are stripped.

## Recommended setup

1. Copy the template:

   ```bash
   cp env.example env.local
   ```

2. Edit `env.local` and set at least:

   ```bash
   GMT_ROOT=/your/path/to/green-metrics-tool
   BEAM_ROOT=/your/path/to/BEAM-web-server-benchmarks   # if you use the HTTP sweep with static|dynamic|all
   ```

3. `env.local` is **gitignored**. Run scripts from this repo as usual; they auto-load `env.local` from the repository root (the directory above `scripts/` that contains `usage_scenario.yml`).

## Alternative: global profile

You may `export GMT_ROOT=...` (and others) in `~/.bashrc` instead of `env.local`.

## Alternative: config file outside the repo

```bash
export BEAM_GMT_ENV_FILE=$HOME/.config/beam-gmt-benchmarks/env.sh
./scripts/run_local_production.sh
```

`BEAM_GMT_ENV_FILE` is sourced first; then `env.local` in the repo (if present) is sourced.

## Hosted / cluster runs

On Green Coding’s infrastructure, GMT clones your Git repo; paths **inside** the scenario (`/tmp/repo/tools/...`) are defined by GMT, not by these variables. This document applies to **your** machine when you run `runner.py` locally.

# Paths: automatic by default

See [README.md](../README.md) for the full workflow. This file is only about directory layout and overrides.

## Zero-configuration layout (recommended)

Put three checkouts **next to each other** under the same parent directory:

```text
your-workspace/
  green-metrics-tool/           # official GMT clone (runner.py + lib/scenario_runner.py)
  BEAM-web-server-benchmarks/   # benchmarks/static, benchmarks/dynamic, …
  beam-gmt-benchmarks/          # this repo
```

Then run:

```bash
./scripts/run_local_production.sh
./scripts/run_beam_gmt_http.sh --static-only --super-quick
```

**No `export` and no `env.local` required.** Scripts start from this repo’s location, walk up toward `/`, and at each level look for **sibling** folders whose names match common clone names:

| What | Sibling names tried |
|------|---------------------|
| GMT | `green-metrics-tool`, `GreenMetricsTool`, `gmt`, `green-metrics-tool-main`, `GMT` |
| BEAM | `BEAM-web-server-benchmarks`, `beam-web-server-benchmarks`, `BEAM_web_server_benchmarks` |

GMT is accepted only if both `runner.py` and `lib/scenario_runner.py` exist. BEAM is accepted if `benchmarks/static` exists.

If you nest **beam-gmt-benchmarks** deeper (e.g. `experiments/beam-gmt-benchmarks`), the walk still eventually reaches a parent that also contains `green-metrics-tool`, so discovery keeps working as long as that layout holds.

## Optional overrides (only when auto-discovery fails)

Set variables **or** use `env.local` / `BEAM_GMT_ENV_FILE` if folders live elsewhere or use non-standard names.

| Variable | When |
|----------|------|
| `GMT_ROOT` | Override detected GMT root |
| `BEAM_GMT_BENCHMARKS_ROOT` | This repo root (rare; default = parent of `scripts/`) |
| `BEAM_ROOT` | BEAM suite root (override or set if discovery fails) |
| `GMT_PYTHON` | Python for `runner.py` (default `${GMT_ROOT}/.venv/bin/python3`, then `python3`) |
| `BEAM_GMT_ENV_FILE` | File sourced **before** `env.local` |
| `BEAM_GMT_VERBOSE=1` | Print auto-detected `GMT_ROOT` / `BEAM_ROOT` to stderr |

`env.local` in this repo root is **gitignored** and loaded after `BEAM_GMT_ENV_FILE`. Copy `env.example` only when you need overrides.

Trailing slashes on paths are stripped.

## Hosted / cluster runs

On Green Coding’s workers, GMT clones your Git repo; in-container paths like `/tmp/repo/tools/...` come from GMT, not from these variables. This page applies to **local** `runner.py` usage.

# beam-gmt-benchmarks

Production-oriented [Green Metrics Tool](https://metrics.green-coding.io/index.html) (GMT) scenarios for [BEAM-web-server-benchmarks](https://github.com/joegharbi/BEAM-web-server-benchmarks).

This repository connects:

- server images from [BEAM-web-server-benchmarks](https://github.com/joegharbi/BEAM-web-server-benchmarks)
- GMT scenarios and load generation
- local runs and hosted Green Coding cluster submissions

The HTTP workload follows BEAM semantics (health check + parallel GET request presets).

## Repository map

| Path | Purpose |
|------|---------|
| `usage_scenario.yml` | Variable-based single-load scenario (`__GMT_VAR_BEAM_IMAGE__`, `__GMT_VAR_NUM_REQUESTS__`). |
| `usage_scenario_full_sweep.yml` | Variable-based chained-load scenario (`--sweep`) for one-run-per-image measurements. |
| `usage_scenario_full_sweep.*.yml` | Explicit cluster-ready full-sweep scenarios (no runtime variable substitution). |
| `usage_scenario.*.n80000.yml` | Explicit single-load 80k scenarios (high-load focused checks). |
| `tools/gmt_http_load.py` | HTTP load generator used in scenarios (`--num_requests` and `--sweep`). |
| `scripts/run_beam_gmt_http.sh` | Main local orchestrator for separate vs together runs. |
| `scripts/run_local_production.sh` | Single local production-style GMT run. |
| `scripts/run_local_full_sweep.sh` | Backward-compatible alias for `run_beam_gmt_http.sh --together`. |
| `scripts/_lib_env.sh` | Shared environment/path bootstrap logic. |
| `scripts/beam_gmt_http_constants.sh` | Request-count presets and optional container presets. |
| `docs/` | Operational and methodology documentation (see index below). |

## Core documentation

- [docs/LOCAL_PRODUCTION.md](docs/LOCAL_PRODUCTION.md) - local production-style workflow
- [docs/HTTP_SWEEP.md](docs/HTTP_SWEEP.md) - separate vs together measurement modes
- [docs/CLUSTER_AND_GITHUB.md](docs/CLUSTER_AND_GITHUB.md) - hosted cluster submission workflow
- [docs/ENERGY_METRICS.md](docs/ENERGY_METRICS.md) - RAPL setup and troubleshooting

## Quick start

1. Install and configure GMT on Linux.
2. Keep these repositories as sibling folders: `green-metrics-tool`, `BEAM-web-server-benchmarks`, `beam-gmt-benchmarks`.
3. Build at least one BEAM server image (example: `st-erlang-index-27`).
4. Run a production-style local measurement:

```bash
./scripts/run_local_production.sh
```

Default single-load variables:

- `GMT_VAR_BEAM_IMAGE=st-erlang-index-27`
- `GMT_VAR_NUM_REQUESTS=10000`

For local orchestration examples (quick/full presets, static/dynamic subsets, together mode), use:

```bash
./scripts/run_beam_gmt_http.sh --help
```

## Scenario strategy (simple)

Use one of these two approaches:

1. **Variable templates**:
   - `usage_scenario.yml`
   - `usage_scenario_full_sweep.yml`
2. **Explicit scenarios** (recommended for hosted reliability):
   - fixed image and load directly in YAML
   - avoids submission-time placeholder issues

Use explicit files when hosted UI variable injection is unavailable or unreliable.

## Hosted workflow

1. Build benchmark images locally or in CI.
2. Push images to a pullable registry (e.g. `ghcr.io/...`) and set package visibility appropriately.
3. Push this repo to GitHub.
4. Submit hosted runs using explicit scenario filenames.

Hosted entry points:

- Request form: [metrics.green-coding.io/request.html](https://metrics.green-coding.io/request.html)
- Cluster profiles: [Measurement cluster](https://docs.green-coding.io/docs/measuring/measurement-cluster/)

## Public results

- Green Coding runs dashboard (joegharbi): [metrics.green-coding.io/runs.html](https://metrics.green-coding.io/runs.html?&uri=joegharbi&show_archived=false&show_other_users=true)

## Current explicit cluster scenarios

### Full sweep (one run per image, all counts chained)

- `usage_scenario_full_sweep.st-erlang-index-27.yml`
- `usage_scenario_full_sweep.st-elixir-index-1-16.yml`
- `usage_scenario_full_sweep.dy-erlang-index-27.yml`
- `usage_scenario_full_sweep.dy-elixir-index-1-16.yml`

### Single-load 80k

- `usage_scenario.st-erlang-index-27.n80000.yml`
- `usage_scenario.st-elixir-index-1-16.n80000.yml`

## Result interpretation notes

- Together mode (`--sweep`) chains loads in one run and includes thermal/state carry-over.
- Separate mode runs one load per measurement and is cleaner for per-load comparisons.
- Interpret energy together with success/failure and runtime.

## License

MIT. See [`LICENSE`](LICENSE).

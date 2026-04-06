# GitHub and hosted cluster workflow

This repository is designed to run both locally and on Green Coding hosted infrastructure.
For cluster runs, treat the process as two independent artifacts:

1. A Git repository with scenario files
2. Pullable Docker images referenced by those scenarios

## Prerequisites for hosted runs

- Repository pushed to GitHub (or another reachable git host)
- Scenario file available at repository root
- Referenced image available in a registry workers can pull
- Hosted submission with matching branch and filename

If images or repository are private, coordinate credentials with Green Coding before submission.

## Recommended hosted workflow

1. Build benchmark images from [BEAM-web-server-benchmarks](https://github.com/joegharbi/BEAM-web-server-benchmarks)
2. Push images to `ghcr.io` (or Docker Hub)
3. Set package visibility appropriately for worker access
4. Push this repository updates
5. Submit hosted run request

Request form:
- [https://metrics.green-coding.io/request.html](https://metrics.green-coding.io/request.html)

Overview:
- [Measuring with hosted service](https://docs.green-coding.io/docs/measuring/measuring-service/)

## Scenario styles in this repository

### Variable-based templates

- `usage_scenario.yml` (single-load)
- `usage_scenario_full_sweep.yml` (chained full sweep)

Required placeholders:

| Variable | Example | Purpose |
|----------|---------|---------|
| `__GMT_VAR_BEAM_IMAGE__` | `ghcr.io/your-org/st-erlang-index-27:v1` | Server image |
| `__GMT_VAR_NUM_REQUESTS__` | `80000` | Single-load request count |
| `__GMT_VAR_SWEEP_EXTRA__` | *(empty)* or `--counts 100,1000` | Optional sweep count override |

Use these when your submission path reliably injects variables.

### Explicit cluster scenarios (no placeholders)

Use these when you want deterministic hosted submissions with no variable injection risk:

- `usage_scenario_full_sweep.st-erlang-index-27.yml`
- `usage_scenario_full_sweep.st-elixir-index-1-16.yml`
- `usage_scenario_full_sweep.dy-erlang-index-27.yml`
- `usage_scenario_full_sweep.dy-elixir-index-1-16.yml`
- `usage_scenario.st-erlang-index-27.n80000.yml`
- `usage_scenario.st-elixir-index-1-16.n80000.yml`

## Suggested submission matrix

For Erlang vs Elixir and static vs dynamic comparisons:

| Dimension | Values |
|-----------|--------|
| Runtime family | `st` and `dy` |
| Language | `erlang` and `elixir` |
| Mode | full sweep together, plus optional isolated 80k checks |

Start with four full-sweep runs (one per image), then add single-load high-stress runs as needed.

## Cluster machine profile selection

Reference:
- [Measurement cluster](https://docs.green-coding.io/docs/measuring/measurement-cluster/)
- [Measurement best practices](https://docs.green-coding.io/docs/measuring/best-practices/)

In short:

- Profiling-style machines reflect more real-world power behavior
- Benchmarking-style machines usually improve strict reproducibility

Choose one profile and keep it consistent across all compared runs.

## Git URI and scenario portability

GMT runner accepts `--uri` as folder or git URL. Hosted execution clones repository state from your submitted branch. Keep scenarios portable:

- no local absolute host paths
- only container image references and in-repo script paths

This repository uses in-container paths such as `/tmp/repo/tools/...`, which are suitable for hosted execution.

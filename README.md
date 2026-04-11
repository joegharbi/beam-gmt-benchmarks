# beam-gmt-benchmarks

**Production-oriented** [Green Metrics Tool](https://metrics.green-coding.io/index.html) (GMT) scenarios for HTTP benchmarks aligned with [BEAM-web-server-benchmarks](https://github.com/joegharbi/BEAM-web-server-benchmarks): health wait, then parallel GETs for the same request-count presets as the BEAM suite. Use this repo for **reproducible energy and performance measurements** on your own GMT host or on **Green Coding’s hosted cluster**.

This repository is the **orchestration layer**: YAML scenarios, [`tools/gmt_http_load.py`](tools/gmt_http_load.py), and shell scripts. **Docker images** are built from the BEAM repository and referenced by local tag or registry URL (e.g. `ghcr.io/joegharbi/st-erlang-index-27:v1`).

### Where to find full results (public runs)

Hosted measurements submitted under this work appear on the Green Coding ScenarioRunner dashboard (filter by URI `joegharbi`):

**[https://metrics.green-coding.io/runs.html?&uri=joegharbi&show_archived=false&show_other_users=true](https://metrics.green-coding.io/runs.html?&uri=joegharbi&show_archived=false&show_other_users=true)**

From there you can open individual runs, timelines, and comparisons. The same link is repeated after the hosted submission steps below.

---

## Contents at a glance

| What | Where |
|------|--------|
| Single-load template (variables) | [`usage_scenario.yml`](usage_scenario.yml) |
| Full sweep in one measurement (variables) | [`usage_scenario_full_sweep.yml`](usage_scenario_full_sweep.yml) |
| Full sweep, image pinned (no variables) | `usage_scenario_full_sweep.<image>.yml` |
| Single load 80k, image pinned | `usage_scenario.<image>.n80000.yml` |
| Load generator | [`tools/gmt_http_load.py`](tools/gmt_http_load.py) |
| Local HTTP orchestration | [`scripts/run_beam_gmt_http.sh`](scripts/run_beam_gmt_http.sh) |
| One local production-style run | [`scripts/run_local_production.sh`](scripts/run_local_production.sh) |

---

## Reproduce a hosted measurement (Green Coding)

These steps match the working flow on [metrics.green-coding.io/request.html](https://metrics.green-coding.io/request.html).

1. **Build** the server image from [BEAM-web-server-benchmarks](https://github.com/joegharbi/BEAM-web-server-benchmarks) (directory name = image tag, e.g. `st-erlang-index-27`).
2. **Tag and push** to a registry workers can pull (often `ghcr.io`). Set the package to **public** unless Green Coding has given you private pull credentials.
3. **Push** this repository to GitHub so the hosted runner can clone it.
4. Open the [measurement request form](https://metrics.green-coding.io/request.html). Fill repository URL, branch (e.g. `main`), and scenario filename (e.g. `usage_scenario.yml`).
5. **Usage scenario variables** — the form already shows `__GMT_VAR_` … `__` around the key field. Enter only the **middle part** of the variable name:

| In the form “key” column | Value example | Becomes in YAML |
|---------------------------|---------------|-----------------|
| `BEAM_IMAGE` | `ghcr.io/joegharbi/st-erlang-index-27:v1` | `__GMT_VAR_BEAM_IMAGE__` |
| `NUM_REQUESTS` | `40000` | `__GMT_VAR_NUM_REQUESTS__` |

Do **not** type the full `__GMT_VAR_BEAM_IMAGE__` in the key box; that would produce a double-wrapped name and placeholders would not be replaced (you would get an email about “Unreplaced leftover variables”).

6. Submit and wait for the result email. When the run is processed, find it on the **[full results dashboard](https://metrics.green-coding.io/runs.html?&uri=joegharbi&show_archived=false&show_other_users=true)** (same as the link at the top of this README).

For **full sweep** with the variable template, use [`usage_scenario_full_sweep.yml`](usage_scenario_full_sweep.yml) and add:

| Key column | Value |
|------------|--------|
| `BEAM_IMAGE` | your `ghcr.io/...` image |
| `SWEEP_EXTRA` | leave **empty** for the default 13-point list, or e.g. `--counts 100,1000,80000` |

---

## Reproduce a local measurement

1. Install [Green Metrics Tool](https://docs.green-coding.io/) on Linux (PostgreSQL, Docker, `config.yml`, venv with app dependencies).
2. Place three folders as **siblings**: `green-metrics-tool`, `BEAM-web-server-benchmarks`, `beam-gmt-benchmarks` (paths are auto-detected; see [docs/PATHS_AND_ENV.md](docs/PATHS_AND_ENV.md)).
3. Build at least one BEAM image locally (same names as in the BEAM repo).
4. From `beam-gmt-benchmarks`:

```bash
./scripts/run_local_production.sh
```

Defaults: `GMT_VAR_BEAM_IMAGE=st-erlang-index-27`, `GMT_VAR_NUM_REQUESTS=10000`. For many images and loads:

```bash
./scripts/run_beam_gmt_http.sh --help
./scripts/run_beam_gmt_http.sh -c st-erlang-index-27 -l 1000
./scripts/run_beam_gmt_http.sh --together -c st-erlang-index-27
```

Full local checklist: [docs/LOCAL_PRODUCTION.md](docs/LOCAL_PRODUCTION.md). Laptop RAPL issues: [docs/ENERGY_METRICS.md](docs/ENERGY_METRICS.md).

---

## Variable templates vs explicit YAML

- **Templates** (`usage_scenario.yml`, `usage_scenario_full_sweep.yml`): one file, many runs; pass variables from the hosted form (keys `BEAM_IMAGE`, `NUM_REQUESTS`, …) or from `runner.py --variable`.
- **Explicit files** (`usage_scenario_full_sweep.st-erlang-index-27.yml`, `usage_scenario.st-erlang-index-27.n80000.yml`, …): image and load are fixed in the file; submit **without** variables — useful for batch jobs or when you want filenames to document the exact configuration.

---

## Pinned scenarios in this repository

**Full sweep (one GMT run per file, chained loads):**

- `usage_scenario_full_sweep.st-erlang-index-27.yml`
- `usage_scenario_full_sweep.st-elixir-index-1-16.yml`
- `usage_scenario_full_sweep.dy-erlang-index-27.yml`
- `usage_scenario_full_sweep.dy-elixir-index-1-16.yml`

**Single load 80k:**

- `usage_scenario.st-erlang-index-27.n80000.yml`
- `usage_scenario.st-elixir-index-1-16.n80000.yml`

Image lines in these files use `ghcr.io/joegharbi/...:v1` — fork or search-replace for your registry and tag before pushing.

---

## Interpreting results

- **Together** (`--sweep`): one run chains all loads; expect shared thermal and server state between steps — not the same as isolated per-load runs.
- **Separate** (default in `run_beam_gmt_http.sh`): one GMT measurement per load level; cleaner for point-by-point curves.
- Compare **energy** together with **runtime**, **success/failure counts** (see `GMT_HTTP_LOAD_SUMMARY` in logs), and the **machine profile** label on the run.

---

## Documentation

| Document | Topic |
|----------|--------|
| [docs/CLUSTER_AND_GITHUB.md](docs/CLUSTER_AND_GITHUB.md) | Hosted workflow, variables, machine profiles |
| [docs/HTTP_SWEEP.md](docs/HTTP_SWEEP.md) | Separate vs together, presets, examples |
| [docs/LOCAL_PRODUCTION.md](docs/LOCAL_PRODUCTION.md) | Local production-style runs |
| [docs/ENERGY_METRICS.md](docs/ENERGY_METRICS.md) | RAPL, laptop bypass, troubleshooting |
| [docs/PATHS_AND_ENV.md](docs/PATHS_AND_ENV.md) | Layout and environment overrides |
| [docs/ADDING_SCENARIOS.md](docs/ADDING_SCENARIOS.md) | New images, naming, WebSocket limits |
| [docs/ARCHITECTURE_FLOW.md](docs/ARCHITECTURE_FLOW.md) | Diagram: BEAM ↔ this repo ↔ GMT ↔ host |

Official GMT docs: [docs.green-coding.io](https://docs.green-coding.io/).

---

## License

MIT. See [LICENSE](LICENSE).

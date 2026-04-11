# Adding more measurements (align with BEAM-web-server-benchmarks)

Upstream benchmark definitions: [BEAM-web-server-benchmarks](https://github.com/joegharbi/BEAM-web-server-benchmarks). The BEAM suite discovers benchmarks by directory layout and uses the **directory name** as the Docker **image** name (`benchmarks/<type>/.../<container>/` → image `st-erlang-cowboy-27`, etc.). This repository reuses **the same image names** so GMT runs line up with BEAM CSV rows.

## Scenario patterns

**Pattern A — variable templates:**  
Keep a single `usage_scenario.yml` and pass different values per run. Locally use `--variable "__GMT_VAR_BEAM_IMAGE__=..."`. On the hosted form, use keys **`BEAM_IMAGE`** and **`NUM_REQUESTS`** only (the UI builds `__GMT_VAR_...__`); see [CLUSTER_AND_GITHUB.md](CLUSTER_AND_GITHUB.md).

**Pattern A′ — variable full sweep:**  
Use `usage_scenario_full_sweep.yml` plus `__GMT_VAR_BEAM_IMAGE__` (and optional `__GMT_VAR_SWEEP_EXTRA__`). Details: [HTTP_SWEEP.md](HTTP_SWEEP.md).

**Pattern B — explicit named scenarios (pinned image/load; optional hosted path with zero variables):**  
Copy the root file to a new name and pin values for deterministic submissions:

```text
usage_scenario.yml
usage_scenario.st-erlang-index-27.n80000.yml
usage_scenario_full_sweep.st-erlang-index-27.yml
usage_scenario_full_sweep.dy-elixir-index-1-16.yml
```

Run with (default layout auto-sets roots; otherwise `source env.local` — see [PATHS_AND_ENV.md](PATHS_AND_ENV.md)):

```bash
"${GMT_PYTHON:-${GMT_ROOT}/.venv/bin/python3}" "${GMT_ROOT}/runner.py" \
  --uri "${BEAM_GMT_BENCHMARKS_ROOT}" \
  --filename usage_scenario.st-erlang-index-27.n80000.yml \
  --name "BEAM static Erlang n80000"
```

If you literalize `image:` and `num_requests` in the YAML, omit runtime variables for that file and ensure no `__GMT_VAR_*__` placeholders remain.

## Naming convention (recommended)

Use filename patterns that encode scope and workload directly:

- Single-load: `usage_scenario.<st|dy>-<lang>-<app>-<version>.n<requests>.yml`
- Full sweep: `usage_scenario_full_sweep.<st|dy>-<lang>-<app>-<version>.yml`

Examples:

- `usage_scenario.st-erlang-index-27.n80000.yml`
- `usage_scenario.dy-elixir-index-1-16.n80000.yml`
- `usage_scenario_full_sweep.st-elixir-index-1-16.yml`

## Checklist for each new server image

1. **BEAM repo**: Image exists under `benchmarks/static/`, `benchmarks/dynamic/`, or `benchmarks/websocket/` with **EXPOSE 80** and HTTP on `/` (WebSocket scenarios need a different flow—not covered by the current `gmt_http_load.py`).
2. **Naming**: Use the same **image tag** as BEAM (`st-*`, `dy-*`, `ws-*` prefixes).
3. **GMT scenario**: Point `beam-server.image` at that name (or registry URL).
4. **Load**: For plain HTTP GET benchmarks, reuse `tools/gmt_http_load.py` and the same `flow` block; only change variables or duplicate the file.
5. **Document**: Add the scenario filename and purpose to `README.md`.

## WebSocket and other protocols

The current load generator is **HTTP GET only**. For `ws-*` containers from BEAM, add a separate scenario (and tool) modeled on BEAM’s `measure_websocket.py` behavior if you need parity; do not pretend the HTTP scenario measures WebSocket traffic.

## Relations (optional)

GMT supports `relations` between services for documentation/diagrams. For a simple two-service chain (`loadgen` → `beam-server`), the defaults are often enough; add explicit relations when the topology grows (e.g. cache + app + loadgen).

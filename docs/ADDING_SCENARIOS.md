# Adding more measurements (align with BEAM-web-server-benchmarks)

The BEAM suite discovers benchmarks by directory layout and uses the **directory name** as the Docker **image** name (see BEAM `README.md`: `benchmarks/<type>/.../<container>/` → image `st-erlang-cowboy-27`, etc.). This GMT package reuses **the same image names** so energy and traffic from GMT can be compared conceptually to BEAM CSV runs.

## One scenario file per measurement variant

**Pattern A — variables (recommended for cluster):**  
Keep a single `usage_scenario.yml` and pass different `__GMT_VAR_BEAM_IMAGE__` / `__GMT_VAR_NUM_REQUESTS__` per run (local `--variable` flags or hosted UI).

**Pattern A′ — full BEAM-style HTTP sweep:**  
Use `scripts/run_gmt_http_sweep.sh` to repeat the same **request-count lists** as `BEAM-web-server-benchmarks/scripts/run_benchmarks.sh` (100 through 80000, or `--quick` / `--super-quick`). Details: [HTTP_SWEEP.md](HTTP_SWEEP.md).

**Pattern B — named scenario files:**  
Copy the root file to a new name and pin values for clarity in Git history:

```text
usage_scenario.yml                          # default / documentation entry
usage_scenario.st-erlang-cowboy-27.yml      # image + N fixed in file
usage_scenario.dy-elixir-phoenix-1-8.yml
```

Run with (after `source env.local` or exporting roots; see [PATHS_AND_ENV.md](PATHS_AND_ENV.md)):

```bash
"${GMT_PYTHON:-${GMT_ROOT}/.venv/bin/python3}" "${GMT_ROOT}/runner.py" \
  --uri "${BEAM_GMT_BENCHMARKS_ROOT}" \
  --filename usage_scenario.st-erlang-cowboy-27.yml \
  --name "..." \
  --variable "__GMT_VAR_BEAM_IMAGE__=st-erlang-cowboy-27" \
  --variable "__GMT_VAR_NUM_REQUESTS__=10000"
```

If you literalize `image:` and `num_requests` in the YAML, you can omit variables for that file—just ensure every `__GMT_VAR_*__` placeholder is either removed or still supplied.

## Checklist for each new server image

1. **BEAM repo**: Image exists under `benchmarks/static/`, `benchmarks/dynamic/`, or `benchmarks/websocket/` with **EXPOSE 80** and HTTP on `/` (WebSocket scenarios need a different flow—not covered by the current `gmt_http_load.py`).
2. **Naming**: Use the same **image tag** as BEAM (`st-*`, `dy-*`, `ws-*` prefixes).
3. **GMT scenario**: Point `beam-server.image` at that name (or registry URL).
4. **Load**: For plain HTTP GET benchmarks, reuse `tools/gmt_http_load.py` and the same `flow` block; only change variables or duplicate the file.
5. **Document**: Add one line to the “Scenarios” table in the main `README.md` (image name, type, notes).

## WebSocket and other protocols

The current load generator is **HTTP GET only**. For `ws-*` containers from BEAM, add a separate scenario (and tool) modeled on BEAM’s `measure_websocket.py` behavior if you need parity; do not pretend the HTTP scenario measures WebSocket traffic.

## Relations (optional)

GMT supports `relations` between services for documentation/diagrams. For a simple two-service chain (`loadgen` → `beam-server`), the defaults are often enough; add explicit relations when the topology grows (e.g. cache + app + loadgen).

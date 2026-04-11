# GitHub and hosted cluster workflow

Hosted measurements use two things the workers must reach:

1. **This Git repository** (scenarios and `tools/gmt_http_load.py`)
2. **Docker images** for `beam-server` (usually from [BEAM-web-server-benchmarks](https://github.com/joegharbi/BEAM-web-server-benchmarks), pushed to `ghcr.io` or another registry)

If either the repo or the registry is private, arrange access with Green Coding before submitting.

---

## Request form

- Submit software: [metrics.green-coding.io/request.html](https://metrics.green-coding.io/request.html)
- Service overview: [Measuring with hosted service](https://docs.green-coding.io/docs/measuring/measuring-service/)

---

## Usage scenario variables (hosted form)

The form wraps each key as `__GMT_VAR_<your-key>__`. In the **key** field, enter **only** the middle segment (letters, digits, underscores).

### Single-load template — `usage_scenario.yml`

| Key field (as shown in form) | Value field |
|------------------------------|-------------|
| `BEAM_IMAGE` | Full image reference, e.g. `ghcr.io/joegharbi/st-erlang-index-27:v1` |
| `NUM_REQUESTS` | Integer, e.g. `40000` |

**Common mistake:** typing `__GMT_VAR_BEAM_IMAGE__` in the key box. That produces an invalid doubled name and you get an email: *Unreplaced leftover variables are still in usage_scenario*.

### Full-sweep template — `usage_scenario_full_sweep.yml`

| Key field | Value field |
|-----------|-------------|
| `BEAM_IMAGE` | Full image reference |
| `SWEEP_EXTRA` | Leave **empty** for the default 13-point BEAM list, or e.g. `--counts 100,5000,80000` |

---

## Scenario styles in this repo

**Variable templates** (one YAML, many runs via variables):

- `usage_scenario.yml`
- `usage_scenario_full_sweep.yml`

**Explicit YAML** (no variables on submit; image and load are fixed in the file):

- `usage_scenario_full_sweep.st-erlang-index-27.yml` (and Elixir / dynamic variants)
- `usage_scenario.st-erlang-index-27.n80000.yml` (and Elixir variant)

Adjust `ghcr.io/joegharbi/...` in explicit files if you use another registry or user.

---

## Study matrix (example)

| Axis | Typical values |
|------|----------------|
| Workload shape | `st` (static) vs `dy` (dynamic) |
| Language | Erlang vs Elixir (e.g. `*-index-*` pairs) |
| GMT mode | Full sweep in one run vs many single-load runs |

Keep **machine profile** consistent across runs you intend to compare directly. See [Measurement cluster](https://docs.green-coding.io/docs/measuring/measurement-cluster/) and [best practices](https://docs.green-coding.io/docs/measuring/best-practices/).

---

## Portability rules

Hosted execution clones your branch. Scenarios must not depend on host-only paths. Image references may be local tags on a dev machine or full registry URLs on the cluster. Loadgen uses paths under the cloned repo, e.g. `/tmp/repo/tools/gmt_http_load.py` after GMT prepares the container.

---

## Local `runner.py` (same variables as YAML)

Use full placeholder names with `--variable`:

```bash
"${GMT_ROOT}/.venv/bin/python3" "${GMT_ROOT}/runner.py" \
  --uri "${BEAM_GMT_BENCHMARKS_ROOT}" \
  --filename usage_scenario.yml \
  --name "example" \
  --variable "__GMT_VAR_BEAM_IMAGE__=ghcr.io/joegharbi/st-erlang-index-27:v1" \
  --variable "__GMT_VAR_NUM_REQUESTS__=40000"
```

For full sweep:

```bash
--variable "__GMT_VAR_BEAM_IMAGE__=ghcr.io/joegharbi/st-erlang-index-27:v1" \
--variable "__GMT_VAR_SWEEP_EXTRA__="
```

(Empty `SWEEP_EXTRA` keeps the default sweep in `gmt_http_load.py`.)

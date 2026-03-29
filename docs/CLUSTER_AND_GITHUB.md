# GitHub layout and Green Coding measurement cluster

This repository is structured so you can **push it to GitHub** (or any Git host) and either run it locally (see [LOCAL_PRODUCTION.md](LOCAL_PRODUCTION.md)) or use **Green Coding’s hosted infrastructure**. On your own machine, paths are **auto-detected** when GMT and BEAM sit next to this repo; optional **`GMT_ROOT`** / **`BEAM_ROOT`** overrides are in [PATHS_AND_ENV.md](PATHS_AND_ENV.md).

## What must be in the repo

Per [Measuring with hosted service](https://docs.green-coding.io/docs/measuring/measuring-service/) and GMT conventions:

- A **`usage_scenario.yml`** at the repository root (this repo provides one). For **one hosted job** that runs the **full in-container sweep**, use **`usage_scenario_full_sweep.yml`** and set **`__GMT_VAR_BEAM_IMAGE__`** plus **`__GMT_VAR_SWEEP_EXTRA__`** (empty string for the default 13-point list; or e.g. `--counts 100,1000` — see [HTTP_SWEEP.md](HTTP_SWEEP.md)).
- **Containerized** workloads: the scenario references Docker **images**. The cluster runners must be able to **pull** those images (or build them from Dockerfiles in the repo—depending on how you integrate with GMT; the common case is a public registry image).

This repo does **not** embed the full BEAM benchmark Dockerfiles; it assumes the **image name** you pass (e.g. `st-erlang-index-27`) exists on the machine that executes the scenario. For hosted runs you typically:

1. Build images in CI and push to **GitHub Container Registry** (`ghcr.io/...`) or Docker Hub, then  
2. Set `__GMT_VAR_BEAM_IMAGE__` to that full reference when scheduling the measurement, **or**  
3. Replace the variable in a branch-specific `usage_scenario.yml` with the pinned image digest.

## Hosted measurement service

- **Request a run**: [https://metrics.green-coding.io/request.html](https://metrics.green-coding.io/request.html)  
- **Overview**: [Measuring with hosted service](https://docs.green-coding.io/docs/measuring/measuring-service/)

Supply your Git repository URL, branch, and—if the UI supports it—the **usage scenario variables**:

| Variable | Example | Meaning |
|----------|---------|---------|
| `__GMT_VAR_BEAM_IMAGE__` | `ghcr.io/your-org/st-erlang-index-27:v1` | Server image to measure |
| `__GMT_VAR_NUM_REQUESTS__` | `10000` | Total parallel GETs (`usage_scenario.yml` single-load scenario) |
| `__GMT_VAR_SWEEP_EXTRA__` | *(empty)* or `--counts 100,1000` | **`usage_scenario_full_sweep.yml` only**: append to `gmt_http_load.py --sweep`; empty = full BEAM list |

If the hosted form does not expose variables, duplicate `usage_scenario.yml` on a branch with literal `image:` and `num_requests` values, or open a scenario file per image (see [ADDING_SCENARIOS.md](ADDING_SCENARIOS.md)).

## Measurement cluster (machine types)

[Measurement cluster](https://docs.green-coding.io/docs/measuring/measurement-cluster/) documents **machine profiles** (e.g. profiling vs benchmarking, DVFS on/off, PSU metric providers). Choose a profile that matches your study:

- **Profiling-style** machines: closer to “off-the-shelf” power behavior.  
- **Benchmarking-style** machines: more reproducible CPU frequency and related settings.

Also read [measurement best practices](https://docs.green-coding.io/docs/measuring/best-practices/) (sampling rates, etc.) so results are comparable across runs.

## `usage_scenario.yml` and Git URI

GMT’s `runner.py` accepts `--uri` as a **folder** or a **git URL**. Hosted/cluster execution uses the remote Git state; keep the scenario file **free of machine-specific absolute paths**. This repo only references:

- Image names (parameterized).
- Paths **inside** the cloned repo (`/tmp/repo/tools/...` after GMT copies the repo into the loadgen container).

## Private repositories

If the repo or container registry is private, coordinate with Green Coding (enterprise / credentials) so workers can clone and pull images. Public GitHub + public `ghcr.io` images are the straightforward path for free-tier hosted requests.

# Three-repository flow (BEAM → GMT)

How **beam-gmt-benchmarks** sits between the **host**, **Green Metrics Tool**, and **BEAM-web-server-benchmarks** when you run measurements. Use this diagram in documentation or slides; details live in the linked guides below.

## Flow

```mermaid
flowchart LR
  subgraph host [Host]
    MSRs[RAPL / MSRs]
    Docker[Docker]
  end
  subgraph gmt [green-metrics-tool]
    Runner[runner.py]
    Config[config.yml]
    DB[(DB / UI)]
  end
  subgraph beam [BEAM-web-server-benchmarks]
    Img[Docker images]
  end
  subgraph orch [beam-gmt-benchmarks]
    YML[usage_scenario.yml]
    Scripts[run_* scripts]
  end
  Img --> Docker
  Scripts --> Runner
  YML --> Runner
  Config --> Runner
  MSRs --> Runner
  Runner --> DB
```

## Reading the diagram

| Box | Role |
|-----|------|
| **Host** | Runs Docker; optional **RAPL** (MSRs) for package energy — needs `msr` / setuid helpers for full GMT providers (see [ENERGY_METRICS.md](ENERGY_METRICS.md)). |
| **green-metrics-tool** | **`runner.py`** loads **`config.yml`**, runs the scenario, ingests metrics into the **DB** for **stats / UI**. |
| **BEAM-web-server-benchmarks** | Source of **Docker images** (e.g. `st-erlang-index-27`); build with `make build` or `docker build`. |
| **beam-gmt-benchmarks** | **`usage_scenario.yml`** defines containers; **`scripts/`** orchestrates invocations (e.g. [HTTP_SWEEP.md](HTTP_SWEEP.md)). |

Suggested order: **host + GMT** → **build images** → run scripts from **this repo** (they `cd` here so `git` and `--uri` match GMT’s expectations). Folder layout without manual `export`: [PATHS_AND_ENV.md](PATHS_AND_ENV.md).

## Paths by goal

| Goal | Where to start |
|------|----------------|
| Smoke test (one run) | [HTTP_SWEEP.md](HTTP_SWEEP.md) (`-c … -l 100`) |
| Production-style local runs | [LOCAL_PRODUCTION.md](LOCAL_PRODUCTION.md) |
| RAPL / energy metrics | [ENERGY_METRICS.md](ENERGY_METRICS.md) |
| Hosted cluster | [CLUSTER_AND_GITHUB.md](CLUSTER_AND_GITHUB.md) |

## Rendering the diagram

- **GitHub**: native Mermaid in Markdown (this file).
- **VS Code / Cursor**: Markdown preview with Mermaid support, or paste the `flowchart LR` block into [mermaid.live](https://mermaid.live) for PNG/SVG export.

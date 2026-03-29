# Local energy (RAPL) and reading concrete values

## 1. Enable RAPL in GMT

In **`green-metrics-tool/config.yml`**, under `measurement.metric_providers.linux`, keep CPU utilization and **uncomment** the two RAPL **component** providers:

```yaml
      cpu.utilization.procfs.system.provider.CpuUtilizationProcfsSystemProvider:
        sampling_rate: 99
      cpu.energy.rapl.msr.component.provider.CpuEnergyRaplMsrComponentProvider:
        sampling_rate: 99
      memory.energy.rapl.msr.component.provider.MemoryEnergyRaplMsrComponentProvider:
        sampling_rate: 99
```

On the next run the log should include:

- `Importing CpuEnergyRaplMsrComponentProvider`
- `Importing MemoryEnergyRaplMsrComponentProvider`

## 2. Git checkout: `hardware_info_root.py`

RAPL providers call a sudo helper to verify RAPL energy filtering. A **full GMT install** puts that script under `/usr/local/bin/green-metrics-tool/`. On a **git clone**, the repo should include **`hardware_info_root.py` at the root of `green-metrics-tool/`**, and `lib/utils.py` resolves it automatically. You can override with **`GMT_HARDWARE_INFO_ROOT`** if needed.

## 3. Host checklist

```bash
./scripts/check_rapl_ready.sh
```

Install **`msr-tools`** (Debian/Ubuntu: `sudo apt install msr-tools`) so `/usr/sbin/rdmsr` exists. Load **`msr`**: `sudo modprobe msr`.

## 4. One Erlang container × all 13 BEAM HTTP loads

Omit **`-l`**: the orchestrator uses the full list  
`100 1000 5000 8000 10000 15000 20000 30000 40000 50000 60000 70000 80000`.

```bash
cd /path/to/beam-gmt-benchmarks
./scripts/run_beam_gmt_http.sh -c st-erlang-index-27
```

That runs **13** separate GMT measurements (one per load). Build the image first (`make build` in BEAM-web-server-benchmarks or `docker build -t st-erlang-index-27 …`).

Options:

- **`GMT_SWEEP_CONTINUE_ON_ERROR=1`** — continue if one load fails.
- **`--dry-run`** — print all 13 `runner.py` commands without running.

## 5. Where the numbers appear in the UI

Open each run’s **`stats.html?id=…`** link from the console. In the **Energy metrics** / phase charts, look for series tied to:

- **`cpu_energy_rapl_msr_component`** (microjoules per sample in provider data)
- **`memory_energy_rapl_msr_component`**

Exact chart labels follow GMT’s frontend naming; if a phase chart is empty, use the **Measurement** / raw metrics tabs for that run to confirm samples were stored.

## 6. Cgroup providers (optional)

Uncomment cgroup CPU/memory/IO providers in the same `config.yml` section if you want **per-container** utilization alongside RAPL. They do not replace package-level joules from RAPL.

## 7. If RAPL still fails

- VM / cloud instance: MSRs often blocked → use [measurement cluster](https://docs.green-coding.io/docs/measuring/measurement-cluster/) for PSU-based energy.
- Errors mentioning **`rdmsr`** or **MSR**: install `msr-tools`, run with sudo working, check firmware/BIOS.

Official: [Metric providers](https://docs.green-coding.io/docs/measuring/metric-providers/).

## Relation to BEAM + Scaphandre

BEAM may use **Scaphandre** on the host; GMT uses **`config.yml` providers**. Compare plots only when you are clear which sensor stack each number comes from.

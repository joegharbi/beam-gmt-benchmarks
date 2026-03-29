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

## 3. `rdmsr:open: Permission denied` (most common failure)

GMT’s RAPL helpers are small C programs (`metric-provider-binary`) that read MSRs. They are meant to be installed **setuid root** so a normal user can run measurements without joining the `msr` group.

**Fix:** from `beam-gmt-benchmarks`, run (will prompt for `sudo` a few times):

```bash
./scripts/build_gmt_rapl_providers.sh
```

That runs `make gmt-lib.o` in `green-metrics-tool/lib/c` (only what RAPL links — **not** the full `lib/c` default target, which needs `libcurl` headers), then `make` in the CPU and memory RAPL `component/` directories (`chown root:root` + `chmod u+s` on each binary).

Verify:

```bash
ls -l "$GMT_ROOT/metric_providers/cpu/energy/rapl/msr/component/metric-provider-binary"
# expect owner root and 's' in user execute bit (e.g. -rwsr-xr-x)
"$GMT_ROOT/metric_providers/cpu/energy/rapl/msr/component/metric-provider-binary" -c
```

If you still see **`youssef:youssef`** and **no `s` bit**, `make` likely said “up to date” and never ran the Makefile’s `chown`/`chmod`. Re-run **`./scripts/build_gmt_rapl_providers.sh`** — it always applies **`sudo chown root:root`** and **`chmod u+s`** after the build.

Alternative (not the default GMT path): add your user to group **`msr`** and use udev rules so `/dev/cpu/*/msr` is group-readable; the **setuid build** above is what the official Makefile encodes.

### `RAPL energy filtering is active and might skew results`

After setuid works, GMT still runs **`sudo … hardware_info_root.py --read-rapl-energy-filtering`**, which reads MSR **0xBC**. If the platform reports **active** RAPL/power filtering (common on **laptops** with OEM power limits, “balanced” profiles, or dynamic PL), the CPU/DRAM RAPL providers **exit on purpose** — clamped hardware makes package energy hard to interpret.

**Try first:** AC power, BIOS/OS **high performance**, relax power limits where your machine allows, or run on a **desktop / lab PC** with fewer OEM clamps.

**Check (raw):** `sudo rdmsr 0xbc -d` (meaning is model-specific; GMT treats a stripped output of **`1`** as “filtering on”.)

**Last resort — local experiments only** (do **not** treat as Green Coding–grade “unfiltered” RAPL without disclosure):

```bash
export GMT_IGNORE_RAPL_ENERGY_FILTERING_CHECK=1
./scripts/run_beam_gmt_http.sh -c st-erlang-index-27 -l 1000
```

Handled in **`green-metrics-tool/lib/utils.py`** (`is_rapl_energy_filtering_deactivated`). You can put the export in **`env.local`** next to `beam-gmt-benchmarks` if you source it before runs.

## 4. Host checklist

```bash
./scripts/check_rapl_ready.sh
```

Install **`msr-tools`** (Debian/Ubuntu: `sudo apt install msr-tools`) so `/usr/sbin/rdmsr` exists for diagnostics. Load **`msr`**: `sudo modprobe msr`.

## 5. One Erlang container × all 13 BEAM HTTP loads

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

## 6. Where the numbers appear in the UI

Open each run’s **`stats.html?id=…`** link from the console. In the **Energy metrics** / phase charts, look for series tied to:

- **`cpu_energy_rapl_msr_component`** (microjoules per sample in provider data)
- **`memory_energy_rapl_msr_component`**

Exact chart labels follow GMT’s frontend naming; if a phase chart is empty, use the **Measurement** / raw metrics tabs for that run to confirm samples were stored.

## 7. Cgroup providers (optional)

Uncomment cgroup CPU/memory/IO providers in the same `config.yml` section if you want **per-container** utilization alongside RAPL. They do not replace package-level joules from RAPL.

## 8. If RAPL still fails

- VM / cloud instance: MSRs often blocked → use [measurement cluster](https://docs.green-coding.io/docs/measuring/measurement-cluster/) for PSU-based energy.
- Errors mentioning **`rdmsr`** or **MSR**: install `msr-tools`, run with sudo working, check firmware/BIOS.

Official: [Metric providers](https://docs.green-coding.io/docs/measuring/metric-providers/).

## Relation to BEAM + Scaphandre

BEAM may use **Scaphandre** on the host; GMT uses **`config.yml` providers**. Compare plots only when you are clear which sensor stack each number comes from.

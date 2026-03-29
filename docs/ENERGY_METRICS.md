# Seeing energy (joules / power) in GMT

## Why you only see CPU utilization

GMT plots whatever **metric providers** are enabled in **`green-metrics-tool/config.yml`** under `measurement.metric_providers.linux`.

A typical dev config has only:

- `CpuUtilizationProcfsSystemProvider`

That gives **CPU %**, not **energy**. RAPL and PSU providers are **commented out** by default.

## Next step on your own Linux machine: RAPL (most common)

If your CPU exposes **Intel RAPL** (many Intel/AMD laptops and desktops), enable the **component** MSR providers in `config.yml` (same names as in `config.yml.example`):

```yaml
    linux:
      cpu.utilization.procfs.system.provider.CpuUtilizationProcfsSystemProvider:
        sampling_rate: 99
      cpu.energy.rapl.msr.component.provider.CpuEnergyRaplMsrComponentProvider:
        sampling_rate: 99
      memory.energy.rapl.msr.component.provider.MemoryEnergyRaplMsrComponentProvider:
        sampling_rate: 99
```

Then run a measurement again. In the console you should see lines like:

`Importing CpuEnergyRaplMsrComponentProvider`

**Requirements (typical):**

- `msr` kernel module loaded (`sudo modprobe msr` if needed).
- Access to MSRs so the provider can read RAPL counters (GMT often runs parts of the flow with **`sudo`**; if a provider fails, check GMT’s provider docs and dmesg).
- RAPL may be limited or absent on some VMs or locked-down firmware.

**Quick checks on the host:**

```bash
ls /sys/class/powercap/intel-rapl 2>/dev/null || ls /sys/devices/virtual/powercap 2>/dev/null
```

If those paths exist, RAPL is often available at the OS level.

Official detail: [Metric providers](https://docs.green-coding.io/docs/measuring/metric-providers/) and installation overview linked from there.

## Cgroup providers (optional, not a full substitute for joules)

Uncommenting **cgroup** CPU/memory/network/disk providers helps **attribute resource use to containers**. They complement RAPL; they do not replace **package/CPU energy** counters if your goal is joules at the hardware counter level.

## Lab / wall power (PSU)

Providers such as **MCP / IPMI / Gude** need specific hardware. That is what Green Coding’s **measurement cluster** machines often use; see [Measurement cluster](https://docs.green-coding.io/docs/measuring/measurement-cluster/).

## After it works

Re-run:

```bash
./scripts/run_beam_gmt_http.sh -c st-erlang-index-27 -l 1000
```

Open the same **stats** URL; energy series should appear under the metric provider names GMT uses (e.g. RAPL-related keys in the charts / raw metrics).

## Relation to BEAM + Scaphandre

Your **BEAM-web-server-benchmarks** stack may use **Scaphandre** on the host. **GMT** uses its **own** providers from `config.yml`. For comparable narratives, document both: “BEAM = Scaphandre attribution; GMT = RAPL/PSU as configured.”

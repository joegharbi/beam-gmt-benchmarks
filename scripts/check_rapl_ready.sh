#!/usr/bin/env bash
# Quick local checks before enabling RAPL in green-metrics-tool/config.yml.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib_env.sh
source "${SCRIPT_DIR}/_lib_env.sh"

echo "=== RAPL / MSR sanity (host) ==="
if [[ -d /sys/class/powercap/intel-rapl ]]; then
  echo "OK: /sys/class/powercap/intel-rapl exists"
else
  echo "WARN: no intel-rapl under /sys/class/powercap (RAPL may be unavailable)"
fi

if lsmod | grep -q '^msr '; then
  echo "OK: kernel module 'msr' is loaded"
else
  echo "TIP: sudo modprobe msr"
fi

if [[ -r /dev/cpu/0/msr ]]; then
  echo "OK: /dev/cpu/0/msr readable as your user (optional; see setuid check below)"
else
  echo "NOTE: /dev/cpu/0/msr not readable as your user — normal. GMT RAPL binaries should be setuid root OR you use the 'msr' group + udev."
fi

if command -v rdmsr >/dev/null 2>&1; then
  echo "OK: rdmsr found at $(command -v rdmsr)"
else
  echo "WARN: rdmsr not found (install msr-tools on Debian/Ubuntu)"
fi

echo ""
echo "=== GMT RAPL binaries (setuid) ==="
CPU_BIN="${GMT_ROOT}/metric_providers/cpu/energy/rapl/msr/component/metric-provider-binary"
MEM_BIN="${GMT_ROOT}/metric_providers/memory/energy/rapl/msr/component/metric-provider-binary"

_check_bin() {
  local name=$1 bin=$2
  if [[ ! -x "$bin" ]]; then
    echo "MISSING: $name binary — run: ./scripts/build_gmt_rapl_providers.sh"
    return
  fi
  local uid
  uid="$(stat -c '%u' "$bin" 2>/dev/null || stat -f '%u' "$bin" 2>/dev/null || echo 1)"
  if [[ -u "$bin" ]] && [[ "$uid" == "0" ]]; then
    echo "OK: $name setuid root: $bin"
  else
    echo "FIX: $name binary exists but is NOT setuid root — expect 'rdmsr: Permission denied'. Run:"
    echo "     ./scripts/build_gmt_rapl_providers.sh"
  fi
}

_check_bin "CPU RAPL" "$CPU_BIN"
_check_bin "Memory RAPL" "$MEM_BIN"

echo ""
echo "=== GMT dev: hardware_info_root.py ==="
if [[ -f "${GMT_ROOT}/hardware_info_root.py" ]]; then
  echo "OK: ${GMT_ROOT}/hardware_info_root.py"
else
  echo "MISSING: ${GMT_ROOT}/hardware_info_root.py — pull latest GMT or set GMT_HARDWARE_INFO_ROOT"
fi

echo ""
echo "Config: enable CpuEnergyRaplMsrComponentProvider + MemoryEnergyRaplMsrComponentProvider in config.yml"
echo "Run:    ./scripts/run_beam_gmt_http.sh -c st-erlang-index-27   # all 13 loads if no -l"
echo "Docs:   docs/ENERGY_METRICS.md"

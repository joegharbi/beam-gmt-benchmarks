#!/usr/bin/env bash
# Quick local checks before enabling RAPL in green-metrics-tool/config.yml.
set -euo pipefail

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
  echo "OK: /dev/cpu/0/msr is readable (RAPL MSR provider can run)"
else
  echo "NOTE: /dev/cpu/0/msr not readable as this user; GMT still uses sudo for RAPL filtering check and provider binaries."
fi

if command -v rdmsr >/dev/null 2>&1; then
  echo "OK: rdmsr found at $(command -v rdmsr)"
else
  echo "WARN: rdmsr not found (install msr-tools on Debian/Ubuntu)"
fi

echo ""
echo "=== GMT dev: hardware_info_root.py ==="
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib_env.sh
source "${SCRIPT_DIR}/_lib_env.sh"
if [[ -f "${GMT_ROOT}/hardware_info_root.py" ]]; then
  echo "OK: ${GMT_ROOT}/hardware_info_root.py (needed for RAPL check on git checkouts)"
else
  echo "MISSING: ${GMT_ROOT}/hardware_info_root.py — pull latest GMT or set GMT_HARDWARE_INFO_ROOT"
fi

echo ""
echo "Next: ensure config.yml has CpuEnergyRaplMsrComponentProvider + MemoryEnergyRaplMsrComponentProvider enabled,"
echo "then run e.g.: ./scripts/run_beam_gmt_http.sh -c st-erlang-index-27"
echo "(omit -l for all 13 BEAM HTTP loads). See docs/ENERGY_METRICS.md"

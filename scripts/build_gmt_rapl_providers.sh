#!/usr/bin/env bash
# Build CPU + memory RAPL MSR metric-provider binaries with the setuid bit (GMT upstream Makefile).
# Without setuid root, runner.py hits: rdmsr:open: Permission denied
#
# Requires: gcc, sudo (for chown root + chmod u+s on the binaries).
# Only builds gmt-lib.o (not gmt-container-lib.o — that needs libcurl dev headers).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib_env.sh
source "${SCRIPT_DIR}/_lib_env.sh"

C_LIB="${GMT_ROOT}/lib/c"
CPU_RAPL="${GMT_ROOT}/metric_providers/cpu/energy/rapl/msr/component"
MEM_RAPL="${GMT_ROOT}/metric_providers/memory/energy/rapl/msr/component"

for d in "$C_LIB" "$CPU_RAPL" "$MEM_RAPL"; do
  [[ -d "$d" ]] || { echo "Missing directory: $d" >&2; exit 1; }
done

echo "=== Building lib/c (gmt-lib.o only — RAPL does not need gmt-container-lib / curl) ==="
make -C "$C_LIB" gmt-lib.o

echo "=== Building CPU RAPL metric-provider-binary ==="
make -C "$CPU_RAPL"

echo "=== Building memory RAPL metric-provider-binary ==="
make -C "$MEM_RAPL"

# GMT's Makefile sets setuid only when the compile recipe runs. If the binary already
# exists and is "up to date", make skips chown/chmod — leaving youssef:youssef and no 's' bit.
echo "=== Applying setuid root (always — fixes stale 'up to date' builds) ==="
sudo chown root:root "$CPU_RAPL/metric-provider-binary" "$MEM_RAPL/metric-provider-binary"
sudo chmod u+s "$CPU_RAPL/metric-provider-binary" "$MEM_RAPL/metric-provider-binary"

echo ""
echo "Verify setuid (expect owner root and 's' in user execute, e.g. -rwsr-xr-x):"
ls -l "$CPU_RAPL/metric-provider-binary" "$MEM_RAPL/metric-provider-binary"

echo ""
echo "Smoke test (must not print Permission denied):"
if "$CPU_RAPL/metric-provider-binary" -c; then
  echo "OK: CPU RAPL self-check passed"
else
  echo "FAIL: still cannot read MSRs — check msr module, Secure Boot, VM" >&2
  exit 1
fi

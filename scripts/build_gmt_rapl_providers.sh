#!/usr/bin/env bash
# Build CPU + memory RAPL MSR metric-provider binaries with the setuid bit (GMT upstream Makefile).
# Without setuid root, runner.py hits: rdmsr:open: Permission denied
#
# Requires: gcc, sudo (for chown root + chmod u+s on the binaries).
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

echo "=== Building lib/c (gmt-lib.o) ==="
make -C "$C_LIB"

echo "=== Building CPU RAPL metric-provider-binary (setuid root) ==="
make -C "$CPU_RAPL"

echo "=== Building memory RAPL metric-provider-binary (setuid root) ==="
make -C "$MEM_RAPL"

echo ""
echo "Verify setuid (expect 'rws' or 'r-s' in owner execute bit, owner root):"
ls -l "$CPU_RAPL/metric-provider-binary" "$MEM_RAPL/metric-provider-binary"

echo ""
echo "Smoke test (should not print Permission denied):"
"$CPU_RAPL/metric-provider-binary" -c || true

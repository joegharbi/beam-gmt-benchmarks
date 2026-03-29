#!/usr/bin/env bash
# Backward-compatible wrapper: maps old positional syntax onto run_beam_gmt_http.sh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${SCRIPT_DIR}/run_beam_gmt_http.sh"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  echo "Prefer: $TARGET --help" >&2
  echo "Legacy: $0 [static|dynamic|all] [IMAGE ...] [--quick|--super-quick]" >&2
  exec "$TARGET" --help
fi

scope=""
case "${1:-}" in
  static)
    scope="--static-only"
    shift
    ;;
  dynamic)
    scope="--dynamic-only"
    shift
    ;;
  all)
    shift
    ;;
esac

converted=()
for a in "$@"; do
  case "$a" in
    --quick | --super-quick | -h | --help | --dry-run | --continue-on-error | --static-only | --dynamic-only)
      converted+=("$a")
      ;;
    --*)
      echo "Unknown flag for legacy sweep wrapper: $a (use $TARGET instead)" >&2
      exit 1
      ;;
    *)
      converted+=(--container "$a")
      ;;
  esac
done

exec_args=()
[[ -n "$scope" ]] && exec_args+=("$scope")
exec "$TARGET" "${exec_args[@]}" "${converted[@]}"

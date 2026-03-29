#!/usr/bin/env bash
# Backward-compatible alias for chained-load mode: run_beam_gmt_http.sh --together
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${SCRIPT_DIR}/run_beam_gmt_http.sh"

forward=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope)
      shift
      [[ -n "${1:-}" ]] || { echo "$0: --scope needs all|static|dynamic" >&2; exit 1; }
      case "$1" in
        all) ;;
        static) forward+=(--static-only) ;;
        dynamic) forward+=(--dynamic-only) ;;
        *) echo "$0: --scope must be all, static, or dynamic (got $1)" >&2; exit 1 ;;
      esac
      shift
      ;;
    *)
      forward+=("$1")
      shift
      ;;
  esac
done

exec "$TARGET" --together "${forward[@]}"

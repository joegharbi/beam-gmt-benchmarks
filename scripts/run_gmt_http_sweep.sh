#!/usr/bin/env bash
# Run one full GMT measurement per (HTTP server image × request count), matching
# BEAM-web-server-benchmarks/scripts/run_benchmarks.sh semantics for static/dynamic HTTP.
#
# Each iteration is a separate runner.py invocation (separate DB run, full metric capture).
# WebSocket containers are not supported here (different workload tool).
#
# Usage:
#   export GMT_ROOT=/path/to/green-metrics-tool
#   export BEAM_ROOT=/path/to/BEAM-web-server-benchmarks   # only if using static|dynamic|all
#   ./scripts/run_gmt_http_sweep.sh static [--quick|--super-quick]
#   ./scripts/run_gmt_http_sweep.sh dynamic [--quick|--super-quick]
#   ./scripts/run_gmt_http_sweep.sh all [--quick|--super-quick]    # static + dynamic (many runs)
#   ./scripts/run_gmt_http_sweep.sh st-erlang-index-27 [more-images...] [--quick|--super-quick]
#
# Env:
#   GMT_SWEEP_DRY_RUN=1       Print runner commands instead of executing
#   GMT_SWEEP_CONTINUE_ON_ERROR=1  Continue after a failed runner exit (default: stop on first error)
#   GMT_PYTHON                Python for runner (default: $GMT_ROOT/.venv/bin/python3 or python3)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

: "${GMT_ROOT:?Set GMT_ROOT to your green-metrics-tool checkout}"
RUNNER="$GMT_ROOT/runner.py"
[[ -f "$RUNNER" ]] || { echo "runner.py not found: $RUNNER" >&2; exit 1; }

PY="${GMT_PYTHON:-$GMT_ROOT/.venv/bin/python3}"
[[ -x "$PY" ]] || PY="${GMT_PYTHON:-python3}"

# Same arrays as BEAM-web-server-benchmarks/scripts/run_benchmarks.sh (HTTP only)
FULL_HTTP_REQUESTS=(100 1000 5000 8000 10000 15000 20000 30000 40000 50000 60000 70000 80000)
QUICK_HTTP_REQUESTS=(1000 5000 10000)
SUPER_QUICK_HTTP_REQUESTS=(1000)

usage() {
  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

discover_http_images() {
  local typ=$1
  local base="${BEAM_ROOT}/benchmarks/${typ}"
  [[ -d "$base" ]] || { echo "BEAM benchmarks dir not found: $base (set BEAM_ROOT?)" >&2; exit 1; }
  find "$base" -type d -exec test -f {}/Dockerfile \; -print 2>/dev/null | while IFS= read -r d; do
    basename "$d"
  done | sort -u
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage 0
fi

QUICK=0
SUPER_QUICK=0
args=()
for arg in "$@"; do
  case "$arg" in
    --quick) QUICK=1 ;;
    --super-quick) SUPER_QUICK=1 ;;
    -h|--help) usage 0 ;;
    *) args+=("$arg") ;;
  esac
done

if [[ $SUPER_QUICK -eq 1 && $QUICK -eq 1 ]]; then
  echo "Use only one of --quick or --super-quick" >&2
  exit 1
fi

if [[ $SUPER_QUICK -eq 1 ]]; then
  REQUEST_COUNTS=("${SUPER_QUICK_HTTP_REQUESTS[@]}")
elif [[ $QUICK -eq 1 ]]; then
  REQUEST_COUNTS=("${QUICK_HTTP_REQUESTS[@]}")
else
  REQUEST_COUNTS=("${FULL_HTTP_REQUESTS[@]}")
fi

if [[ ${#args[@]} -eq 0 ]]; then
  echo "Specify: static | dynamic | all | or one or more image names. See --help." >&2
  exit 1
fi

IMAGES=()
case "${args[0]}" in
  static|dynamic)
    : "${BEAM_ROOT:?Set BEAM_ROOT to your BEAM-web-server-benchmarks checkout for static/dynamic discovery}"
    while IFS= read -r img; do
      [[ -n "$img" ]] && IMAGES+=("$img")
    done < <(discover_http_images "${args[0]}")
    if [[ ${#IMAGES[@]} -eq 0 ]]; then
      echo "No containers discovered under benchmarks/${args[0]}" >&2
      exit 1
    fi
    ;;
  all)
    : "${BEAM_ROOT:?Set BEAM_ROOT to your BEAM-web-server-benchmarks checkout for all discovery}"
    while IFS= read -r img; do
      [[ -n "$img" ]] && IMAGES+=("$img")
    done < <(discover_http_images static)
    while IFS= read -r img; do
      [[ -n "$img" ]] && IMAGES+=("$img")
    done < <(discover_http_images dynamic)
    if [[ ${#IMAGES[@]} -eq 0 ]]; then
      echo "No static/dynamic containers discovered" >&2
      exit 1
    fi
    ;;
  *)
    IMAGES=("${args[@]}")
    ;;
esac

if ! git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Warning: $REPO_ROOT is not a git repo; GMT --uri may require git init + commit." >&2
fi

mkdir -p "$REPO_ROOT/logs"
LOG="$REPO_ROOT/logs/gmt_http_sweep_$(date +%Y-%m-%d_%H%M%S).log"
echo "Logging to $LOG"
exec > >(tee -a "$LOG") 2>&1

total_runs=$((${#IMAGES[@]} * ${#REQUEST_COUNTS[@]}))
echo "Images: ${#IMAGES[@]}, request counts per image: ${#REQUEST_COUNTS[@]} (${REQUEST_COUNTS[*]}), total GMT runs: $total_runs"
run_idx=0

for image in "${IMAGES[@]}"; do
  for n in "${REQUEST_COUNTS[@]}"; do
    run_idx=$((run_idx + 1))
    name="BEAM-HTTP-${image}-n${n}"
    echo ""
    echo "========== [$run_idx/$total_runs] $name =========="

    cmd=(
      "$PY" "$RUNNER"
      --uri "$REPO_ROOT"
      --filename usage_scenario.yml
      --name "$name"
      --variable "__GMT_VAR_BEAM_IMAGE__=${image}"
      --variable "__GMT_VAR_NUM_REQUESTS__=${n}"
    )

    if [[ "${GMT_SWEEP_DRY_RUN:-0}" == "1" ]]; then
      printf '%q ' "${cmd[@]}"
      echo
      continue
    fi

    set +e
    "${cmd[@]}"
    rc=$?
    set -e
    if [[ $rc -ne 0 ]]; then
      echo "[ERROR] runner exited $rc for $name" >&2
      if [[ "${GMT_SWEEP_CONTINUE_ON_ERROR:-0}" != "1" ]]; then
        exit "$rc"
      fi
    fi
  done
done

echo ""
echo "Sweep finished at $(date). Log: $LOG"

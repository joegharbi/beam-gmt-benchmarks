#!/usr/bin/env bash
# One GMT measurement per image: all BEAM HTTP load sizes in sequence inside the loadgen container.
# Uses usage_scenario_full_sweep.yml (see docs/HTTP_SWEEP.md).
#
# Default: discover every image under BEAM benchmarks/static and benchmarks/dynamic (same as
# run_beam_gmt_http.sh). Override with -c, --static-only, --dynamic-only, or BEAM_GMT_HTTP_PRESET_CONTAINERS.
#
# Optional -l N (repeatable): custom sweep counts (comma list passed as --counts); omit for full 13-point list.
#
# Paths: scripts/_lib_env.sh, scripts/beam_gmt_http_constants.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib_env.sh
source "${SCRIPT_DIR}/_lib_env.sh"
# shellcheck source=beam_gmt_http_constants.sh
source "${SCRIPT_DIR}/beam_gmt_http_constants.sh"

usage() {
  cat <<'EOF'
Usage: run_local_full_sweep.sh [options]

One Green Metrics Tool run per Docker image; each run executes the full HTTP sweep inside loadgen
(tools/gmt_http_load.py --sweep).

  Default: all images in BEAM benchmarks/static + benchmarks/dynamic; full request-count list (13 points).

Options:
  -c, --container NAME   Only this image (repeatable). Skips discovery; BEAM_ROOT not required.
  -l, --load N           Include N in the sweep (repeatable). Omit for full BEAM list. Order preserved.
      --static-only      Discover only benchmarks/static (ignored if -c is used)
      --dynamic-only     Discover only benchmarks/dynamic
      --dry-run          Print runner.py commands only (also GMT_SWEEP_DRY_RUN=1)
      --continue-on-error  Keep going after a failed measurement
  -h, --help

Examples:
  ./scripts/run_local_full_sweep.sh -c st-erlang-index-27
  ./scripts/run_local_full_sweep.sh --static-only
  ./scripts/run_local_full_sweep.sh -c st-erlang-index-27 -l 100 -l 1000

Edit scripts/beam_gmt_http_constants.sh for optional BEAM_GMT_HTTP_PRESET_CONTAINERS (default subset
when you do not pass -c). Leave that array empty for full static+dynamic discovery.

Hosted / manual runner: set __GMT_VAR_SWEEP_EXTRA__ to empty string or e.g. "--counts 100,1000" — see usage_scenario_full_sweep.yml.
EOF
  exit "${1:-0}"
}

discover_http_images() {
  local typ=$1
  local root="${BEAM_ROOT%/}"
  local base="${root}/benchmarks/${typ}"
  [[ -d "$base" ]] || {
    echo "beam-gmt-benchmarks: benchmarks/${typ} not found at ${base} — check BEAM_ROOT" >&2
    exit 1
  }
  find "$base" -type d -exec test -f {}/Dockerfile \; -print 2>/dev/null | while IFS= read -r d; do
    basename "$d"
  done | sort -u
}

CONTAINERS=()
LOADS=()
STATIC_ONLY=0
DYNAMIC_ONLY=0
DRY_RUN=0
CONTINUE_ERR=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h | --help) usage 0 ;;
    --static-only) STATIC_ONLY=1; shift ;;
    --dynamic-only) DYNAMIC_ONLY=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --continue-on-error) CONTINUE_ERR=1; shift ;;
    -c | --container)
      shift
      [[ -n "${1:-}" ]] || { echo "--container requires a name" >&2; exit 1; }
      CONTAINERS+=("$1")
      shift
      ;;
    -l | --load)
      shift
      [[ -n "${1:-}" ]] || { echo "--load requires a number" >&2; exit 1; }
      [[ "$1" =~ ^[0-9]+$ ]] || { echo "--load must be a positive integer: $1" >&2; exit 1; }
      LOADS+=("$1")
      shift
      ;;
    *)
      echo "Unknown option: $1 (try --help)" >&2
      exit 1
      ;;
  esac
done

if [[ $STATIC_ONLY -eq 1 && $DYNAMIC_ONLY -eq 1 ]]; then
  echo "Use at most one of --static-only and --dynamic-only" >&2
  exit 1
fi

sweep_extra=""
if [[ ${#LOADS[@]} -gt 0 ]]; then
  sweep_extra="--counts $(IFS=,; echo "${LOADS[*]}")"
fi

IMAGES=()
if [[ ${#CONTAINERS[@]} -gt 0 ]]; then
  IMAGES=("${CONTAINERS[@]}")
elif [[ ${#BEAM_GMT_HTTP_PRESET_CONTAINERS[@]} -gt 0 ]]; then
  IMAGES=("${BEAM_GMT_HTTP_PRESET_CONTAINERS[@]}")
else
  : "${BEAM_ROOT:?beam-gmt-benchmarks: BEAM_ROOT not set and auto-discovery failed. Put BEAM-web-server-benchmarks next to this repo or set BEAM_ROOT in env.local}"
  if [[ $STATIC_ONLY -eq 1 ]]; then
    while IFS= read -r img; do
      [[ -n "$img" ]] && IMAGES+=("$img")
    done < <(discover_http_images static)
  elif [[ $DYNAMIC_ONLY -eq 1 ]]; then
    while IFS= read -r img; do
      [[ -n "$img" ]] && IMAGES+=("$img")
    done < <(discover_http_images dynamic)
  else
    while IFS= read -r img; do
      [[ -n "$img" ]] && IMAGES+=("$img")
    done < <(discover_http_images static)
    while IFS= read -r img; do
      [[ -n "$img" ]] && IMAGES+=("$img")
    done < <(discover_http_images dynamic)
  fi
  if [[ ${#IMAGES[@]} -eq 0 ]]; then
    echo "No HTTP containers discovered for the selected scope" >&2
    exit 1
  fi
fi

if [[ $DRY_RUN -eq 1 ]]; then
  export GMT_SWEEP_DRY_RUN=1
fi
if [[ $CONTINUE_ERR -eq 1 ]]; then
  export GMT_SWEEP_CONTINUE_ON_ERROR=1
fi

if ! git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Warning: $REPO_ROOT is not a git repo; GMT --uri may require git init + commit." >&2
fi

mkdir -p "${REPO_ROOT}/logs"
LOG="${REPO_ROOT}/logs/gmt_beam_full_sweep_$(date +%Y-%m-%d_%H%M%S).log"
echo "Logging to $LOG"
exec > >(tee -a "$LOG") 2>&1

cd "$REPO_ROOT"

total_runs=${#IMAGES[@]}
echo "=== run_local_full_sweep.sh ==="
echo "GMT_ROOT=$GMT_ROOT"
echo "BEAM_GMT_BENCHMARKS_ROOT=$REPO_ROOT"
echo "BEAM_ROOT=${BEAM_ROOT:-<not used (explicit/preset images)>}"
echo "Images (${#IMAGES[@]}): ${IMAGES[*]}"
if [[ ${#LOADS[@]} -gt 0 ]]; then
  echo "Sweep counts (custom): ${LOADS[*]}"
else
  echo "Sweep counts: full BEAM list (${#BEAM_GMT_HTTP_FULL_COUNTS[@]} points)"
fi
echo "Total GMT runs: $total_runs"
run_idx=0

for image in "${IMAGES[@]}"; do
  run_idx=$((run_idx + 1))
  name="BEAM-HTTP-full-sweep-${image}"
  echo ""
  echo "========== [$run_idx/$total_runs] $name =========="

  cmd=(
    "$PY" "$RUNNER"
    --uri "$REPO_ROOT"
    --filename usage_scenario_full_sweep.yml
    --name "$name"
    --variable "__GMT_VAR_BEAM_IMAGE__=${image}"
    --variable "__GMT_VAR_SWEEP_EXTRA__=${sweep_extra}"
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

echo ""
echo "Finished at $(date). Log: $LOG"

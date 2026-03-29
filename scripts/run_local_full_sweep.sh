#!/usr/bin/env bash
# One GMT measurement per Docker image: chained HTTP loads inside loadgen (usage_scenario_full_sweep.yml).
#
# You only choose three things on the command line:
#   1) Container(s)     —  -c NAME …  OR  leave off -c to use the preset lists below + --scope
#   2) Load / workload  —  -l N …     OR  omit -l to run the full 13 BEAM sizes (100 … 80000)
#   3) Static / dynamic —  --scope all | static | dynamic  (only when you did NOT pass -c)
#
# Edit the preset image lists in this file when you want “run these containers” without typing -c each time.
# (Advanced: --dry-run, --continue-on-error — for debugging only.)
#
# Internally the scenario still uses Green Metrics variable names; you do not need to set those yourself.
set -euo pipefail

# =============================================================================
# Preset container names when you do NOT pass -c (same names as BEAM Docker images).
# Static  → benchmarks/static/*   Dynamic → benchmarks/dynamic/*
# =============================================================================
FULL_SWEEP_STATIC_CONTAINERS=(
  st-erlang-index-27
)
FULL_SWEEP_DYNAMIC_CONTAINERS=(
  # Add dynamic HTTP image names here, e.g.:
  # dy-erlang-cowboy-27
)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib_env.sh
source "${SCRIPT_DIR}/_lib_env.sh"

usage() {
  cat <<'EOF'
run_local_full_sweep.sh — three main knobs

  1) CONTAINER
     -c, --container NAME    Run only this image (repeatable). Example: -c st-erlang-index-27
     (no -c)                  Use the preset lists in this script, filtered by --scope.

  2) LOAD / WORKLOAD (request counts per step in the sweep)
     -l, --load N             Run only these sizes, in order (repeatable). Example: -l 100 -l 1000
     (no -l)                  Run the full BEAM list: 100, 1000, 5000, …, 80000 (13 steps).

  3) SCOPE (only when you did NOT use -c)
     --scope all              Static preset list, then dynamic preset list (default).
     --scope static           Only FULL_SWEEP_STATIC_CONTAINERS in this script.
     --scope dynamic          Only FULL_SWEEP_DYNAMIC_CONTAINERS in this script.

Advanced (optional):
     --dry-run                Print runner.py commands only
     --continue-on-error      Continue after a failed GMT run

Preset lists to edit: FULL_SWEEP_STATIC_CONTAINERS and FULL_SWEEP_DYNAMIC_CONTAINERS near the top of this file.

Examples:
  ./scripts/run_local_full_sweep.sh -c st-erlang-index-27
  ./scripts/run_local_full_sweep.sh -c st-erlang-index-27 -l 100 -l 1000
  ./scripts/run_local_full_sweep.sh --scope static
EOF
  exit "${1:-0}"
}

CONTAINERS=()
LOADS=()
SCOPE="all"
DRY_RUN=0
CONTINUE_ERR=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h | --help) usage 0 ;;
    --scope)
      shift
      [[ -n "${1:-}" ]] || { echo "--scope needs all|static|dynamic" >&2; exit 1; }
      case "$1" in
        all | static | dynamic) SCOPE="$1" ;;
        *) echo "--scope must be all, static, or dynamic (got $1)" >&2; exit 1 ;;
      esac
      shift
      ;;
    --dry-run) DRY_RUN=1; shift ;;
    --continue-on-error) CONTINUE_ERR=1; shift ;;
    -c | --container)
      shift
      [[ -n "${1:-}" ]] || { echo "--container requires a name" >&2; exit 1; }
      CONTAINERS+=("$1")
      shift
      ;;
    -l | --load | --loads)
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

# ---- Build image list ----
IMAGES=()
if [[ ${#CONTAINERS[@]} -gt 0 ]]; then
  IMAGES=("${CONTAINERS[@]}")
else
  case "$SCOPE" in
    all)
      IMAGES+=("${FULL_SWEEP_STATIC_CONTAINERS[@]}")
      IMAGES+=("${FULL_SWEEP_DYNAMIC_CONTAINERS[@]}")
      ;;
    static) IMAGES+=("${FULL_SWEEP_STATIC_CONTAINERS[@]}") ;;
    dynamic) IMAGES+=("${FULL_SWEEP_DYNAMIC_CONTAINERS[@]}") ;;
  esac
  # Drop empty entries (unset slots in sparse arrays)
  _tmp=()
  for img in "${IMAGES[@]}"; do
    [[ -n "$img" ]] || continue
    _tmp+=("$img")
  done
  IMAGES=("${_tmp[@]}")
  if [[ ${#IMAGES[@]} -eq 0 ]]; then
    cat >&2 <<EOF
No images to run: preset list for scope "$SCOPE" is empty.

  Edit FULL_SWEEP_STATIC_CONTAINERS / FULL_SWEEP_DYNAMIC_CONTAINERS in:
    ${SCRIPT_DIR}/run_local_full_sweep.sh

  Or pass explicit names:  -c your-image-name
EOF
    exit 1
  fi
fi

# Map workload to the single optional tail the scenario file expects (implementation detail).
sweep_extra=""
if [[ ${#LOADS[@]} -gt 0 ]]; then
  sweep_extra="--counts $(IFS=,; echo "${LOADS[*]}")"
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
echo "Containers (${#IMAGES[@]}): ${IMAGES[*]}"
if [[ ${#LOADS[@]} -gt 0 ]]; then
  echo "Workload (custom steps): ${LOADS[*]}"
else
  echo "Workload: full BEAM sweep (13 steps: 100 … 80000)"
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

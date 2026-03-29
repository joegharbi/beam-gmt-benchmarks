#!/usr/bin/env bash
# Orchestrate BEAM static/dynamic HTTP measurements through Green Metrics Tool.
# One GMT measurement per (container image × request count). WebSocket: not yet supported.
#
# Defaults with no arguments: discover all images under BEAM benchmarks/static and
# benchmarks/dynamic, use the full HTTP count list (same as BEAM full HTTP run).
#
# Paths: sibling-folder auto-discovery — see docs/PATHS_AND_ENV.md and scripts/_lib_env.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib_env.sh
source "${SCRIPT_DIR}/_lib_env.sh"
# shellcheck source=beam_gmt_http_constants.sh
source "${SCRIPT_DIR}/beam_gmt_http_constants.sh"

usage() {
  cat <<'EOF'
Usage: run_beam_gmt_http.sh [options]

Run BEAM HTTP server images through GMT (one runner.py invocation per image × load).

  Default: all containers in BEAM benchmarks/static + benchmarks/dynamic, full request-count
  list (13 points from 100 to 80000, same as BEAM-web-server-benchmarks full HTTP).

Options:
  -c, --container NAME   Only this Docker image (repeatable). Skips discovery; BEAM_ROOT not needed.
                         Example: -c st-erlang-index-27 with no -l runs all 13 BEAM loads (100…80000).
  -l, --load N           Request count (repeatable). Omit to use full / quick / super-quick preset.
                         Cannot combine --load with --quick / --super-quick.
      --quick            Three counts: 1000, 5000, 10000
      --super-quick      Single count: 1000
      --static-only      Discover only benchmarks/static (ignored if -c is used)
      --dynamic-only     Discover only benchmarks/dynamic
      --dry-run          Print runner commands only
      --continue-on-error  Keep going after a failed measurement
  -h, --help

Edit scripts/beam_gmt_http_constants.sh for optional BEAM_GMT_HTTP_PRESET_CONTAINERS (default
subset when you do not pass -c). Leave that array empty for full static+dynamic discovery.

Env: GMT_SWEEP_DRY_RUN, GMT_SWEEP_CONTINUE_ON_ERROR, BEAM_GMT_VERBOSE — see docs/HTTP_SWEEP.md
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
QUICK=0
SUPER_QUICK=0
DRY_RUN=0
CONTINUE_ERR=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h | --help) usage 0 ;;
    --quick) QUICK=1; shift ;;
    --super-quick) SUPER_QUICK=1; shift ;;
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

if [[ $SUPER_QUICK -eq 1 && $QUICK -eq 1 ]]; then
  echo "Use only one of --quick and --super-quick" >&2
  exit 1
fi

if [[ ${#LOADS[@]} -gt 0 ]]; then
  if [[ $QUICK -eq 1 || $SUPER_QUICK -eq 1 ]]; then
    echo "Do not combine --load with --quick or --super-quick" >&2
    exit 1
  fi
  REQUEST_COUNTS=("${LOADS[@]}")
elif [[ $SUPER_QUICK -eq 1 ]]; then
  REQUEST_COUNTS=("${BEAM_GMT_HTTP_SUPER_QUICK_COUNTS[@]}")
elif [[ $QUICK -eq 1 ]]; then
  REQUEST_COUNTS=("${BEAM_GMT_HTTP_QUICK_COUNTS[@]}")
else
  REQUEST_COUNTS=("${BEAM_GMT_HTTP_FULL_COUNTS[@]}")
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
LOG="${REPO_ROOT}/logs/gmt_beam_http_$(date +%Y-%m-%d_%H%M%S).log"
echo "Logging to $LOG"
exec > >(tee -a "$LOG") 2>&1

# GMT's system check runs `git status` in the *current working directory* (not --uri).
# If you invoke this script from ~ or another non-repo path, runner.py would see git fail.
cd "$REPO_ROOT"

total_runs=$((${#IMAGES[@]} * ${#REQUEST_COUNTS[@]}))
echo "=== run_beam_gmt_http.sh ==="
echo "GMT_ROOT=$GMT_ROOT"
echo "BEAM_GMT_BENCHMARKS_ROOT=$REPO_ROOT"
echo "BEAM_ROOT=${BEAM_ROOT:-<not used (explicit/preset images)>}"
echo "Images (${#IMAGES[@]}): ${IMAGES[*]}"
echo "Loads (${#REQUEST_COUNTS[@]}): ${REQUEST_COUNTS[*]}"
echo "Total GMT runs: $total_runs"
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
echo "Finished at $(date). Log: $LOG"

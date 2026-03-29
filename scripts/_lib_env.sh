#!/usr/bin/env bash
# shellcheck shell=bash
# Internal: sourced by run_local_production.sh and run_gmt_http_sweep.sh after SCRIPT_DIR is set.
#
# Path resolution (least configuration first):
#   1) Optional BEAM_GMT_ENV_FILE, then env.local (override / non-standard layouts).
#   2) BEAM_GMT_BENCHMARKS_ROOT defaults to this repo root (parent of scripts/).
#   3) GMT_ROOT: if still unset, auto-detect by walking upward from this repo and looking for a
#      sibling directory that looks like a Green Metrics Tool checkout (runner.py + lib/scenario_runner.py).
#   4) BEAM_ROOT: if still unset, same walk for a sibling with benchmarks/static (BEAM-web-server-benchmarks).
#
# Typical layout (zero exports):
#   workspace/
#     green-metrics-tool/
#     BEAM-web-server-benchmarks/
#     beam-gmt-benchmarks/

[[ -n "${SCRIPT_DIR:-}" ]] || {
  echo "_lib_env.sh: caller must set SCRIPT_DIR to the scripts/ directory" >&2
  exit 1
}

_beam_gmt_default_repo="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ -n "${BEAM_GMT_ENV_FILE:-}" && -f "${BEAM_GMT_ENV_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${BEAM_GMT_ENV_FILE}"
  set +a
fi

if [[ -f "${_beam_gmt_default_repo}/env.local" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${_beam_gmt_default_repo}/env.local"
  set +a
fi

BEAM_GMT_BENCHMARKS_ROOT="${BEAM_GMT_BENCHMARKS_ROOT:-${_beam_gmt_default_repo}}"
BEAM_GMT_BENCHMARKS_ROOT="${BEAM_GMT_BENCHMARKS_ROOT%/}"
REPO_ROOT="$BEAM_GMT_BENCHMARKS_ROOT"
export BEAM_GMT_BENCHMARKS_ROOT REPO_ROOT

_beam_gmt_is_gmt_root() {
  [[ -f "$1/runner.py" && -f "$1/lib/scenario_runner.py" ]]
}

# Print GMT root on stdout; exit 1 if not found.
_beam_gmt_discover_gmt_root() {
  local repo="${1%/}"
  local w parent name c
  local -a names=(green-metrics-tool GreenMetricsTool gmt green-metrics-tool-main GMT)
  w="$repo"
  while [[ -n "$w" && "$w" != "/" ]]; do
    parent="$(cd "$w/.." && pwd)" || break
    for name in "${names[@]}"; do
      c="$parent/$name"
      if _beam_gmt_is_gmt_root "$c"; then
        printf '%s\n' "$c"
        return 0
      fi
    done
    w="$parent"
  done
  return 1
}

_beam_gmt_is_beam_benchmarks_root() {
  [[ -d "$1/benchmarks/static" ]]
}

# Print BEAM repo root on stdout; exit 1 if not found.
_beam_gmt_discover_beam_root() {
  local repo="${1%/}"
  local w parent name c
  local -a names=(BEAM-web-server-benchmarks beam-web-server-benchmarks BEAM_web_server_benchmarks)
  w="$repo"
  while [[ -n "$w" && "$w" != "/" ]]; do
    parent="$(cd "$w/.." && pwd)" || break
    for name in "${names[@]}"; do
      c="$parent/$name"
      if _beam_gmt_is_beam_benchmarks_root "$c"; then
        printf '%s\n' "$c"
        return 0
      fi
    done
    w="$parent"
  done
  return 1
}

if [[ -z "${GMT_ROOT:-}" ]]; then
  if gmt_path="$(_beam_gmt_discover_gmt_root "$REPO_ROOT")"; then
    GMT_ROOT="$gmt_path"
    export GMT_ROOT
    if [[ "${BEAM_GMT_VERBOSE:-0}" == "1" ]]; then
      echo "[beam-gmt-benchmarks] GMT_ROOT=${GMT_ROOT} (auto-detected)" >&2
    fi
  fi
fi

if [[ -z "${GMT_ROOT:-}" ]]; then
  cat >&2 <<'EOF'
beam-gmt-benchmarks: Could not find Green Metrics Tool.

  Automatic search looks next to this repo (and further up) for a sibling folder named e.g.
  green-metrics-tool containing runner.py and lib/scenario_runner.py.

  Fix one of:
    • Clone GMT next to beam-gmt-benchmarks under the same parent directory, or
    • Set GMT_ROOT in env.local (copy env.example), or
    • export GMT_ROOT=/path/to/green-metrics-tool
EOF
  exit 1
fi

GMT_ROOT="${GMT_ROOT%/}"

RUNNER="${GMT_ROOT}/runner.py"
if [[ ! -f "$RUNNER" ]]; then
  echo "runner.py not found at ${RUNNER} (GMT_ROOT=${GMT_ROOT})" >&2
  exit 1
fi

PY="${GMT_PYTHON:-${GMT_ROOT}/.venv/bin/python3}"
if [[ ! -x "$PY" ]]; then
  PY="${GMT_PYTHON:-python3}"
fi

if [[ -z "${BEAM_ROOT:-}" ]]; then
  if beam_path="$(_beam_gmt_discover_beam_root "$REPO_ROOT")"; then
    BEAM_ROOT="$beam_path"
    export BEAM_ROOT
    if [[ "${BEAM_GMT_VERBOSE:-0}" == "1" ]]; then
      echo "[beam-gmt-benchmarks] BEAM_ROOT=${BEAM_ROOT} (auto-detected)" >&2
    fi
  fi
fi

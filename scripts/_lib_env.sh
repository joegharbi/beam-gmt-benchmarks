#!/usr/bin/env bash
# shellcheck shell=bash
# Internal: sourced by run_local_production.sh and run_gmt_http_sweep.sh after SCRIPT_DIR is set.
#
# Resolves all paths from root environment variables so moving GMT or this repo only requires
# updating env (e.g. env.local), not editing scripts.
#
# Load order:
#   1) If BEAM_GMT_ENV_FILE is set and points to a file, source it (export your roots there).
#   2) If env.local exists next to this repo's root (parent of scripts/), source it.
#   3) BEAM_GMT_BENCHMARKS_ROOT defaults to the directory containing usage_scenario.yml derived
#      from this file's location; override if you run scripts from a copy outside the repo.
#
# Required: GMT_ROOT — root directory of the Green Metrics Tool checkout (contains runner.py).

[[ -n "${SCRIPT_DIR:-}" ]] || {
  echo "_lib_env.sh: caller must set SCRIPT_DIR to the scripts/ directory" >&2
  exit 1
}

_BEAM_GMT_DEFAULT_REPO="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ -n "${BEAM_GMT_ENV_FILE:-}" && -f "${BEAM_GMT_ENV_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${BEAM_GMT_ENV_FILE}"
  set +a
fi

if [[ -f "${_BEAM_GMT_DEFAULT_REPO}/env.local" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${_BEAM_GMT_DEFAULT_REPO}/env.local"
  set +a
fi

BEAM_GMT_BENCHMARKS_ROOT="${BEAM_GMT_BENCHMARKS_ROOT:-${_BEAM_GMT_DEFAULT_REPO}}"
BEAM_GMT_BENCHMARKS_ROOT="${BEAM_GMT_BENCHMARKS_ROOT%/}"
REPO_ROOT="$BEAM_GMT_BENCHMARKS_ROOT"
export BEAM_GMT_BENCHMARKS_ROOT REPO_ROOT

: "${GMT_ROOT:?Set GMT_ROOT to the root directory of your Green Metrics Tool checkout (contains runner.py). Tip: put it in env.local next to usage_scenario.yml so moving GMT is a one-line change.}"
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

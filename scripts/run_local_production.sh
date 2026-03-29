#!/usr/bin/env bash
# Production-style GMT run: no --dev-*, no --skip-optimizations, no --skip-download-dependencies.
# Requires a full Green Metrics Tool install (PostgreSQL, Redis, metric providers as configured).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

: "${GMT_ROOT:?Set GMT_ROOT to your green-metrics-tool checkout (directory containing runner.py)}"
RUNNER="$GMT_ROOT/runner.py"
if [[ ! -f "$RUNNER" ]]; then
  echo "runner.py not found at $RUNNER" >&2
  exit 1
fi

PY="${GMT_PYTHON:-$GMT_ROOT/.venv/bin/python3}"
if [[ ! -x "$PY" ]]; then
  PY="${GMT_PYTHON:-python3}"
fi

export GMT_VAR_BEAM_IMAGE="${GMT_VAR_BEAM_IMAGE:-st-erlang-index-27}"
export GMT_VAR_NUM_REQUESTS="${GMT_VAR_NUM_REQUESTS:-10000}"
export GMT_RUN_NAME="${GMT_RUN_NAME:-BEAM static HTTP (GMT)}"

cd "$REPO_ROOT"
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Warning: $REPO_ROOT is not a git repository. GMT --uri requires a git repo; run: git init && git add -A && git commit -m init" >&2
fi

exec "$PY" "$RUNNER" \
  --uri "$REPO_ROOT" \
  --filename usage_scenario.yml \
  --name "$GMT_RUN_NAME" \
  --variable "__GMT_VAR_BEAM_IMAGE__=${GMT_VAR_BEAM_IMAGE}" \
  --variable "__GMT_VAR_NUM_REQUESTS__=${GMT_VAR_NUM_REQUESTS}"

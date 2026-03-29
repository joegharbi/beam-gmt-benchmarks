#!/usr/bin/env bash
# One production-style GMT run: all 13 BEAM HTTP load sizes in sequence inside the loadgen container.
# Uses usage_scenario_full_sweep.yml (see docs/HTTP_SWEEP.md for methodology vs 13 separate runs).
#
# Same path discovery as run_local_production.sh — sibling green-metrics-tool, optional env.local.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib_env.sh
source "${SCRIPT_DIR}/_lib_env.sh"

export GMT_VAR_BEAM_IMAGE="${GMT_VAR_BEAM_IMAGE:-st-erlang-index-27}"
export GMT_RUN_NAME="${GMT_RUN_NAME:-BEAM HTTP full sweep (one run) — ${GMT_VAR_BEAM_IMAGE}}"

cd "$REPO_ROOT"
if ! git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Warning: $REPO_ROOT is not a git repository. GMT --uri requires a git repo; run: git init && git add -A && git commit -m init" >&2
fi

exec "$PY" "$RUNNER" \
  --uri "$REPO_ROOT" \
  --filename usage_scenario_full_sweep.yml \
  --name "$GMT_RUN_NAME" \
  --variable "__GMT_VAR_BEAM_IMAGE__=${GMT_VAR_BEAM_IMAGE}"

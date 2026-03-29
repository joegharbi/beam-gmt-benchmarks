#!/usr/bin/env bash
# shellcheck shell=bash
# HTTP workload presets aligned with BEAM-web-server-benchmarks/scripts/run_benchmarks.sh
# Edit BEAM_GMT_HTTP_PRESET_CONTAINERS to pin a default subset; leave empty to auto-discover
# all static + all dynamic containers from BEAM-web-server-benchmarks.

BEAM_GMT_HTTP_FULL_COUNTS=(100 1000 5000 8000 10000 15000 20000 30000 40000 50000 60000 70000 80000)
BEAM_GMT_HTTP_QUICK_COUNTS=(1000 5000 10000)
BEAM_GMT_HTTP_SUPER_QUICK_COUNTS=(1000)

# When non-empty and you do not pass --container, these image names are used in order
# (no filesystem discovery). WebSocket images belong here only after you add a WS scenario.
# Example:
#   BEAM_GMT_HTTP_PRESET_CONTAINERS=(st-erlang-index-27 st-erlang-cowboy-27)
BEAM_GMT_HTTP_PRESET_CONTAINERS=()

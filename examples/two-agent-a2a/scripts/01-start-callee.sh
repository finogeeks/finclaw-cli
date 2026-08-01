#!/usr/bin/env bash
# Start callee `finclaw serve` with inbound A2A (mock LLM). Leaves process in background.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

if [[ -f "$DEMO_ROOT/env.sh" ]]; then
  # shellcheck disable=SC1091
  source "$DEMO_ROOT/env.sh"
fi

require_finclaw
require_cmd curl
ensure_demo_dirs
common_env

inbound="$(callee_config_dir)/a2a-inbound.yaml"
[[ -f "$inbound" ]] || {
  echo "error: missing $inbound — run scripts/00-prepare-homes.sh first" >&2
  exit 1
}

stop_pidfile serve-callee
serve_log="$(log_file serve-callee)"
pf="$(pid_file serve-callee)"

(
  cd /tmp
  export FINCLAW_HOME="$CALLEE_HOME"
  export AI_INFRA_RS_A2A_INBOUND_CONFIG_PATH="$inbound"
  # shellcheck disable=SC2030
  unset LLM_API_KEY
  export LLM_PROVIDER=mock
  export AI_INFRA_RS_EXECUTION_POSTURE=naked
  export FINCLAW_NO_UPDATE_CHECK=1
  "$FINCLAW_BIN" serve --port "$CALLEE_PORT" >"$serve_log" 2>&1 &
  echo $! >"$pf"
)

SERVER_PID="$(cat "$pf")"
base="http://127.0.0.1:${CALLEE_PORT}"
if ! wait_http "${base}/.well-known/agent-card.json"; then
  echo "error: callee serve did not become ready" >&2
  tail -40 "$serve_log" >&2 || true
  exit 1
fi

echo "OK callee serve"
echo "  pid:  $SERVER_PID"
echo "  base: $base"
echo "  log:  $serve_log"
echo "Stop with: kill \$(cat $pf)"

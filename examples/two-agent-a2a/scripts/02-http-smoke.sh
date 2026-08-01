#!/usr/bin/env bash
# HTTP smoke: Agent Card + authorised SendMessage against callee serve.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

if [[ -f "$DEMO_ROOT/env.sh" ]]; then
  # shellcheck disable=SC1091
  source "$DEMO_ROOT/env.sh"
fi

require_cmd curl
require_cmd python3

base="http://127.0.0.1:${CALLEE_PORT}"
if ! wait_http "${base}/.well-known/agent-card.json" 30; then
  echo "error: callee not reachable at $base — run scripts/01-start-callee.sh" >&2
  exit 1
fi

card="$(curl -fsS "${base}/.well-known/agent-card.json")"
echo "$card" | CALLEE_CARD_NAME="$CALLEE_CARD_NAME" python3 -c '
import json, os, sys
name = os.environ.get("CALLEE_CARD_NAME", "two-agent-callee")
d = json.load(sys.stdin)
got = d.get("name")
assert got == name, f"card name {got!r} != {name!r}"
print(f"OK agent card name={got}")
'

rpc_out="$(mktemp)"
trap 'rm -f "$rpc_out"' EXIT
jsonrpc_send_message "$base" "$DEMO_TOKEN" "ping from http smoke" >"$rpc_out"
python3 "$SCRIPT_DIR/assert_a2a_reply.py" <"$rpc_out"

# Optional: finclaw a2a inspection from caller home
if command -v "$FINCLAW_BIN" >/dev/null 2>&1; then
  (
    export FINCLAW_HOME="$CALLER_HOME"
    export FINCLAW_NO_UPDATE_CHECK=1
    "$FINCLAW_BIN" a2a list 2>/dev/null || true
    "$FINCLAW_BIN" a2a probe callee 2>/dev/null || true
  ) || true
fi

echo "OK http smoke"

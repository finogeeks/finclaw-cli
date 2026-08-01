#!/usr/bin/env bash
# Redeem share ticket, smoke Agent Card + SendMessage through the local tunnel.
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
require_cmd python3
ensure_demo_dirs
common_env

if ! share_available; then
  echo "SKIP p2p redeem (this finclaw build does not support \`share\`)"
  exit 0
fi

ticket_file="$DEMO_ROOT/ticket.txt"
[[ -s "$ticket_file" ]] || {
  echo "error: missing ticket — run scripts/03-p2p-offer.sh first" >&2
  exit 1
}
TICKET="$(cat "$ticket_file")"
RELAY_MODE="${SHARE_RELAY:-disabled}"

stop_pidfile share-redeem
redeem_out="$(log_file share-redeem.json)"
redeem_err="$(log_file share-redeem.err)"
pf="$(pid_file share-redeem)"
: >"$redeem_out"
: >"$redeem_err"

(
  export FINCLAW_HOME="$CALLER_HOME"
  export FINCLAW_NO_UPDATE_CHECK=1
  "$FINCLAW_BIN" share redeem \
    --ticket "$TICKET" \
    --relay "$RELAY_MODE" \
    --json >"$redeem_out" 2>"$redeem_err" &
  echo $! >"$pf"
)

local_base=""
for _ in $(seq 1 150); do
  if [[ -s "$redeem_out" ]] && python3 -c 'import json,sys; json.load(open(sys.argv[1]))["local_a2a_base"]' "$redeem_out" 2>/dev/null; then
    local_base="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["local_a2a_base"].rstrip("/"))' "$redeem_out")"
    break
  fi
  if ! kill -0 "$(cat "$pf")" 2>/dev/null; then
    break
  fi
  sleep 0.2
done

if [[ -z "$local_base" ]]; then
  echo "error: share redeem did not emit local_a2a_base" >&2
  tail -40 "$redeem_err" >&2 || true
  exit 1
fi

printf '%s\n' "$local_base" >"$DEMO_ROOT/local_a2a_base.txt"

# Fill caller P2P agents yaml (optional; HTTP yaml remains default until overwritten).
python3 - "$EXAMPLE_ROOT/caller/a2a-agents.p2p.yaml.tmpl" \
  "$(caller_config_dir)/a2a-agents.p2p.yaml" \
  "$local_base" "$DEMO_TOKEN" <<'PY'
import pathlib, sys
src, dst, base, token = sys.argv[1:5]
text = pathlib.Path(src).read_text(encoding="utf-8")
text = text.replace("__LOCAL_A2A_BASE__", base.rstrip("/"))
text = text.replace("two-agent-a2a-demo-token", token)
pathlib.Path(dst).write_text(text, encoding="utf-8")
PY

if ! wait_http "${local_base}/.well-known/agent-card.json"; then
  echo "error: tunnel card not reachable at $local_base" >&2
  exit 1
fi

card="$(curl -fsS "${local_base}/.well-known/agent-card.json")"
echo "$card" | CALLEE_CARD_NAME="$CALLEE_CARD_NAME" python3 -c '
import json, os, sys
name = os.environ.get("CALLEE_CARD_NAME", "two-agent-callee")
d = json.load(sys.stdin)
got = d.get("name")
assert got == name, f"card name {got!r} != {name!r}"
print(f"OK p2p agent card name={got}")
'

rpc_out="$(mktemp)"
trap 'rm -f "$rpc_out"' EXIT
jsonrpc_send_message "$local_base" "$DEMO_TOKEN" "ping via peer share" >"$rpc_out"
python3 "$SCRIPT_DIR/assert_a2a_reply.py" <"$rpc_out"

echo "OK p2p redeem smoke"
echo "  local_a2a_base: $local_base"
echo "  agents file:    $(caller_config_dir)/a2a-agents.p2p.yaml"
echo "  (offer + redeem processes must stay running while you use the tunnel)"

#!/usr/bin/env bash
# Start `finclaw share offer` for the running callee (same-machine: --relay disabled).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

if [[ -f "$DEMO_ROOT/env.sh" ]]; then
  # shellcheck disable=SC1091
  source "$DEMO_ROOT/env.sh"
fi

require_finclaw
ensure_demo_dirs
common_env

if ! share_available; then
  echo "SKIP p2p offer (this finclaw build does not support \`share\`)"
  echo "  HTTP path still works. See docs/a2a.md § Share your agent with a peer."
  exit 0
fi

base="http://127.0.0.1:${CALLEE_PORT}"
if ! wait_http "${base}/.well-known/agent-card.json" 30; then
  echo "error: callee not reachable — run scripts/01-start-callee.sh" >&2
  exit 1
fi

stop_pidfile share-offer
offer_out="$(log_file share-offer.json)"
offer_err="$(log_file share-offer.err)"
pf="$(pid_file share-offer)"
: >"$offer_out"
: >"$offer_err"

RELAY_MODE="${SHARE_RELAY:-disabled}"

(
  export FINCLAW_HOME="$CALLEE_HOME"
  export FINCLAW_NO_UPDATE_CHECK=1
  "$FINCLAW_BIN" share offer \
    --upstream "$base" \
    --bearer "$DEMO_TOKEN" \
    --ttl 1h \
    --relay "$RELAY_MODE" \
    --json >"$offer_out" 2>"$offer_err" &
  echo $! >"$pf"
)

# Wait for ticket field in JSON output.
ticket=""
for _ in $(seq 1 150); do
  if [[ -s "$offer_out" ]] && python3 -c 'import json,sys; json.load(open(sys.argv[1]))["ticket"]' "$offer_out" 2>/dev/null; then
    ticket="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["ticket"])' "$offer_out")"
    break
  fi
  if ! kill -0 "$(cat "$pf")" 2>/dev/null; then
    break
  fi
  sleep 0.2
done

if [[ -z "$ticket" ]]; then
  echo "error: share offer did not emit a ticket" >&2
  tail -40 "$offer_err" >&2 || true
  exit 1
fi

printf '%s\n' "$ticket" >"$DEMO_ROOT/ticket.txt"
echo "OK p2p offer"
echo "  ticket saved: $DEMO_ROOT/ticket.txt"
echo "  offer pid:    $(cat "$pf")"
echo "  relay:        $RELAY_MODE"
echo "  (leave offer running; next: scripts/04-p2p-redeem-smoke.sh)"

#!/usr/bin/env bash
# Optional: one-shot chat with /ask when a real LLM is configured.
# Default demo uses mock LLM + curl smokes; this path needs LLM_API_KEY (or profile LLM).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

if [[ -f "$DEMO_ROOT/env.sh" ]]; then
  # shellcheck disable=SC1091
  source "$DEMO_ROOT/env.sh"
fi

require_finclaw

if [[ -z "${LLM_API_KEY:-}" && "${LLM_PROVIDER:-mock}" == "mock" ]]; then
  echo "SKIP chat /ask (set LLM_PROVIDER + LLM_API_KEY for a real model, then re-run)"
  echo "  Example:"
  echo "    LLM_PROVIDER=openai LLM_API_KEY=… LLM_MODEL=gpt-4o-mini \\"
  echo "      bash scripts/05-chat-ask-optional.sh"
  exit 0
fi

agents="$(caller_config_dir)/a2a-agents.yaml"
if [[ -f "$(caller_config_dir)/a2a-agents.p2p.yaml" && "${USE_P2P_AGENTS:-}" == "1" ]]; then
  agents="$(caller_config_dir)/a2a-agents.p2p.yaml"
fi
[[ -f "$agents" ]] || {
  echo "error: missing $agents — run scripts/00-prepare-homes.sh" >&2
  exit 1
}

base="http://127.0.0.1:${CALLEE_PORT}"
if [[ "${USE_P2P_AGENTS:-}" == "1" && -f "$DEMO_ROOT/local_a2a_base.txt" ]]; then
  base="$(cat "$DEMO_ROOT/local_a2a_base.txt")"
fi
if ! wait_http "${base}/.well-known/agent-card.json" 30; then
  echo "error: callee not reachable — start serve (and offer/redeem if P2P)" >&2
  exit 1
fi

msg="${ASK_MESSAGE:-/ask callee Say hi in one short sentence for the two-agent demo.}"

(
  export FINCLAW_HOME="$CALLER_HOME"
  export FINCLAW_NO_UPDATE_CHECK=1
  export AI_INFRA_RS_A2A_AGENTS_CONFIG_PATH="$agents"
  export AI_INFRA_RS_EXECUTION_POSTURE=naked
  "$FINCLAW_BIN" chat --embedded -m "$msg"
)

echo "OK chat ask (optional)"

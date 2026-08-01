#!/usr/bin/env bash
# Optional: one-shot chat with /ask when a real LLM is configured.
# Default demo uses mock LLM + curl smokes; this path needs LLM_API_KEY (or profile LLM).
#
# Always uses the profile's a2a-agents.yaml (same file the published CLI reads).
# Pass --via-share to install a2a-agents.p2p.yaml into that path first (after
# scripts/04-p2p-redeem-smoke.sh) — mirrors `finclaw share redeem --write-agents-yaml`.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

if [[ -f "$DEMO_ROOT/env.sh" ]]; then
  # shellcheck disable=SC1091
  source "$DEMO_ROOT/env.sh"
fi

require_finclaw
require_cmd python3

VIA_SHARE=0
if [[ "${1:-}" == "--via-share" ]]; then
  VIA_SHARE=1
  shift
fi

if [[ -z "${LLM_API_KEY:-}" && "${LLM_PROVIDER:-mock}" == "mock" ]]; then
  echo "SKIP chat /ask (set LLM_PROVIDER + LLM_API_KEY for a real model, then re-run)"
  echo "  Example:"
  echo "    LLM_PROVIDER=openai LLM_API_KEY=… LLM_MODEL=gpt-4o-mini \\"
  echo "      bash scripts/05-chat-ask-optional.sh"
  echo "  Share tunnel (after 03/04):"
  echo "    … bash scripts/05-chat-ask-optional.sh --via-share"
  exit 0
fi

agents="$(caller_config_dir)/a2a-agents.yaml"
if [[ "$VIA_SHARE" -eq 1 ]]; then
  p2p="$(caller_config_dir)/a2a-agents.p2p.yaml"
  [[ -f "$p2p" ]] || {
    echo "error: missing $p2p — run scripts/03-p2p-offer.sh and scripts/04-p2p-redeem-smoke.sh first" >&2
    exit 1
  }
  cp "$p2p" "$agents"
  echo "installed share peer into $agents"
  echo "  (same idea as: finclaw share redeem --write-agents-yaml)"
fi

[[ -f "$agents" ]] || {
  echo "error: missing $agents — run scripts/00-prepare-homes.sh" >&2
  exit 1
}

# Card base from the peer URL the CLI will actually use (…/a2a/v1 → origin).
base="$(
  python3 - "$agents" <<'PY'
import pathlib, re, sys
from urllib.parse import urlparse
text = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
m = re.search(r"(?m)^\s*url:\s*(\S+)", text)
if not m:
    raise SystemExit("a2a-agents.yaml: no url: field")
url = m.group(1).strip().strip("\"'")
p = urlparse(url)
if not p.scheme or not p.netloc:
    raise SystemExit(f"invalid peer url: {url!r}")
print(f"{p.scheme}://{p.netloc}")
PY
)"

if ! wait_http "${base}/.well-known/agent-card.json" 30; then
  echo "error: peer not reachable at $base — start serve (and leave offer/redeem running for share)" >&2
  exit 1
fi

msg="${ASK_MESSAGE:-/ask callee Say hi in one short sentence for the two-agent demo.}"

(
  export FINCLAW_HOME="$CALLER_HOME"
  export FINCLAW_NO_UPDATE_CHECK=1
  export AI_INFRA_RS_EXECUTION_POSTURE=naked
  # Do not set AI_INFRA_RS_A2A_AGENTS_CONFIG_PATH: embedded chat pins the
  # profile runtime_home/config/a2a-agents.yaml itself.
  "$FINCLAW_BIN" chat --embedded -m "$msg"
)

echo "OK chat ask (optional)"

#!/usr/bin/env bash
# Shared helpers for examples/two-agent-a2a.
# shellcheck shell=bash

set -euo pipefail

EXAMPLE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC2034
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DEMO_ROOT="${TWO_AGENT_DEMO_ROOT:-$EXAMPLE_ROOT/.demo-homes}"
CALLEE_HOME="${CALLEE_HOME:-$DEMO_ROOT/callee}"
CALLER_HOME="${CALLER_HOME:-$DEMO_ROOT/caller}"
CALLEE_PORT="${CALLEE_PORT:-28701}"
DEMO_TOKEN="${DEMO_TOKEN:-two-agent-a2a-demo-token}"
CALLEE_CARD_NAME="${CALLEE_CARD_NAME:-two-agent-callee}"
PROFILE="${FINCLAW_PROFILE:-default}"

FINCLAW_BIN="${FINCLAW_BIN:-finclaw}"

callee_profile() { echo "$CALLEE_HOME/profiles/$PROFILE"; }
caller_profile() { echo "$CALLER_HOME/profiles/$PROFILE"; }
callee_config_dir() { echo "$(callee_profile)/runtime_home/config"; }
caller_config_dir() { echo "$(caller_profile)/runtime_home/config"; }
callee_workspace() { echo "$(callee_profile)/workspace"; }
caller_workspace() { echo "$(caller_profile)/workspace"; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "error: required command not found: $1" >&2
    exit 1
  }
}

require_finclaw() {
  require_cmd "$FINCLAW_BIN"
}

share_available() {
  # Returns 0 when this binary supports peer share.
  "$FINCLAW_BIN" share status >/dev/null 2>&1
}

wait_http() {
  local url="$1"
  local tries="${2:-150}"
  local i
  for i in $(seq 1 "$tries"); do
    if curl -fsS "$url" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.2
  done
  return 1
}

wait_file_nonzero() {
  local path="$1"
  local tries="${2:-150}"
  local i
  for i in $(seq 1 "$tries"); do
    if [[ -s "$path" ]]; then
      return 0
    fi
    sleep 0.2
  done
  return 1
}

jsonrpc_send_message() {
  local base="$1"
  local token="$2"
  local text="$3"
  local base_trim="${base%/}"
  curl -fsS -X POST "${base_trim}/a2a/v1" \
    -H "Authorization: Bearer ${token}" \
    -H "Content-Type: application/json" \
    -d "$(
      TEXT="$text" python3 -c '
import json, os
print(json.dumps({
  "jsonrpc": "2.0",
  "id": "two-agent-1",
  "method": "SendMessage",
  "params": {
    "message": {
      "role": "user",
      "messageId": "two-agent-msg-1",
      "parts": [{"kind": "text", "text": os.environ["TEXT"]}],
    }
  },
}))
'
    )"
}

common_env() {
  export FINCLAW_NO_UPDATE_CHECK=1
  export AI_INFRA_RS_EXECUTION_POSTURE=naked
  export LLM_PROVIDER="${LLM_PROVIDER:-mock}"
  unset LLM_API_KEY || true
}

pid_file() {
  echo "$DEMO_ROOT/pids/$1.pid"
}

log_file() {
  echo "$DEMO_ROOT/logs/$1.log"
}

ensure_demo_dirs() {
  mkdir -p "$DEMO_ROOT/pids" "$DEMO_ROOT/logs"
}

stop_pidfile() {
  local name="$1"
  local pf
  pf="$(pid_file "$name")"
  if [[ -f "$pf" ]]; then
    local pid
    pid="$(cat "$pf" 2>/dev/null || true)"
    if [[ -n "${pid:-}" ]] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
    fi
    rm -f "$pf"
  fi
}

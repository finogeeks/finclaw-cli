#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
if LATEST_HTML_URL='https://github.com/finogeeks/finclaw-cli/releases/tag/hooks' \
   RELEASE_JSON_STATUS=404 \
   "$root/scripts/hooks-latest-guard.sh"; then
  echo "expected failure when latest is hooks" >&2
  exit 1
fi
LATEST_HTML_URL='https://github.com/finogeeks/finclaw-cli/releases/tag/v0.12.8' \
  RELEASE_JSON_STATUS=200 \
  "$root/scripts/hooks-latest-guard.sh"

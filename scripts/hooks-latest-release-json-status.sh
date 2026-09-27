#!/usr/bin/env bash
# Print the final HTTP status for releases/latest/download/release.json.
set -euo pipefail

if [[ "$#" -ne 1 ]]; then
  echo "usage: $0 <release.json URL>" >&2
  exit 2
fi

curl -sS -L -o /dev/null -w '%{http_code}' "$1"

#!/usr/bin/env bash
# Ensure Apple Container services are running.
set -euo pipefail

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "error: required command not found: $1" >&2
    exit 1
  }
}

require_cmd container

if container system status 2>/dev/null | grep -qi 'running'; then
  echo "OK container system already running"
  exit 0
fi

echo "==> container system start"
container system start
container system status
echo "OK container system started"

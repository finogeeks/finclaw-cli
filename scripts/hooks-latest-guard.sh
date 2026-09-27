#!/usr/bin/env bash
# Fail if GitHub releases/latest is not a v* tag, or if
# releases/latest/download/release.json is not HTTP 200.
#
# env: LATEST_HTML_URL — resolved Location (or a mock URL)
#      RELEASE_JSON_STATUS — HTTP status of release.json
set -euo pipefail

if [[ -z "${LATEST_HTML_URL:-}" ]]; then
  echo "LATEST_HTML_URL is required" >&2
  exit 1
fi
if [[ -z "${RELEASE_JSON_STATUS:-}" ]]; then
  echo "RELEASE_JSON_STATUS is required" >&2
  exit 1
fi

url="${LATEST_HTML_URL}"
url="${url%%\?*}"
url="${url%%#*}"
url="${url%/}"
tag="${url##*/}"

if [[ "${tag}" != v* ]]; then
  echo "latest release tag must be v* (got '${tag}' from ${LATEST_HTML_URL})" >&2
  exit 1
fi

if [[ "${RELEASE_JSON_STATUS}" != "200" ]]; then
  echo "releases/latest/download/release.json must be HTTP 200 (got ${RELEASE_JSON_STATUS})" >&2
  exit 1
fi

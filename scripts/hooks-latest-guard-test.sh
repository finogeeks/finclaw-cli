#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
mock_dir="$(mktemp -d)"
trap 'rm -f "$mock_dir/curl"; rmdir "$mock_dir"' EXIT
cat > "$mock_dir/curl" <<'EOF'
#!/usr/bin/env bash
for arg in "$@"; do
  if [[ "$arg" == "-L" ]]; then
    printf '200'
    exit 0
  fi
done
printf '302'
EOF
chmod +x "$mock_dir/curl"

redirect_status="$(
  PATH="$mock_dir:$PATH" bash "$root/scripts/hooks-latest-release-json-status.sh" \
    "https://example.test/releases/latest/download/release.json"
)"
if [[ "$redirect_status" != "200" ]]; then
  echo "expected redirected release.json probe to return 200, got $redirect_status" >&2
  exit 1
fi

if LATEST_HTML_URL='https://github.com/finogeeks/finclaw-cli/releases/tag/hooks' \
   RELEASE_JSON_STATUS=404 \
   "$root/scripts/hooks-latest-guard.sh"; then
  echo "expected failure when latest is hooks" >&2
  exit 1
fi
LATEST_HTML_URL='https://github.com/finogeeks/finclaw-cli/releases/tag/v0.12.8' \
  RELEASE_JSON_STATUS=200 \
  "$root/scripts/hooks-latest-guard.sh"

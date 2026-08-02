#!/usr/bin/env bash
# Fetch Linux x86_64 finclaw from finogeeks/finclaw-cli GitHub Releases.
# Used inside Apple Container (amd64 + Rosetta) — no aarch64 Linux artifact yet.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CACHE_DIR="${FINCLAW_LINUX_CACHE:-$EXAMPLE_ROOT/.demo-homes/linux-bin}"
REPO="${FINCLAW_CLI_REPO:-finogeeks/finclaw-cli}"
VERSION="${FINCLAW_VERSION:-}"

mkdir -p "$CACHE_DIR"

if [[ -z "$VERSION" ]]; then
  if command -v gh >/dev/null 2>&1; then
    VERSION="$(gh release view -R "$REPO" --json tagName -q .tagName)"
  else
    VERSION="$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"])')"
  fi
fi
VERSION="${VERSION#v}"
TAG="v${VERSION}"
TRIPLE="x86_64-unknown-linux-gnu"
ARCHIVE="finclaw-${TAG}-${TRIPLE}.tar.gz"
OUT_BIN="$CACHE_DIR/finclaw"

# Do not exec the Linux binary on the macOS host (Exec format error).
# Cache hit: matching version stamp file written at install time.
stamp="$CACHE_DIR/VERSION"
if [[ -x "$OUT_BIN" && -f "$stamp" && "$(cat "$stamp")" == "$VERSION" ]]; then
  echo "OK cached Linux finclaw v${VERSION} → $OUT_BIN" >&2
  echo "$OUT_BIN"
  exit 0
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
url="https://github.com/${REPO}/releases/download/${TAG}/${ARCHIVE}"
sums_url="https://github.com/${REPO}/releases/download/${TAG}/SHA256SUMS"

echo "==> download $url" >&2
curl -fsSL -o "$tmpdir/$ARCHIVE" "$url"
curl -fsSL -o "$tmpdir/SHA256SUMS" "$sums_url"
(
  cd "$tmpdir"
  grep -F "$ARCHIVE" SHA256SUMS | shasum -a 256 -c -
) >&2
tar -xzf "$tmpdir/$ARCHIVE" -C "$tmpdir"
# Archive layout: finclaw-vX-triple/finclaw
src="$(find "$tmpdir" -type f -name finclaw | head -1)"
[[ -n "$src" ]] || {
  echo "error: finclaw binary not found in $ARCHIVE" >&2
  exit 1
}
install -m 0755 "$src" "$OUT_BIN"
printf '%s\n' "$VERSION" >"$stamp"
echo "OK installed Linux finclaw v${VERSION} → $OUT_BIN" >&2
echo "$OUT_BIN"

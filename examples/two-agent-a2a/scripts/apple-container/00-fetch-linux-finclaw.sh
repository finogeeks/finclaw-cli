#!/usr/bin/env bash
# Fetch Linux finclaw from finogeeks/finclaw-cli GitHub Releases.
# Default on Apple Silicon hosts: aarch64-unknown-linux-gnu (native Apple Container).
# Override with FINCLAW_LINUX_TRIPLE=x86_64-unknown-linux-gnu for Rosetta/amd64 guests.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CACHE_DIR="${FINCLAW_LINUX_CACHE:-$EXAMPLE_ROOT/.demo-homes/linux-bin}"
REPO="${FINCLAW_CLI_REPO:-finogeeks/finclaw-cli}"
VERSION="${FINCLAW_VERSION:-}"

# Prefer native arm64 Linux for Apple Container on Apple Silicon.
default_triple="aarch64-unknown-linux-gnu"
case "$(uname -m)" in
  x86_64) default_triple="x86_64-unknown-linux-gnu" ;;
esac
TRIPLE="${FINCLAW_LINUX_TRIPLE:-$default_triple}"

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
ARCHIVE="finclaw-${TAG}-${TRIPLE}.tar.gz"
OUT_BIN="$CACHE_DIR/finclaw-${TRIPLE}"
stamp="$CACHE_DIR/VERSION-${TRIPLE}"

# Do not exec the Linux binary on the macOS host (wrong OS/arch).
if [[ -x "$OUT_BIN" && -f "$stamp" && "$(cat "$stamp")" == "$VERSION" ]]; then
  # Keep a stable path for volume mounts.
  ln -sfn "$(basename "$OUT_BIN")" "$CACHE_DIR/finclaw"
  echo "OK cached Linux finclaw v${VERSION} (${TRIPLE}) → $OUT_BIN" >&2
  echo "$CACHE_DIR/finclaw"
  exit 0
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
url="https://github.com/${REPO}/releases/download/${TAG}/${ARCHIVE}"
sums_url="https://github.com/${REPO}/releases/download/${TAG}/SHA256SUMS"

echo "==> download $url" >&2
if ! curl -fsSL -o "$tmpdir/$ARCHIVE" "$url"; then
  echo "error: failed to download $ARCHIVE" >&2
  echo "  If this release predates linux/aarch64, set FINCLAW_LINUX_TRIPLE=x86_64-unknown-linux-gnu" >&2
  echo "  and run guests with --arch amd64 --rosetta." >&2
  exit 1
fi
curl -fsSL -o "$tmpdir/SHA256SUMS" "$sums_url"
(
  cd "$tmpdir"
  grep -F "$ARCHIVE" SHA256SUMS | shasum -a 256 -c -
) >&2
tar -xzf "$tmpdir/$ARCHIVE" -C "$tmpdir"
src="$(find "$tmpdir" -type f -name finclaw | head -1)"
[[ -n "$src" ]] || {
  echo "error: finclaw binary not found in $ARCHIVE" >&2
  exit 1
}
install -m 0755 "$src" "$OUT_BIN"
printf '%s\n' "$VERSION" >"$stamp"
ln -sfn "$(basename "$OUT_BIN")" "$CACHE_DIR/finclaw"
echo "OK installed Linux finclaw v${VERSION} (${TRIPLE}) → $OUT_BIN" >&2
echo "$CACHE_DIR/finclaw"

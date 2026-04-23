#!/usr/bin/env sh
# Install finclaw from GitHub releases published in finogeeks/finclaw-cli.
# Intended usage:
#   curl -fsSL https://raw.githubusercontent.com/finogeeks/finclaw-cli/main/install.sh | sh
# With explicit version and/or install location:
#   curl -fsSL .../install.sh | env FINCLAW_VERSION=0.1.0 FINCLAW_INSTALL_DIR="$HOME/.local/bin" sh

set -eu

REPO_DEFAULT="finogeeks/finclaw-cli"
REPO="${FINCLAW_REPO:-$REPO_DEFAULT}"

# Version without a leading "v" (e.g. 0.1.0). If empty, use GitHub "latest" release.
VERSION_RAW="${FINCLAW_VERSION:-}"

# Where to place the `finclaw` binary. Default matches README guidance.
INSTALL_DIR="${FINCLAW_INSTALL_DIR:-"$HOME/.local/bin"}"

# 1 = do not require SHA256SUMS (emergency escape hatch; not recommended)
SKIP_CHECKSUM="${FINCLAW_INSECURE_SKIP_CHECKSUM:-0}"

die() {
  printf "error: %s\n" "$1" >&2
  exit 1
}

info() {
  printf "==> %s\n" "$1" >&2
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

strip_v() {
  # shellcheck disable=SC2001
  echo "$1" | sed 's/^v//'
}

usage() {
  cat <<'EOF' >&2
Usage:
  install.sh [--version <x.y.z|vx.y.z>]

Environment:
  FINCLAW_VERSION                 Install this version (e.g. 0.1.0). If unset, uses latest.
  FINCLAW_INSTALL_DIR             Install directory (default: $HOME/.local/bin)
  FINCLAW_REPO                    GitHub "owner/name" (default: finogeeks/finclaw-cli)
  FINCLAW_INSECURE_SKIP_CHECKSUM  Set to 1 to skip SHA256 verification (not recommended)

Examples:
  curl -fsSL https://raw.githubusercontent.com/finogeeks/finclaw-cli/main/install.sh | sh
  curl -fsSL https://raw.githubusercontent.com/finogeeks/finclaw-cli/main/install.sh | sh -s -- --version 0.1.0
  FINCLAW_VERSION=0.1.0 sh install.sh
EOF
}

# Minimal argv parsing: forward compatibility with "curl | sh" one-liner.
# Supports:
#   sh -s -- --version 0.1.0
while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --version)
      [ "$#" -ge 2 ] || die "--version requires a value"
      VERSION_RAW="$2"
      shift 2
      ;;
    *)
      die "unknown argument: $1 (see --help)"
      ;;
  esac
done

need_cmd curl
need_cmd uname
need_cmd mkdir
need_cmd mktemp
need_cmd rm
need_cmd cp
need_cmd chmod
need_cmd tar

os="$(uname -s)"
arch="$(uname -m)"

detect_triple() {
  case "$os" in
    Linux)
      case "$arch" in
        x86_64) echo "x86_64-unknown-linux-gnu" ;;
        aarch64|arm64) die "this installer currently supports Linux x86_64 only (got $arch). Try manual download, or WSL/amd64, or a future aarch64 build." ;;
        *) die "unsupported Linux machine: $arch" ;;
      esac
      ;;
    Darwin)
      case "$arch" in
        x86_64) echo "x86_64-apple-darwin" ;;
        arm64) echo "aarch64-apple-darwin" ;;
        *) die "unsupported macOS machine: $arch" ;;
      esac
      ;;
    *) die "unsupported OS: $os (on Windows, install WSL2 + Linux, then rerun)" ;;
  esac
}

TRIPLE="$(detect_triple)"

if [ -z "$VERSION_RAW" ]; then
  info "resolving latest release for https://github.com/${REPO}"
  latest_json="$(mktemp)"
  curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" -o "$latest_json"

  if command -v python3 >/dev/null 2>&1; then
    VERSION_STRIP="$(
      python3 - "$latest_json" <<'PY'
import json, sys
path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    d = json.load(f)
print(d.get("tag_name", "") or "")
PY
    )"
  else
    # Fallback: look for a "tag_name" line. Not as robust as JSON parse, but works for GitHub's API JSON.
    VERSION_STRIP="$(sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\(v\?[0-9][^\"]*\)".*/\1/p' "$latest_json" | head -n 1 || true)"
  fi
  rm -f "$latest_json" >/dev/null 2>&1 || true
  [ -n "$VERSION_STRIP" ] || die "could not parse latest release tag from GitHub API response"
  VERSION_STRIP="$(strip_v "$VERSION_STRIP")"
else
  VERSION_STRIP="$(strip_v "$VERSION_RAW")"
fi

version_tag="v${VERSION_STRIP}"
archive_name="finclaw-v${VERSION_STRIP}-${TRIPLE}.tar.zst"
inner_dir="finclaw-v${VERSION_STRIP}-${TRIPLE}"

# GitHub "download" URLs for release assets
base="https://github.com/${REPO}/releases/download/${version_tag}"
archive_url="${base}/${archive_name}"
sums_url="${base}/SHA256SUMS"

stage="$(mktemp -d)"
cleanup_stage() {
  rm -rf "$stage" >/dev/null 2>&1 || true
}
trap cleanup_stage INT TERM EXIT

cd "$stage" || die "could not enter temp directory"

info "downloading ${archive_url}"
curl -fSL --retry 3 --retry-delay 1 -o "$archive_name" "$archive_url"

if [ "$SKIP_CHECKSUM" = "1" ]; then
  info "WARNING: skipping checksum verification (FINCLAW_INSECURE_SKIP_CHECKSUM=1)"
else
  info "downloading ${sums_url}"
  curl -fSL --retry 3 --retry-delay 1 "$sums_url" -o SHA256SUMS

  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 -c SHA256SUMS
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum -c SHA256SUMS
  else
    die "neither shasum nor sha256sum is available; install one, or (not recommended) set FINCLAW_INSECURE_SKIP_CHECKSUM=1"
  fi
fi

if command -v zstd >/dev/null 2>&1; then
  info "extracting with zstd + tar"
  zstd -dc "$archive_name" | tar -xf -
elif [ "$os" = "Linux" ] && command -v grep >/dev/null 2>&1 && tar --help 2>&1 | grep -q -- '--zstd'; then
  info "extracting with tar --zstd"
  tar --zstd -xf "$archive_name"
else
  die "could not find zstd, and this tar does not support --zstd. Install zstd and retry (macOS: brew install zstd)"
fi

[ -d "$inner_dir" ] || die "expected directory missing after extract: $inner_dir"
[ -f "$inner_dir/finclaw" ] || die "expected binary missing: $inner_dir/finclaw"

# shellcheck disable=SC2088
info "installing to ${INSTALL_DIR}"
# NOTE: we expand ~-style paths because users may set FINCLAW_INSTALL_DIR=~/bin
case "$INSTALL_DIR" in
  "~"|"~"/*|"~root"|"~root"/*) die "please expand ~ in FINCLAW_INSTALL_DIR (use an absolute path like \$HOME/... )" ;;
esac
mkdir -p "$INSTALL_DIR" || die "could not create install dir: $INSTALL_DIR"

cp -f "$inner_dir/finclaw" "$INSTALL_DIR/finclaw"
chmod 0755 "$INSTALL_DIR/finclaw"

cp_path="$INSTALL_DIR/finclaw"
if command -v finclaw >/dev/null 2>&1; then
  first="$(command -v finclaw)"
  info "installed: $cp_path (first on PATH: $first)"
  "$first" --version || true
else
  info "installed: $cp_path, but it is not on your PATH yet"
  info "add this to your shell rc: export PATH=\"$INSTALL_DIR:\$PATH\""
fi

info "done"

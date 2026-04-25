# Installation and updates

**Chinese:** [installation.zh.md](installation.zh.md)

## Supported platforms

- **macOS** — arm64 and x86_64 artifacts are published.
- **Linux** — `x86_64-unknown-linux-gnu` (glibc) is the typical target; WSL2 on Windows uses the same Linux archive.
- **Windows** — use **WSL2** and the Linux binary until a native Windows artifact is published in [Releases](https://github.com/finogeeks/finclaw-cli/releases).

## One-line install (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/finogeeks/finclaw-cli/main/install.sh | sh
```

Cache-busting the script URL (if a CDN serves an old `install.sh`):

```bash
curl -fsSL "https://raw.githubusercontent.com/finogeeks/finclaw-cli/main/install.sh?$(date +%s)" | sh
```

Pin a version (adjust tag when your release provides `install.sh` on that tag):

```bash
curl -fsSL https://raw.githubusercontent.com/finogeeks/finclaw-cli/main/install.sh | sh -s -- --version 0.1.0
```

Useful environment variables (see `install.sh --help` on the branch you install from):

- `FINCLAW_VERSION` — version with or without `v` prefix
- `FINCLAW_INSTALL_DIR` — default is `$HOME/.local/bin`
- `FINCLAW_INSECURE_SKIP_CHECKSUM=1` — **emergency only**; do not use for normal installs

**After install**, ensure the install directory is on your `PATH`, then:

```bash
finclaw --version
```

## Manual download and verify

1. Open [Releases](https://github.com/finogeeks/finclaw-cli/releases) and pick a version tag (for example `v0.1.0`).
2. Download **one** platform archive (`.tar.zst`) and the **`SHA256SUMS`** file for that release.

`SHA256SUMS` lists **every** platform archive in the release. You only have **one** file on disk, so **do not** run `shasum -a 256 -c` or `sha256sum -c` on the full `SHA256SUMS` file (it will look for the other platform archives and fail). Verify **only the line** for the file you downloaded:

```bash
cd ~/Downloads
VER=0.1.0
FILE="finclaw-v${VER}-aarch64-apple-darwin.tar.zst"   # match your platform triple
grep -F "$FILE" SHA256SUMS | shasum -a 256 -c -
```

On Linux you can use `sha256sum -c` in the same `grep` pipeline if you prefer.

## Extract and install the binary

You need **`tar`** and **`zstd`** (archives are `*.tar.zst`).

**Example (Apple Silicon macOS, adjust `VER` and the archive name):**

```bash
VER=0.1.0
FILE="finclaw-v${VER}-aarch64-apple-darwin.tar.zst"
zstd -dc "$FILE" | tar -xf -
install -m 0755 "finclaw-v${VER}-aarch64-apple-darwin/finclaw" "$HOME/.local/bin/finclaw"
```

Many Linux distros also support:

```bash
tar --zstd -xf "finclaw-v${VER}-x86_64-unknown-linux-gnu.tar.zst"
```

**PATH** — if `finclaw` is not found:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc   # or ~/.bashrc
export PATH="$HOME/.local/bin:$PATH"
```

## macOS Gatekeeper

Unsigned binaries can be blocked by **Gatekeeper**. If the binary is quarantined or blocked, use **System Settings → Privacy & Security** to allow it, or follow your organization’s policy for signed builds.

## Updating

When a new release is published, download the new archive for your platform, **re-verify** checksums, and **replace** the `finclaw` binary. Run `finclaw update --help` for the behavior of the `update` subcommand in your build (it may only print channel/URL guidance; it does not always replace the binary automatically).

## Uninstall

See [troubleshooting.md](troubleshooting.md) and run `finclaw uninstall --help` for options to remove the binary and local state.

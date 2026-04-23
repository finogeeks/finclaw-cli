# finclaw CLI (binary releases)

This repository is the **public download surface** for the `finclaw` command-line tool. The application source is developed in a private monorepo; **build artifacts are published here** as [GitHub Releases](https://github.com/finogeeks/finclaw-cli/releases) so end users can install without source access.

- **English (this file)** — you are here  
- **中文** — see [`README.zh.md`](README.zh.md)

## 1) Download the first binary (manual)

1. Open **Releases**: `https://github.com/finogeeks/finclaw-cli/releases`
2. Pick a version (tags look like `v0.1.0`).
3. Download **one** of the per-platform archives, plus the checksums file:
   - `finclaw-v<version>-x86_64-unknown-linux-gnu.tar.zst` (Linux x86_64, including most WSL2 distros on Intel/AMD)
   - `finclaw-v<version>-x86_64-apple-darwin.tar.zst` (macOS Intel)
   - `finclaw-v<version>-aarch64-apple-darwin.tar.zst` (macOS Apple Silicon)
   - `SHA256SUMS`
   - `release.json` (metadata; optional for install)

> **There is not currently a Windows `.exe` in these releases.** On Windows, use **WSL2** with a glibc-based Linux (Ubuntu is the common default) and install the **Linux** archive, or run `finclaw` on macOS/Linux natively.

### Verify the download

macOS (ships `shasum`):

```bash
cd ~/Downloads
shasum -a 256 -c SHA256SUMS
```

Linux (GNU coreutils):

```bash
cd ~/Downloads
sha256sum -c SHA256SUMS
```

If verification fails, **do not run** the binary; re-download from the release page.

## 2) Install and set up on your machine

Prerequisites:
- A shell (`bash`/`zsh` on macOS/Linux, or a Linux environment on Windows)
- `tar` and `zstd` available (`zstd` is required to decompress `*.tar.zst`)

### Extract the archive

The archive contains a single directory:

- `finclaw-v<version>-<target>/finclaw`

Example (macOS, Apple Silicon) — adjust `VER` and the filename to match the release you downloaded:

```bash
VER=0.1.0
FILE="finclaw-v${VER}-aarch64-apple-darwin.tar.zst"
zstd -dc "$FILE" | tar -xf -
```

If `tar` on your system supports zstd directly, this also works on many Linux distributions:

```bash
tar --zstd -xf "finclaw-v${VER}-x86_64-unknown-linux-gnu.tar.zst"
```

### Put `finclaw` on your `PATH`

Replace the path below with the extracted folder name you actually have.

```bash
install -m 0755 "finclaw-v${VER}-aarch64-apple-darwin/finclaw" "$HOME/.local/bin/finclaw"
```

Make sure your shell can find it:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc   # or ~/.bashrc
export PATH="$HOME/.local/bin:$PATH"
```

Confirm:

```bash
finclaw --version
```

### First-time configuration (profiles + `~/.finclaw`)

`finclaw` stores per-machine state under `~/.finclaw/` by default (or under `$FINCLAW_HOME` if you set it). A single isolated environment is called a **profile** (default name: `default`).

Run the interactive first-run flow:

```bash
finclaw init
```

Non-interactive automation (for scripts) is also supported; see `finclaw init --help`.

You will need **LLM provider credentials** for real model calls. The embedded mock provider is useful for smoke tests, but it will not call a real model. For detailed provider setup, refer to the host documentation you received with your distribution, or use `finclaw config --help` and `finclaw doctor` after you configure keys.

**macOS security note:** unsigned binaries may trigger Gatekeeper. If you cannot open the file, use **System Settings → Privacy & Security** to allow it, or use an Apple Developer–signed build if your organization provides one.

**Windows note:** if you are not using WSL, treat native Windows as **unsupported** until a `*-pc-windows-msvc` artifact is published.

## 3) How to use the CLI (basics)

Global help and command discovery:

```bash
finclaw --help
finclaw <command> --help
```

Useful “health” commands:

```bash
finclaw version
finclaw doctor
```

Start a one-shot agent message (exits after the reply):

```bash
finclaw chat -m "Hello from finclaw"
```

Open the interactive REPL (when run without `--message`):

```bash
finclaw chat
```

Run a long-lived daemon (when you are ready for that deployment mode):

```bash
finclaw serve
```

## Updates

When new versions appear on the **Releases** page, download the new archive for your platform, verify `SHA256SUMS`, and replace the binary. If your `finclaw` build exposes an `update` subcommand, treat it as **documentation and safety checks** unless your release notes explicitly state it performs automatic in-place replacement.

## Support

- **Download issues:** open a discussion/issue on this repo with the **release tag** and the **file name** you tried to download.  
- **Product/runtime issues (agent behavior, configuration):** use the support channel your team links from the private `finclaw` distribution, if applicable.

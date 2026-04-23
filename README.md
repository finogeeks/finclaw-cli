<p align="center">
  <img src="assets/finclaw-wordmark.svg" width="560" alt="FINCLAW" />
</p>

<p align="center"><em>Wordmark fill: CLI theme gradient (#4796E4 → #847ACE → #C3677F), same as <code>finclaw chat</code> on a color TTY.</em></p>

# finclaw

[![GitHub release](https://img.shields.io/github/v/release/finogeeks/finclaw-cli?label=release&sort=semver)](https://github.com/finogeeks/finclaw-cli/releases)
![Platforms macOS and Linux](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey)

**A lightweight, high-performance CLI built in Rust** — a single **~20 MB** (release/stripped) binary, statically linked, with no Node or Python required to run the tool. The header above uses the same CLI theme colors you see in `finclaw chat` on a color terminal.

**What it does:** terminal-native work on the **Claw** agent runtime (public wire contract: [`finclaw-contract`](https://github.com/Geeksfino/finclaw-contract)) — interactive REPL, slash commands, per-machine **profiles**, and optional **daemon** mode (`finclaw serve`).

This repository is the **public install surface** for the `finclaw` command-line tool. The application is developed in a private monorepo; **release builds are published here** on [GitHub Releases](https://github.com/finogeeks/finclaw-cli/releases) so you can install without source access.

| | |
| --- | --- |
| **English** | *You are here* |
| **中文** | [README.zh.md](README.zh.md) |

---

## What you get

| | |
| --- | --- |
| **Small Rust binary, fast path** | Native code, small disk footprint (on the order of **~20 MB** per platform build), and a responsive CLI — ideal for daily terminal use. |
| **Real terminal UI** | Interactive REPL when you run `finclaw chat` with no message: multiline input, inline help, and slash commands. |
| **Profiles, not a single global blob** | Isolated `~/.finclaw/profiles/<name>/` layout — templates, skills, policies, and identity, shareable with backup/import flows. |
| **Claw under the hood** | Tool/skill and policy contracts from the Finclaw stack; one binary talks to embedded or remote Claw as the host is designed. |
| **Run modes** | **One-shot** (`finclaw chat -m "…"`), **REPL** (`finclaw chat`), or a **long-lived** process (`finclaw serve`) when you want a daemon. |
| **Operator-friendly** | `finclaw doctor`, `finclaw version`, shell completions, and explicit update guidance — built for people who read `--help` first. |

---

## Quick install

**Works on macOS, Linux, and on Windows via WSL2** (glibc-based Linux; use the `*-unknown-linux-gnu` archive). A native Windows `.exe` is not in the current release set.

**One-liner** (downloads the correct `*.tar.zst` for this machine, verifies `SHA256SUMS` when the release provides it, installs into `$HOME/.local/bin`):

```bash
curl -fsSL https://raw.githubusercontent.com/finogeeks/finclaw-cli/main/install.sh | sh
```

Pin a **stable script URL** to a tag once that tag’s `install.sh` exists:

```bash
curl -fsSL https://raw.githubusercontent.com/finogeeks/finclaw-cli/v0.1.0/install.sh | sh
```

Pass flags through the pipe:

```bash
curl -fsSL https://raw.githubusercontent.com/finogeeks/finclaw-cli/main/install.sh | sh -s -- --version 0.1.0
```

Or use environment variables (same as `install.sh` documents):

```bash
curl -fsSL https://raw.githubusercontent.com/finogeeks/finclaw-cli/main/install.sh \
  | env FINCLAW_VERSION=0.1.0 FINCLAW_INSTALL_DIR="$HOME/.local/bin" sh
```

`FINCLAW_INSECURE_SKIP_CHECKSUM=1` is an **emergency** escape hatch; you should not need it for normal releases.

**After install:**

```bash
source ~/.zshrc    # or: source ~/.bashrc
finclaw --version
```

---

## First run in four commands

```text
finclaw init        # first-time: profile dirs, stub config, optional template
finclaw doctor      # quick sanity check after you add LLM settings
finclaw chat        # drop into the interactive REPL (no -m)
finclaw --help      # full command tree; every subcommand has --help
```

**One-liner to the model** (for scripts or CI — exits after the reply):

```bash
finclaw chat -m "Hello from finclaw"
```

**When you are ready for a service-style deployment** (long-lived process on the machine):

```bash
finclaw serve
```

**LLM providers:** the embedded mock is fine for smoke tests; for real models you will configure API keys and endpoints. Use `finclaw config` / `finclaw doctor` after editing `config.yaml`, or read the host documentation that ships with your distribution.

---

## Command cheat sheet

| I want to… | Start here |
| --- | --- |
| See what this build is | `finclaw version` |
| Health / config / sandbox hints | `finclaw doctor` |
| Talk to the agent in the shell | `finclaw chat` (REPL) or `finclaw chat -m "…"` |
| Switch or inspect models | `finclaw model` / `finclaw model <id>` |
| Manage a profile (clone, template, diff) | `finclaw profile --help` |
| Policies and identity | `finclaw policy --help` · `finclaw identity --help` |
| Shell completion | `finclaw completion bash` (zsh, fish, elvish, PowerShell) |
| Follow logs | `finclaw logs --help` |
| Check for a newer public build | `finclaw update` (prints channel + URL; replace binary manually unless release notes say otherwise) |
| Uninstall / wipe local state | `finclaw uninstall` |

`finclaw --help` and `finclaw <subcommand> --help` are authoritative for flags.

---

## Manual download (full control)

1. Open **[Releases](https://github.com/finogeeks/finclaw-cli/releases)** and pick a version (tags look like `v0.1.0`).
2. Download **one** platform archive and **`SHA256SUMS`**.
3. Verify, then extract and install the binary to a directory on your `PATH`.

| Asset | When to use it |
| --- | --- |
| `finclaw-v<version>-aarch64-apple-darwin.tar.zst` | macOS Apple Silicon |
| `finclaw-v<version>-x86_64-apple-darwin.tar.zst` | macOS Intel |
| `finclaw-v<version>-x86_64-unknown-linux-gnu.tar.zst` | Linux x86_64 and typical WSL2 distros on Intel/AMD |
| `SHA256SUMS` | Always, unless you are intentionally skipping verification |
| `release.json` | Optional metadata |

**Verify the download** — do not run the binary if this fails.

macOS:

```bash
cd ~/Downloads
shasum -a 256 -c SHA256SUMS
```

Linux (GNU coreutils):

```bash
cd ~/Downloads
sha256sum -c SHA256SUMS
```

**Prerequisites to extract:** `tar` and `zstd` (the archives are `*.tar.zst`).

Example extract (Apple Silicon, adjust `VER` and the filename to your download):

```bash
VER=0.1.0
FILE="finclaw-v${VER}-aarch64-apple-darwin.tar.zst"
zstd -dc "$FILE" | tar -xf -
```

Many Linux distros also support:

```bash
tar --zstd -xf "finclaw-v${VER}-x86_64-unknown-linux-gnu.tar.zst"
```

**Install the binary** (path matches the directory name inside the archive):

```bash
install -m 0755 "finclaw-v${VER}-aarch64-apple-darwin/finclaw" "$HOME/.local/bin/finclaw"
```

**PATH** (if `finclaw` is not found):

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc   # or ~/.bashrc
export PATH="$HOME/.local/bin:$PATH"
```

### Platforms

- **macOS** — unsigned binaries can trigger **Gatekeeper**. If the binary is blocked, use **System Settings → Privacy & Security** to allow it, or use a signed build from your organization if one is available.
- **Windows** — native Windows is **not** in the current artifact matrix; use **WSL2** and the Linux binary until a `*-pc-windows-msvc` (or similar) build is published.

### Data layout (high level)

- Default root: `~/.finclaw` (or `$FINCLAW_HOME`).
- A **profile** is an isolated environment under that root; the default name is `default` and is created by `finclaw init` on first use.

### Updates

When a new release appears, **download the new archive** for your platform, **re-verify** `SHA256SUMS`, and **replace** the `finclaw` binary. The `update` subcommand is there to show channel and download guidance; it does not silently overwrite the binary unless your release documentation explicitly says it does for your edition.

### Support

- **Install / download / checksum / cannot extract:** open a **[discussion or issue](https://github.com/finogeeks/finclaw-cli/issues)** on this repository with the **release tag**, **file name**, and **OS and CPU architecture** (e.g. `macOS 15, arm64` or `Ubuntu 24.04, x86_64`).
- **Agent behaviour, product configuration, and runtime issues** may be routed through your team’s or vendor’s private Finclaw support channel when applicable; this public repo is focused on **shipping and installing** the binary.

---

## License

Licensing and redistribution terms for the **published binaries** are defined on each **GitHub Release** and in any `LICENSE` or notice bundled with the archive you download. This README does not override those terms.

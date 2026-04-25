<p align="center">
  <img src="assets/finclaw-wordmark.svg" width="560" alt="FINCLAW" />
</p>

# finclaw

[![GitHub release](https://img.shields.io/github/v/release/finogeeks/finclaw-cli?label=release&sort=semver)](https://github.com/finogeeks/finclaw-cli/releases)
![Platforms macOS and Linux](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey)

**A lightweight, high-performance CLI built in Rust** — a single **~20 MB** (release/stripped) binary, statically linked, with no Node or Python required to run the tool.

**What it does:** terminal-native work on the **Claw** agent runtime (public wire contract: [`finclaw-contract`](https://github.com/Geeksfino/finclaw-contract)) — interactive REPL, slash commands, per-machine **profiles**, and optional **daemon** mode (`finclaw serve`).

This repository is the **official home** for the `finclaw` command-line tool: install scripts, user documentation, and **release builds** on [GitHub Releases](https://github.com/finogeeks/finclaw-cli/releases).

| | |
| --- | --- |
| **English** | *You are here* |
| **中文** | [README.zh.md](README.zh.md) |

## Documentation

All user guides are **self-contained in this repository** (no private source access required). See **[docs/README.md](docs/README.md)** for the full index (English + 中文 for each topic).

| Topic | English | 中文 |
| --- | --- | --- |
| **Index** | [docs/README.md](docs/README.md) | 同上（双语对照表） |
| Quick start | [docs/getting-started.md](docs/getting-started.md) | [docs/getting-started.zh.md](docs/getting-started.zh.md) |
| Install and updates | [docs/installation.md](docs/installation.md) | [docs/installation.zh.md](docs/installation.zh.md) |
| Configuration | [docs/configuration.md](docs/configuration.md) | [docs/configuration.zh.md](docs/configuration.zh.md) |
| Profiles and backup | [docs/profiles.md](docs/profiles.md) | [docs/profiles.zh.md](docs/profiles.zh.md) |
| Security and policies | [docs/security-and-policies.md](docs/security-and-policies.md) | [docs/security-and-policies.zh.md](docs/security-and-policies.zh.md) |
| Skills | [docs/skills.md](docs/skills.md) | [docs/skills.zh.md](docs/skills.zh.md) |
| Chat and operations | [docs/chat-and-operations.md](docs/chat-and-operations.md) | [docs/chat-and-operations.zh.md](docs/chat-and-operations.zh.md) |
| Command index | [docs/reference-commands.md](docs/reference-commands.md) | [docs/reference-commands.zh.md](docs/reference-commands.zh.md) |
| Troubleshooting | [docs/troubleshooting.md](docs/troubleshooting.md) | [docs/troubleshooting.zh.md](docs/troubleshooting.zh.md) |
| Advanced (completions, man, optional features) | [docs/advanced.md](docs/advanced.md) | [docs/advanced.zh.md](docs/advanced.zh.md) |
| Contributor doc maintenance | [docs/MAINTENANCE.md](docs/MAINTENANCE.md) | [docs/MAINTENANCE.md](docs/MAINTENANCE.md) (EN) |

`finclaw --help` and `finclaw <subcommand> --help` remain authoritative for flags on your build.

## Quick install

**Platforms:** macOS, Linux, and **Windows via WSL2** (glibc Linux). A native Windows `.exe` is not in the current release set.

```bash
curl -fsSL https://raw.githubusercontent.com/finogeeks/finclaw-cli/main/install.sh | sh
```

Then ensure `$HOME/.local/bin` (or your chosen install dir) is on `PATH` and run `finclaw --version`.

**Details:** [docs/installation.md](docs/installation.md) (manual download, checksums, extract, updates).

## First run

```text
finclaw init
finclaw setup
finclaw doctor
finclaw chat
finclaw --help
```

**One-shot:** `finclaw chat -m "Hello"` · **LLM setup:** [docs/getting-started.md](docs/getting-started.md)

## License

Licensing and redistribution terms for the **published binaries** are defined on each **GitHub Release** and in any `LICENSE` or notice bundled with the archive you download. This README does not override those terms.

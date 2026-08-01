<p align="center">
  <img src="assets/finclaw-wordmark.svg" width="560" alt="FINCLAW" />
</p>

# finclaw

[![GitHub release](https://img.shields.io/github/v/release/finogeeks/finclaw-cli?label=release&sort=semver)](https://github.com/finogeeks/finclaw-cli/releases)
![Platforms](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey)
![A2A](https://img.shields.io/badge/A2A-HTTP%20%2B%20peer%20share-0A7A3E)

**Peer-to-peer agent networking on the A2A protocol.**

`finclaw` is a fast Rust CLI — one binary (~20–30 MB) — that runs your personal
agent in the **terminal** and in **[Zed](https://zed.dev/)** via
**[ACP](https://agentclientprotocol.com/)**. Other agents can call yours over
**[A2A](docs/a2a.md)** (Agent2Agent) the same way: on a LAN or local **HTTP**
URL, or via **peer share** when you can’t expose a public port. The wire stays
Agent Card + JSON-RPC; share only provides reachability. A **Hermes-style
learning loop** grows memory and skills over time — no Node or Python required
to run the tool itself.

| | |
| --- | --- |
| **English** | *You are here* |
| **中文** | [README.zh.md](README.zh.md) |

---

## Why finclaw?

| You want… | finclaw gives you… |
| --- | --- |
| Agents that reach each other **without a public URL** | **Peer share** (`finclaw share offer\|redeem`) — ticket → localhost A2A base; both sides stay online |
| Agents that talk on a known network | **A2A over HTTP** — `finclaw serve` + `a2a-agents.yaml`, `/ask` / `/delegate` |
| A serious coding / research agent in the terminal | Interactive REPL, optional full-screen `--tui`, one-shot `chat`, profiles, skills, MCP |
| The same agent inside your editor | **`finclaw acp`** — Agent Client Protocol for Zed and other ACP clients |
| An agent that improves over time | **Post-turn learning** (default on): memory facts + agent-authored skills |
| Clean local state | Profile-scoped `~/.finclaw/` — config, skills, history, secrets stay isolated |
| Easy install & updates | One-liner install + `finclaw update` from GitHub Releases |

This repository is the **official public home** for the `finclaw` binary: install scripts, user docs, and [GitHub Releases](https://github.com/finogeeks/finclaw-cli/releases).

---

## Highlights

### Peer-to-peer agents (A2A HTTP + peer share)

finclaw treats **multi-agent** as a first-class surface — not a bolt-on webhook.

| Path | When to use | Operator surface |
| --- | --- | --- |
| **HTTP** | Same machine, LAN, or any reachable URL | `finclaw serve` + inbound config; peers in `a2a-agents.yaml` |
| **Peer share** | No public inbound port; hand a peer a ticket | `finclaw share offer` / `redeem` → use `local_a2a_base` like any A2A HTTP peer |

- Inspect peers: `finclaw a2a list|card|probe`
- Steer the model: `/ask` / `/delegate` in chat
- Two-agent lab (Callee + Caller): [`examples/two-agent-a2a/`](examples/two-agent-a2a/)
- Full guide: **[docs/a2a.md](docs/a2a.md)** (including [peer share](docs/a2a.md#share-your-agent-with-a-peer-finclaw-share))

### Terminal-native agent
- One-shot or interactive chat: `finclaw chat` / `finclaw chat -m "…"`
- Optional full-screen TUI: `finclaw chat --tui` (experimental; same agent, ratatui UI)
- Slash commands for session control, model switch, skills, A2A steers, and more
- Optional long-lived daemon: `finclaw serve`

### IDE via ACP (Zed)
Speak [Agent Client Protocol](https://agentclientprotocol.com/) over stdio. Register `finclaw` as a custom agent in Zed — prompts, tool permission UI, cancel, and session reopen with history. See **[docs/acp.md](docs/acp.md)**.

### Self-learning (Hermes-style)
After enough turns, a background review can write **facts to memory** and **procedures as skills**. Default mode is **`promote`** (write-through). Dial it back with `stage` / `observe`, or `finclaw learning disable`. Guide: **[docs/learning.md](docs/learning.md)**.

### Skills & markets
Install packs from hubs and public sources; curate agent-authored skills. Guide: **[docs/skills.md](docs/skills.md)**.

### Profiles & policy
Templates (`general`, `coder`, `researcher`), per-profile policies, identity, and capability. Guides: **[docs/profiles.md](docs/profiles.md)**, **[docs/security-and-policies.md](docs/security-and-policies.md)**.

---

## Quick install

**Platforms:** macOS (arm64 / x86_64), Linux (x86_64 glibc), Windows (x86_64 MSVC archives on Releases). The one-liner installer covers macOS and Linux; on Windows download from Releases or use WSL2.

```bash
curl -fsSL https://raw.githubusercontent.com/finogeeks/finclaw-cli/main/install.sh | sh
```

Put `$HOME/.local/bin` on your `PATH`, then:

```bash
finclaw --version
finclaw share status   # peer share is included in release builds (v0.11+)
```

**Details:** [docs/installation.md](docs/installation.md) (manual download, checksums, `finclaw update`).

---

## First five minutes

```bash
finclaw init          # create ~/.finclaw profile (mock LLM is fine to smoke-test)
finclaw setup         # guided LLM provider / model (or edit config.yaml)
finclaw doctor        # sanity check
finclaw chat          # interactive line-based REPL
finclaw chat --tui    # optional full-screen TUI (experimental)
# or:
finclaw chat -m "Summarize what you can do"
```

### Try agent-to-agent next

**Outbound only (no second finclaw):** run the mock peer, point `a2a-agents.yaml` at it, then `finclaw a2a probe` / `/ask` — see [docs/a2a.md](docs/a2a.md#quick-start-test-a2a-locally-recommended-first-step).

**Two real agents (HTTP, then peer share):**

```bash
cd examples/two-agent-a2a
bash scripts/00-prepare-homes.sh
bash scripts/01-start-callee.sh
bash scripts/02-http-smoke.sh          # A2A over local HTTP
# optional peer share (leave offer/redeem running):
bash scripts/03-p2p-offer.sh
bash scripts/04-p2p-redeem-smoke.sh
```

Learning starts **on** by default (`mode: promote`). Check or change it anytime:

```bash
finclaw learning status
finclaw learning set-mode stage    # review before writes
finclaw learning disable           # turn the loop off
```

---

## Agent-to-agent in one glance

```bash
# HTTP peers — edit under the active profile, then:
finclaw a2a list
finclaw a2a card <peer-id>
finclaw a2a probe <peer-id>

# Peer share — no public inbound port required
finclaw share status
finclaw share doctor --upstream http://127.0.0.1:PORT
# A:  finclaw share offer --upstream http://127.0.0.1:PORT --bearer TOKEN --json
# B:  finclaw share redeem --ticket '…' --json
#     → put local_a2a_base + grant bearer in a2a-agents.yaml (or --write-agents-yaml)
```

In the chat REPL: `/ask <peer> <message>` steers the model toward outbound A2A. Same tools whether the peer URL is LAN HTTP or a share tunnel. Details: [docs/a2a.md](docs/a2a.md), mock peer [`examples/mock-a2a-peer.py`](examples/mock-a2a-peer.py), two-agent lab [`examples/two-agent-a2a/`](examples/two-agent-a2a/).

---

## Use with Zed (ACP)

1. Install `finclaw` so it is on your `PATH` (or note the absolute path).
2. Initialize a profile (once):

   ```bash
   finclaw init --non-interactive
   # or a dedicated home:
   finclaw --finclaw-home "$HOME/.finclaw-zed" init --non-interactive
   finclaw --finclaw-home "$HOME/.finclaw-zed" setup
   ```

3. In Zed, add a **custom external agent**:
   - **Command:** absolute path to `finclaw` (e.g. `/Users/you/.local/bin/finclaw`)
   - **Args:**

     ```text
     --profile default acp
     ```

     With a dedicated home:

     ```text
     --finclaw-home /Users/you/.finclaw-zed --profile default acp
     ```

4. Open an agent thread and send a prompt. Supervised tools use Zed’s permission UI; reopen a thread to resume history via `session/load`.

**Full walkthrough (permissions, cancel, cwd, limits):** [docs/acp.md](docs/acp.md)

> **Note:** FinClaw owns tools via your **profile** (and optional MCP servers you configure for FinClaw). Client-supplied ACP `mcpServers` from the IDE are **rejected** by design — configure tools in FinClaw, not by attaching arbitrary MCP processes per editor session.

---

## Documentation

Everything end users need lives **in this repository**. Index: **[docs/README.md](docs/README.md)**.

| Topic | English | 中文 |
| --- | --- | --- |
| **Index** | [docs/README.md](docs/README.md) | bilingual table |
| Quick start | [getting-started.md](docs/getting-started.md) | [getting-started.zh.md](docs/getting-started.zh.md) |
| Install & updates | [installation.md](docs/installation.md) | [installation.zh.md](docs/installation.zh.md) |
| Configuration | [configuration.md](docs/configuration.md) | [configuration.zh.md](docs/configuration.zh.md) |
| Profiles & backup | [profiles.md](docs/profiles.md) | [profiles.zh.md](docs/profiles.zh.md) |
| Security & policies | [security-and-policies.md](docs/security-and-policies.md) | [security-and-policies.zh.md](docs/security-and-policies.zh.md) |
| Skills | [skills.md](docs/skills.md) | [skills.zh.md](docs/skills.zh.md) |
| Post-turn learning | [learning.md](docs/learning.md) | [learning.zh.md](docs/learning.zh.md) |
| Chat & operations | [chat-and-operations.md](docs/chat-and-operations.md) | [chat-and-operations.zh.md](docs/chat-and-operations.zh.md) |
| **ACP / Zed** | [acp.md](docs/acp.md) | [acp.zh.md](docs/acp.zh.md) |
| **A2A (HTTP + peer share)** | [a2a.md](docs/a2a.md) | [a2a.zh.md](docs/a2a.zh.md) |
| Command index | [reference-commands.md](docs/reference-commands.md) | [reference-commands.zh.md](docs/reference-commands.zh.md) |
| Troubleshooting | [troubleshooting.md](docs/troubleshooting.md) | [troubleshooting.zh.md](docs/troubleshooting.zh.md) |
| Advanced | [advanced.md](docs/advanced.md) | [advanced.zh.md](docs/advanced.zh.md) |

**Flags on your build:** always prefer `finclaw --help` and `finclaw <cmd> --help`. Use `--locale en|zh` when you want help text in a fixed language.

---

## Honest defaults (read this)

- **Execution:** by default the CLI runs **without a built-in OS sandbox** (“naked” host). Policy files (exec / HTTP / tool-invocation) and supervised approvals still apply. See [security-and-policies.md](docs/security-and-policies.md).
- **Peer share:** included in default release builds from **v0.11**. Tickets and grant bearers are secrets; both peers must stay online; after redeem stops, localhost peer URLs go stale.
- **Learning:** default **on** with `promote`. Use `stage` / `observe` / `disable` if you want a slower or quieter loop.
- **ACP:** strong IDE interop; not a claim of full ACP v1 conformance (see [acp.md](docs/acp.md)).

---

## Issues & support

Report bugs with the [issue template](https://github.com/finogeeks/finclaw-cli/issues/new/choose). Include `finclaw version` output and OS.

---

## License

Licensing for **published binaries** is defined on each [GitHub Release](https://github.com/finogeeks/finclaw-cli/releases) and in any `LICENSE` / notice bundled with the archive. This README does not override those terms.

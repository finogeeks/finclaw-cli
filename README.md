<p align="center">
  <img src="assets/finclaw-wordmark.svg" width="560" alt="FINCLAW" />
</p>

# Peer-to-peer. No server needed. Agents on different PCs talk over A2A.

**finclaw** — [![GitHub release](https://img.shields.io/github/v/release/finogeeks/finclaw-cli?label=release&sort=semver)](https://github.com/finogeeks/finclaw-cli/releases)
![Platforms](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey)
![P2P](https://img.shields.io/badge/peer--to--peer-no%20server%20needed-0A7A3E)
![A2A](https://img.shields.io/badge/protocol-A2A-informational)

Run `finclaw` on **your** machine. When a colleague should talk to **that** agent
— not a clone they configure themselves — hand them a short-lived **share
ticket**. They connect **peer-to-peer**; no cloud agent broker and no public URL
you have to host. Under the hood they still speak standard
**[A2A](docs/a2a.md)**. On a LAN you already share, plain HTTP works too.

Also: a fast Rust CLI (~20–30 MB) for terminal chat, **[Zed](https://zed.dev/)**
via **[ACP](https://agentclientprotocol.com/)**, skills, and a Hermes-style
learning loop — no Node or Python to run the tool itself.

| | |
| --- | --- |
| **English** | *You are here* |
| **中文** | [README.zh.md](README.zh.md) |

---

## Why finclaw?

| You want… | finclaw gives you… |
| --- | --- |
| **finclaw on PC A ↔ finclaw on PC B** | **Peer share** — let someone reach the agent on your desktop (live instance), without putting it on a cloud server |
| Same house / same VPN | **A2A over HTTP** — `serve` + peer URL, `/ask` / `/delegate` |
| A serious coding / research agent in the terminal | Interactive REPL, optional full-screen `--tui`, one-shot `chat`, profiles, skills, MCP |
| The same agent inside your editor | **`finclaw acp`** — Agent Client Protocol for Zed and other ACP clients |
| An agent that improves over time | **Post-turn learning** (default on): memory facts + agent-authored skills |
| Clean local state | Profile-scoped `~/.finclaw/` — config, skills, history, secrets stay isolated |
| Easy install & updates | One-liner install + `finclaw update` from GitHub Releases |

This repository is the **official public home** for the `finclaw` binary: install scripts, user docs, and [GitHub Releases](https://github.com/finogeeks/finclaw-cli/releases).

---

## Highlights

### Peer-to-peer agents on different PCs (A2A)

**When would you use this?**

Ask yourself:

- Do you want someone else to talk to **the agent already running on your
  desktop** — with its files, tools, skills, and memory — not a blank copy they
  have to set up from scratch?
- Do you **not** want to put that agent on a cloud or company server — because
  it’s awkward, you don’t know how, you have no server to spare, or you only
  need **ad-hoc** access for a meeting or an afternoon?
- Is “here’s my agent **template** / config” not enough, because what matters is
  the **live instance** that already knows your context?

If those sound familiar, **peer share** (`finclaw share`) is for you: keep the
agent on your PC, hand the other person a short-lived **ticket**, and their
finclaw reaches **your running agent** over a peer-to-peer link. No public URL
you must host. The share can **expire** (or you stop offering) when you’re done —
good for temporary collaboration, not forever-open exposure.

Sharing a recipe for “how to build an agent like mine” is different. Templates
help **reuse setup**. Peer share shares the **working agent** — data, tools, and
skills included — for as long as both sides stay online.

Same protocol (**A2A**) either way: if you’re already on one LAN or VPN with a
known URL, you can skip tickets and use plain HTTP. Peer share is the path when
you don’t have that.

```text
You: keep agent running + share a ticket  ──►  Them: redeem ticket → talk to your agent
```

| Path | When it fits | What you do |
| --- | --- | --- |
| **Peer share** | Different networks, no server you want to run | `share offer` / `redeem`, then chat with `/ask` |
| **HTTP** | Same LAN / VPN / known URL | `serve` + peer URL in config |

- Inspect peers: `finclaw a2a list|card|probe` · chat: `/ask` / `/delegate`
- Plain-language + how-to: **[docs/a2a.md](docs/a2a.md)** · lab: [`examples/two-agent-a2a/`](examples/two-agent-a2a/)

### Terminal-native agent
- One-shot or interactive chat: `finclaw chat` / `finclaw chat -m "…"`
- Optional full-screen TUI: `finclaw chat --tui` (experimental; same agent, ratatui UI)
- Slash commands for session control, model switch, skills, A2A steers, and more
- Optional long-lived daemon: `finclaw serve` (eager) or `finclaw serve --lazy` (supervisor mux)

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

**Platforms:** macOS (arm64 / x86_64), Linux (x86_64 / aarch64 glibc), Windows (x86_64 MSVC archives on Releases). The one-liner installer covers macOS and Linux; on Windows download from Releases or use WSL2.

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

**Situation:** you want another person’s finclaw to reach **your** desktop agent
without hosting it in the cloud. **Peer share** = send a ticket. **Same network
already?** use plain A2A HTTP instead.

```bash
# Peer share (you offer, they redeem) — no public inbound port you must open
finclaw share status
finclaw share doctor --upstream http://127.0.0.1:PORT
# You:  finclaw share offer --upstream http://127.0.0.1:PORT --bearer TOKEN --json
# Them: finclaw share redeem --ticket '…' --json
#       → put local_a2a_base + grant bearer in a2a-agents.yaml (or --write-agents-yaml)

# HTTP peers when you already have a reachable URL
finclaw a2a list
finclaw a2a card <peer-id>
finclaw a2a probe <peer-id>
```

In chat: `/ask <peer> <message>`. Same A2A tools on LAN HTTP or after peer share.
Why this exists and how to set it up in plain language: [docs/a2a.md](docs/a2a.md).
Hands-on: [`examples/two-agent-a2a/`](examples/two-agent-a2a/), mock
[`examples/mock-a2a-peer.py`](examples/mock-a2a-peer.py).

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
| Chat & operations (`serve` / `--lazy`) | [chat-and-operations.md](docs/chat-and-operations.md) | [chat-and-operations.zh.md](docs/chat-and-operations.zh.md) |
| **ACP / Zed** | [acp.md](docs/acp.md) | [acp.zh.md](docs/acp.zh.md) |
| **A2A (HTTP + peer share)** | [a2a.md](docs/a2a.md) | [a2a.zh.md](docs/a2a.zh.md) |
| Command index | [reference-commands.md](docs/reference-commands.md) | [reference-commands.zh.md](docs/reference-commands.zh.md) |
| Troubleshooting | [troubleshooting.md](docs/troubleshooting.md) | [troubleshooting.zh.md](docs/troubleshooting.zh.md) |
| Advanced | [advanced.md](docs/advanced.md) | [advanced.zh.md](docs/advanced.zh.md) |

**Flags on your build:** always prefer `finclaw --help` and `finclaw <cmd> --help`. Use `--locale en|zh` when you want help text in a fixed language.

---

## Honest defaults (read this)

- **Execution:** by default the CLI runs **without a built-in OS sandbox** (“naked” host). Policy files (exec / HTTP / tool-invocation) and supervised approvals still apply. See [security-and-policies.md](docs/security-and-policies.md).
- **Peer share:** included from **v0.11**. Share a **live desktop agent** for a while via a ticket — no cloud host required. Tickets are secrets; both sides stay online; access ends when the share expires or redeem stops.
- **Learning:** default **on** with `promote`. Use `stage` / `observe` / `disable` if you want a slower or quieter loop.
- **ACP:** strong IDE interop; not a claim of full ACP v1 conformance (see [acp.md](docs/acp.md)).

---

## Issues & support

Report bugs with the [issue template](https://github.com/finogeeks/finclaw-cli/issues/new/choose). Include `finclaw version` output and OS.

---

## License

Licensing for **published binaries** is defined on each [GitHub Release](https://github.com/finogeeks/finclaw-cli/releases) and in any `LICENSE` / notice bundled with the archive. This README does not override those terms.

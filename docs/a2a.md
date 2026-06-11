# Agent-to-agent (A2A) with finclaw

**Chinese:** [a2a.zh.md](a2a.zh.md)

This guide explains how **A2A (Agent2Agent)** works in finclaw, how it compares to the **FinSAFE Hermes adapter**, and how behaviour differs when finclaw is the **CLI host** versus when agents run behind **chatkit-middleware**. The hands-on section at the top is written so you can try A2A with only the published `finclaw` binary and Python 3.

Wire-level conventions (method names, error codes, hop headers) follow the public [A2A interop note](https://github.com/Geeksfino/finclaw-contract/blob/main/docs/a2a-interop.md).

---

## Quick start: test A2A locally (recommended first step)

You can verify outbound A2A **without a real LLM** using the read-only CLI and a tiny mock peer.

### Prerequisites

- `finclaw` installed ([installation.md](installation.md))
- `finclaw init` completed at least once
- Python 3.9+ (stdlib only)

### 1. Start a mock A2A peer

From a checkout of this repository (or after downloading `examples/mock-a2a-peer.py`):

```bash
python3 examples/mock-a2a-peer.py
```

The script prints a line like:

```text
LISTENING http://127.0.0.1:54321
```

Keep this terminal open. Copy the base URL (no trailing slash).

### 2. Point your profile at the mock peer

Create the outbound peer registry file (create parent directories if needed):

```text
~/.finclaw/profiles/default/runtime_home/config/a2a-agents.yaml
```

Example (replace the URL with your `LISTENING` line):

```yaml
agents:
  - id: mockpeer
    url: http://127.0.0.1:54321/a2a/v1
    description: local mock A2A peer
    allow_private: true
    policy: allow
```

| Field | Meaning |
| --- | --- |
| `id` | Short name you use in `finclaw a2a` and `/ask` |
| `url` | Peer JSON-RPC endpoint (`…/a2a/v1`) |
| `allow_private: true` | Required for `127.0.0.1` / loopback peers in dev |
| `policy` | `allow` (immediate), `ask` (approval first), or `deny` |

Restart any running `finclaw chat` or `finclaw serve` session so the runtime reloads the file.

### 3. Inspect the peer (no LLM)

```bash
finclaw a2a list
finclaw a2a card mockpeer
finclaw a2a probe mockpeer
```

You should see `mockpeer` listed, an Agent Card with an `echo` skill, and a reachable probe.

### 4. Delegate in chat (requires a real LLM)

Configure a provider ([getting-started.md](getting-started.md)), then either:

**Natural language** — in `finclaw chat`, ask the agent to delegate, for example:

```text
Use the mockpeer A2A agent to echo the phrase hello-a2a and summarise its reply.
```

**Explicit REPL command** — forces a delegation hint the model should follow:

```text
/ask mockpeer echo hello-a2a
```

In verbose REPL output, delegation tool calls appear with a `⇄` prefix (for example `⇄ a2a_send → agent=mockpeer`). A successful mock reply contains the sentinel `A2A-REMOTE-REPLY`.

### 5. Optional: inbound (another agent calls you)

To accept calls **into** your finclaw instance:

1. Create `~/.finclaw/profiles/default/runtime_home/config/a2a-inbound.yaml` (see [Inbound: `a2a-inbound.yaml`](#inbound-a2a-inboundyaml) below).
2. Run `finclaw serve` (pick a port with `--port` if needed).
3. Callers fetch `GET http://<host>:<port>/.well-known/agent-card.json` and `POST /a2a/v1` with `Authorization: Bearer <token>`.

Two finclaw instances can talk to each other: instance A runs inbound `serve`, instance B lists A in `a2a-agents.yaml`.

---

## How A2A works in finclaw

A2A is **agent-to-agent** traffic. It is separate from the Host↔Claw HTTP API your CLI uses internally. Finclaw implements two directions:

| Direction | Config | Who initiates |
| --- | --- | --- |
| **Outbound** | `a2a-agents.yaml` | Your agent calls **remote** peers |
| **Inbound** | `a2a-inbound.yaml` | **Remote** peers call your agent |

If neither file exists (or inbound is disabled), finclaw behaves as if A2A were off: no extra HTTP routes, no delegation tools.

### Protocol surface

- **Discovery:** `GET /.well-known/agent-card.json` — public Agent Card (skills, version, RPC URL).
- **Calls:** `POST <base>/a2a/v1` — JSON-RPC 2.0 (`SendMessage`, streaming variants; legacy `message/send` aliases accepted).
- **Auth:** Bearer token per peer on RPC (card fetch may be public).
- **Loop guard:** `x-a2a-hop-count` — default max depth 2; exceeded calls return `HOP_LIMIT_EXCEEDED`.
- **Tracing:** `x-a2a-trace-id` — correlates audit records across hops.

`contextId` on the wire maps to finclaw `session_id` for multi-turn delegation.

### Outbound: LLM tools

When `a2a-agents.yaml` lists at least one enabled peer, the Claw runtime registers:

| Tool | Purpose |
| --- | --- |
| `a2a_list_agents` | List configured peers and advertised skills |
| `a2a_send` | Send a message to a peer and return its reply |
| `a2a_check_task` | Poll a long-running remote task (when the peer returns a task) |

These tools are included for **`standard`** and **`workspace`** tool bundles (default `general` and `coder` profile templates). They are **not** registered when no peers are configured.

The CLI command `finclaw a2a` is **read-only inspection** (list / card / probe). It does not send chat traffic itself.

### Inbound: HTTP ingress on `finclaw serve`

When `a2a-inbound.yaml` has `enabled: true` and at least one peer with a bearer token, `finclaw serve` exposes:

- `GET /.well-known/agent-card.json`
- `POST /a2a/v1` (authenticated)

Inbound turns run with capability `a2a_inbound`, tenant `a2a-peers`, and synthetic user id `a2a:<peer-id>`. Remote message content is treated as **untrusted** (same posture as MCP tool output).

### CLI-only affordances

| Feature | Role |
| --- | --- |
| `finclaw a2a list\|card\|probe` | Operator/debug: verify config, card, reachability |
| `/ask <peer> <message>` | REPL shortcut: re-issue turn so the model calls `a2a_send` |
| `⇄` in tool render | Visual distinction for delegation vs local tools |

---

## Comparison with the FinSAFE Hermes adapter

Finclaw and the **FinSAFE Hermes adapter** speak the **same A2A wire protocol** and share the same Rust core types (`ai_infra_rs_a2a_core`). They are aimed at different deployment shapes:

| Topic | finclaw CLI | Hermes adapter |
| --- | --- | --- |
| **Primary host** | Desktop / single-user CLI (`finclaw chat`, `finclaw serve`) | Confined Hermes agents behind FinSAFE broker pool |
| **Inbound config** | `a2a-inbound.yaml` | `a2a-inbound.toml` (same semantics, TOML) |
| **Outbound (`a2a_send`)** | Yes — `a2a-agents.yaml` + LLM tools | Inbound-focused; outbound delegation is not the adapter’s main path |
| **Identity on inbound** | Synthetic `a2a:<peer-id>` under tenant `a2a-peers` | Same pattern; routes into broker / claw-api handlers |
| **User UX** | `finclaw a2a`, `/ask`, chat | Operator config + HTTP; no finclaw REPL |
| **Execution** | Naked host by default (optional FinSAFE wrap) | Sandboxed Hermes execution |

**Practical interop:** a finclaw desktop agent can call a Hermes adapter ingress (configure the adapter URL and bearer in `a2a-agents.yaml`). A remote peer can call **your** finclaw inbound URL the same way.

Hermes-style slash-command muscle memory (`/ask`, `/delegate`) exists in finclaw REPL, but implementation goes through Claw’s `a2a_send` tool, not a separate Hermes client.

**OpenClaw note:** chatkit ships an OpenClaw-**style** WebSocket compat gateway for chat; that is **not** the same as this A2A JSON-RPC path. Finclaw A2A aligns with the Hermes adapter and chatkit `a2a-gateway`, not with OpenClaw WebSocket chat.

---

## CLI host vs chatkit-middleware host

The **Claw runtime** implements A2A tools and (optionally) direct inbound ingress. The **host** decides how users authenticate, which tenant/user ids apply, and where the public URL lives.

### finclaw as CLI host (this guide)

| Concern | Where it lives |
| --- | --- |
| Outbound peers | `<profile>/runtime_home/config/a2a-agents.yaml` |
| Inbound peers + card | `<profile>/runtime_home/config/a2a-inbound.yaml` |
| Public URL (inbound) | Your machine + `finclaw serve --port` + `base_url` in inbound config |
| End-user testing | `finclaw a2a`, `finclaw chat`, `/ask` |
| Identity | Single-user profile; inbound uses `a2a-peers` tenant |

Config resolution order for outbound (highest first):

1. `AI_INFRA_RS_A2A_AGENTS_CONFIG_PATH` (explicit file)
2. `$AI_INFRA_RS_HOME/config/a2a-agents.yaml` (default when using finclaw — `runtime_home`)

Inbound uses `AI_INFRA_RS_A2A_INBOUND_CONFIG_PATH` or `$AI_INFRA_RS_HOME/config/a2a-inbound.yaml`.

### chatkit-middleware as host (enterprise)

When agents run in **chatkit-middleware**, the **host layer** changes; Claw may still perform **outbound** `a2a_send` if operators deploy `a2a-agents.yaml` on the Claw service, but **inbound** A2A for external peers is normally **not** mounted on each Claw pod directly.

Instead, chatkit runs a dedicated **`a2a-gateway`** service (default port **26108**):

```text
External A2A peer
    → GET  a2a-gateway/.well-known/agent-card.json
    → POST a2a-gateway/a2a/v1  (Bearer)
        → identity mapping (static peers or JWT validation)
        → orchestrator inbound flow (/flows/inbound/execute/stream)
        → ai-infra-rs Claw agent loop
```

| Concern | chatkit-middleware |
| --- | --- |
| Inbound URL | Gateway public URL (`A2A_GATEWAY_PUBLIC_URL`), not per-user CLI |
| Peer allowlist | `A2A_GATEWAY_PEERS` JSON env (token → `userId`, `tenantId`, `allowedAgents`) |
| Advertised skills | `A2A_GATEWAY_SKILLS` JSON env |
| Identity | Gateway maps bearer → platform principal; callers **cannot** spoof `X-User-ID` |
| Multi-tenant | Per-user / per-tenant cards at gateway level (not one desktop card) |
| finclaw CLI commands | **Not used** by end users; ops configure gateway + Claw service config |

**Outbound from chatkit:** deploy `a2a-agents.yaml` where the Claw process resolves config (`AI_INFRA_RS_HOME` or `AI_INFRA_RS_A2A_AGENTS_CONFIG_PATH`). Users interact via AG-UI / orchestrator; the model may call `a2a_send` when tools are exposed for that capability profile.

**Finclaw → chatkit example (integrator):**

1. Operator configures `A2A_GATEWAY_PEERS` with a token bound to a service user/tenant.
2. On the finclaw machine, add a peer pointing at `https://<gateway-host>:26108/a2a/v1` with the same bearer.
3. In chat, delegate with `/ask <id> …` or natural language.

**chatkit → finclaw example:** run `finclaw serve` with inbound config; register finclaw’s URL and token in the caller’s `a2a-agents.yaml` (or gateway peer list if the caller is another chatkit stack).

---

## Configuration reference

### Outbound: `a2a-agents.yaml`

```yaml
defaults:
  max_hops: 2
  allow_private_network: false
agents:
  - id: legal
    url: https://legal.example.com/a2a/v1
    description: Legal specialist
    auth_token_env: LEGAL_A2A_TOKEN
    policy: allow
    allowed_skills: []
    max_calls: null
    allow_private: false
    enabled: true
```

| `policy` | Behaviour |
| --- | --- |
| `allow` | Delegate immediately |
| `ask` | First `a2a_send` requires approval; approve in the chat approval flow, then retry |
| `deny` | Always refused |

Prefer `auth_token_env` over inline `auth_token`. Store secrets in profile `.env` or the shell.

### Inbound: `a2a-inbound.yaml`

```yaml
enabled: true
base_url: http://127.0.0.1:26500
tenant: a2a-peers
max_hops: 2
card:
  name: my-finclaw
  description: My local A2A endpoint
  skills:
    - id: default
      name: General
      description: General assistant
peers:
  - id: partner-a
    auth_token_env: A2A_INBOUND_PARTNER_A_TOKEN
    allowed_agents: [default]
    allow_default: true
```

Callers must send `Authorization: Bearer <token>` on `POST /a2a/v1`. Optional `skillId` / `agentId` in message metadata must match `allowed_agents`.

### Environment overrides

| Variable | Purpose |
| --- | --- |
| `AI_INFRA_RS_A2A_AGENTS_CONFIG_PATH` | Explicit outbound config file |
| `AI_INFRA_RS_A2A_INBOUND_CONFIG_PATH` | Explicit inbound config file |
| `AI_INFRA_RS_HOME` | Set automatically to `<profile>/runtime_home` by finclaw |

---

## Troubleshooting

| Symptom | Things to check |
| --- | --- |
| `finclaw a2a list` says no config | File path under `runtime_home/config/a2a-agents.yaml`; restart chat/serve |
| `probe` unreachable | URL ends with `/a2a/v1`; peer is up; `allow_private: true` for localhost |
| No `a2a_send` in chat | Peers configured; tool bundle is `standard` or `workspace`; model actually chose the tool |
| `ask` policy stuck | Approve the delegation prompt; second infer should set `pre_approved` |
| Inbound 401 | Bearer matches `auth_token` / env; `enabled: true` on peer |
| Hop limit errors | Chain too deep; raise `max_hops` only if you understand loop risk |

```bash
finclaw doctor
finclaw tools list    # when runtime is up — look for a2a_* tools
finclaw a2a list --json
```

---

## See also

- [chat-and-operations.md](chat-and-operations.md) — REPL, `finclaw serve`, slash commands
- [configuration.md](configuration.md) — profile paths and env
- [reference-commands.md](reference-commands.md) — `finclaw a2a` cheat sheet
- [A2A interop (contract)](https://github.com/Geeksfino/finclaw-contract/blob/main/docs/a2a-interop.md)

# Agent Client Protocol (ACP) with finclaw

**Chinese:** [acp.zh.md](acp.zh.md)

Connect editors such as **[Zed](https://zed.dev/)** to finclaw over the open **[Agent Client Protocol](https://agentclientprotocol.com/)** (ACP). The IDE speaks JSON-RPC on stdio; `finclaw acp` is the agent process.

This is **not** A2A. A2A (`finclaw a2a`) is HTTP agent-to-agent. ACP is client↔agent for IDE hosts.

---

## What you get

| Capability | Status |
| --- | --- |
| `initialize` (ACP v1) | Yes |
| `session/new` | Yes (empty client `mcpServers`) |
| `session/load` | Yes — reopens history for the conversation id |
| `session/list` / `session/close` | Yes |
| `session/prompt` (text, resource links, text resources) | Yes |
| Streamed assistant text + tool call updates | Yes (titles, arg hints, kinds, result previews when available) |
| `session/request_permission` (allow once / reject once) | Yes |
| `session/cancel` | Yes (cooperative abort) |
| Client-supplied `mcpServers` | **Rejected** — configure tools in finclaw, not per editor session |
| Images / audio / binary prompt blobs | Rejected |
| Full ACP v1 conformance certificate | **Not claimed** — Zed-compatible for common chat/edit flows |

Stdout is **protocol-only**. Do not wrap `finclaw acp` in scripts that print banners to stdout.

---

## Prerequisites

1. Install finclaw ([installation.md](installation.md)) so the binary is on your `PATH` (or note its absolute path).
2. Initialize and configure a profile at least once:

   ```bash
   finclaw init --non-interactive
   finclaw setup          # real LLM, or keep mock for smoke tests
   finclaw doctor
   ```

Optional dedicated home (recommended if you want Zed isolated from your daily CLI profile):

```bash
finclaw --finclaw-home "$HOME/.finclaw-zed" init --non-interactive
finclaw --finclaw-home "$HOME/.finclaw-zed" setup
```

---

## Configure Zed

Zed documents custom agents under [External Agents](https://zed.dev/docs/ai/external-agents).

### UI path

1. Open **Agent Settings** (`agent: open settings`).
2. Go to **External Agents** → **Add Agent** → **Add Custom Agent**.
3. Zed opens `settings.json` with an `agent_servers` entry — fill it in as below.

### `settings.json` example

Use the **absolute** path to your binary (Zed should not depend on an interactive shell `PATH`):

```json
{
  "agent_servers": {
    "FinClaw": {
      "type": "custom",
      "command": "/Users/YOU/.local/bin/finclaw",
      "args": ["--profile", "default", "acp"],
      "env": {}
    }
  }
}
```

Dedicated home:

```json
{
  "agent_servers": {
    "FinClaw": {
      "type": "custom",
      "command": "/Users/YOU/.local/bin/finclaw",
      "args": [
        "--finclaw-home",
        "/Users/YOU/.finclaw-zed",
        "--profile",
        "default",
        "acp"
      ],
      "env": {}
    }
  }
}
```

Find the path with `which finclaw` (macOS/Linux) or the folder you extracted from [Releases](https://github.com/finogeeks/finclaw-cli/releases).

### Use it

1. Open the Agent panel (`cmd-?` / `ctrl-?`).
2. Create a new thread and select **FinClaw** (or the name you chose).
3. Send a prompt. Supervised tools open Zed’s permission UI — allow once / reject once.
4. Reopen a prior FinClaw thread to resume history (`session/load`).

---

## CLI reference

```bash
finclaw [--profile <name>] [--finclaw-home <dir>] [--config <path>] acp \
  [--agent <id>] [--user <id>] [--capability <name>] \
  [--embedded | --daemon]
```

| Flag | Meaning |
| --- | --- |
| `--agent` | Agent id (default `default`) |
| `--user` | Attribution user id (same semantics as `finclaw chat`) |
| `--capability` | Override loop capability for this connection (`general`, `coding`, `read_only`, …) |
| `--embedded` | Force in-process Claw (do not prefer a running `serve` daemon) |
| `--daemon` | Require daemon dispatch; fail if none |

There is **no** tool auto-approval flag on ACP: supervised tools always go through the client permission UI.

Always confirm flags with:

```bash
finclaw acp --help
```

---

## Working directory (`cwd`)

ACP `session/new` and `session/load` require an **absolute existing directory**. FinClaw uses it as the tools-visible launch cwd. Relative or non-directory paths are rejected.

`cwd` does **not** bypass policy: exec / HTTP / tool-invocation rules on the profile still apply. See [security-and-policies.md](security-and-policies.md).

---

## Approvals and cancel

- When the runtime requires approval, finclaw emits `session/request_permission`. Prefer **allow once** / **reject once** in Zed.
- Cancel an in-flight turn from the IDE; finclaw cooperatively aborts (typically within a few seconds).
- Failed / cancelled permission transport **never** auto-approves.

---

## Why client MCP is rejected

ACP allows clients to attach stdio MCP servers per session. FinClaw’s tools and policies are owned by the **profile**. Attaching arbitrary editor-forwarded MCP processes would bypass that ownership. Configure MCP and other tools through finclaw profile tooling instead ([advanced.md](advanced.md), [skills.md](skills.md)).

---

## Smoke checklist

- [ ] Short text prompt → streamed reply in Zed
- [ ] Supervised tool (e.g. `exec` / write) → permission UI → allow once
- [ ] Cancel mid-turn → turn stops
- [ ] Second prompt in the same session works
- [ ] Reopen the thread → prior messages appear; follow-ups continue the same conversation

If reopen is empty or load fails, start a **new** thread and [file an issue](https://github.com/finogeeks/finclaw-cli/issues/new/choose) with `finclaw version` and OS.

---

## Troubleshooting

| Symptom | What to try |
| --- | --- |
| Agent never starts | Absolute `command` path; args end with `acp`; run the same argv in a terminal |
| Protocol / JSON errors | Ensure nothing prints to stdout before ACP frames; avoid wrapper scripts |
| No tools / wrong tools | Fix profile policies and MCP in finclaw — not Zed MCP for this agent |
| Empty history on reopen | Confirm `session/load` path; try a new thread; collect logs via `finclaw logs` |
| LLM errors | Run `finclaw doctor` and `finclaw chat -m "ping"` with the same `--finclaw-home` / `--profile` |

More: [troubleshooting.md](troubleshooting.md).

---

## Related

- [a2a.md](a2a.md) — agent-to-agent (different protocol)
- [learning.md](learning.md) — post-turn memory / skills (also applies under ACP sessions using the same profile)
- [chat-and-operations.md](chat-and-operations.md) — terminal chat / daemon
- [Zed External Agents](https://zed.dev/docs/ai/external-agents)
- [Agent Client Protocol](https://agentclientprotocol.com/)

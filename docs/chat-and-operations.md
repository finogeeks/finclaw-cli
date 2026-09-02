# Chat, REPL, daemon, logs, and day-two operations

**Chinese:** [chat-and-operations.zh.md](chat-and-operations.zh.md)

## Chat modes

| Mode | Command | Notes |
| --- | --- | --- |
| Interactive REPL | `finclaw chat` | Multiline input and slash commands when stdin is a TTY |
| One-shot (script/CI) | `finclaw chat -m "..."` | Exits after the assistant reply |
| Experimental TUI | `finclaw chat --tui` | Full-screen ratatui REPL (wordmark, scrollback, `/` menu). Requires a TTY; ignored with `-m`. Same Claw/dispatch path as line chat. |

**TUI caveats:** supervised tools that need an interactive approval prompt may **auto-reject** under `--tui` (raw mode cannot safely share stdin with line prompts). For approval-heavy workflows, use line-based `finclaw chat` or ACP in the IDE — see [security-and-policies.md](security-and-policies.md). Run `finclaw chat --help` for the flag text on your build.

### Dispatch: embedded vs daemon

By default the CLI may **prefer a running `finclaw serve` daemon** when one is available, or fall back to an embedded path. For explicit control (when your build supports these flags):

- `finclaw chat --embedded` — do not use the long-lived daemon
- `finclaw chat --daemon` — require daemon dispatch; fail if not running

If a **lazy supervisor** (`finclaw serve --lazy`) is already up, `--daemon` talks to that mux (starts or reuses a profile worker) instead of requiring an eager `serve` for the same profile. Use `finclaw chat --help` for the exact behaviour of your version.

### Streaming and session hints

Token streaming to the terminal is on by default; `--no-stream` prints only the final message.

Optional per-invocation knobs (see `finclaw chat --help`):

- `--user <id>` or `FINCLAW_USER_ID` — stable attribution for scripts and tests.
- `--auto-approve-all-tools` — force auto-approve for guarded tools **for this chat** (mutually exclusive with `--confirm-all-tools`). Use only when policy and environment already match your threat model ([security-and-policies.md](security-and-policies.md)).
- `--confirm-all-tools` — force confirmation prompts for guarded tools **for this chat**.

### Capability override for one call

```bash
finclaw chat --capability read_only -m "Explain this repository layout."
```

### Host posture and policy

Published binaries run as a **naked** host process by default. Tighten what the agent may do with profile **policies** and supervised approvals — see [security-and-policies.md](security-and-policies.md). For IDE permission UI, use [acp.md](acp.md).

## Long-lived daemon

**As of v0.12.8**, `finclaw serve` without extra flags still boots the **active profile** (eager mode). Claw and the host shim listen as soon as the process is up.

```bash
finclaw serve
```

Foreground is the default; `--background` (Unix) detaches. See `finclaw serve --help`. Pair with your OS service manager or `finclaw service` (if present) for boot-time start.

### Supervisor mux

`finclaw serve --lazy` starts a **profile-less supervisor** instead of booting Claw. It claims the home slot (`$FINCLAW_HOME/run/daemon.json` with `mode: lazy`, plus `$FINCLAW_HOME/run/finclaw.pid`). One home can run either a lazy mux **or** an eager profile daemon, not both.

Workers start on demand:

```bash
finclaw serve --lazy
# another terminal:
finclaw --profile default chat --daemon -m "Hello"
```

`chat --daemon` (with `--profile` or the active profile) asks the mux to start or reuse `finclaw --profile <name> serve`. Infer runs on that worker. The mux itself does not answer chat (`POST /ai/infer` on the mux port returns 409). Hosts that speak HTTP can `POST /threads` with a JSON body containing `profile` on the mux listen port; the response includes the worker’s `claw_port`.

When `daemon.json` is `mode: lazy`, `finclaw stop` signals the mux (which stops its workers) even if a worker wrote a profile pidfile. `finclaw status` reports the mux when the profile daemon is absent (`mode: lazy`, and a worker count when available).

Confirm flags on your binary: `finclaw serve --help`.

## Status and stop

```bash
finclaw status
finclaw stop
```

With a lazy mux, `stop` prefers the home pidfile so you shut down the supervisor (and its workers), not a single worker. See [troubleshooting.md](troubleshooting.md) if lazy boot fails because an eager daemon already holds the home.

## Diagnostics (run ledger)

```bash
finclaw diagnose last
```

## Logs

```bash
finclaw logs --help
```

Service selection (CLI, Claw, shim) depends on the build.

## Model picker

```bash
finclaw model
finclaw model <model-id>
```

With a TTY and no model id, the interactive flow uses the **same numbered catalog picker** as `finclaw setup` (provider-scoped entries from the bundled list). You need `llm.provider` in your profile config or `--provider …` on the command line; if neither is set, run `finclaw setup` first. Non-interactive use (no TTY) or a concrete `<model-id>` sets the value directly.

Print the bundled catalogue **without changing config**:

```bash
finclaw model --list
finclaw model --list --json
```

## History

Beyond `list` / `show` / `search`, recent builds expose session pickup, housekeeping, and stats:

```bash
finclaw history resume          # picker or `--session …`
finclaw history prune --dry-run
finclaw history stats --json
```

See `finclaw history --help` for `--user`, limits, `prune`, and confirmations.

## Cron and auth (operator)

```bash
finclaw cron --help
finclaw auth --help
```

## Conformance and tools inspection

- `finclaw tools` — list tools the runtime registers (see `--help`)
- `finclaw conformance` — contract harness; mostly for integrators (see `--help`)

## REPL slash commands

Inside `finclaw chat`, type `/help` for the list supported by **your** binary. Common families include history, session, policy, profile, and skills shortcuts—see [security-and-policies.md](security-and-policies.md) and [profiles.md](profiles.md).

**A2A delegation:** `/ask <peer> <message>` (alias `/delegate`) asks the agent to call the `a2a_send` tool for a peer listed in `a2a-agents.yaml`. Inspect peers with `finclaw a2a list|card|probe`. Full walkthrough: [a2a.md](a2a.md).

## Post-turn learning

Learning is **on by default** (`mode: promote`). Normal `finclaw chat` turns may trigger background reviews that persist memory or agent-authored skills. Toggle with `finclaw learning disable` / `set-mode stage`. Use new `--session` ids to test cross-session recall. Operator commands: `finclaw learning status`, `enable`, `disable`, `promote`, `reject`.

Full guide: [learning.md](learning.md).

## See also

- [getting-started.md](getting-started.md) — first run
- [configuration.md](configuration.md) — LLM config
- [learning.md](learning.md) — self-evolution / learning loop
- [a2a.md](a2a.md) — agent-to-agent (local testing, inbound `serve`)
- [advanced.md](advanced.md) — shell completions, man page, optional `mcp` feature

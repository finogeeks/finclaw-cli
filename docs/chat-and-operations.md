# Chat, REPL, daemon, logs, and day-two operations

**Chinese:** [chat-and-operations.zh.md](chat-and-operations.zh.md)

## Chat modes

| Mode | Command | Notes |
| --- | --- | --- |
| Interactive REPL | `finclaw chat` | Multiline input and slash commands when stdin is a TTY |
| One-shot (script/CI) | `finclaw chat -m "..."` | Exits after the assistant reply |
| Experimental TUI | `finclaw chat --tui` | Full-screen TUI; see `--help` |

### Dispatch: embedded vs daemon

By default the CLI may **prefer a running `finclaw serve` daemon** when one is available, or fall back to an embedded path. For explicit control (when your build supports these flags):

- `finclaw chat --embedded` — do not use the long-lived daemon
- `finclaw chat --daemon` — require daemon dispatch; fail if not running

Use `finclaw chat --help` for the exact behaviour of your version.

### Streaming

Token streaming to the terminal is typically on by default; `--no-stream` (or the equivalent in `--help`) prints only the final message.

### Capability override for one call

```bash
finclaw chat --capability read_only -m "Explain this repository layout."
```

## Long-lived daemon

```bash
finclaw serve
```

Commonly runs Claw and the host shim in the foreground; `--background` or related flags may detach—see `finclaw serve --help`. Pair with your OS service manager or `finclaw service` (if present) for boot-time start.

## Status and stop

```bash
finclaw status
finclaw stop
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

Interactive mode lists the bundled model catalogue; non-interactive use passes an id directly.

## History

```bash
finclaw history --help
```

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

## See also

- [getting-started.md](getting-started.md) — first run
- [configuration.md](configuration.md) — LLM config
- [advanced.md](advanced.md) — shell completions, man page, optional `mcp` feature

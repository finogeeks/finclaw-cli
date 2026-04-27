# Command index (cheat sheet)

**Chinese:** [reference-commands.zh.md](reference-commands.zh.md)

This is a **road map**, not a full flag list. Always run `finclaw --help` and `finclaw <subcommand> --help` for your installed version.

| Goal | Start here |
| --- | --- |
| Version / build / contract info | `finclaw version` |
| Health, config, sandbox hints | `finclaw doctor` |
| Host execution sandbox (global) | `finclaw --security <isolated\|restricted\|yolo> …` — see [security-and-policies.md](security-and-policies.md) |
| Chat (REPL or one-shot) | `finclaw chat` · `finclaw chat -m "…"` |
| Long-lived process | `finclaw serve` |
| Runtime status / stop | `finclaw status` · `finclaw stop` |
| Read/write `config.yaml` | `finclaw config` |
| Guided LLM setup | `finclaw setup` |
| Conversation history | `finclaw history` |
| Shell completion script | `finclaw completion` |
| Tokens / LLM host credentials / cron auth | `finclaw auth` |
| Scheduled jobs | `finclaw cron` |
| Skills (hubs, ClawHub, install) | `finclaw skills` |
| Tool registry listing | `finclaw tools` |
| Contract conformance run | `finclaw conformance` |
| Wipe local profile state (careful) | `finclaw reset` |
| Man page (roff toolchain) | `finclaw man` |
| systemd / launchd unit helper | `finclaw service` |
| MCP stdio (optional build feature) | `finclaw mcp` |
| Model id (picker matches `finclaw setup` when interactive) / set | `finclaw model` |
| Log tailing | `finclaw logs` |
| Profiles (list, create, apply, …) | `finclaw profile` |
| Policy files and admin sync | `finclaw policy` |
| Persona (IDENTITY) | `finclaw identity` |
| Loop capability | `finclaw capability` |
| Backup / import archives | `finclaw backup` · `finclaw import` |
| Update channel / URL guidance | `finclaw update` |
| Uninstall | `finclaw uninstall` |
| First-time profile bootstrap | `finclaw init` |

**Topic guides in this repository:**

- [getting-started.md](getting-started.md)
- [installation.md](installation.md)
- [configuration.md](configuration.md)
- [profiles.md](profiles.md)
- [security-and-policies.md](security-and-policies.md)
- [skills.md](skills.md)
- [chat-and-operations.md](chat-and-operations.md)
- [troubleshooting.md](troubleshooting.md)
- [advanced.md](advanced.md)

**Public wire reference:** [finclaw-contract](https://github.com/Geeksfino/finclaw-contract)

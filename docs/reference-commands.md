# Command index (cheat sheet)

**Chinese:** [reference-commands.zh.md](reference-commands.zh.md)

This is a **road map**, not a full flag list. Always run `finclaw --help` and `finclaw <subcommand> --help` for your installed version.

| Goal | Start here |
| --- | --- |
| Version / build / contract info | `finclaw version` |
| Health, config, sandbox hints | `finclaw doctor` (`--fix` can materialize safe missing files — see `--help`) |
| Run ledger peek (latest chat) | `finclaw diagnose last` |
| Help / completions language | `finclaw --locale <auto\|en\|zh>` (also affects shared CLI messages) |
| Explicit config file | `finclaw --config <path>` · env `FINCLAW_CONFIG` |
| User-data root | `finclaw --finclaw-home <dir>` · env `FINCLAW_HOME` |
| Chat (REPL or one-shot) | `finclaw chat` · `finclaw chat -m "…"` |
| **ACP / IDE (e.g. Zed)** | `finclaw acp` — see [acp.md](acp.md) |
| Long-lived process | `finclaw serve` |
| Runtime status / stop | `finclaw status` · `finclaw stop` |
| Read/write `config.yaml` | `finclaw config` (includes `check`, `migrate`, `env-path` — see `--help`) |
| Guided onboarding | `finclaw setup` · `finclaw setup agent-profile` (profile scaffold) · `finclaw setup llm` |
| Conversation history | `finclaw history` (`list`, `show`, `search`, `resume`, `prune`, `stats`) |
| Shell completion script | `finclaw completion` |
| Tokens / LLM host credentials / cron auth | `finclaw auth` |
| Scheduled jobs | `finclaw cron` |
| Skills (hubs, ClawHub, install) | `finclaw skills` |
| Post-turn learning (memory/skills review) | `finclaw learning` — see [learning.md](learning.md) |
| Tool registry listing | `finclaw tools` |
| Contract conformance run | `finclaw conformance` |
| Wipe local profile state (careful) | `finclaw reset` |
| Man page (roff toolchain) | `finclaw man` |
| systemd / launchd unit helper | `finclaw service` |
| MCP stdio (optional build feature) | `finclaw mcp` |
| A2A peers (list / card / probe) | `finclaw a2a` — see [a2a.md](a2a.md) |
| Model id (picker matches `finclaw setup` when interactive) / catalogue | `finclaw model` · `finclaw model --list` (`--json`) |
| Log tailing | `finclaw logs` |
| Profiles (list, create, apply, …) | `finclaw profile` |
| Policy files and admin sync | `finclaw policy` |
| Persona (IDENTITY envelope) | `finclaw identity` (`show` / `render` / `reset`) |
| Edit agent Markdown (IDENTITY / SOUL / AGENT / TOOLS) | `finclaw agent edit <identity\|soul\|agent\|tools>` |
| Loop capability | `finclaw capability` |
| Backup / import archives | `finclaw backup` · `finclaw import` |
| Update channel / URL guidance | `finclaw update` |
| Uninstall | `finclaw uninstall` |
| First-time profile bootstrap | `finclaw init` |

**Global options (all subcommands):** `--finclaw-home`, `--profile`, `-v`/`--verbose`, `-q`/`--quiet`, `--config`, `--locale` — see `finclaw --help`.

**Topic guides in this repository:**

- [getting-started.md](getting-started.md)
- [installation.md](installation.md)
- [configuration.md](configuration.md)
- [profiles.md](profiles.md)
- [security-and-policies.md](security-and-policies.md)
- [skills.md](skills.md)
- [learning.md](learning.md)
- [chat-and-operations.md](chat-and-operations.md)
- [acp.md](acp.md)
- [a2a.md](a2a.md)
- [troubleshooting.md](troubleshooting.md)
- [advanced.md](advanced.md)

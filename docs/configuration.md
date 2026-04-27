# Configuration

**Chinese:** [configuration.zh.md](configuration.zh.md)

## Data root and profiles

| Location | Role |
| --- | --- |
| `~/.finclaw` or `$FINCLAW_HOME` | Default user data root |
| `~/.finclaw/profiles/<name>/` | Per-profile directory (config, skills, policies, data) |
| `--profile <name>` or `FINCLAW_PROFILE` | Select which profile to use (default profile name is `default`) |

To switch the active profile for later commands without passing `--profile` every time:

```bash
finclaw profile use <name>
```

This records the choice under the finclaw home (for example `active-profile`).

## Global flag: host sandbox (`--security`)

`--security <isolated|restricted|yolo>` is a **global** flag (place it before or after the subcommand; it applies to the whole process). It is **not** stored in `config.yaml`. It sets `AI_INFRA_RS_*` variables for local tool/exec isolation before the runtime starts. This is separate from policy YAML under `policies/` — see [security-and-policies.md](security-and-policies.md) (section *Host execution sandbox*).

## Host config file

The main YAML file for LLM provider, keys, and host toggles lives under the **active profile**:

```bash
finclaw config path
```

Use `finclaw config set`, `finclaw config show`, and `finclaw config check` to inspect and change values. For a list of keys, use `finclaw config --help` and subcommand help on your build.

## Environment variables (LLM)

Common mappings (exact set can vary by release; prefer `finclaw config --help` and `config check`):

| Variable | Typically maps to |
| --- | --- |
| `FINCLAW_LLM_PROVIDER` or `LLM_PROVIDER` | `llm.provider` |
| `FINCLAW_LLM_MODEL` or `LLM_MODEL` | `llm.model` |
| `FINCLAW_LLM_BASE_URL` or `LLM_BASE_URL` | `llm.base_url` |
| `FINCLAW_LLM_API_KEY` | `llm.api_key` |
| `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `DEEPSEEK_API_KEY`, `LLM_API_KEY` | may supply `llm.api_key` when the finclaw-specific key is unset |

**Precedence (highest first):** process environment → `.env` files (see below) → `config.yaml` → built-in defaults.

## `.env` file loading (layered)

Order is typically:

1. **Current working directory:** `./.env` (only if that directory is your shell’s cwd when you start `finclaw`)
2. **Profile root:** `<profile_root>/.env`
3. **Finclaw home:** `~/.finclaw/.env` (or `$FINCLAW_HOME/.env`)

For API keys that must load **regardless of** which directory you run from, prefer `~/.finclaw/.env` or the profile’s `.env`, not only a project-local file.

## Validation

```bash
finclaw config check
finclaw doctor
```

## Wire contract

For HTTP/API contract details, the public [finclaw-contract](https://github.com/Geeksfino/finclaw-contract) repository is the reference. CLI flags remain authoritative for what **your** binary supports.

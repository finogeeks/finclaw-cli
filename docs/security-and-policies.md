# Security: policies, presets, identity, and capability

**Chinese:** [security-and-policies.zh.md](security-and-policies.zh.md)

This page describes **how to configure** what the agent is allowed to do: OS command execution (exec), outbound HTTP allowlists, per-tool invocation rules, LLM defaults, persona (identity), and the **capability** (agent loop mode). Apply changes with `finclaw policy …` and `finclaw profile apply` as described below.

**Authoritative for flags:** `finclaw policy --help`, `finclaw identity --help`, `finclaw capability --help`.

## Policy kinds (on disk)

Under `<profile_root>/policies/`, four policy **kinds** are used (file names are conventional):

| Kind | File name (typical) | What it controls |
| --- | --- | --- |
| tool-invocation | `tool-invocation-policy.yaml` | Auto-approve vs ask vs deny per tool |
| exec | `exec-policy.yaml` | Whether exec is enabled, allowlist/blocklist, sandbox, network |
| http-allowlist | `http-allowlist.yaml` | Allowed outbound domains and browser SSRF posture |
| llm-defaults | `llm-defaults.yaml` | Default temperature, max tokens, thinking flags |

You can also point to explicit paths from `profile.yaml` under a `policies:` key; your `finclaw profile show --resolved` output reflects the resolved layout.

## Choosing presets in `profile.yaml`

Instead of hand-writing all YAML, set **presets** (snake_case) under `presets:`:

```yaml
presets:
  exec: local_power_user
  http: api_curated
  tool: ask_for_writes
```

**There is no dedicated `finclaw preset set` command** — edit `profile.yaml` with `finclaw profile edit` or an editor, then run `finclaw profile apply`.

### Resolution order (simplified)

For each policy **kind**, the effective body is typically resolved as:

1. Explicit file path in `profile.yaml` for that kind (if set), or
2. The file `<profile_root>/policies/<kind>.yaml` if it exists, or
3. The **preset** from `profile.yaml` for that kind (expanded at apply time), or
4. **Skip** (no override file and no preset) — the runtime’s baseline continues to apply.

A hand-edited `policies/*.yaml` **wins** over a preset for that kind. Presets are often materialised to disk **only when** the policy file is missing; behaviour is summarized when you run `finclaw policy show <kind> --resolved`.

## Preset catalogues (v1, typical)

Values below are **policy intent**; always confirm with `finclaw policy show exec --resolved` on your build.

### Exec presets (`presets.exec`)

| Name | Summary |
| --- | --- |
| `read_only_safe` | Exec effectively off; blocklist `*`; no network/process as exposed by policy |
| `workspace_dev` | Exec on; allowlist includes common dev tools (**includes `curl`**, not `ls`); sandbox on; network on |
| `local_power_user` | Exec on; wider allowlist including **`ls`**, `cat`, `git`, `curl`, `make`, `just`, language runtimes, etc.; sandbox on; network and process as per policy |
| `full_admin` | Most permissive exec preset; **strong warnings** at apply time — use only when you understand the risk |

### HTTP presets (`presets.http`)

| Name | Summary |
| --- | --- |
| `lan_only` | Local/private address patterns; strict browser SSRF policy |
| `api_curated` | Small set of common API / Git / vendor hosts; strict browser SSRF policy |
| `open_internet` | Broad outbound allow; **strong warnings** at apply time |

### Tool presets (`presets.tool`)

| Name | Summary |
| --- | --- |
| `auto_all` | High automation for tool use |
| `ask_for_writes` | More confirmation on writes, edits, exec, browser tools |
| `deny_all` | Deny-style posture for tools (see resolved YAML) |

`llm-defaults` may not use the same `presets.*` short form on all versions — if absent, set `policies/llm-defaults.yaml` or use `finclaw policy edit llm-defaults`.

## `finclaw policy` commands

```bash
# On-disk (or resolved from preset) vs live runtime
finclaw policy show exec --source file
finclaw policy show exec --resolved
finclaw policy show exec --source live

# Edit YAML in $EDITOR (scaffold from preset when the file is missing)
finclaw policy edit exec

# Push policies to the running runtime (or embedded path per build)
finclaw policy apply exec
finclaw policy apply

# Compare file vs live
finclaw policy diff exec
finclaw policy diff --check

# Remove on-disk file so preset/baseline can apply on next apply
finclaw policy reset exec
```

`policy show` and `policy edit` use policy kind names such as: `tool-invocation`, `exec`, `http-allowlist`, `llm-defaults` (see `--help`).

**Note:** A `policy set key=value` style subcommand is **not** a substitute for editing YAML in many builds. Prefer `finclaw policy edit <kind>` and `finclaw policy apply <kind>`.

## `identity` and `capability`

- **Identity** — `IDENTITY.md` and rendering to the runtime AIEOS file: `finclaw identity` (`show`, `edit`, `render`, `reset`). Multiple sources can exist; **precedence** is complex—after edits, run `finclaw identity render` and `finclaw profile apply` if chat does not reflect changes.
- **Capability** — which agent **loop** profile is used: `finclaw capability set`, `finclaw capability show`, `finclaw capability list`. A one-shot chat can pass `--capability` without changing the file.

## REPL

Inside `finclaw chat`, use `/policy`, `/identity`, and `/capability` for session-oriented shortcuts; `/policy reload` re-applies from disk in supported builds. Type `/help` in the REPL for the list on your version.

## Doctor and drift

```bash
finclaw doctor
finclaw doctor --fix
```

`doctor` can report policy drift (on-disk file vs what the runtime holds). If drift appears after out-of-band changes, re-run `finclaw policy apply` or align files with `finclaw policy show <kind> --source live`.

## See also

- [profiles.md](profiles.md) — `profile apply`, backup/import
- [configuration.md](configuration.md) — `config.yaml` and env
- [finclaw-contract](https://github.com/Geeksfino/finclaw-contract) — public wire contract (not a full policy schema dump)

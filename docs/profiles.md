# Profiles, templates, backup and import

**Chinese:** [profiles.zh.md](profiles.zh.md)

A **profile** is an isolated directory under your finclaw home that holds configuration, persona files, policies, skills, and (private) state such as conversation data.

Default layout (illustrative):

```text
~/.finclaw/
├── active-profile              # optional; written by `profile use`
└── profiles/
    └── <name>/
        ├── profile.yaml        # agent template (capability, tools, presets, …)
        ├── IDENTITY.md         # persona source (optional; see security doc)
        ├── policies/           # policy overrides (optional)
        ├── skills/             # profile-local skill packs
        ├── mcp-servers.yaml    # optional MCP config
        ├── config.yaml         # host config (LLM, keys, toggles)
        ├── data/               # local state — not for sharing
        ├── secrets/            # credentials — not for sharing by default
        └── …
```

**Legacy paths:** older releases may have used XDG-style locations on some OSes. Run `finclaw doctor` to see hints if data was left behind after migration.

## First-time setup: `init`

```bash
finclaw init
```

With a TTY, you can pick a template interactively. Non-interactive examples:

```bash
finclaw init --template coder --non-interactive
finclaw init --no-template
```

Templates are bundled in the binary (no extra download). Typical built-in template **names** include `general`, `coder`, and `researcher` — run `finclaw profile templates` to list them on your version.

| Template (typical) | Capability (typical) | Tool bundle (typical) | Notes |
| --- | --- | --- | --- |
| `general` | `general` | `standard` | General assistant, conservative writes |
| `coder` | `coding` | `full` | Coding-oriented; dev tools and web |
| `researcher` | `general` | `basic` | Read-oriented; lean tool set |

`init` writes `profile.yaml` and a starter `IDENTITY.md` into the active profile, creates an empty `policies/` directory, and **does not** overwrite an existing `profile.yaml` unless you pass `--force` (see `finclaw init --help`).

## Create and list profiles

```bash
finclaw profile templates
finclaw profile list
finclaw profile list --json
```

Create a new profile from a template:

```bash
finclaw profile create mydev --from-template coder --activate
```

Optional knobs at create time (see `finclaw profile create --help`):

- `--capability` — `general`, `coding`, or `read_only`
- `--tool-bundle` — `basic`, `standard`, `workspace`, or `full`
- `--identity <path>` — seed `IDENTITY.md` from a file
- `--activate` — same as running `finclaw profile use <name>` after create

## Clone a profile

To copy **shareable** artefacts from an existing profile without copying conversation history or keys:

```bash
finclaw profile clone <from> <to>
```

This is a convenience over `profile create --clone-from`. Copied items are those considered part of the portable profile (such as `profile.yaml`, `IDENTITY.md`, `mcp-servers.yaml`, `skills/`, `policies/`). It does **not** copy `data/`, default `config.yaml`, or `secrets/` — see `finclaw profile clone --help`.

## Capability (loop mode)

```bash
finclaw capability list
finclaw capability show
finclaw capability set coding
```

One-shot override without editing files:

```bash
finclaw chat --capability read_only -m "Summarize this file."
```

## Identity (persona)

```bash
finclaw identity show
finclaw identity edit
finclaw identity render
finclaw identity reset
```

See [security-and-policies.md](security-and-policies.md) for how identity relates to policy and runtime.

## Validate and inspect

```bash
finclaw profile validate
finclaw profile validate --strict
finclaw profile show --resolved
finclaw profile active --json
```

## Apply changes to a running runtime

After editing `profile.yaml`, `policies/*.yaml`, or `IDENTITY.md`:

```bash
finclaw profile apply
finclaw profile apply --dry-run
```

If no daemon is running, your build may still complete apply by starting an embedded supervisor for the duration—read the command output.

## Shareable backup and import

### Producer: profile-only archive

```bash
finclaw backup --profile-only --out my-profile.tar.zst --profile <name>
```

This is meant to share **configuration and portable files** without history or provider secrets. It is mutually exclusive with flags that pull in secrets or volatile runtime dirs; see `finclaw backup --help`.

### Consumer: import profile-only

```bash
finclaw import my-profile.tar.zst --profile-only --name <newname>
```

`--profile-only` refuses full backups that were not created as profile-only, so you do not silently drop data by mistake.

### Full backup

For a full machine-local restore (including more state), use `finclaw backup` / `finclaw import` without `--profile-only`, with options documented in `--help`.

## REPL shortcuts

Inside `finclaw chat`, slash commands such as `/profile` mirror read-only views of profile-related state. See [chat-and-operations.md](chat-and-operations.md).

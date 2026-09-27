# Command hooks and official recipes

**Chinese:** [hooks.zh.md](hooks.zh.md)

Command hooks are **opt-in** shell commands FinClaw can run at lifecycle
events (for example `PreToolUse`). They are **not** installed by
`finclaw update` and they are **not** on by default.

**Authoritative flags:** `finclaw hooks --help` on your installed build.
If your binary has no `hooks` subcommand, upgrade before following this
page.

## What you install

Official **hook recipes** are versioned packs on this repository’s
rolling GitHub Release tag `hooks`. Git sources live in
[`hooks/recipes/`](../hooks/recipes/). The catalog may be empty.

The first reserved official recipe id is **`tool-gate`** (a PreToolUse
gate for mutating tools). It is not published until its own recipe
lands. Recipes are ordinary scripts. They do not require a particular
judgment engine.

## Recipient flow

```bash
finclaw hooks catalog
finclaw hooks install tool-gate     # only once that recipe exists
finclaw hooks list
finclaw hooks trust --recipe tool-gate
finclaw hooks remove tool-gate
```

`install` writes files into the **active profile**
(`<profile>/hooks/<id>/` plus entries in `<profile>/hooks.json`).
It never writes `$FINCLAW_HOME/hooks-trust.json`. Nothing is spawned
until you trust the hashes.

`finclaw update` only replaces the CLI binary. It does not read
`hooks-index.json`.

## Default catalog URL

```text
https://github.com/finogeeks/finclaw-cli/releases/download/hooks/hooks-index.json
```

Override in the active profile `config.yaml`:

```yaml
extra:
  hooks:
    index_url: "https://github.com/finogeeks/finclaw-cli/releases/download/hooks/hooks-index.json"
```

## Trust

Interactive `finclaw chat` prompts when a handler is untrusted or its
hash changed. Non-interactive chat and daemons skip untrusted handlers.

Revoke with `finclaw hooks revoke` (handler id or `--recipe <id>`).

## Not skills and not MCP

Skills stay `finclaw skills`. MCP servers stay `finclaw mcp add`.
A recipe must not bundle those.

## Related

- [security-and-policies.md](security-and-policies.md) — exec / HTTP / tool-invocation policies (separate from hooks)
- [skills.md](skills.md) — skill hubs
- [reference-commands.md](reference-commands.md) — command index

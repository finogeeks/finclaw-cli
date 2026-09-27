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
[`hooks/recipes/`](../hooks/recipes/).

The published catalog includes three official recipes:

| Id | Event | Summary |
| --- | --- | --- |
| `tool-gate` | `PreToolUse` | Gate mutating tools (exec, writes, patches) |
| `turn-router` | `UserPromptSubmit` | Route safe turns to a configured model lane |
| `turn-review` | `Stop` | Reject answers that are empty or unsupported by tool results |

Recipes are ordinary scripts. They do not require a particular judgment
engine beyond what you configure locally.

### Requirements and limits

- Requires finclaw CLI `--version` ≥ `0.13.0`.
- Requires `node` on `PATH` (including on Windows).
- Optional `FINCLAW_HOOK_JUDGE_TOKEN` enables remote judgment in
  `tool-gate` and `turn-router`, and enables `turn-review`. Without the
  token, `tool-gate` still asks or denies by its built-in rules;
  `turn-router` and `turn-review` do nothing (no route change, no review).
- `turn-router` only switches among models on the **same provider** as the
  active session; it cannot change provider, base URL, or credentials.
  It cannot see the provider's live model allow list, so the host ignores a
  configured model id that is not allowed.
- `turn-review` cannot start a second inference; when it rejects a Stop
  event, the reason is a fixed template and is **not** an injected
  assistant message. Tools that already ran stay run.
- `tool-gate` uses `failurePolicy: deny`: if the hook process fails or
  times out, the matching tool request is denied.
- Each hook check runs in a **new process**; handlers do not share memory
  across events.
- On Unix, the host starts command hooks through `$SHELL -lc`; a heavy login
  shell can make hook startup slow.

## Recipient flow

```bash
finclaw hooks catalog
finclaw hooks install tool-gate
finclaw hooks install turn-router
finclaw hooks install turn-review
finclaw hooks list
finclaw hooks trust --recipe tool-gate
finclaw hooks trust --recipe turn-router
finclaw hooks trust --recipe turn-review
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

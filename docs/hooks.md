# Command hooks and official recipes

**Chinese:** [hooks.zh.md](hooks.zh.md)

**Write or pack a hook:** [hooks-develop.md](hooks-develop.md)

Command hooks are **opt-in** local shell commands FinClaw can run at
lifecycle events (for example before a tool runs, or when you send a
prompt). They are **off by default**. `finclaw update` only replaces the
CLI binary; it does **not** install recipes.

**Authoritative flags:** `finclaw hooks --help` on your installed build.
If your binary has no `hooks` subcommand, upgrade first.

## What the mechanism is

FinClaw reads `<profile>/hooks.json` and `<workspace>/.finclaw/hooks.json`.
Each handler is a command. After you **trust** its hash, the host copies
that handler into the running agent. The agent never reads `hooks.json`
itself.

Nothing is spawned until you trust. Interactive `finclaw chat` asks when
a handler is new or its hash changed. `finclaw chat -m …`, no TTY, and
daemons skip untrusted handlers.

Hook children run with the same privileges as the FinClaw process. Trust
is a review gate, not an OS sandbox. Policies (`finclaw policy`) stay a
separate layer — see [security-and-policies.md](security-and-policies.md).

## What is available (official catalog)

Official **hook recipes** are versioned packs on this repository’s
`hook-catalog` GitHub Release (prerelease, never GitHub `latest`).
Sources live in [`hooks/recipes/`](../hooks/recipes/).

| Id | Event | What it does | Per-recipe notes |
| --- | --- | --- | --- |
| `tool-gate` | `PreToolUse` | Allow, **ask**, or **deny** mutating tools (`exec`, jobs, writes, patches) | [tool-gate/README.md](../hooks/recipes/tool-gate/README.md) |
| `turn-router` | `UserPromptSubmit` | Route a safe turn to a **same-provider** cheap/strong model | [turn-router/README.md](../hooks/recipes/turn-router/README.md) |
| `turn-review` | `Stop` | **Reject** an empty, placeholder, or unsupported assistant answer | [turn-review/README.md](../hooks/recipes/turn-review/README.md) |

List what the public index currently advertises:

```bash
finclaw hooks catalog
```

There is no `finclaw hooks install suite`. Install and trust each id you
want. The official trio can run without a judge token (`tool-gate` still
uses built-in rules). Remote judgment uses **TypeSafe System One**
(default model **Jev**) — see [TypeSafe / Jev](#typesafe--jev).

### Requirements

- **Install / trust / hard deny:** CLI `--version` ≥ `0.13.0` and `node`
  on `PATH` (including Windows).
- **Ask, model route, and Stop reject:** CLI **0.13.1** or newer. On
  0.13.0 the recipes still install; `tool-gate` can still hard-deny;
  `ask` / `updatedModel` / Stop `reject` are ignored.
- Published `min_cli` on the catalog is still `0.13.0` (install).
- Optional `FINCLAW_HOOK_JUDGE_TOKEN` (a TypeSafe API key, **not**
  `TYPESAFE_API_KEY` in the child — see [TypeSafe / Jev](#typesafe--jev))
  enables remote judgment in `tool-gate` and `turn-router`, and enables
  `turn-review`. Without it, `tool-gate` still asks or denies by
  built-in rules; the other two emit no decision.
- `0.13.0` binaries default to a retired catalog tag. Point them at
  `hook-catalog` (see [Default catalog URL](#default-catalog-url)) or
  upgrade to 0.13.1+, which uses that URL by default.

### Honest limits

- `turn-router` cannot change provider, base URL, or credentials, and
  cannot see the live allow list. The host ignores a model id that is
  not allowed for the active provider.
- `turn-review` cannot start a second inference. A reject reason is a
  fixed template, not an injected assistant message. Tools that already
  ran stay run.
- `tool-gate` uses `failurePolicy: deny`: if that hook process fails or
  times out, the matching tool request is denied.
- Each check is a **new process**. Handlers do not share memory.
- On Unix the host starts commands with `$SHELL -lc`. A heavy login
  shell (for example some `fish` configs) can make startup slow or fail
  to expand `${FINCLAW_PROFILE_ROOT}`. Use a POSIX `SHELL` if that
  happens.

## Configure and install

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

`install` writes the **active profile** only (`<profile>/hooks/<id>/`
plus entries in `<profile>/hooks.json`). It never writes
`$FINCLAW_HOME/hooks-trust.json`. Review hashes with `hooks trust`
before anything is spawned.

Revoke with `finclaw hooks revoke` (handler id or `--recipe <id>`).

### TypeSafe / Jev

The official recipes call [TypeSafe System One](https://docs.typesafe.ai)
over HTTP (`POST /v1/systemone`). The default model id is `jev-latest`
(**Jev**). They do **not** start `mcp_jev` or any other MCP server.

TypeSafe (and `mcp_jev`, if you already use it) store the key as
`TYPESAFE_API_KEY`. FinClaw **strips every `*_API_KEY`** from hook
children, so that name never reaches the recipe. Copy the same secret
into a name that is not stripped:

```bash
# POSIX — same value as TYPESAFE_API_KEY / ~/.mcp_jev/.env
export FINCLAW_HOOK_JUDGE_TOKEN="$TYPESAFE_API_KEY"
```

```powershell
# Windows PowerShell
$env:FINCLAW_HOOK_JUDGE_TOKEN = $env:TYPESAFE_API_KEY
```

If `TYPESAFE_API_KEY` is only in `~/.mcp_jev/.env` and not in the
current shell, set `FINCLAW_HOOK_JUDGE_TOKEN` from that file yourself.
Do not put the key in `hooks.json`, `config.yaml`, or a git-tracked
file.

| Variable | Role | Default |
| --- | --- | --- |
| `FINCLAW_HOOK_JUDGE_TOKEN` | Bearer token for TypeSafe | unset (no remote judgment) |
| `FINCLAW_HOOK_JUDGE_BASE_URL` | API origin | `https://api.typesafe.ai` |
| `FINCLAW_HOOK_JUDGE_MODEL` | System One model | `jev-latest` |

Without the token: `tool-gate` still asks or denies by its built-in
rules; `turn-router` does not change the model; `turn-review` lets the
answer through. If the TypeSafe call fails or times out, `tool-gate`
falls back to those rules; the other two emit no decision.

### Router lanes

After install, edit
`<profile>/hooks/turn-router/routes.json` (cheap/strong ids per
provider). Re-trust the recipe after that edit. See the
[turn-router README](../hooks/recipes/turn-router/README.md).

### Default catalog URL

```text
https://github.com/finogeeks/finclaw-cli/releases/download/hook-catalog/hooks-index.json
```

Override in the active profile `config.yaml`:

```yaml
extra:
  hooks:
    index_url: "https://github.com/finogeeks/finclaw-cli/releases/download/hook-catalog/hooks-index.json"
```

`finclaw update` does not read `hooks-index.json`.

## Hand-written hooks

You can skip the catalog and put commands in
`<profile>/hooks.json` or `<workspace>/.finclaw/hooks.json`. Then
`finclaw hooks list` and `finclaw hooks trust`. How to write those
files, stdin/stdout shapes, and how official recipes are built:
[hooks-develop.md](hooks-develop.md).

## Not skills and not MCP

Skills stay `finclaw skills`. MCP servers stay `finclaw mcp add`.
A recipe must not bundle those.

## Related

- [hooks-develop.md](hooks-develop.md) — author `hooks.json` or a recipe
- [security-and-policies.md](security-and-policies.md) — exec / HTTP / tool-invocation policies
- [skills.md](skills.md) — skill hubs
- [reference-commands.md](reference-commands.md) — command index

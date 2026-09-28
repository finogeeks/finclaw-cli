# Develop command hooks

**Chinese:** [hooks-develop.zh.md](hooks-develop.zh.md)

**Users (install official recipes):** [hooks.md](hooks.md)

This page is for people who write hook commands. Flags stay
`finclaw hooks --help` on your installed binary.

Two ways to ship a hook:

1. **Hand-written `hooks.json`** in the active profile or the workspace.
   FinClaw discovers it, you trust it, it runs. No catalog required.
2. **Official-style recipe** (same layout as
   [`hooks/recipes/`](../hooks/recipes/)): TypeScript source, assembled
   JS, `recipe.json`. Recipients install from a catalog URL, or you copy
   the tree into a profile and merge `hooks.json` yourself.

Recipe **ids** must not be named after TypeSafe, Jev, or other judgment
products. The official trio still documents those products as the
configured backend (see [hooks.md](hooks.md#typesafe--jev)).

## Hand-written `hooks.json`

Sources (both optional; profile handlers run first):

- Profile: `<profile_root>/hooks.json`
- Project: `<workspace>/.finclaw/hooks.json`

```json
{
  "description": "local policy",
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "exec|start_exec_job",
        "hooks": [
          {
            "type": "command",
            "command": "node /Users/you/.finclaw/hooks/guard.js",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

Then:

```bash
finclaw hooks list
finclaw hooks trust --all
```

### Command object

| Field | Meaning |
| --- | --- |
| `type` | `command` only |
| `command` | Shell command. Unix: `$SHELL -lc` (fallback `/bin/sh`). Windows: `cmd.exe /C` |
| `timeout` | Seconds. Default 30. Minimum 1 |
| `async` | Fire-and-forget. Rejected on `PreToolUse`, `PermissionRequest`, `UserPromptSubmit`, `SessionStart` |
| `statusMessage` | Optional text while the command runs |
| `id` | Optional stable id (`[a-z0-9]+(?:-[a-z0-9]+)*`, max 64). Recipes must set this |
| `failurePolicy` | `deny` only on **PreToolUse**. Other events: discovery error |
| `recipe` | Set only by `finclaw hooks install`. Do not hand-write it unless you want `hooks remove <id>` to treat you as that recipe |

`matcher` is an optional regex on the **full** match string (Codex-shaped).
For tool events that string is the FinClaw tool name (`exec`,
`write_file`, MCP names, …). Omit it or use `*` to match every call.
Every matching group runs; groups are not first-match.

Unknown fields or a bad regex: that handler is skipped; the session still
starts.

### Events

| Event | Spawned? | What a handler can do |
| --- | --- | --- |
| `PreToolUse` | Yes | Deny, ask (approval), rewrite `updatedInput` |
| `PermissionRequest` | Yes | Allow or deny when the host would ask a human |
| `PostToolUse` | Yes | Append context; block replaces the tool result |
| `UserPromptSubmit` | Yes | Block, rewrite prompt, or `updatedModel` (same provider) |
| `SessionStart` | Yes | `additionalContext` on the first infer |
| `SessionEnd` | Yes | Notify only (fail-open; `async` allowed) |
| `SubagentStart` / `SubagentStop` | Yes | Notify |
| `Stop` | Yes (CLI ≥ 0.13.1) | `decision: "reject"` only |
| `PreCompact`, `PostCompact`, `Interrupt` | Hashed and listed, **not** spawned | — |

Handlers on one event run **in order** (profile, then project). A deny
wins. Rewrites: last non-blocking value wins. Each handler sees the
**original** stdin.

Need CLI **0.13.1+** for `permissionDecision: "ask"`, `updatedModel`,
and Stop `reject`. Older 0.13.0 builds still spawn the events but ignore
those three honours.

### Stdin

Every event sends JSON on stdin. Common fields: `session_id`, `turn_id`,
`cwd`, `hook_event_name`, `model`, `permission_mode`, `transcript_path`
(`null`).

Tool events also send `tool_name`, `tool_input`, `tool_use_id`, and
`PostToolUse` sends `tool_response`.

| Event | Extra |
| --- | --- |
| `UserPromptSubmit` | `prompt` |
| `SessionStart` | `source`: `startup` or `resume` |
| `SessionEnd` | `reason`: `quit`, `close`, `new`, … |
| `SubagentStart` / `SubagentStop` | `subagent_id`, `task`, `tool_name` |

`UserPromptSubmit`, `PreToolUse`, `PostToolUse`, and `Stop` also get a
bounded `turn` object when any trusted handler for those events exists:

```json
{
  "turn": {
    "user_text": "…",
    "assistant_text": null,
    "tools": [
      {
        "name": "exec",
        "input_summary": "…",
        "result_summary": "…"
      }
    ]
  }
}
```

Caps: `user_text` / `assistant_text` 8192 UTF-8 bytes; at most 32
`tools` (oldest dropped); each summary 1024 bytes.

Working directory is the session workspace. Environment is the parent
minus stripped secret names (`*_API_KEY`, configured LLM key names,
internal tokens, `FINSAFE_LICENSE*`). The runner adds `FINCLAW_HOOK_EVENT`
and `FINCLAW_PROFILE`. There is no `pass_env`.

`TYPESAFE_API_KEY` is stripped with every other `*_API_KEY`. Official
recipes therefore read `FINCLAW_HOOK_JUDGE_TOKEN` and call TypeSafe
System One (`https://api.typesafe.ai/v1/systemone`, model `jev-latest`).
If you already have a TypeSafe or `mcp_jev` key, copy it:

```bash
export FINCLAW_HOOK_JUDGE_TOKEN="$TYPESAFE_API_KEY"
```

Do not spawn `mcp_jev` from a hook command unless you are writing a
different recipe. There is no `pass_env` to re-admit `TYPESAFE_API_KEY`.

### Stdout and exit codes

- Exit 0, empty stdout: no decision.
- Exit 0, JSON object: parsed as below. Looks-like-JSON that fails to
  parse is a hook failure.
- Exit 2 with non-empty stderr: **block** on tool / prompt events
  (Codex-compatible). Not a Stop reject.
- Any other exit: hook failure.

**PreToolUse deny / ask** (CLI 0.13.1+ for `ask`):

```json
{
  "hookSpecificOutput": {
    "permissionDecision": "deny",
    "permissionDecisionReason": "blocked by local rule"
  }
}
```

```json
{
  "hookSpecificOutput": {
    "permissionDecision": "ask"
  }
}
```

Empty stdout never means allow for a fail-closed gate you wrote yourself —
emit deny/ask explicitly, or rely on `failurePolicy: deny` for crashes.

**UserPromptSubmit route** (CLI 0.13.1+):

```json
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "updatedModel": "deepseek-v4-flash"
  }
}
```

The id must be on the active provider’s allow list (bundled `finclaw model`
catalog plus the current model). The host ignores provider/URL/key
changes. A request that already pins `model` / `provider` / `base_url` /
`api_key` ignores `updatedModel`.

**Stop reject** (CLI 0.13.1+). Codex `block` / exit 2 is **not** reject:

```json
{
  "hookSpecificOutput": {
    "decision": "reject",
    "reason": "unsupported by tool results"
  }
}
```

`reason` must be non-empty. The user sees that reason instead of the
assistant text. No second infer. Tools already run stay run.

Default PreToolUse failures (timeout, crash) are **fail-open** unless
that handler set `failurePolicy: deny`. `PermissionRequest` spawn
failure denies.

### Trust

`$FINCLAW_HOME/hooks-trust.json` is per-machine. The hash covers event,
matcher, command, timeout, `async`, `failurePolicy` when set, Stop
`stop:v1`, and the script file bytes when the command resolves to a
file (`node`, `python3`, `bash`, …). Edit the script → status
**Modified** until you trust again.

Claw re-hashes the file before each spawn. A mid-session edit is skipped
for the rest of the session.

Timed-out children are killed as a tree (Unix process group, Windows Job
Object).

## Official-style recipes

Use this when you want `finclaw hooks install` from a catalog, or to
match the published trio.

```text
hooks/recipes/<id>/
  recipe.json
  README.md
  src/…           # TypeScript + tests
  routes.json     # turn-router only
```

`id` is `[a-z0-9]+(?:-[a-z0-9]+)*`, max 64, must not start with `.`.

`recipe.json` uses schema `hooks.recipe.v1`. Every command **must** have
`id`. Commands are relative to the recipe root (`node scripts/main.js`).
Do not set `recipe` (install stamps it). Example:
[`hooks/recipes/tool-gate/recipe.json`](../hooks/recipes/tool-gate/recipe.json).

Shared helpers live in [`hooks/lib/`](../hooks/lib/). From this repo:

```bash
npm ci --prefix hooks
npm test --prefix hooks
python3 scripts/hooks_assemble.py --hooks-dir hooks --out-dir assembled-recipes
python3 scripts/hooks_pack.py \
  --recipes-dir assembled-recipes \
  --out-dir dist \
  --asset-base-url "https://example.test/catalog"
```

Assemble compiles `src/` to `scripts/main.js` and copies `hooks/lib/`
into `scripts/lib/`. Packed archives must not contain `node_modules` or
symlinks. Recipients run `node scripts/main.js` (Node on `PATH`).

Catalog document schema is `hooks.catalog.v1` (`id`, `latest`,
`min_cli`, version `url` + `sha256`). Recipients set
`extra.hooks.index_url` to your index if it is not the official
`hook-catalog` URL.

The official GitHub tag `hook-catalog` is **immutable**. Maintainers do
not clobber it; a new catalog tag requires a matching
`DEFAULT_INDEX_URL` / `extra.hooks.index_url` change. Tag `hooks` is
retired and must not be recreated.

### Try a handler without install

From an assembled tree:

```bash
printf '%s' '{"hook_event_name":"PreToolUse","tool_name":"exec","tool_input":{"command":"rm -rf /"},"model":"x","turn":{"user_text":"x","assistant_text":null,"tools":[]}}' \
  | node assembled-recipes/tool-gate/scripts/main.js
```

Expect deny JSON on stdout, exit 0.

## Related

- [hooks.md](hooks.md) — install the official trio
- Per-recipe notes under [`hooks/recipes/`](../hooks/recipes/)

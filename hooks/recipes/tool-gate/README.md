# tool-gate

`tool-gate` is a PreToolUse gate for mutating tools. It matches:

- `exec`
- `start_exec_job`
- `write_file`
- `edit_file`
- `apply_patch`

The recipe requires `node` on `PATH`, including on Windows. Install needs
finclaw CLI `0.13.0` or newer. `permissionDecision: "ask"` needs CLI
**0.13.1**. See [docs/hooks.md](../../../docs/hooks.md).

## Hook wiring

- Command: `node scripts/main.js`
- Matcher: `exec|start_exec_job|write_file|edit_file|apply_patch`

## Decisions

Without configuration, the gate denies destructive or sensitive requests and
asks for approval for every other matching request. It never silently allows a
request in this deterministic mode.

Remote judgment uses TypeSafe System One (default model `jev-latest`,
Jev). Copy your TypeSafe key — the same secret as `TYPESAFE_API_KEY` /
`~/.mcp_jev/.env` — into `FINCLAW_HOOK_JUDGE_TOKEN`. FinClaw strips
`*_API_KEY` from hook children, so `TYPESAFE_API_KEY` alone does nothing
here. Optional: `FINCLAW_HOOK_JUDGE_BASE_URL` (default
`https://api.typesafe.ai`) and `FINCLAW_HOOK_JUDGE_MODEL`. Full setup:
[docs/hooks.md](../../../docs/hooks.md#typesafe--jev).

The handler uses `failurePolicy: deny`: if the hook process cannot run or
times out, the matching tool request is denied.

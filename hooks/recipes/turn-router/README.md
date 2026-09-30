# turn-router

`turn-router` is a UserPromptSubmit hook that selects a configured model lane
for safe user turns. It requires `node` on `PATH`, including on Windows.
Install needs CLI `0.13.0` or newer. Honouring `updatedModel` needs CLI
**0.13.1**. See [docs/hooks.md](../../../docs/hooks.md).

## Hook wiring

- Command: `node scripts/main.js`
- Matcher: `*` (the recipe omits the field, which matches every event)

Remote judgment uses TypeSafe System One (default model `jev-latest`,
Jev). Copy your TypeSafe key — the same secret as `TYPESAFE_API_KEY` /
`~/.mcp_jev/.env` — into `FINCLAW_HOOK_JUDGE_TOKEN`. FinClaw strips
`*_API_KEY` from hook children, so `TYPESAFE_API_KEY` alone does nothing
here. Without that token the router emits no decision. Optional:
`FINCLAW_HOOK_JUDGE_BASE_URL` (default `https://api.typesafe.ai`) and
`FINCLAW_HOOK_JUDGE_MODEL`. Full setup:
[docs/hooks.md](../../../docs/hooks.md#typesafe--jev).

## Configure routes

`routes.json` lists cheap/strong ids per provider. The router picks the group
that contains the current `model` from stdin and emits only an id from that
group. A current model that is not in any group produces no route.

Each lane uses at most its first eight ids. Re-trust the recipe after editing
`routes.json`. The shipped groups follow the bundled `finclaw model` catalog
plus common aliases; add a group or id if your profile uses something else.

A legacy file with top-level `cheap` / `strong` arrays is still valid and is
treated as a single group.

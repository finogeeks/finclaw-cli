# turn-router

`turn-router` is a UserPromptSubmit hook that selects a configured model lane
for safe user turns. It requires `node` on `PATH`, including on Windows, and
finclaw CLI version `0.13.0` or newer.

## Hook wiring

- Command: `node scripts/main.js`
- Matcher: `*` (the recipe omits the field, which matches every event)

Set `FINCLAW_HOOK_JUDGE_TOKEN` to enable the optional remote judgment step.
`FINCLAW_HOOK_JUDGE_BASE_URL` and `FINCLAW_HOOK_JUDGE_MODEL` can override its
endpoint and model.

## Configure routes

`routes.json` lists cheap/strong ids per provider. The router picks the group
that contains the current `model` from stdin and emits only an id from that
group. A current model that is not in any group produces no route.

Each lane uses at most its first eight ids. Re-trust the recipe after editing
`routes.json`. The shipped groups follow the bundled `finclaw model` catalog
plus common aliases; add a group or id if your profile uses something else.

A legacy file with top-level `cheap` / `strong` arrays is still valid and is
treated as a single group.

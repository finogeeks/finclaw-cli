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

Edit `routes.json` to set the `cheap` and `strong` model ids. Each lane uses at
most its first eight ids. Re-trust the recipe after editing `routes.json`.
The router cannot see the active provider's live model allow list; configure
only model ids that the current provider allows.

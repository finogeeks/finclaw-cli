# turn-review

`turn-review` is a Stop hook that can reject an assistant answer when the
answer is unsupported by the turn's tool results or is empty or a placeholder.
It requires `node` on `PATH`, including on Windows. Install needs CLI
`0.13.0` or newer. Stop `reject` needs CLI **0.13.1**. See
[docs/hooks.md](../../../docs/hooks.md).

## Hook wiring

- Command: `node scripts/main.js`
- Matcher: `*` (the recipe omits the field, which matches every event)

Review uses TypeSafe System One (default model `jev-latest`, Jev). Copy
your TypeSafe key — the same secret as `TYPESAFE_API_KEY` /
`~/.mcp_jev/.env` — into `FINCLAW_HOOK_JUDGE_TOKEN`. FinClaw strips
`*_API_KEY` from hook children, so `TYPESAFE_API_KEY` alone does nothing
here. Without that token, or when the turn is unavailable, the hook
emits no output and lets the answer proceed. Full setup:
[docs/hooks.md](../../../docs/hooks.md#typesafe--jev).

When it rejects an answer, the hook returns a fixed reason template. It does
not include the assistant answer in that reason. Review cannot start a second
inference, and tools that already ran stay run.

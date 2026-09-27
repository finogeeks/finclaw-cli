# turn-review

`turn-review` is a Stop hook that can reject an assistant answer when the
answer is unsupported by the turn's tool results or is empty or a placeholder.
It requires `node` on `PATH`, including on Windows, and finclaw CLI version
`0.13.0` or newer.

## Hook wiring

- Command: `node scripts/main.js`
- Matcher: `*` (the recipe omits the field, which matches every event)

Set `FINCLAW_HOOK_JUDGE_TOKEN` to enable review. Without the token, or when the
turn is unavailable, the hook emits no output and lets the answer proceed.

When it rejects an answer, the hook returns a fixed reason template. It does
not include the assistant answer in that reason. Review cannot start a second
inference, and tools that already ran stay run.

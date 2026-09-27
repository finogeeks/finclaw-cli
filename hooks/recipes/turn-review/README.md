# turn-review

`turn-review` is a Stop hook that can reject an assistant answer when the
answer is unsupported by the turn's tool results or is empty or a placeholder.
It requires `node` on `PATH`, including on Windows, and finclaw CLI version
`0.13.0` or newer.

Set `FINCLAW_HOOK_JUDGE_TOKEN` to enable review. Without the token, or when the
turn is unavailable, the hook emits no output and lets the answer proceed.

When it rejects an answer, the hook returns a fixed reason template. It does
not include the assistant answer in that reason.

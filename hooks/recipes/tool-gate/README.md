# tool-gate

`tool-gate` is a PreToolUse gate for mutating tools. It matches:

- `exec`
- `start_exec_job`
- `write_file`
- `edit_file`
- `apply_patch`

The recipe requires `node` on `PATH`, including on Windows. It requires
finclaw CLI version `0.13.0` or newer.

## Decisions

Without configuration, the gate denies destructive or sensitive requests and
asks for approval for every other matching request. It never silently allows a
request in this deterministic mode.

Set `FINCLAW_HOOK_JUDGE_TOKEN` to enable the optional remote judgment step.
`FINCLAW_HOOK_JUDGE_BASE_URL` and `FINCLAW_HOOK_JUDGE_MODEL` can override its
endpoint and model.

The handler uses `failurePolicy: deny`: if the hook process cannot run or
times out, the matching tool request is denied.

# Post-turn learning (self-evolution)

**Chinese:** [learning.zh.md](learning.zh.md)

Finclaw can run a **post-turn learning loop**: after enough chat turns or tool use, a background reviewer inspects the conversation and may persist **facts to memory** or **procedures as skills**. The parent chat session is not polluted by the review fork.

**Default:** learning is **off** (`learning.enabled: false`). You must opt in per profile.

**Authoritative:** `finclaw learning --help` and subcommand help for your build.

## What it does (at a glance)

| Step | Behavior |
| --- | --- |
| 1. You chat | Normal `finclaw chat` turns; you do not call `memory_save` yourself for the loop to work. |
| 2. Nudge fires | After `memory_nudge_turns` user turns (and/or `skill_nudge_tool_iters` tool iterations), a review may run. |
| 3. Review | A forked subagent summarizes what is worth remembering or turning into a skill. |
| 4. Persist | Depends on `mode` — observe (log only), stage (pending), or promote (live memory/skills). |
| 5. Reuse | A **new session** can recall facts from durable memory; skills live under the agent workspace. |

There is **no** `finclaw chat --learning` flag. Enable learning in profile `config.yaml` or via environment variables (below), then use `finclaw chat` as usual.

## Enable in profile `config.yaml`

Edit the active profile file (`finclaw config path`) and add a `learning:` block:

```yaml
learning:
  enabled: true
  mode: stage              # observe | stage | promote
  memory_nudge_turns: 10   # user turns before a memory review nudge
  skill_nudge_tool_iters: 10
  eval_gate: off           # off | manual | auto (promote gate in stage mode)
  failure_reflection: false
```

Restart embedded chat or the daemon after changing config so the runtime picks up values.

### Recommended modes

| `mode` | Use when |
| --- | --- |
| **`observe`** | First try: reviews run but **do not write** to disk (intents logged only). Safest. |
| **`stage`** | Production-style: candidates land under **pending** paths; you **promote** or **reject** with `finclaw learning`. |
| **`promote`** | Dogfood / Hermes-like immediate writes to live memory and agent-authored skills. Use only when you accept automatic persistence. |

### `eval_gate` (stage mode + promote)

| Value | Meaning |
| --- | --- |
| `off` | No extra gate before promote. |
| `manual` | Operator must run `finclaw learning promote <id>` (optionally `--force`). |
| `auto` | Promote only when a scorecard verdict is not `regressed` (see `promote --scorecard-verdict`). |

## Environment variables (override YAML)

When set in the process environment, these override the corresponding `learning:` keys for that process (embedded boot or daemon):

| Variable | Maps to |
| --- | --- |
| `AI_INFRA_RS_LEARNING_ENABLED` | `learning.enabled` (`1` / `true` / `yes` = on) |
| `AI_INFRA_RS_LEARNING_MODE` | `learning.mode` (`observe`, `stage`, `promote`) |
| `AI_INFRA_RS_LEARNING_MEMORY_NUDGE_TURNS` | `learning.memory_nudge_turns` |
| `AI_INFRA_RS_LEARNING_SKILL_NUDGE_TOOL_ITERS` | `learning.skill_nudge_tool_iters` |
| `AI_INFRA_RS_LEARNING_EVAL_GATE` | `learning.eval_gate` |
| `AI_INFRA_RS_LEARNING_FAILURE_REFLECTION` | `learning.failure_reflection` |
| `AI_INFRA_RS_LEARNING_REVIEW_TIMEOUT_MS` | Max wait for a review to finish on one-shot chat (default often ~45s) |

**Precedence:** process environment overrides profile `config.yaml` for these keys when the variable is set.

Example (session-only, without editing YAML):

```bash
export AI_INFRA_RS_LEARNING_ENABLED=1
export AI_INFRA_RS_LEARNING_MODE=stage
finclaw chat --embedded -m "Remember my project codename is NEBULA."
```

## `finclaw learning` commands

Manage the loop when `enabled: true` (especially in **`stage`** mode):

```bash
finclaw learning status
finclaw learning list-pending
finclaw learning promote <artifact-id> [--force] [--scorecard-verdict improved|unchanged|inconclusive|regressed]
finclaw learning reject <artifact-id>
finclaw learning review [--kind memory|skill|combined|failure] [--summary "..."]
finclaw learning consolidate [--dry-run] [--observe-max-age-days 14] [--rejected-max-age-days 30]
```

| Command | Role |
| --- | --- |
| `status` | Show whether learning is enabled, current mode, and pending counts. |
| `list-pending` | List staged artifacts awaiting promote/reject. |
| `promote` / `reject` | Move a staged artifact to live memory/skills or to rejected storage. |
| `review` | Force one review pass (needs embedded or daemon Claw). |
| `consolidate` | Prune old observe/rejected artifacts; **never auto-promotes**. |

Add `--json` on the parent command when your build supports it (`finclaw learning --json status`).

## Chat and sessions

- Reviews run **after** a qualifying turn; one-shot `finclaw chat -m` waits up to the review timeout so short-lived processes can still persist learning.
- **Cross-session recall** uses durable memory in the agent workspace — use a **new** `--session` id (or a new REPL session) to test whether a fact from an earlier conversation is recalled.
- Lower `memory_nudge_turns` (for example `2`) speeds up local dogfood; **10** matches common Hermes-style cadence for published parity.

See [chat-and-operations.md](chat-and-operations.md) for dispatch (`--embedded` / daemon), streaming, and session flags.

## Skills and curator

- Procedures discovered in review may create **agent-authored skills** under the workspace `skills/` tree (Channel C), subject to `mode`.
- **`finclaw skills curator`** is a separate lifecycle for idle/archived skills. Learning and curator can coexist: staged or promoted skills follow learning rules; curator still ages unused packs. See [skills.md](skills.md).

Ensure `skill-creator` (or equivalent scaffold) is available in the profile if you expect `skill_create` during review — run `finclaw skills list` after enabling learning.

## HTTP / multi-tenant deployments

The **CLI** reads `learning:` from **profile** `config.yaml`. A **long-running Claw HTTP service** (middleware, desktop host, or custom deployment) may instead read a fleet `ai-infra.yaml` or the same `AI_INFRA_RS_LEARNING_*` variables in its service environment. That wiring is **operator-specific** — configure the runtime your integration uses; do not assume profile YAML applies to a remote Claw URL unless your operator documents that mapping.

## Quick smoke (stage mode)

```bash
finclaw config path   # note profile config.yaml
# Add learning.enabled: true, mode: stage, memory_nudge_turns: 2 (dogfood)

finclaw learning status
finclaw chat --embedded --session learn-smoke -m "My status token is ALPHA-7. Acknowledge briefly."
finclaw chat --embedded --session learn-smoke -m "Filler turn two."
finclaw learning list-pending
finclaw chat --embedded --session learn-smoke-recall -m "What status token did I set?"
```

Adjust nudge count and provider credentials per [configuration.md](configuration.md).

## See also

- [configuration.md](configuration.md) — profile paths, env precedence, LLM keys
- [profiles.md](profiles.md) — per-profile isolation
- [skills.md](skills.md) — install, check, curator
- [chat-and-operations.md](chat-and-operations.md) — REPL, daemon, sessions
- [reference-commands.md](reference-commands.md) — command cheat sheet

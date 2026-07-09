# Post-turn learning (self-evolution)

**Chinese:** [learning.zh.md](learning.zh.md)

Finclaw can run a **post-turn learning loop**: after enough chat turns or tool use, a background reviewer inspects the conversation and may persist **facts to memory** or **procedures as skills**. The parent chat session is not polluted by the review fork.

**Default:** learning is **on** with `mode: promote` (Hermes-style write-through). `finclaw init` writes this into the stub `config.yaml` and can ask interactively; use `finclaw learning disable` or `mode: stage` / `observe` when you want a safer posture.

**Authoritative:** `finclaw learning --help` and subcommand help for your build.

## What it does (at a glance)

| Step | Behavior |
| --- | --- |
| 1. You chat | Normal `finclaw chat` turns; you do not call `memory_save` yourself for the loop to work. |
| 2. Nudge fires | After `memory_nudge_turns` user turns (and/or `skill_nudge_tool_iters` tool iterations), a review may run. |
| 3. Review | A forked subagent summarizes what is worth remembering or turning into a skill. |
| 4. Persist | Depends on `mode` — observe (log only), stage (pending), or promote (live memory/skills). |
| 5. Reuse | A **new session** can recall facts from durable memory; skills live under the agent workspace. |

There is **no** `finclaw chat --learning` flag. Preference lives in profile `config.yaml` (or `AI_INFRA_RS_LEARNING_*`), then use `finclaw chat` as usual.

## Profile `config.yaml`

`finclaw init` seeds (or you can edit via `finclaw config path`):

```yaml
learning:
  enabled: true
  mode: promote            # observe | stage | promote
  memory_nudge_turns: 10   # user turns before a memory review nudge
  skill_nudge_tool_iters: 10
  eval_gate: off           # off | manual | auto (promote gate in stage mode)
  failure_reflection: false
```

Restart embedded chat or the daemon after changing config so the runtime picks up values.

### Modes

| `mode` | Use when |
| --- | --- |
| **`promote`** | **Default.** Immediate writes to live memory and agent-authored skills (Hermes-like). |
| **`stage`** | Candidates land under **pending**; you **promote** or **reject** with `finclaw learning`. |
| **`observe`** | Reviews run but **do not write** to disk (intents logged only). Safest dry-run. |

### `eval_gate` (stage mode + promote)

| Value | Meaning |
| --- | --- |
| `off` | No extra gate before promote. |
| `manual` | Operator must run `finclaw learning promote <id>` (optionally `--force`). |
| `auto` | Promote only when a scorecard verdict is not `regressed` (see `promote --scorecard-verdict`). |

## Toggle without editing YAML by hand

```bash
finclaw learning status
finclaw learning enable                 # on; keeps or defaults mode to promote
finclaw learning enable --mode stage
finclaw learning set-mode observe
finclaw learning disable
finclaw config set learning.enabled true
finclaw config set learning.mode stage
```

Also during `finclaw init`:

- Interactive: confirm enable (default yes) and pick mode (default promote).
- Non-interactive: stub stays enabled+promote; override with `--no-learning` or `--learning-mode stage|observe|promote`.
- `--skip-learning-prompt` skips the interactive question and keeps the stub defaults.

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

Example (session-only override to stage):

```bash
export AI_INFRA_RS_LEARNING_MODE=stage
finclaw chat --embedded -m "Remember my project codename is NEBULA."
```

## `finclaw learning` commands

```bash
finclaw learning status
finclaw learning enable [--mode observe|stage|promote]
finclaw learning disable
finclaw learning set-mode <observe|stage|promote>
finclaw learning list-pending
finclaw learning promote <artifact-id> [--force] [--scorecard-verdict improved|unchanged|inconclusive|regressed]
finclaw learning reject <artifact-id>
finclaw learning review [--kind memory|skill|combined|failure] [--summary "..."]
finclaw learning consolidate [--dry-run] [--observe-max-age-days 14] [--rejected-max-age-days 30]
```

| Command | Role |
| --- | --- |
| `status` | Show whether learning is enabled, current mode, and pending counts. |
| `enable` / `disable` / `set-mode` | Persist preference into profile `config.yaml`. |
| `list-pending` | List staged artifacts awaiting promote/reject. |
| `promote` / `reject` | Move a staged artifact to live memory/skills or to rejected storage. |
| `review` | Force one review pass (needs embedded or daemon Claw). |
| `consolidate` | Prune old observe/rejected artifacts; **never auto-promotes**. |

Add `--json` on the parent command when your build supports it (`finclaw learning --json status`).

## Chat and sessions

- Reviews run **after** eligible turns; `finclaw chat -m` waits for the review (with a timeout) so short-lived processes still persist.
- **Cross-session recall** needs durable memory on disk under the agent workspace — use a **new** `--session` (or a new REPL session) to verify the agent remembers prior facts.
- For local dogfood, set `memory_nudge_turns: 2`; keep `10` for Hermes-like cadence in published results.

See [chat-and-operations.md](chat-and-operations.md) for `--embedded` / daemon and session flags.

## Skills and curator

- Reviews may create **agent-authored skills** via `skill_create` under the workspace `skills/` tree (Channel C), subject to `mode`.
- **`finclaw skills curator`** still manages idle/archive of agent skills independently of the learning loop. See [skills.md](skills.md).

Ensure scaffolding such as `skill-creator` is present if you expect skill creation (`finclaw skills list` after init).

## HTTP / multi-tenant deployments

The **CLI** reads `learning:` from **profile** `config.yaml`. A **long-running Claw HTTP service** (middleware, desktop host, or custom deployment) may instead read a fleet `ai-infra.yaml` or the same `AI_INFRA_RS_LEARNING_*` variables in its service environment. That wiring is **operator-specific** — configure the runtime your integration uses; do not assume profile YAML applies to a remote Claw URL unless your operator documents that mapping.

## Quick smoke (promote mode)

```bash
finclaw config path   # note profile config.yaml
# init already seeds learning.enabled: true, mode: promote; optional: memory_nudge_turns: 2

finclaw learning status
finclaw chat --embedded --session learn-smoke -m "My status token is ALPHA-7. Confirm briefly."
finclaw chat --embedded --session learn-smoke -m "Second filler turn."
finclaw chat --embedded --session learn-smoke-recall -m "What status token did I set?"
```

For LLM keys and providers, see [configuration.md](configuration.md).

## See also

- [configuration.md](configuration.md) — profile paths, env precedence, LLM keys
- [profiles.md](profiles.md) — profile isolation
- [skills.md](skills.md) — install, check, curator
- [chat-and-operations.md](chat-and-operations.md) — REPL, daemon, sessions
- [reference-commands.md](reference-commands.md) — command index

# 回合后学习（自进化）

**English:** [learning.md](learning.md)

Finclaw 可启用**回合后学习循环**：在足够多的对话轮次或工具调用之后，后台审阅子智能体会检查对话，并可能将**事实写入记忆**或把**流程保存为技能**。审阅在独立分支中运行，**不会污染**主会话 transcript。

**默认：关闭**（`learning.enabled: false`）。需在 profile 中显式开启。

**以本机 `finclaw learning --help` 及各子命令 `--help` 为准。**

## 机制概览

| 步骤 | 行为 |
| --- | --- |
| 1. 正常对话 | 使用 `finclaw chat`；无需用户主动调用 `memory_save`。 |
| 2. 触发 nudge | 达到 `memory_nudge_turns` 用户轮次和/或 `skill_nudge_tool_iters` 工具迭代后，可能启动审阅。 |
| 3. 审阅 | 子智能体判断哪些内容值得记忆或固化为技能。 |
| 4. 持久化 | 由 `mode` 决定：observe（仅记录）、stage（待审批）、promote（直接写入）。 |
| 5. 复用 | **新会话**可从持久记忆召回事实；技能位于 agent 工作区。 |

**没有** `finclaw chat --learning` 开关。请在 profile 的 `config.yaml` 或环境变量中启用，然后照常 `finclaw chat`。

## 在 profile `config.yaml` 中启用

编辑活动 profile（`finclaw config path`），增加 `learning:` 段：

```yaml
learning:
  enabled: true
  mode: stage              # observe | stage | promote
  memory_nudge_turns: 10
  skill_nudge_tool_iters: 10
  eval_gate: off           # off | manual | auto（stage 模式下 promote 门禁）
  failure_reflection: false
```

修改后需重启内嵌 chat 或 daemon，运行时才会加载新配置。

### 推荐 `mode`

| `mode` | 适用场景 |
| --- | --- |
| **`observe`** | 首次试用：审阅运行但**不写盘**（仅记录意图）。最安全。 |
| **`stage`** | 生产风格：候选写入 **pending**；用 `finclaw learning` **批准或拒绝**。 |
| **`promote`** | 内测/Hermes 式：立即写入 live 记忆与 agent 技能。仅在接受自动持久化时使用。 |

### `eval_gate`（stage + promote）

| 值 | 含义 |
| --- | --- |
| `off` | promote 无额外门禁。 |
| `manual` | 须执行 `finclaw learning promote <id>`（可加 `--force`）。 |
| `auto` | 仅当 scorecard 判决非 `regressed` 时允许 promote（见 `promote --scorecard-verdict`）。 |

## 环境变量（覆盖 YAML）

在进程环境中设置时，会覆盖 profile `config.yaml` 中对应项（内嵌启动或 daemon 进程）：

| 变量 | 对应配置 |
| --- | --- |
| `AI_INFRA_RS_LEARNING_ENABLED` | `learning.enabled`（`1` / `true` / `yes` 为开） |
| `AI_INFRA_RS_LEARNING_MODE` | `learning.mode`（`observe`、`stage`、`promote`） |
| `AI_INFRA_RS_LEARNING_MEMORY_NUDGE_TURNS` | `learning.memory_nudge_turns` |
| `AI_INFRA_RS_LEARNING_SKILL_NUDGE_TOOL_ITERS` | `learning.skill_nudge_tool_iters` |
| `AI_INFRA_RS_LEARNING_EVAL_GATE` | `learning.eval_gate` |
| `AI_INFRA_RS_LEARNING_FAILURE_REFLECTION` | `learning.failure_reflection` |
| `AI_INFRA_RS_LEARNING_REVIEW_TIMEOUT_MS` | 单次 `chat -m` 等待审阅完成的上限（默认约 45s） |

**优先级：** 已设置的环境变量优先于 profile `config.yaml`。

示例（不改 YAML，仅当前 shell）：

```bash
export AI_INFRA_RS_LEARNING_ENABLED=1
export AI_INFRA_RS_LEARNING_MODE=stage
finclaw chat --embedded -m "记住项目代号 NEBULA，简短确认即可。"
```

## `finclaw learning` 命令

在 `enabled: true` 时管理循环（尤其 **`stage`** 模式）：

```bash
finclaw learning status
finclaw learning list-pending
finclaw learning promote <artifact-id> [--force] [--scorecard-verdict improved|unchanged|inconclusive|regressed]
finclaw learning reject <artifact-id>
finclaw learning review [--kind memory|skill|combined|failure] [--summary "..."]
finclaw learning consolidate [--dry-run] [--observe-max-age-days 14] [--rejected-max-age-days 30]
```

| 命令 | 作用 |
| --- | --- |
| `status` | 是否启用、当前 mode、pending 数量。 |
| `list-pending` | 列出待 promote/reject 的暂存项。 |
| `promote` / `reject` | 写入 live 记忆/技能，或移入 rejected。 |
| `review` | 强制跑一次审阅（需内嵌或 daemon Claw）。 |
| `consolidate` | 清理过期 observe/rejected 产物；**不会自动 promote**。 |

若构建支持，可在父命令加 `--json`（例如 `finclaw learning --json status`）。

## 对话与会话

- 审阅在符合条件的回合**之后**运行；`finclaw chat -m` 会等待审阅完成（有超时），短进程也能完成持久化。
- **跨会话召回**依赖 agent 工作区中的持久记忆 — 用**新** `--session`（或新 REPL 会话）验证是否记得先前事实。
- 本地调试可将 `memory_nudge_turns` 设为 `2`；**10** 更接近常见 Hermes 节奏。

详见 [chat-and-operations.zh.md](chat-and-operations.zh.md)（`--embedded`/daemon、流式、会话参数）。

## 技能与 curator

- 审阅可能通过 `skill_create` 在工作区 `skills/` 下创建 **agent 技能**（Channel C），受 `mode` 约束。
- **`finclaw skills curator`** 管理闲置/归档，与学习循环独立但可并存。见 [skills.zh.md](skills.zh.md)。

若期望审阅创建技能，请确认 profile 中有 `skill-creator` 等脚手架 — 启用学习后执行 `finclaw skills list` 检查。

## HTTP / 多租户部署

**CLI** 从 **profile** `config.yaml` 读取 `learning:`。常驻 **Claw HTTP 服务**（中间件、桌面宿主等）可能从 fleet 级 `ai-infra.yaml` 或服务环境中的 `AI_INFRA_RS_LEARNING_*` 读取 — 属**运维配置**，勿默认认为 profile YAML 会自动作用于远程 Claw URL。

## 快速冒烟（stage 模式）

```bash
finclaw config path
# 在 config.yaml 增加 learning.enabled: true、mode: stage、memory_nudge_turns: 2

finclaw learning status
finclaw chat --embedded --session learn-smoke -m "我的状态令牌是 ALPHA-7，简短确认。"
finclaw chat --embedded --session learn-smoke -m "第二条填充轮次。"
finclaw learning list-pending
finclaw chat --embedded --session learn-smoke-recall -m "我设的状态令牌是什么？"
```

LLM 与 nudge 参数见 [configuration.zh.md](configuration.zh.md)。

## 另见

- [configuration.zh.md](configuration.zh.md) — profile 路径、环境优先级、LLM 密钥
- [profiles.zh.md](profiles.zh.md) — profile 隔离
- [skills.zh.md](skills.zh.md) — 安装、检查、curator
- [chat-and-operations.zh.md](chat-and-operations.zh.md) — REPL、daemon、会话
- [reference-commands.zh.md](reference-commands.zh.md) — 命令索引

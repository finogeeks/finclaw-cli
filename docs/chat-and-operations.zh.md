# 对话、REPL、守护进程、日志与日常运维

**English:** [chat-and-operations.md](chat-and-operations.md)

## 对话模式

| 方式 | 命令 | 说明 |
| --- | --- | --- |
| 交互式 REPL | `finclaw chat` | 在 TTY 上通常支持多行输入与 slash 命令 |
| 一次性 | `finclaw chat -m "..."` | 得到回复后退出，适合脚本/CI |
| 实验性 TUI | `finclaw chat --tui` | 全屏 ratatui REPL（字标、滚动、`/` 菜单）。需要 TTY；与 `-m` 联用时忽略。与行式 chat 走同一 Claw/调度路径。 |

**TUI 注意：** 需要交互式审批提示的受监督工具在 `--tui` 下可能**自动拒绝**（raw mode 无法与行式提示安全共享 stdin）。审批密集时请用行式 `finclaw chat` 或 IDE 中的 ACP — 见 [security-and-policies.zh.md](security-and-policies.zh.md)。以本机 `finclaw chat --help` 为准。

### 内嵌 与 常驻守护进程

默认策略可能是：**若本机已有 `finclaw serve` 则优先走守护进程**，否则走内嵌路径。显式控制（以当前构建是否支持这些参数为准）：

- `finclaw chat --embedded` — 不使用常驻进程
- `finclaw chat --daemon` — 要求走守护进程；未运行则失败

若本机已有 **lazy 监督进程**（`finclaw serve --lazy`），`--daemon` 会走该 mux（按需启动或复用 profile worker），而不要求同一 profile 上另有一份 eager `serve`。以 `finclaw chat --help` 为准。

### 流式与会话级参数

一般默认**流式**输出；`--no-stream` 仅输出最终回复。

可选的一次性参数（见 `finclaw chat --help`）：

- `--user <id>` 或 `FINCLAW_USER_ID` —— 脚本/测试中稳定归因用户。
- `--auto-approve-all-tools` —— 本会话对 guarded 工具倾向「全自动批准」（与 `--confirm-all-tools` 互斥）；仅在策略与环境已符合信任模型时使用（[security-and-policies.zh.md](security-and-policies.zh.md)）。
- `--confirm-all-tools` —— 本会话要求对 guarded 工具走确认流程。

### 单次指定 capability

```bash
finclaw chat --capability read_only -m "用一段话说明本仓库目录结构。"
```

### 宿主姿态与策略

公开发布的二进制默认以**裸宿主**进程运行。用配置档**策略**与受监督审批收紧能力 — 见 [security-and-policies.zh.md](security-and-policies.zh.md)。IDE 权限 UI 见 [acp.zh.md](acp.zh.md)。

## 常驻服务

**自 v0.12.8 起**，不加额外参数的 `finclaw serve` 仍会启动**当前 profile**（eager 模式）。进程起来后 Claw 与 host shim 即可监听。

```bash
finclaw serve
```

默认为前台；Unix 上 `--background` 可脱离终端。见 `finclaw serve --help`。可与系统 `service`/`launchd` 或 `finclaw service`（若提供）一起使用。

### 监督 mux

`finclaw serve --lazy` 启动一个**不绑定 profile 的监督进程**，不会启动 Claw。它占用 home 槽位（`$FINCLAW_HOME/run/daemon.json` 中 `mode: lazy`，以及 `$FINCLAW_HOME/run/finclaw.pid`）。同一 home 只能跑 lazy mux **或** eager profile 守护进程，不能两者并存。

Worker 按需启动：

```bash
finclaw serve --lazy
# 另一个终端：
finclaw --profile default chat --daemon -m "你好"
```

`chat --daemon`（加上 `--profile` 或当前活动 profile）会请求 mux 启动或复用 `finclaw --profile <name> serve`。推理走该 worker。mux 本身不回答对话（mux 端口上的 `POST /ai/infer` 返回 409）。会 HTTP 的宿主可向 mux 监听端口 `POST /threads`，JSON 体带 `profile`；响应里含 worker 的 `claw_port`。

当 `daemon.json` 为 `mode: lazy` 时，`finclaw stop` 会向 mux 发信号（进而停止其 worker），即使某个 worker 已写入 profile pidfile。profile 守护进程不在时，`finclaw status` 会报告 mux（`mode: lazy`，并在可得时给出 worker 数量）。

以本机 `finclaw serve --help` 为准。

## 状态与停止

```bash
finclaw status
finclaw stop
```

在 lazy mux 下，`stop` 优先使用 home pidfile，从而关掉监督进程及其 worker，而不是单个 worker。若 lazy 启动失败是因为 eager 守护进程已占用 home，见 [troubleshooting.zh.md](troubleshooting.zh.md)。

## 诊断（运行 ledger）

```bash
finclaw diagnose last
```

## 日志

```bash
finclaw logs --help
```

可指定 CLI / Claw / Shim 等，依构建而定。

## 模型选择

```bash
finclaw model
finclaw model <model-id>
```

在交互式终端、且未在命令行写 model id 时，**与 `finclaw setup` 使用同一套**编号列表从内置目录中选模型（按 provider 过滤）。需已在配置中设置 `llm.provider`，或本次命令加 `--provider`；若尚未配置 provider，请先执行 `finclaw setup`。无 TTY 或显式给出 `<model-id>` 时则直接设置该 id。

**只读**打印内置目录（不写配置）：

```bash
finclaw model --list
finclaw model --list --json
```

## 历史记录

除 `list` / `show` / `search` 外，还支持会话接续、清理与统计：

```bash
finclaw history resume          # 选择器或 `--session …`
finclaw history prune --dry-run
finclaw history stats --json
```

参数与 `--user`、`prune` 确认等见 `finclaw history --help`。

```bash
finclaw cron --help
finclaw auth --help
```

## 工具列表与合同自检

- `finclaw tools` — 列出运行时登记的工具
- `finclaw conformance` — 合同/一致性相关（偏集成方）

## REPL 内 slash

在 `finclaw chat` 中输入 `/help` 查看**当前版本**支持的命令。与策略、profile、技能相关的见 [security-and-policies.zh.md](security-and-policies.zh.md)、[profiles.zh.md](profiles.zh.md)。

**A2A 委派：** `/ask <对端> <消息>`（别名 `/delegate`）引导智能体对 `a2a-agents.yaml` 中的对端调用 `a2a_send`。用 `finclaw a2a list|card|probe` 检查对端。完整步骤见 [a2a.zh.md](a2a.zh.md)。

## 回合后学习

**默认开启**（`mode: promote`）。普通 `finclaw chat` 可能在后台审阅并持久化记忆或 agent 技能。可用 `finclaw learning disable` / `set-mode stage` 调整。用新的 `--session` 测试跨会话召回。运维命令：`finclaw learning status`、`enable`、`disable`、`promote`、`reject`。

完整说明：[learning.zh.md](learning.zh.md)。

## 另见

- [getting-started.zh.md](getting-started.zh.md)
- [configuration.zh.md](configuration.zh.md)
- [learning.zh.md](learning.zh.md) — 自进化 / 学习循环
- [a2a.zh.md](a2a.zh.md) — 智能体互联（本地测试、入站 `serve`）
- [advanced.zh.md](advanced.zh.md)

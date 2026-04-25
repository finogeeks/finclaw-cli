# 对话、REPL、守护进程、日志与日常运维

**English:** [chat-and-operations.md](chat-and-operations.md)

## 对话模式

| 方式 | 命令 | 说明 |
| --- | --- | --- |
| 交互式 REPL | `finclaw chat` | 在 TTY 上通常支持多行输入与 slash 命令 |
| 一次性 | `finclaw chat -m "..."` | 得到回复后退出，适合脚本/CI |
| 实验性 TUI | `finclaw chat --tui` | 全屏界面；以 `--help` 为准 |

### 内嵌 与 常驻守护进程

默认策略可能是：**若本机已有 `finclaw serve` 则优先走守护进程**，否则走内嵌路径。显式控制（以当前构建是否支持这些参数为准）：

- `finclaw chat --embedded` — 不使用常驻进程
- `finclaw chat --daemon` — 要求走守护进程；未运行则失败

以 `finclaw chat --help` 为准。

### 流式输出

一般默认**流式**输出到终端；`--no-stream` 或帮助中等价项可只打最终消息。

### 单次指定 capability

```bash
finclaw chat --capability read_only -m "用一段话说明本仓库目录结构。"
```

## 常驻服务

```bash
finclaw serve
```

常见为前台运行 Claw 与 shim；`--background` 等见 `finclaw serve --help`。可与系统 `service`/`launchd` 或 `finclaw service`（若提供）一起使用。

## 状态与停止

```bash
finclaw status
finclaw stop
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

## 历史记录

```bash
finclaw history --help
```

## 定时与认证（偏运维）

```bash
finclaw cron --help
finclaw auth --help
```

## 工具列表与合同自检

- `finclaw tools` — 列出运行时登记的工具
- `finclaw conformance` — 合同/一致性相关（偏集成方）

## REPL 内 slash

在 `finclaw chat` 中输入 `/help` 查看**当前版本**支持的命令。与策略、profile、技能相关的见 [security-and-policies.zh.md](security-and-policies.zh.md)、[profiles.zh.md](profiles.zh.md)。

## 另见

- [getting-started.zh.md](getting-started.zh.md)
- [configuration.zh.md](configuration.zh.md)
- [advanced.zh.md](advanced.zh.md)

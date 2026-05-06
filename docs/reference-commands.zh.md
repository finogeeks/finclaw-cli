# 命令索引（速查）

**English:** [reference-commands.md](reference-commands.md)

以下为**导航**，非完整参数说明。完整选项务必使用 `finclaw --help` 与 `finclaw <子命令> --help`。

| 目的 | 入口命令 |
| --- | --- |
| 版本 / 构建 / 合同信息 | `finclaw version` |
| 健康检查、配置、沙箱提示 | `finclaw doctor`（`--fix` 可补全部分缺失文件，见 `--help`） |
| 运行 ledger 速览（最近 chat） | `finclaw diagnose last` |
| 帮助与补全语言 | `finclaw --locale <auto\|en\|zh>`（亦影响部分 CLI 文案） |
| 显式指定配置文件 | `finclaw --config <path>` · 环境变量 `FINCLAW_CONFIG` |
| 全局宿主执行沙箱 | `finclaw --security <isolated\|restricted\|yolo> …`（见 [security-and-policies.zh.md](security-and-policies.zh.md)） |
| 对话（REPL 或一次性） | `finclaw chat` · `finclaw chat -m "…"` |
| 常驻进程 | `finclaw serve` |
| 状态 / 停止 | `finclaw status` · `finclaw stop` |
| 读写 `config.yaml` | `finclaw config`（含 `check`、`migrate`、`env-path` 等，见 `--help`） |
| 引导式上手 | `finclaw setup` · `finclaw setup agent-profile`（profile 脚手架）· `finclaw setup llm` |
| 对话历史 | `finclaw history`（`list` / `show` / `search` / `resume` / `prune` / `stats`） |
| Shell 补全脚本 | `finclaw completion` |
| 凭据、令牌等 | `finclaw auth` |
| 定时任务 | `finclaw cron` |
| 技能（hub、ClawHub、安装） | `finclaw skills` |
| 工具注册表 | `finclaw tools` |
| 合同/一致性检查 | `finclaw conformance` |
| 重置本地状态（慎用） | `finclaw reset` |
| man 页生成 | `finclaw man` |
| systemd/launchd 单元辅助 | `finclaw service` |
| MCP stdio（可选编译特性） | `finclaw mcp` |
| 模型 id（交互时与 `finclaw setup` 相同的选择器）/ 目录只读列表 | `finclaw model` · `finclaw model --list`（`--json`） |
| 日志 | `finclaw logs` |
| Profile 管理 | `finclaw profile` |
| 策略与运行时同步 | `finclaw policy` |
| 人设 / identity 信封 | `finclaw identity`（`show` / `render` / `reset`） |
| 编辑智能体 Markdown（IDENTITY / SOUL / AGENT / TOOLS） | `finclaw agent edit <identity\|soul\|agent\|tools>` |
| 能力 / capability | `finclaw capability` |
| 备份 / 导入 | `finclaw backup` · `finclaw import` |
| 更新渠道说明 | `finclaw update` |
| 卸载 | `finclaw uninstall` |
| 首次 profile 初始化 | `finclaw init` |

**全局参数（各子命令通用）：** `--profile`、`-v`/`--verbose`、`-q`/`--quiet`、`--config`、`--security`、`--locale` — 见 `finclaw --help`。

**本仓库中的专题文档：**

- [getting-started.zh.md](getting-started.zh.md)
- [installation.zh.md](installation.zh.md)
- [configuration.zh.md](configuration.zh.md)
- [profiles.zh.md](profiles.zh.md)
- [security-and-policies.zh.md](security-and-policies.zh.md)
- [skills.zh.md](skills.zh.md)
- [chat-and-operations.zh.md](chat-and-operations.zh.md)
- [troubleshooting.zh.md](troubleshooting.zh.md)
- [advanced.zh.md](advanced.zh.md)

**线路与 API：** 以所部署的 Claw 运行时为准；需协议级说明时请查阅运维或厂商文档。

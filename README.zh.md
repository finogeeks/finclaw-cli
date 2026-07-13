<p align="center">
  <img src="assets/finclaw-wordmark.svg" width="560" alt="FINCLAW" />
</p>

# finclaw

[![GitHub release](https://img.shields.io/github/v/release/finogeeks/finclaw-cli?label=release&sort=semver)](https://github.com/finogeeks/finclaw-cli/releases)
![Platforms](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey)

**你的个人 AI Agent —— 终端里、IDE 里、Agent 之间。**

`finclaw` 是一个轻量、快速的 Rust CLI：单个二进制（约 20–30 MB）即可托管完整 Agent 运行时。在富交互 REPL 里聊天，通过 **[ACP](https://agentclientprotocol.com/)** 接入 **[Zed](https://zed.dev/)** 等编辑器，用 **A2A** 与其他 Agent 协作，并通过 **Hermes 风格的学习闭环** 沉淀记忆与技能 —— 运行工具本身不依赖 Node / Python。

| | |
| --- | --- |
| **English** | [README.md](README.md) |
| **中文** | *当前页* |

---

## 为什么选 finclaw？

| 你想要… | finclaw 提供… |
| --- | --- |
| 终端里可靠的编码 / 研究 Agent | 交互式 REPL + 一次性 `chat`、配置档、技能、MCP |
| 同一套 Agent 进编辑器 | **`finclaw acp`** — Agent Client Protocol，适配 Zed 等 ACP 客户端 |
| Agent 与 Agent 协作 | **A2A** 出站对等体（`a2a-agents.yaml` + `finclaw a2a` / `/ask`） |
| 用得越久越懂你 | **回合后学习**（默认开启）：写入记忆事实 + Agent 自写技能 |
| 干净的本地状态 | 按配置档隔离的 `~/.finclaw/` — 配置、技能、历史、密钥分开 |
| 安装与升级省心 | 一键安装 + `finclaw update`（GitHub Releases） |

本仓库是 `finclaw` 二进制的**官方公开入口**：安装脚本、用户文档与 [GitHub Releases](https://github.com/finogeeks/finclaw-cli/releases)。

---

## 能力速览

### 终端原生 Agent
- 一次性或交互聊天：`finclaw chat` / `finclaw chat -m "…"`
- 斜杠命令：会话控制、切模型、技能、A2A 引导等
- 可选常驻守护：`finclaw serve`

### IDE：ACP（Zed）
通过 stdio 使用 [Agent Client Protocol](https://agentclientprotocol.com/)。在 Zed 中把 `finclaw` 注册为自定义 Agent —— 提示词、工具权限 UI、取消、带历史的会话重开。详见 **[docs/acp.zh.md](docs/acp.zh.md)**。

### Agent 到 Agent（A2A）
在 `a2a-agents.yaml` 配置对等体，用 `finclaw a2a list|card|probe` 探活，在聊天里用 `/ask` / `/delegate` 引导模型。完整说明：**[docs/a2a.zh.md](docs/a2a.zh.md)**。

### 自学习（Hermes 风格）
足够轮次后，后台审阅可把**事实写入记忆**、把**流程写成技能**。默认 **`promote`**（直接写入）。可用 `stage` / `observe` 放缓，或 `finclaw learning disable`。指南：**[docs/learning.zh.md](docs/learning.zh.md)**。

### 技能与市场
从市场与公开源安装技能包，管理 Agent 自写技能。指南：**[docs/skills.zh.md](docs/skills.zh.md)**。

### 配置档与策略
模板（`general` / `coder` / `researcher`）、按档策略、身份与能力。指南：**[docs/profiles.zh.md](docs/profiles.zh.md)**、**[docs/security-and-policies.zh.md](docs/security-and-policies.zh.md)**。

---

## 快速安装

**平台：** macOS（arm64 / x86_64）、Linux（x86_64 glibc）、Windows（Releases 提供 x86_64 MSVC 压缩包）。一键安装脚本覆盖 macOS / Linux；Windows 请从 Releases 下载，或使用 WSL2。

```bash
curl -fsSL https://raw.githubusercontent.com/finogeeks/finclaw-cli/main/install.sh | sh
```

将 `$HOME/.local/bin` 加入 `PATH`，然后：

```bash
finclaw --version
```

**细节：** [docs/installation.zh.md](docs/installation.zh.md)（手动下载、校验和、`finclaw update`）。

---

## 前五分钟

```bash
finclaw init          # 创建 ~/.finclaw 配置档（可用 mock LLM 冒烟）
finclaw setup         # 引导配置 LLM 提供商 / 模型（或手改 config.yaml）
finclaw doctor        # 自检
finclaw chat          # 交互 REPL
# 或：
finclaw chat -m "总结一下你能做什么"
```

学习默认**开启**（`mode: promote`）。随时查看或调整：

```bash
finclaw learning status
finclaw learning set-mode stage    # 写入前先审阅
finclaw learning disable           # 关闭学习闭环
```

---

## 在 Zed 中使用（ACP）

1. 安装 `finclaw` 并保证在 `PATH` 中（或记下绝对路径）。
2. 初始化配置档（一次即可）：

   ```bash
   finclaw init --non-interactive
   # 或独立数据目录：
   finclaw --finclaw-home "$HOME/.finclaw-zed" init --non-interactive
   finclaw --finclaw-home "$HOME/.finclaw-zed" setup
   ```

3. 在 Zed 中添加**自定义外部 Agent**：
   - **命令：** `finclaw` 的绝对路径（例如 `/Users/you/.local/bin/finclaw`）
   - **参数：**

     ```text
     --profile default acp
     ```

     若使用独立 home：

     ```text
     --finclaw-home /Users/you/.finclaw-zed --profile default acp
     ```

4. 打开 Agent 线程并发送提示。受监督的工具会走 Zed 权限 UI；重新打开线程可通过 `session/load` 恢复历史。

**完整说明（权限、取消、工作目录、限制）：** [docs/acp.zh.md](docs/acp.zh.md)

> **说明：** 工具由 FinClaw **配置档**（以及你为 FinClaw 配置的 MCP）提供。IDE 通过 ACP 传入的客户端 `mcpServers` 会被**拒绝** —— 请在 FinClaw 侧配置工具，而不是为每次编辑器会话挂接任意 MCP 进程。

---

## A2A 一瞥

```bash
# 在当前配置档下编辑对等体后：
finclaw a2a list
finclaw a2a card <peer-id>
finclaw a2a probe <peer-id>
```

聊天 REPL 中：`/ask <peer> <message>` 会引导模型走 outbound A2A。见 [docs/a2a.zh.md](docs/a2a.zh.md) 与本地 mock：[`examples/mock-a2a-peer.py`](examples/mock-a2a-peer.py)。

---

## 文档

最终用户所需内容**都在本仓库**。总目录：**[docs/README.md](docs/README.md)**。

| 主题 | English | 中文 |
| --- | --- | --- |
| **总目录** | [docs/README.md](docs/README.md) | 中英对照表 |
| 快速开始 | [getting-started.md](docs/getting-started.md) | [getting-started.zh.md](docs/getting-started.zh.md) |
| 安装与更新 | [installation.md](docs/installation.md) | [installation.zh.md](docs/installation.zh.md) |
| 配置 | [configuration.md](docs/configuration.md) | [configuration.zh.md](docs/configuration.zh.md) |
| 配置档与备份 | [profiles.md](docs/profiles.md) | [profiles.zh.md](docs/profiles.zh.md) |
| 安全与策略 | [security-and-policies.md](docs/security-and-policies.md) | [security-and-policies.zh.md](docs/security-and-policies.zh.md) |
| 技能 | [skills.md](docs/skills.md) | [skills.zh.md](docs/skills.zh.md) |
| 回合后学习 | [learning.md](docs/learning.md) | [learning.zh.md](docs/learning.zh.md) |
| 聊天与运维 | [chat-and-operations.md](docs/chat-and-operations.md) | [chat-and-operations.zh.md](docs/chat-and-operations.zh.md) |
| **ACP / Zed** | [acp.md](docs/acp.md) | [acp.zh.md](docs/acp.zh.md) |
| Agent 到 Agent（A2A） | [a2a.md](docs/a2a.md) | [a2a.zh.md](docs/a2a.zh.md) |
| 命令索引 | [reference-commands.md](docs/reference-commands.md) | [reference-commands.zh.md](docs/reference-commands.zh.md) |
| 排错 | [troubleshooting.md](docs/troubleshooting.md) | [troubleshooting.zh.md](docs/troubleshooting.zh.md) |
| 进阶 | [advanced.md](docs/advanced.md) | [advanced.zh.md](docs/advanced.zh.md) |

**以本机帮助为准：** `finclaw --help`、`finclaw <cmd> --help`。需要固定语言可用 `--locale en|zh`。

---

## 诚实默认值（请读）

- **执行：** CLI 默认**不带内置 OS 沙箱**（“裸宿主”）。策略文件（exec / HTTP / 工具调用）与受监督审批仍然生效。见 [security-and-policies.zh.md](docs/security-and-policies.zh.md)。
- **学习：** 默认开启，模式为 `promote`。需要更慢或更安静时用 `stage` / `observe` / `disable`。
- **ACP：** 强 IDE 互操作；**不声称**完整 ACP v1 符合性（见 [acp.zh.md](docs/acp.zh.md)）。

---

## 问题与支持

请用 [issue 模板](https://github.com/finogeeks/finclaw-cli/issues/new/choose) 反馈，并附上 `finclaw version` 与操作系统信息。

---

## 许可

**已发布二进制**的许可以各 [GitHub Release](https://github.com/finogeeks/finclaw-cli/releases) 及压缩包内 `LICENSE` / 声明为准。本 README 不覆盖那些条款。

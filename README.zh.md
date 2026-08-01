<p align="center">
  <img src="assets/finclaw-wordmark.svg" width="560" alt="FINCLAW" />
</p>

# 点对点。无需自建服务器。不同电脑上的 Agent 用 A2A 互聊。

**finclaw** — [![GitHub release](https://img.shields.io/github/v/release/finogeeks/finclaw-cli?label=release&sort=semver)](https://github.com/finogeeks/finclaw-cli/releases)
![Platforms](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey)
![P2P](https://img.shields.io/badge/peer--to--peer-no%20server%20needed-0A7A3E)
![A2A](https://img.shields.io/badge/protocol-A2A-informational)

在你的电脑和朋友的电脑上各装一份 `finclaw` —— 两个个人 Agent、两台 PC，
**不需要云端 Agent 中转，也不必自己挂一个公网地址**。交换一张短暂的
**共享票据（share ticket）**，双方 **点对点** 连通，对话仍走标准
**[A2A](docs/a2a.zh.md)**（Agent Card + JSON-RPC）。若已在同一局域网，也可直接用
HTTP 上的 A2A。

同时：轻量 Rust CLI（约 20–30 MB）支持终端聊天、经
**[ACP](https://agentclientprotocol.com/)** 接入 **[Zed](https://zed.dev/)**、
技能与 Hermes 风格学习闭环 —— 运行工具本身不依赖 Node / Python。

| | |
| --- | --- |
| **English** | [README.md](README.md) |
| **中文** | *当前页* |

---

## 为什么选 finclaw？

| 你想要… | finclaw 提供… |
| --- | --- |
| **电脑 A 上的 finclaw ↔ 电脑 B 上的 finclaw** | **点对点** `finclaw share` — 票据进、A2A 出；**无需自建服务器 / 公网端口** |
| 同一局域网 / VPN | **A2A over HTTP** — `serve` + `a2a-agents.yaml`，`/ask` / `/delegate` |
| 终端里可靠的编码 / 研究 Agent | 交互式 REPL、可选全屏 `--tui`、一次性 `chat`、配置档、技能、MCP |
| 同一套 Agent 进编辑器 | **`finclaw acp`** — Agent Client Protocol，适配 Zed 等 ACP 客户端 |
| 用得越久越懂你 | **回合后学习**（默认开启）：写入记忆事实 + Agent 自写技能 |
| 干净的本地状态 | 按配置档隔离的 `~/.finclaw/` — 配置、技能、历史、密钥分开 |
| 安装与升级省心 | 一键安装 + `finclaw update`（GitHub Releases） |

本仓库是 `finclaw` 二进制的**官方公开入口**：安装脚本、用户文档与 [GitHub Releases](https://github.com/finogeeks/finclaw-cli/releases)。

---

## 能力速览

### 不同电脑上的点对点 Agent（A2A）

**差异化：** 两台机器上的 finclaw 可以直接互相委托，**不必先搭一套 Agent
服务器**。协议仍是 **A2A**；没有公网 HTTP 时，用 `finclaw share` 解决可达性。

```text
电脑 A:  finclaw serve  +  finclaw share offer   ──票据──►  电脑 B:  finclaw share redeem
                                                              └─► 本机 A2A ──► /ask
```

| 路径 | 何时 | 你怎么跑 |
| --- | --- | --- |
| **对端共享** | 不同 PC、无公网服务器 | `share offer` / `redeem` → 把 `local_a2a_base` 写入 `a2a-agents.yaml` |
| **HTTP** | 同一局域网 / 已知 URL | `finclaw serve` + 在 `a2a-agents.yaml` 填对端 URL |

- 探活：`finclaw a2a list|card|probe` · 聊天：`/ask` / `/delegate`
- 实验：[`examples/two-agent-a2a/`](examples/two-agent-a2a/) · 指南：**[docs/a2a.zh.md](docs/a2a.zh.md)**

### 终端原生 Agent
- 一次性或交互聊天：`finclaw chat` / `finclaw chat -m "…"`
- 可选全屏 TUI：`finclaw chat --tui`（实验性；同一 Agent，ratatui 界面）
- 斜杠命令：会话控制、切模型、技能、A2A 引导等
- 可选常驻守护：`finclaw serve`

### IDE：ACP（Zed）
通过 stdio 使用 [Agent Client Protocol](https://agentclientprotocol.com/)。在 Zed 中把 `finclaw` 注册为自定义 Agent —— 提示词、工具权限 UI、取消、带历史的会话重开。详见 **[docs/acp.zh.md](docs/acp.zh.md)**。

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
finclaw share status   # 正式版二进制默认包含对端共享（v0.11+）
```

**细节：** [docs/installation.zh.md](docs/installation.zh.md)（手动下载、校验和、`finclaw update`）。

---

## 前五分钟

```bash
finclaw init          # 创建 ~/.finclaw 配置档（可用 mock LLM 冒烟）
finclaw setup         # 引导配置 LLM 提供商 / 模型（或手改 config.yaml）
finclaw doctor        # 自检
finclaw chat          # 行式交互 REPL
finclaw chat --tui    # 可选全屏 TUI（实验性）
# 或：
finclaw chat -m "总结一下你能做什么"
```

### 接着试 Agent 互调

**仅出站（无需第二个 finclaw）：** 跑 mock 对端，把 `a2a-agents.yaml` 指过去，再 `finclaw a2a probe` / `/ask` — 见 [docs/a2a.zh.md](docs/a2a.zh.md#快速上手在本地测试-a2a建议第一步)。

**两个真实 Agent（先 HTTP，再对端共享）：**

```bash
cd examples/two-agent-a2a
bash scripts/00-prepare-homes.sh
bash scripts/01-start-callee.sh
bash scripts/02-http-smoke.sh          # 本机 HTTP 上的 A2A
# 可选对端共享（offer/redeem 需保持运行）：
bash scripts/03-p2p-offer.sh
bash scripts/04-p2p-redeem-smoke.sh
```

学习默认**开启**（`mode: promote`）。随时查看或调整：

```bash
finclaw learning status
finclaw learning set-mode stage    # 写入前先审阅
finclaw learning disable           # 关闭学习闭环
```

---

## A2A 一瞥

**不同电脑、不自建服务器：** 交换 share 票据。**同一局域网：** 直接 A2A HTTP。

```bash
# 对端共享（A 端 offer，B 端 redeem）— 无需公网入站端口
finclaw share status
finclaw share doctor --upstream http://127.0.0.1:PORT
# A:  finclaw share offer --upstream http://127.0.0.1:PORT --bearer TOKEN --json
# B:  finclaw share redeem --ticket '…' --json
#     → 把 local_a2a_base + grant bearer 写入 a2a-agents.yaml（或 --write-agents-yaml）

# 已有可达 URL 时的 HTTP 对等体
finclaw a2a list
finclaw a2a card <peer-id>
finclaw a2a probe <peer-id>
```

聊天里：`/ask <peer> <message>`。局域网 HTTP 与对端共享后工具面相同。详见 [docs/a2a.zh.md](docs/a2a.zh.md)、[`examples/two-agent-a2a/`](examples/two-agent-a2a/)、mock [`examples/mock-a2a-peer.py`](examples/mock-a2a-peer.py)。

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
| **A2A（HTTP + 对端共享）** | [a2a.md](docs/a2a.md) | [a2a.zh.md](docs/a2a.zh.md) |
| 命令索引 | [reference-commands.md](docs/reference-commands.md) | [reference-commands.zh.md](docs/reference-commands.zh.md) |
| 排错 | [troubleshooting.md](docs/troubleshooting.md) | [troubleshooting.zh.md](docs/troubleshooting.zh.md) |
| 进阶 | [advanced.md](docs/advanced.md) | [advanced.zh.md](docs/advanced.zh.md) |

**以本机帮助为准：** `finclaw --help`、`finclaw <cmd> --help`。需要固定语言可用 `--locale en|zh`。

---

## 诚实默认值（请读）

- **执行：** CLI 默认**不带内置 OS 沙箱**（“裸宿主”）。策略文件（exec / HTTP / 工具调用）与受监督审批仍然生效。见 [security-and-policies.zh.md](docs/security-and-policies.zh.md)。
- **对端共享：** 自 **v0.11** 起正式版默认包含。**不必自建 Agent 服务器** — 两台 PC 交换票据即可点对点走 A2A。票据与 grant 是密钥；双方需保持在线；redeem 结束后本机对等 URL 会失效。
- **学习：** 默认开启，模式为 `promote`。需要更慢或更安静时用 `stage` / `observe` / `disable`。
- **ACP：** 强 IDE 互操作；**不声称**完整 ACP v1 符合性（见 [acp.zh.md](docs/acp.zh.md)）。

---

## 问题与支持

请用 [issue 模板](https://github.com/finogeeks/finclaw-cli/issues/new/choose) 反馈，并附上 `finclaw version` 与操作系统信息。

---

## 许可

**已发布二进制**的许可以各 [GitHub Release](https://github.com/finogeeks/finclaw-cli/releases) 及压缩包内 `LICENSE` / 声明为准。本 README 不覆盖那些条款。

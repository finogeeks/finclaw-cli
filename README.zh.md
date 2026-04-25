<p align="center">
  <img src="assets/finclaw-wordmark.svg" width="560" alt="FINCLAW" />
</p>

# finclaw

[![GitHub release](https://img.shields.io/github/v/release/finogeeks/finclaw-cli?label=release&sort=semver)](https://github.com/finogeeks/finclaw-cli/releases)
![支持平台 macOS 与 Linux](https://img.shields.io/badge/平台-macOS%20%7C%20Linux-lightgrey)

**以 Rust 实现、体积极小、追求高性能的终端 CLI**：默认可为 strip 后**单文件二进制约 20 MB 量级**，静态链接，运行**不依赖 Node / Python**。

**能力概览：** 在 **Claw** 智能体运行时之上工作（公开线路合同见 [`finclaw-contract`](https://github.com/Geeksfino/finclaw-contract)）— 支持交互式 REPL、slash 命令、本机 **profile** 与可选的常驻 **`finclaw serve`**。

本仓库是 `finclaw` 的**官方发布与文档站点**；**正式构建**在 [GitHub Releases](https://github.com/finogeeks/finclaw-cli/releases) 提供。

| | |
| --- | --- |
| **English** | [README.md](README.md) |
| **中文** | *当前页面* |

## 文档

用户文档**全部位于本公开仓库**（**无需**访问任何私有源码库）。完整索引见 **[docs/README.md](docs/README.md)**（各专题均含中、英文档）。

| 专题 | English | 中文 |
| --- | --- | --- |
| **总索引** | [docs/README.md](docs/README.md) | 索引内双语对照 |
| 快速上手 | [docs/getting-started.md](docs/getting-started.md) | [docs/getting-started.zh.md](docs/getting-started.zh.md) |
| 安装与更新 | [docs/installation.md](docs/installation.md) | [docs/installation.zh.md](docs/installation.zh.md) |
| 配置 | [docs/configuration.md](docs/configuration.md) | [docs/configuration.zh.md](docs/configuration.zh.md) |
| Profile 与备份 | [docs/profiles.md](docs/profiles.md) | [docs/profiles.zh.md](docs/profiles.zh.md) |
| 安全与策略 | [docs/security-and-policies.md](docs/security-and-policies.md) | [docs/security-and-policies.zh.md](docs/security-and-policies.zh.md) |
| 技能 | [docs/skills.md](docs/skills.md) | [docs/skills.zh.md](docs/skills.zh.md) |
| 对话与运维 | [docs/chat-and-operations.md](docs/chat-and-operations.md) | [docs/chat-and-operations.zh.md](docs/chat-and-operations.zh.md) |
| 命令索引 | [docs/reference-commands.md](docs/reference-commands.md) | [docs/reference-commands.zh.md](docs/reference-commands.zh.md) |
| 排错 | [docs/troubleshooting.md](docs/troubleshooting.md) | [docs/troubleshooting.zh.md](docs/troubleshooting.zh.md) |
| 高级（补全、man、可选特性） | [docs/advanced.md](docs/advanced.md) | [docs/advanced.zh.md](docs/advanced.zh.md) |
| 文档维护说明（贡献者） | [docs/MAINTENANCE.md](docs/MAINTENANCE.md) | 英文（贡献者通用） |

**权威参数说明**仍以本机 `finclaw --help` 与子命令 `--help` 为准。

## 快速安装

**适用环境：** macOS、Linux、**WSL2** 下 glibc Linux；**当前发布不含原生 Windows `.exe`**。

```bash
curl -fsSL https://raw.githubusercontent.com/finogeeks/finclaw-cli/main/install.sh | sh
```

安装后把 `$HOME/.local/bin`（或自定义目录）加入 `PATH`，执行 `finclaw --version`。

**详情：** [docs/installation.zh.md](docs/installation.zh.md)（手动下载、校验、解压、升级）。

## 首次运行

```text
finclaw init
finclaw setup
finclaw doctor
finclaw chat
finclaw --help
```

**一次性对话：** `finclaw chat -m "你好"` · **大模型配置：** [docs/getting-started.zh.md](docs/getting-started.zh.md)

## 许可

**已发布二进制** 的许可与再分发条件以各 **GitHub Release** 页面及随包 `LICENSE` 为准；本 README 不替代发版条款。

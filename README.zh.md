<p align="center">
  <img src="assets/finclaw-wordmark.svg" width="560" alt="FINCLAW" />
</p>



# finclaw

[![GitHub release](https://img.shields.io/github/v/release/finogeeks/finclaw-cli?label=release&sort=semver)](https://github.com/finogeeks/finclaw-cli/releases)
![支持平台 macOS 与 Linux](https://img.shields.io/badge/平台-macOS%20%7C%20Linux-lightgrey)

**以 Rust 实现、体积极小、追求高性能的终端 CLI**：默认发布为经过 strip 的**单个二进制，约 20 MB 量级**，静态链接，运行**不依赖 Node / Python**。上方 **FINCLAW** 头图使用了与彩色终端下 `finclaw chat` 一致的主题渐变色。

**能力概览：** 在 **Claw** 智能体运行时之上工作（公开线路合同见 [`finclaw-contract`](https://github.com/Geeksfino/finclaw-contract)）— 支持交互式 REPL、slash 命令、本机 **profile（配置隔离）**，以及可选的**常驻** `finclaw serve` 模式。

本仓库是 `finclaw` 的**公开下载与发版地址**。主工程在私有单仓中开发；**正式构建**发布在 [GitHub Releases](https://github.com/finogeeks/finclaw-cli/releases)，**无需拉取源码**即可安装。

| | |
| --- | --- |
| **English** | [README.md](README.md) |
| **中文** | *当前页面* |

### 文档

| | |
| --- | --- |
| **Getting started（英文完整上手指南）** | [docs/getting-started.md](docs/getting-started.md) |
| **上手指南（安装、大模型、校验）** | [docs/getting-started.zh.md](docs/getting-started.zh.md) |
| **技能（`finclaw skills`、hub、安装/校验）** — 主仓库用户文档（英文） | <https://github.com/Geeksfino/finclaw/blob/main/docs/agent/managing-skills-with-finclaw.md> |

---

## 你能得到什么

| | |
| --- | --- |
| **轻量 Rust 单文件、低负担** | 原生机器码、磁盘占用约 **20 MB** 量级、交互路径短，适合长驻终端日常使用。 |
| **真·终端体验** | 无 `-m` 时进入交互式 REPL：多行输入、内联帮助、以及 slash 命令。 |
| **Profile 优先** | 使用 `~/.finclaw/profiles/<name>/` 做隔离，涵盖模板、技能、策略与身份，并支持备份/导入等分享工作流。 |
| **Claw 后端** | 与 Finclaw 生态中工具、技能、策略等合同一致；单二进制按宿主设计连接内嵌或远程 Claw。 |
| **多种运行方式** | **一次性**（`finclaw chat -m "…"`）· **REPL**（`finclaw chat`）· **常驻**（`finclaw serve`）。 |
| **偏运维/工程向** | `doctor`、`version`、各 shell 的 completion 生成、以及可预期的更新说明 — 适合先读 `--help` 再动手的人。 |

---

## 快速安装

**适用环境：** macOS、Linux，以及在 **WSL2** 下的 glibc Linux（如常见 Ubuntu 发行版）。**当前发布矩阵不含原生 Windows `.exe`**，请在 WSL2 内使用 `*-unknown-linux-gnu` 包，或在 macOS/Linux 原生使用。

**一行命令**（按机器解析最新或指定版本、拉取 `*.tar.zst`、在发布物提供时校验 `SHA256SUMS`、默认安装到 `$HOME/.local/bin`）：

```bash
curl -fsSL https://raw.githubusercontent.com/finogeeks/finclaw-cli/main/install.sh | sh
```

若对应 tag 已存在 **install.sh**，建议将脚本**固定到该 tag**（更可复现）：

```bash
curl -fsSL https://raw.githubusercontent.com/finogeeks/finclaw-cli/v0.1.0/install.sh | sh
```

通过管道向 `sh` 传参：

```bash
curl -fsSL https://raw.githubusercontent.com/finogeeks/finclaw-cli/main/install.sh | sh -s -- --version 0.1.0
```

或使用环境变量（与 `install.sh` 说明一致）：

```bash
curl -fsSL https://raw.githubusercontent.com/finogeeks/finclaw-cli/main/install.sh \
  | env FINCLAW_VERSION=0.1.0 FINCLAW_INSTALL_DIR="$HOME/.local/bin" sh
```

`FINCLAW_INSECURE_SKIP_CHECKSUM=1` 仅作**应急**跳过校验，正常发布**不建议**使用。

**安装后：**

```bash
source ~/.zshrc    # 或: source ~/.bashrc
finclaw --version
```

---

## 首次上手（四条命令）

```text
finclaw init        # 首次：资料目录、模板与初始配置
finclaw doctor      # 配置好 LLM 后做一次健康检查
finclaw chat        # 进入 REPL（不要带 -m）
finclaw --help      # 子命令全览；各子命令另有 --help
```

**单轮对话**（适合脚本/CI，得到回复后退出）：

```bash
finclaw chat -m "你好，finclaw"
```

**需要常驻服务时**（本机长进程）：

```bash
finclaw serve
```

**大模型与 Key：** 内建 mock 适合冒烟；真实调用需配置 **provider、model、API key**（及可选 `base_url`）。步骤与优先级见 **[上手指南](docs/getting-started.zh.md)**（`finclaw config set`、环境变量、`~/.finclaw/.env`）。改完后可运行 `finclaw doctor`、`finclaw config check`。

---

## 命令速查

| 想做的事 | 从这儿开始 |
| --- | --- |
| 看构建/合同信息 | `finclaw version` |
| 自检、配置与沙箱提示 | `finclaw doctor` |
| 在终端里和智能体聊 | `finclaw chat`（REPL）或 `finclaw chat -m "…"` |
| 切换或查看模型 | `finclaw model` / `finclaw model <id>` |
| 管理 profile | `finclaw profile --help` |
| 策略与身份 | `finclaw policy --help` · `finclaw identity --help` |
| Shell 补全 | `finclaw completion bash`（亦支持 zsh、fish、elvish、PowerShell 等） |
| 看日志 | `finclaw logs --help` |
| 查公开升级渠道 | `finclaw update`（多数产品形态下偏**提示+下载说明**；是否自动覆盖二进制以**发行说明**为准） |
| 卸载/清理本机数据 | `finclaw uninstall` |

以 `finclaw --help` 与 `finclaw <子命令> --help` 为准。

---

## 手动下载（完全可控）

1. 打开 **[Releases](https://github.com/finogeeks/finclaw-cli/releases)**，选择版本（如 `v0.1.0`）。
2. 下载**对应本机架构**的压缩包，以及 **`SHA256SUMS`**。
3. 校验通过后再解包、安装 `finclaw` 到 `PATH` 中的目录。

| 发布文件 | 适用场景 |
| --- | --- |
| `finclaw-v<version>-aarch64-apple-darwin.tar.zst` | Apple 芯片 macOS |
| `finclaw-v<version>-x86_64-apple-darwin.tar.zst` | Intel 芯片 macOS |
| `finclaw-v<version>-x86_64-unknown-linux-gnu.tar.zst` | Linux x86_64；多数 WSL2 环境选此 |
| `SHA256SUMS` | 建议始终下载并执行校验 |
| `release.json` | 元数据，可选 |

**校验** — 若失败，**不要运行**二进制，请从 Release 页重新下载。

`SHA256SUMS` 中列出**所有平台**的压缩包。你一般只下载**其中一个** `*.tar.zst`，因此**不要**对整份 `SHA256SUMS` 直接执行 `shasum -a 256 -c` 或 `sha256sum -c`（会去找其它平台文件并报错）。只校验**你下载文件对应的一行**，例如（按实际 `VER` 与 `FILE` 修改）：

```bash
cd ~/Downloads
VER=0.1.0
FILE="finclaw-v${VER}-aarch64-apple-darwin.tar.zst"
grep -F "$FILE" SHA256SUMS | shasum -a 256 -c -
```

Linux 上亦可用同一条 `grep` 后接 `sha256sum -c`（若你更习惯 `sha256sum`）。

**解压依赖：** `tar` 与 `zstd`（格式为 `*.tar.zst`）。

示例（Apple 芯片，请把 `VER` 与文件名换成你的实际包名）：

```bash
VER=0.1.0
FILE="finclaw-v${VER}-aarch64-apple-darwin.tar.zst"
zstd -dc "$FILE" | tar -xf -
```

部分发行版上也可：

```bash
tar --zstd -xf "finclaw-v${VER}-x86_64-unknown-linux-gnu.tar.zst"
```

**安装二进制**（目录名以包内实际为准）：

```bash
install -m 0755 "finclaw-v${VER}-aarch64-apple-darwin/finclaw" "$HOME/.local/bin/finclaw"
```

**PATH**（若提示找不到命令）：

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc   # 或 ~/.bashrc
export PATH="$HOME/.local/bin:$PATH"
```

### 平台与安全提示

- **macOS** — 未签名/未公证的二进制可能触发 **Gatekeeper**；若被拦截，在 **系统设置 → 隐私与安全性** 中按提示允许，或改用企业签/组织内发版包。
- **Windows** — 目前**不**在矩阵内提供独立 `.exe`；请使用 **WSL2 + Linux 包**，或 macOS/Linux 原生，直到出现 Windows 目标产物（如 `*-pc-windows-msvc`）。

### 本机数据（摘要）

- 默认根目录：`~/.finclaw`（或环境变量 `FINCLAW_HOME`）。
- **Profile** 即其下的一个隔离环境；首次运行常由 `finclaw init` 建立默认 `default`（以实际 `init` 行为为准）。

### 升级

**Releases** 出现新版本时：**重新下载**本机对应包，**再次校验** `SHA256SUMS`，**覆盖**本地 `finclaw`。`update` 子命令多数情况下用于**说明渠道与升级步骤**；除非你的发行说明明确写「自动原地更新」，否则不要默认假设会默默替换二进制。

### 支持渠道

- **下载失败、包损坏、校验不过、无法解压**：请在 **[Issues](https://github.com/finogeeks/finclaw-cli/issues)** 中反馈，并附上**版本号**、**文件名**、**操作系统与 CPU 架构**（例如 `macOS 15, arm64` 或 `Ubuntu 24.04, x86_64`）。
- **产品行为、智能体能力、与私有部署或商业支持相关的问题**：若你们有**内部分发/工单渠道**，以该渠道为准；本公开仓库以**发版与安装**为主。

---

## 许可

你下载的**二进制**的许可、再分发与商标条款，以对应 **GitHub Release** 页面及包内 `LICENSE` / 说明文件为准，本页文字**不能替代**其法律含义。

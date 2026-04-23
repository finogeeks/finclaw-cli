# finclaw CLI（二进制发布说明）

本仓库是 `finclaw` 命令行工具的**公开下载发布仓库**。应用源码在私有的主仓库中开发；**构建产物发布在本仓库的 GitHub Releases**，方便最终用户**无需拉取源码**即可安装使用。

- **English** — 见 [`README.md`](README.md)  
- **中文（本页）** — 你正在阅读的就是中文版

## 0）一行命令安装（`install.sh`）

本仓库提供 [`install.sh`](install.sh)：一个尽量兼容的 POSIX `sh` 安装脚本，会：

- 自动解析 **latest** 发布（或你指定的版本号）
- 按当前系统/架构选择正确的 `*.tar.zst`
- 在发布物包含时校验 `SHA256SUMS`
- 默认把 `finclaw` 安装到 `$HOME/.local/bin`

从 `main` 分支拉取并执行（始终使用本仓库 `main` 上最新的 `install.sh`）：

```bash
curl -fsSL https://raw.githubusercontent.com/finogeeks/finclaw-cli/main/install.sh | sh
```

当对应 tag 已存在后，推荐“固定到某个已发布版本”的脚本（更可复现）：

```bash
curl -fsSL https://raw.githubusercontent.com/finogeeks/finclaw-cli/v0.1.0/install.sh | sh
```

因为使用了管道，需要通过 `sh` 转发参数：

```bash
curl -fsSL https://raw.githubusercontent.com/finogeeks/finclaw-cli/main/install.sh | sh -s -- --version 0.1.0
```

或者使用环境变量：

```bash
curl -fsSL https://raw.githubusercontent.com/finogeeks/finclaw-cli/main/install.sh \
  | env FINCLAW_VERSION=0.1.0 FINCLAW_INSTALL_DIR="$HOME/.local/bin" sh
```

如确有需要，可设置 `FINCLAW_INSECURE_SKIP_CHECKSUM=1` **跳过**校验（不推荐，仅应急）。

## 1）如何手动下载并获取首个二进制

1. 打开 **Releases** 页面：`https://github.com/finogeeks/finclaw-cli/releases`
2. 选择一个版本（通常标签为 `v0.1.0` 这种形式）。
3. 下载**对应你平台**的压缩包，并同时下载校验文件：
   - `finclaw-v<version>-x86_64-unknown-linux-gnu.tar.zst`（Linux x86_64；在大多数 WSL2 发行版上也适用）
   - `finclaw-v<version>-x86_64-apple-darwin.tar.zst`（Intel 芯片 macOS）
   - `finclaw-v<version>-aarch64-apple-darwin.tar.zst`（Apple 芯片 macOS）
   - `SHA256SUMS`（强烈建议下载并校验）
   - `release.json`（元数据；可选，不影响安装）

> **目前 Releases 不提供原生 Windows 的 `*.exe`。** 在 Windows 上请使用 **WSL2** 搭配常见的 glibc Linux（如 Ubuntu），并安装 **Linux** 压缩包；或在 macOS/Linux 上原生运行。

### 校验下载内容是否完整、未被篡改

macOS 通常自带 `shasum`：

```bash
cd ~/Downloads
shasum -a 256 -c SHA256SUMS
```

大多数 Linux 发行版使用 GNU `coreutils`：

```bash
cd ~/Downloads
sha256sum -c SHA256SUMS
```

**校验失败请不要运行二进制**，请从 Release 页面重新下载。

## 2）在本地安装与初始化配置

先决条件：

- 终端环境（macOS / Linux 终端；或 Windows 上的 Linux 子系统）
- 已安装 `tar` 和 `zstd`（`*.tar.zst` 格式需要 `zstd` 解压/解包）

### 解压缩发布包

压缩包内目录结构固定为：

- `finclaw-v<version>-<target>/finclaw`

以 Apple Silicon 的 macOS 为例（请把 `VER` 与文件名改成你实际下载的版本/架构）：

```bash
VER=0.1.0
FILE="finclaw-v${VER}-aarch64-apple-darwin.tar.zst"
zstd -dc "$FILE" | tar -xf -
```

在部分支持 `--zstd` 的 `tar` 上也可以：

```bash
tar --zstd -xf "finclaw-v${VER}-x86_64-unknown-linux-gnu.tar.zst"
```

### 将 `finclaw` 安装到 `PATH`（用户目录，无需 root）

将下面目录名替换为你实际解包出来的目录名。

```bash
install -m 0755 "finclaw-v${VER}-aarch64-apple-darwin/finclaw" "$HOME/.local/bin/finclaw"
```

确保 shell 能找到它（示例）：

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc   # 或 ~/.bashrc
export PATH="$HOME/.local/bin:$PATH"
```

验证安装：

```bash
finclaw --version
```

### 第一次配置（资料目录在 `~/.finclaw`）

`finclaw` 默认把本机数据放在 `~/.finclaw/`（如果你设置了 `FINCLAW_HOME`，则使用该目录）。其中每个隔离环境称为 **profile**（默认名通常是 `default`）。

运行交互式初始化：

```bash
finclaw init
```

也支持非交互/脚本化参数；详见：

```bash
finclaw init --help
```

要调用**真实大模型**通常需要配置 **LLM 提供商 API Key/endpoint** 等信息。你使用的发行方一般会提供“如何配置”的说明文档；在本地完成配置后，也可以运行 `finclaw doctor` 做基础自检。

**macOS 安全提示：** 未签名/未公证的二进制可能触发 Gatekeeper 拦截。如果无法直接运行，请在 **系统设置 → 隐私与安全性** 中按提示允许，或改用你们公司提供的已签名包。

**Windows 说明：** 如果不使用 WSL，目前原生 Windows 可执行文件不在发布矩阵中，请先以 WSL2 使用 Linux 包（直到发布 `*-pc-windows-msvc` 等 Windows 目标产物）。

## 3）基本用法（每天最常用的命令）

查看帮助与命令列表：

```bash
finclaw --help
finclaw <子命令> --help
```

健康检查/版本信息：

```bash
finclaw version
finclaw doctor
```

一次对话（发一条消息，拿到回复就退出；适合脚本）：

```bash
finclaw chat -m "你好，finclaw"
```

进入交互式 REPL（不携带 `--message` 时）：

```bash
finclaw chat
```

在适合的生产部署方式下，也可以运行常驻进程（当你准备好这种部署时）：

```bash
finclaw serve
```

## 如何升级

**Releases 页面**出现新版本时：重新下载你平台对应文件 → 用 `SHA256SUMS` 校验 → 覆盖本地 `finclaw` 二进制。若你的 `finclaw` 提供 `update` 子命令，在多数产品形态里它更偏向**提示/安全检查**；只有当你的发布说明明确写了“可自动更新”才应按说明使用。

## 支持渠道

- **下载/包损坏/无法解压**：请在本仓库提 issue，并附上**版本标签**、**文件名**、以及你使用的操作系统/架构。  
- **功能/行为/配置**相关问题：以你们内部分发的支持链接为准（如果适用）。

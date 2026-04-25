# 安装与更新

**English:** [installation.md](installation.md)

## 支持平台

- **macOS** — 提供 arm64 与 x86_64 等构建产物。
- **Linux** — 常见为 `x86_64-unknown-linux-gnu`（glibc）；在 Windows 上请用 **WSL2** 下载对应 Linux 包。
- **Windows** — 在官方发布**原生 .exe 之前**请使用 WSL2 + Linux 包（见 [Releases](https://github.com/finogeeks/finclaw-cli/releases)）。

## 一行安装（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/finogeeks/finclaw-cli/main/install.sh | sh
```

若 CDN 缓存了旧的 `install.sh`，可加时间戳避免命中缓存：

```bash
curl -fsSL "https://raw.githubusercontent.com/finogeeks/finclaw-cli/main/install.sh?$(date +%s)" | sh
```

固定版本（请按实际发版标签与脚本是否存在于该 tag 上调整）：

```bash
curl -fsSL https://raw.githubusercontent.com/finogeeks/finclaw-cli/main/install.sh | sh -s -- --version 0.1.0
```

环境变量以 **当前分支上的 `install.sh --help`** 为准，常见项包括：

- `FINCLAW_VERSION` — 版本号，可有或没有 `v` 前缀
- `FINCLAW_INSTALL_DIR` — 默认多为 `$HOME/.local/bin`
- `FINCLAW_INSECURE_SKIP_CHECKSUM=1` — **仅应急**，正常安装勿用

**安装后** 将安装目录加入 `PATH`，并执行：

```bash
finclaw --version
```

## 手动下载与校验

1. 打开 [Releases](https://github.com/finogeeks/finclaw-cli/releases) 选择版本（例如 `v0.1.0`）。
2. 下载**一个**与当前机器匹配的 `*.tar.zst`，并下载同版本的 **`SHA256SUMS`**。

`SHA256SUMS` 中通常包含**所有平台**的条目。你本地只下了一个包，**不要**用整份 `SHA256SUMS` 直接做 `shasum -a 256 -c` / `sha256sum -c`（会找不到其他平台文件而失败）。只校验**你下载文件**那一行，例如：

```bash
cd ~/Downloads
VER=0.1.0
FILE="finclaw-v${VER}-aarch64-apple-darwin.tar.zst"   # 按实际平台调整
grep -F "$FILE" SHA256SUMS | shasum -a 256 -c -
```

Linux 也可将 `shasum` 换成 `sha256sum`，管道用法相同。

## 解压与安装二进制

需已安装 **`tar`** 与 **`zstd`**（包名为 `*.tar.zst`）。

**示例（Apple Silicon，请按版本与包名改）：**

```bash
VER=0.1.0
FILE="finclaw-v${VER}-aarch64-apple-darwin.tar.zst"
zstd -dc "$FILE" | tar -xf -
install -m 0755 "finclaw-v${VER}-aarch64-apple-darwin/finclaw" "$HOME/.local/bin/finclaw"
```

部分 Linux 发行版支持：

```bash
tar --zstd -xf "finclaw-v${VER}-x86_64-unknown-linux-gnu.tar.zst"
```

**PATH** — 若提示找不到 `finclaw`：

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc   # 或 ~/.bashrc
export PATH="$HOME/.local/bin:$PATH"
```

## macOS Gatekeeper

未签名的二进制可能被 **Gatekeeper** 拦截。可在 **系统设置 → 隐私与安全性** 中放行，或按组织策略使用已签名构建。

## 更新

出新版本时重新下载本机对应包、**再次校验** SHA256 并**覆盖**原 `finclaw` 文件。`finclaw update --help` 可查看你当前构建中 `update` 子命令的行为（可能仅展示渠道/下载说明，不一定会自动覆盖二进制）。

## 卸载

见 [troubleshooting.zh.md](troubleshooting.zh.md)，并运行 `finclaw uninstall --help` 了解删除二进制与本地数据等选项。

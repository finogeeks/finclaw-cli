# finclaw 上手指南

本文面向从 [GitHub Releases](https://github.com/finogeeks/finclaw-cli/releases) **直接安装**的用户。`finclaw` 可执行文件在私有单仓中构建；**本公开仓库是安装与说明入口**。

**English:** [getting-started.md](getting-started.md)

---

## 1. 安装二进制

### 一行命令（推荐）

```bash
curl -fsSL "https://raw.githubusercontent.com/finogeeks/finclaw-cli/main/install.sh?$(date +%s)" | sh
```

`?$(date +%s)` 用于减少 `install.sh` 的 CDN 缓存；一般可不加，若脚本行为异常可带参数重试。

固定版本安装：

```bash
curl -fsSL https://raw.githubusercontent.com/finogeeks/finclaw-cli/main/install.sh | sh -s -- --version 0.1.0
```

环境变量（与 `install.sh` 内说明一致）：

- `FINCLAW_VERSION` — 版本号，可加或不加 `v` 前缀
- `FINCLAW_INSTALL_DIR` — 默认 `$HOME/.local/bin`

**安装后**确认安装目录在 `PATH` 中，并能找到命令：

```bash
finclaw --version
```

### 手动下载

1. 打开 [Releases](https://github.com/finogeeks/finclaw-cli)，选择 tag（如 `v0.1.0-rc`）。
2. 只下载**本机对应**的 `*.tar.zst` 与 `SHA256SUMS`（表见 [README.md](../README.zh.md#手动下载完全可控)）。

**校验说明：** 发布物中的 `SHA256SUMS` 会列出**全平台**产物。你本地只会有一个压缩包，因此**不要**对整份 `SHA256SUMS` 直接执行 `shasum -a 256 -c SHA256SUMS`（会尝试校验你未下载的其它平台文件并报错）。请只校验你下载的那一行，例如：

```bash
VER=0.1.0-rc
FILE="finclaw-v${VER}-aarch64-apple-darwin.tar.zst"   # 按本机 triplet 修改
grep -F "$FILE" SHA256SUMS | shasum -a 256 -c -
```

或自行计算 `FILE` 的 SHA256，与 `SHA256SUMS` 中对应行的哈希比对。

---

## 2. 首次初始化：`init`

```bash
finclaw init
```

通常会在 Finclaw 主目录（一般为 `~/.finclaw`）下建立 profile 与初始 `config.yaml`；默认 LLM 为 **mock**，便于未配置密钥时也能冒烟自测。

---

## 3. 配置真实大模型（可选，但常用）

内建 **mock** 仅适合连通性/冒烟；真实使用需设置 **provider**、**model**、**API 密钥**（及可选 **base_url** 等）。

### 方式 A — `finclaw config`（写入 YAML）

```bash
finclaw config path
finclaw config set llm.provider openai
finclaw config set llm.model gpt-4.1
finclaw config set llm.api_key sk-...   # 密钥更推荐用环境变量（见下）
```

### 方式 B — 环境变量

| 变量 | 对应配置项 |
| --- | --- |
| `FINCLAW_LLM_PROVIDER` 或 `LLM_PROVIDER` | `llm.provider` |
| `FINCLAW_LLM_MODEL` 或 `LLM_MODEL` | `llm.model` |
| `FINCLAW_LLM_BASE_URL` 或 `LLM_BASE_URL` | `llm.base_url` |
| `FINCLAW_LLM_API_KEY` | `llm.api_key` |
| `OPENAI_API_KEY`、`ANTHROPIC_API_KEY`、`DEEPSEEK_API_KEY`、`LLM_API_KEY` | 在未设 `FINCLAW_LLM_API_KEY` 时可作为 `llm.api_key` 使用 |

**优先级（高 → 低）：** Shell 已导出变量 → `.env` 注入 → 磁盘 `config.yaml` → 内置默认。

### 方式 C — `.env` 分层加载

1. **当前工作目录**下的 `./.env`（仅当启动 `finclaw` 时 **cwd 在该目录** 才加载）
2. **Profile 根目录** `<profile_root>/.env`
3. **Finclaw 主目录** `~/.finclaw/.env`（或 `$FINCLAW_HOME/.env`）

希望「不论在哪个目录执行都能读到密钥」时，请用 **`~/.finclaw/.env`** 或 **profile 下 `.env`**，不要只把密钥放在某个随意 clone 的仓库里。

### 检查配置

```bash
finclaw config show
finclaw config check
finclaw doctor
```

**公开合同：** 线路与合同见 [finclaw-contract](https://github.com/Geeksfino/finclaw-contract)；日常子命令以 `finclaw --help` 为准。

---

## 4. 与智能体对话

**交互式 REPL**（多行、slash 等）：

```bash
finclaw chat
```

**单轮**（脚本/CI，回复后退出）：

```bash
finclaw chat -m "你好，finclaw"
```

**常驻服务**（本机长进程）：

```bash
finclaw serve
```

模型与 `finclaw model` 的说明见 `finclaw model --help`。

---

## 5. 数据目录（摘要）

| 位置 | 作用 |
| --- | --- |
| `~/.finclaw`（或 `FINCLAW_HOME`） | 默认主目录 |
| `~/.finclaw/profiles/<name>/` | 各 profile 隔离环境 |
| `finclaw config path` | 当前 profile 的 `config.yaml` 路径 |

备份、导入、profile 管理见 `finclaw profile --help`。

---

## 6. 升级

新版本见 [Releases](https://github.com/finogeeks/finclaw-cli)。可再次使用一行安装脚本，或重新手动下载、**再次校验**哈希并覆盖旧二进制。`finclaw update` 的行为以终端提示与你们发行版说明为准。

---

## 7. 遇到问题？

- **下载失败、包损坏、校验不通过、无法解压**：到 [Issues](https://github.com/finogeeks/finclaw-cli/issues) 反馈，并附上**版本号**、**文件名**、**系统与 CPU 架构**（如 `macOS 15, arm64`）。
- **产品行为、私有部署、商业支持**：若有组织内渠道，以该渠道为准；本公开仓库以**发版与安装**为主。

---

*更短的总览见仓库根 [README.zh.md](../README.zh.md)。*

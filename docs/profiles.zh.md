# Profile、模板、备份与导入

**English:** [profiles.md](profiles.md)

**Profile** 是 finclaw 用户数据目录下的一个**隔离配置根**，包含人设、策略、技能以及对话等**私有状态**。

典型布局如下（示意）：

```text
~/.finclaw/
├── active-profile              # 可选，由 `profile use` 写入
└── profiles/
    └── <name>/
        ├── profile.yaml        # 智能体模板（能力、工具集、预设等）
        ├── IDENTITY.md         # 人设来源（可选；与策略关系见安全文档）
        ├── policies/           # 策略覆盖（可选）
        ├── skills/             # 本 profile 技能包
        ├── mcp-servers.yaml    # 可选 MCP 配置
        ├── config.yaml         # 宿主配置（大模型、密钥、开关）
        ├── data/               # 本地状态，一般勿分享
        ├── secrets/            # 凭据，默认勿随意外发
        └── …
```

**旧版路径：** 部分系统上旧版本可能曾使用 XDG 风格目录。若迁移后仍有遗留，可运行 `finclaw doctor` 查看提示。

## 首次初始化：`init`

```bash
finclaw init
```

有 TTY 时可交互选模板。非交互示例：

```bash
finclaw init --template coder --non-interactive
finclaw init --no-template
```

模板**打包在二进制内**，无需单独下载。内置名称通常包含 `general`、`coder`、`researcher` 等 — 以 `finclaw profile templates` 为准。

| 模板（常见） | 能力（常见） | 工具包（常见） | 说明 |
| --- | --- | --- | --- |
| `general` | `general` | `standard` | 通用助手，偏稳妥 |
| `coder` | `coding` | `full` | 偏工程与本地/网络开发 |
| `researcher` | `general` | `basic` | 偏只读与检索 |

`init` 会在**活动 profile** 下写入 `profile.yaml` 与初始 `IDENTITY.md`，并创建空的 `policies/`；**默认不覆盖**已有 `profile.yaml`，除非使用 `--force`（见 `finclaw init --help`）。

## 创建与列出

```bash
finclaw profile templates
finclaw profile list
finclaw profile list --json
```

从模板创建：

```bash
finclaw profile create mydev --from-template coder --activate
```

创建时常用参数（见 `finclaw profile create --help`）：

- `--capability` — `general` / `coding` / `read_only`
- `--tool-bundle` — `basic` / `standard` / `workspace` / `full`
- `--identity <path>` — 从文件复制人设
- `--activate` — 创建后设为当前 profile（等价于随后执行 `finclaw profile use`）

## 克隆 profile

在不复制对话历史与密钥的前提下，复制**可移植**部分：

```bash
finclaw profile clone <from> <to>
```

等价于带 `--clone-from` 的 `profile create`。复制范围以 `finclaw profile clone --help` 为准（通常含 `profile.yaml`、`IDENTITY.md`、`mcp-servers.yaml`、`skills/`、`policies/` 等；**不含** `data/`、默认 `config.yaml`、`secrets/` 等）。

## 能力（循环 / capability）

```bash
finclaw capability list
finclaw capability show
finclaw capability set coding
```

单次调用覆盖（不改磁盘上的 `profile.yaml`）：

```bash
finclaw chat --capability read_only -m "用一句话说明这段代码做什么。"
```

## 身份 / 人设（identity）

```bash
finclaw identity show
finclaw identity edit
finclaw identity render
finclaw identity reset
```

与策略、运行时关系见 [security-and-policies.zh.md](security-and-policies.zh.md)。

## 校验与查看

```bash
finclaw profile validate
finclaw profile validate --strict
finclaw profile show --resolved
finclaw profile active --json
```

## 对运行中的实例应用变更

编辑 `profile.yaml`、`policies/*.yaml` 或 `IDENTITY.md` 后：

```bash
finclaw profile apply
finclaw profile apply --dry-run
```

若无常驻守护进程，部分构建会短时拉起内嵌监督进程以完成 apply，请以实际输出为准。

## 可分享备份与导入

### 生成方：仅 profile 内容

```bash
finclaw backup --profile-only --out my-profile.tar.zst --profile <name>
```

用于**不含对话历史、不含本机密钥**的分享。与包含密钥或运行期目录的选项**互斥**，见 `finclaw backup --help`。

### 接收方：按 profile-only 导入

```bash
finclaw import my-profile.tar.zst --profile-only --name <newname>
```

`--profile-only` 会**拒绝**非 profile-only 方式生成的全量备份，避免误操作丢数据。

### 全量备份

需要包含更多本地状态用于整机恢复时，使用不带 `--profile-only` 的 `backup` / `import`，选项见 `finclaw backup --help`、`finclaw import --help`。

## REPL 快捷方式

在 `finclaw chat` 中，`/profile` 等仅用于查看，详见 [chat-and-operations.zh.md](chat-and-operations.zh.md)。

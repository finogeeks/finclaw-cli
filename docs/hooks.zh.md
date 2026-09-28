# 命令钩子与官方配方

**English:** [hooks.md](hooks.md)

**编写或打包钩子：** [hooks-develop.zh.md](hooks-develop.zh.md)

命令钩子是**可选**的本地 shell 命令，可在生命周期事件（例如工具运行前、
或你提交提示词时）运行。**默认关闭**。`finclaw update` 只替换 CLI
二进制，**不会**安装配方。

**以本机帮助为准：** `finclaw hooks --help`。若当前二进制没有 `hooks`
子命令，请先升级。

## 机制是什么

FinClaw 读取 `<profile>/hooks.json` 与 `<workspace>/.finclaw/hooks.json`。
每个处理程序是一条命令。你**信任**其哈希后，宿主把该处理程序交给正在
运行的智能体。智能体本身从不读取 `hooks.json`。

未信任前不会派生命令。交互式 `finclaw chat` 会在处理程序为新或哈希变化
时询问。`finclaw chat -m …`、无 TTY 与 daemon 会跳过未信任的处理程序。

钩子子进程与 FinClaw 进程权限相同。信任是审阅门，不是操作系统沙箱。
策略（`finclaw policy`）是另一层——见
[security-and-policies.zh.md](security-and-policies.zh.md)。

## 有哪些可用（官方目录）

官方**钩子配方**是本仓库 `hook-catalog` GitHub Release（prerelease，绝非
GitHub `latest`）上的版本化包。源码在
[`hooks/recipes/`](../hooks/recipes/)。

| Id | 事件 | 作用 | 配方说明 |
| --- | --- | --- | --- |
| `tool-gate` | `PreToolUse` | 对会改系统的工具允许 / **询问** / **拒绝**（`exec`、后台任务、写入、补丁） | [tool-gate/README.md](../hooks/recipes/tool-gate/README.md) |
| `turn-router` | `UserPromptSubmit` | 将安全轮次路由到**同一提供商**的便宜/强模型 | [turn-router/README.md](../hooks/recipes/turn-router/README.md) |
| `turn-review` | `Stop` | **拒绝**空答案、占位答案或与工具结果不符的答案 | [turn-review/README.md](../hooks/recipes/turn-review/README.md) |

查看当前公开索引：

```bash
finclaw hooks catalog
```

没有 `finclaw hooks install suite`。按需安装并信任各个 id。配方是普通
脚本；除非你在本机配置，否则不绑定特定判断引擎。

### 要求

- **安装 / 信任 / 硬拒绝：** CLI `--version` ≥ `0.13.0`，且 `node` 在
  `PATH` 上（含 Windows）。
- **询问、模型路由、Stop 拒绝：** 需要 CLI **0.13.1** 或更新。在 0.13.0
  上配方仍可安装；`tool-gate` 仍可硬拒绝；`ask` / `updatedModel` /
  Stop `reject` 会被忽略。
- 目录上的 `min_cli` 仍为 `0.13.0`（安装门槛）。
- 可选 `FINCLAW_HOOK_JUDGE_TOKEN` 为 `tool-gate`、`turn-router` 启用远程
  判断，并为 `turn-review` 启用审查。未设置时，`tool-gate` 仍按内置规则
  询问或拒绝；另外两个不产出决策。
- `0.13.0` 二进制默认指向已退役的目录标签。请改到 `hook-catalog`（见
  [默认目录 URL](#默认目录-url)），或升级到默认使用该 URL 的 0.13.1+。

### 诚实限制

- `turn-router` 不能改提供商、基础 URL 或凭证，也看不到实时允许列表。
  若模型 id 对当前提供商不允许，宿主会忽略该路由。
- `turn-review` 不能启动第二次推理。拒绝原因是固定模板，不是注入的助手
  消息。已经运行过的工具不会被撤销。
- `tool-gate` 使用 `failurePolicy: deny`：钩子进程失败或超时时，对应工具
  请求被拒绝。
- 每次检查在**新进程**中运行，处理程序不在事件之间共享内存。
- Unix 上宿主通过 `$SHELL -lc` 启动命令。较重的登录 shell（例如部分
  `fish` 配置）可能导致启动慢，或无法展开 `${FINCLAW_PROFILE_ROOT}`。
  此时请换用 POSIX `SHELL`。

## 配置与安装

```bash
finclaw hooks catalog
finclaw hooks install tool-gate
finclaw hooks install turn-router
finclaw hooks install turn-review
finclaw hooks list
finclaw hooks trust --recipe tool-gate
finclaw hooks trust --recipe turn-router
finclaw hooks trust --recipe turn-review
finclaw hooks remove tool-gate
```

`install` 只写入**当前配置档**（`<profile>/hooks/<id>/` 以及
`<profile>/hooks.json` 中的条目）。它**不会**写入
`$FINCLAW_HOME/hooks-trust.json`。派生命令前请用 `hooks trust` 审阅哈希。

用 `finclaw hooks revoke`（处理程序 id 或 `--recipe <id>`）撤销。

### 可选远程判断

在父进程环境中设置专用令牌（不要用 `*_API_KEY`，钩子子进程不会继承）：

```bash
export FINCLAW_HOOK_JUDGE_TOKEN="…"
# 可选
export FINCLAW_HOOK_JUDGE_BASE_URL="https://…"
export FINCLAW_HOOK_JUDGE_MODEL="…"
```

### 路由通道

安装后编辑 `<profile>/hooks/turn-router/routes.json`（按提供商的
cheap/strong id）。修改后需重新信任该配方。见
[turn-router README](../hooks/recipes/turn-router/README.md)。

### 默认目录 URL

```text
https://github.com/finogeeks/finclaw-cli/releases/download/hook-catalog/hooks-index.json
```

可在当前配置档的 `config.yaml` 覆盖：

```yaml
extra:
  hooks:
    index_url: "https://github.com/finogeeks/finclaw-cli/releases/download/hook-catalog/hooks-index.json"
```

`finclaw update` 不读取 `hooks-index.json`。

## 手写钩子

可以不经过目录，直接把命令写进 `<profile>/hooks.json` 或
`<workspace>/.finclaw/hooks.json`，然后 `finclaw hooks list` 与
`finclaw hooks trust`。文件格式、stdin/stdout 以及官方配方如何构建：
[hooks-develop.zh.md](hooks-develop.zh.md)。

## 不是技能，也不是 MCP

技能仍走 `finclaw skills`。MCP 仍走 `finclaw mcp add`。配方不得打包这两类内容。

## 相关

- [hooks-develop.zh.md](hooks-develop.zh.md) — 编写 `hooks.json` 或配方
- [security-and-policies.zh.md](security-and-policies.zh.md)
- [skills.zh.md](skills.zh.md)
- [reference-commands.zh.md](reference-commands.zh.md)

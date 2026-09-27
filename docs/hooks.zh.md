# 命令钩子与官方配方

**English:** [hooks.md](hooks.md)

命令钩子是**可选**的本地 shell 命令，可在生命周期事件（例如 `PreToolUse`）
运行。它们**不会**随 `finclaw update` 安装，默认关闭。

**以本机帮助为准：** `finclaw hooks --help`。若当前二进制没有 `hooks`
子命令，请先升级。

## 安装的是什么

官方**钩子配方**是本仓库滚动 Release 标签 `hooks` 上的版本化包。源码在
[`hooks/recipes/`](../hooks/recipes/)。

已发布的目录包含三个官方配方：

| Id | 事件 | 说明 |
| --- | --- | --- |
| `tool-gate` | `PreToolUse` | 对会改系统的工具做允许/拒绝/询问 |
| `turn-router` | `UserPromptSubmit` | 为安全用户轮次选择已配置的模型通道 |
| `turn-review` | `Stop` | 拒绝空答案或与工具结果不符的答案 |

配方是普通脚本，不绑定特定判断引擎，仅取决于本机配置。

### 要求与限制

- 需要 finclaw CLI `--version` ≥ `0.13.0`。
- 需要 `node` 在 `PATH` 上（含 Windows）。
- 可选环境变量 `FINCLAW_HOOK_JUDGE_TOKEN` 用于在 `tool-gate` 与
  `turn-router` 中启用远程判断，并用于启用 `turn-review`。未设置时，
  `turn-router` 与 `turn-review` 不生效（不改路由、不做审查）。
- `turn-router` 只能在**同一提供商**的已配置模型间切换，不能改提供商、
  基础 URL 或凭证。
- `turn-review` 不能启动第二次推理；拒绝 Stop 时返回固定模板原因，**不是**
  注入新的助手消息。
- `tool-gate` 使用 `failurePolicy: deny`：钩子进程失败或超时时，对应工具
  请求被拒绝。
- 每次检查在**新进程**中运行，处理程序不在事件之间共享内存。

## 使用流程

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
`$FINCLAW_HOME/hooks-trust.json`。未信任前不会派生命令。

`finclaw update` 只替换 CLI 二进制，不读取 `hooks-index.json`。

## 默认目录 URL

```text
https://github.com/finogeeks/finclaw-cli/releases/download/hooks/hooks-index.json
```

可在当前配置档的 `config.yaml` 覆盖：

```yaml
extra:
  hooks:
    index_url: "https://github.com/finogeeks/finclaw-cli/releases/download/hooks/hooks-index.json"
```

## 信任

交互式 `finclaw chat` 会在处理程序未信任或哈希变化时询问。非交互聊天与
daemon 会跳过未信任的处理程序。

用 `finclaw hooks revoke`（处理程序 id 或 `--recipe <id>`）撤销。

## 不是技能，也不是 MCP

技能仍走 `finclaw skills`。MCP 仍走 `finclaw mcp add`。配方不得打包这两类内容。

## 相关

- [security-and-policies.zh.md](security-and-policies.zh.md)
- [skills.zh.md](skills.zh.md)
- [reference-commands.zh.md](reference-commands.zh.md)

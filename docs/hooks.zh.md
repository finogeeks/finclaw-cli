# 命令钩子与官方配方

**English:** [hooks.md](hooks.md)

命令钩子是**可选**的本地 shell 命令，可在生命周期事件（例如 `PreToolUse`）
运行。它们**不会**随 `finclaw update` 安装，默认关闭。

**以本机帮助为准：** `finclaw hooks --help`。若当前二进制没有 `hooks`
子命令，请先升级。

## 安装的是什么

官方**钩子配方**是本仓库滚动 Release 标签 `hooks` 上的版本化包。源码在
[`hooks/recipes/`](../hooks/recipes/)。目录可以为空。

首个预留官方配方 id 是 **`tool-gate`**（针对会改系统的工具的 PreToolUse
门闸）。在该配方单独落地之前不会发布。配方就是普通脚本，不绑定特定判断引擎。

## 使用流程

```bash
finclaw hooks catalog
finclaw hooks install tool-gate     # 仅当该配方已发布
finclaw hooks list
finclaw hooks trust --recipe tool-gate
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

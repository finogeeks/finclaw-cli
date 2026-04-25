# 高级：补全、man、可选特性

**English:** [advanced.md](advanced.md)

## Shell 补全

```bash
finclaw completion bash
finclaw completion zsh
finclaw completion fish
finclaw completion elvish
finclaw completion powershell
```

将生成脚本按各 shell 的加载方式加入配置；生成文件头部往往有说明注释。

## man 页

`finclaw man` 会生成 roff 并可能尝试用系统 man 查看。若无 `man`/`groff`，请直接使用 `--help`。

## 系统服务单元

`finclaw service` 可输出 **systemd** 或 **launchd** 用的单元片段，用于 `finclaw serve`。以 `finclaw service --help` 为准并核对本机路径与用户。

## 通过 stdio 的 MCP

`finclaw mcp` 可能仅在构建启用 **`mcp` feature** 时存在；若 `finclaw --help` 中无此子命令，则当前二进制未包含该功能。

## 备份子命令与特性矩阵

极精简构建可能**不包含** `backup`/`import`；以当前 `--help` 与发行说明为准。

## 另见

- [chat-and-operations.zh.md](chat-and-operations.zh.md)
- [reference-commands.zh.md](reference-commands.zh.md)

# Advanced: completions, man page, optional features

**Chinese:** [advanced.zh.md](advanced.zh.md)

## Shell completion

```bash
finclaw completion bash
finclaw completion zsh
finclaw completion fish
finclaw completion elvish
finclaw completion powershell
```

Install the script using your shell’s plugin mechanism; see the comments at the top of the generated file.

## Man page

`finclaw man` generates roff and may pipe to a viewer if available. If your system lacks `man`/`groff`, use `--help` instead.

## Service units

`finclaw service` can emit **systemd** or **launchd** unit snippets for `finclaw serve`. Use `finclaw service --help` and verify paths for your user.

## MCP over stdio

`finclaw mcp` may be available only when the binary is built with the **`mcp` feature** (not all public builds ship it). If the subcommand is missing from `--help`, your build does not include it.

## Backup feature matrix

`finclaw backup` and `import` can be **feature-gated** in minimal builds. If the commands are missing, use an official release that lists backup support.

## See also

- [chat-and-operations.md](chat-and-operations.md) — serve/daemon
- [reference-commands.md](reference-commands.md) — full index

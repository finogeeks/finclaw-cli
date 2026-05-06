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

`finclaw mcp` ships only when the binary is built with the **`mcp` feature**. If the command is missing from `finclaw --help`, your build omits it.

When enabled:

- Running `finclaw mcp` **with no subcommand** speaks MCP over **stdio** — the same as explicit `finclaw mcp serve`.
- `finclaw mcp add/remove/list/test` manage **external** MCP servers registered in the profile so `chat` and the REPL can call their tools (`--help` lists argv/env capture rules).

## Backup feature matrix

`finclaw backup` and `import` can be **feature-gated** in minimal builds. If the commands are missing, use an official release that lists backup support.

## See also

- [chat-and-operations.md](chat-and-operations.md) — serve/daemon
- [reference-commands.md](reference-commands.md) — full index

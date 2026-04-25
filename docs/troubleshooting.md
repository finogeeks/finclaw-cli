# Troubleshooting

**Chinese:** [troubleshooting.zh.md](troubleshooting.zh.md)

## Install and download

- **Binary not found** — ensure `$HOME/.local/bin` (or your install dir) is on `PATH` (see [installation.md](installation.md)).
- **Checksum failed** — re-download `SHA256SUMS` and your platform archive; verify **only the line** for your file (not the full checksums file with every platform).
- **Extract failed** — install `zstd` and a modern `tar`; use `tar --zstd` on Linux if available.

**Still stuck on install?** Open an issue on the [finclaw-cli](https://github.com/finogeeks/finclaw-cli/issues) tracker with the **release tag**, **file name**, and **OS + CPU architecture**.

## First-run and configuration

- **`finclaw doctor` reports config issues** — run `finclaw config check`, fix `config path`, and confirm env/`.env` precedence (see [configuration.md](configuration.md)).
- **Mock model only** — set `llm.provider`, `llm.model`, and an API key (or compatible `base_url`) via `finclaw config set` or env vars.

## Policy drift

If `finclaw doctor` reports that **on-disk** policies disagree with the **live** runtime:

- Re-apply: `finclaw policy apply` or per-kind `finclaw policy apply exec`
- Or align files with what the runtime has: `finclaw policy show <kind> --source live`

## Identity changes not visible

If you edit `IDENTITY.md` outside `finclaw identity edit`:

- Run `finclaw identity render`, then `finclaw profile apply`

## Skills and boot

- **Duplicate skill id** — `finclaw skills check` shows conflicts; remove or rename one pack.
- **Skill not loading** — confirm files live under the active profile’s `skills/<id>/SKILL.md` and you used the correct `--profile`.

## macOS Gatekeeper

Unsigned binaries can be blocked—use **System Settings → Privacy & Security** or your org’s signed build policy.

## Capabilities and builds

If chat reports a capability (for example `coding`) is not enabled, your **build** may have been compiled without that loop—try `finclaw capability set general` or use a build that includes the feature.

## Import / backup errors

- **`import --profile-only` rejected** — the archive was a **full** backup, not `backup --profile-only`. Use the correct import mode or re-export with `--profile-only`.

## Uninstall

```bash
finclaw uninstall --help
```

Options may remove the binary, profiles, and state—read the help before confirming.

## Getting help

- **Install/download/checksum** — [finclaw-cli issues](https://github.com/finogeeks/finclaw-cli/issues)
- **Agent behaviour in a private deployment** — follow your organization’s support channel

## See also

- [security-and-policies.md](security-and-policies.md) — policy apply and presets
- [skills.md](skills.md) — `skills check`

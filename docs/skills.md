# Skills: hubs, catalogs, ClawHub, and local packs

**Chinese:** [skills.zh.md](skills.zh.md)

Finclaw loads skills from the **active profile** and from additional scan roots configured for that profile. Layout on disk:

```text
~/.finclaw/profiles/<profile>/skills/<skill-id>/SKILL.md
```

**Authoritative:** `finclaw skills --help` and subcommand help for your build.

## Why `skills check` matters

The CLI validates skill directories and **duplicate skill ids** can prevent the embedded runtime from starting. After installing or moving packs, run:

```bash
finclaw skills check
```

Use `--profile <name>` when the install target is not the default profile.

## Configured hubs

List and manage hub entries (URLs and names) that publish `skills.hub.v1` style indexes:

```bash
finclaw skills hubs list
finclaw skills hubs add <name> <url>
finclaw skills hubs remove <name>
```

## Browse, search, install (generic hub)

When hubs are configured:

```bash
finclaw skills browse
finclaw skills search "your query"
finclaw skills info <reference>
finclaw skills install <reference>
finclaw skills update
finclaw skills update <id>
finclaw skills uninstall <id>
```

`--offline` may use cached indexes for read-only operations (see `--help`).

## ClawHub adapter (public registry browse)

For public ClawHub-style browsing without extra login in typical flows:

```bash
finclaw skills clawhub browse
finclaw skills clawhub search "topic"
finclaw skills clawhub info <slug>
finclaw skills clawhub install <slug>
```

Flags such as registry choice or limits vary—use `finclaw skills clawhub --help`.

## List and show effective config

```bash
finclaw skills list
finclaw skills list --json
finclaw skills config
```

## Open ecosystem: `npx skills` and copying into a profile

You can use external generators that output OpenClaw-compatible skill trees, then copy the resulting directory into your profile’s `skills/` path:

```bash
mkdir -p /tmp/finclaw-skills-import
cd /tmp/finclaw-skills-import
npx skills add vercel-labs/agent-skills --skill frontend-design --agent openclaw --copy -y
mkdir -p ~/.finclaw/profiles/default/skills
cp -R skills/frontend-design ~/.finclaw/profiles/default/skills/
finclaw skills check
```

Adjust `default` to your profile name.

## Wire contract

[finclaw-contract](https://github.com/Geeksfino/finclaw-contract) documents integration surfaces; it does not replace the CLI skill UX above.

## See also

- [configuration.md](configuration.md) — env and `config.yaml` layers
- [profiles.md](profiles.md) — profile isolation and backup

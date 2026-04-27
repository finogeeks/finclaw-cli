# Maintaining finclaw-cli documentation

## Audience

These notes are for people who edit documentation in the **finclaw-cli** public repository.

## Public-only rule

- **Do not link to private repositories, internal paths, or unreleased source trees.**
- End users must be able to follow every doc using only:
  - this repo (`finclaw-cli` on GitHub),
  - the installed `finclaw` binary’s `--help` output.
- **Do not link** to other internal source repositories (runtime monorepos, contract repos, or middleware) unless your org explicitly publishes them. If you need wire-level API detail, point readers to **vendor/operator** documentation or ship a copy in this repo.
- If behavior is known only from unreleased or private trees, **extract and rewrite** the user-relevant material here when you make a public-facing change (presets, new flags, new subcommands).

## When the CLI changes

1. Update the topic guide (English + Chinese) for the affected area.
2. Update [reference-commands.md](reference-commands.md) (and `.zh.md`) if top-level commands or primary workflows change.
3. **Global `--security` / host isolation** — if the mapping to `AI_INFRA_RS_*` or default behavior changes upstream, update [security-and-policies.md](security-and-policies.md) and [security-and-policies.zh.md](security-and-policies.zh.md) first, then [configuration.md](configuration.md) / [configuration.zh.md](configuration.zh.md) and [chat-and-operations.md](chat-and-operations.md) / `.zh.md` cross-references as needed.
4. Add a short “as of / behavior note” in the doc if a release introduces a breaking or notable change.
5. Run through `finclaw --help` and the relevant `finclaw <cmd> --help` to avoid documenting removed flags.

## Bilingual files

- Keep [topic].md and [topic].zh.md in sync: same structure, same commands; translate prose.
- If you add a new English doc, add the Chinese counterpart in the same change when possible.

## HTTP/API and the Claw runtime

- These guides document the **CLI**; Claw’s HTTP API and integration contract are **not** assumed to live in a separate public repository.
- Do not point readers at private org repos. Summarize or reproduce here only what end users need, or send them to documentation bundled with their deployment.

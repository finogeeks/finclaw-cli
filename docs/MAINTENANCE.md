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
4. **Global `--locale` / `--config`** — if help language selection or alternate `config.yaml` paths change, update [configuration.md](configuration.md), [reference-commands.md](reference-commands.md), and [docs/README.md](README.md) (English prose + bilingual note as needed).
5. **Post-turn learning** — if `learning:` schema, `finclaw learning` subcommands, or `AI_INFRA_RS_LEARNING_*` env vars change, update [learning.md](learning.md) / [learning.zh.md](learning.zh.md) first, then cross-links in [configuration.md](configuration.md), [chat-and-operations.md](chat-and-operations.md), [skills.md](skills.md), and [reference-commands.md](reference-commands.md) (and `.zh.md` counterparts).
6. Add a short “as of / behavior note” in the doc if a release introduces a breaking or notable change.
7. Run through `finclaw --help` and the relevant `finclaw <cmd> --help` to avoid documenting removed flags.

## Bilingual files

- Keep [topic].md and [topic].zh.md in sync: same structure, same commands; translate prose.
- If you add a new English doc, add the Chinese counterpart in the same change when possible.
- **A2A:** [a2a.md](a2a.md) / [a2a.zh.md](a2a.zh.md) and [examples/mock-a2a-peer.py](../examples/mock-a2a-peer.py) ship together; update the index rows in [README.md](../README.md), [README.zh.md](../README.zh.md), and [docs/README.md](README.md) when the guide changes.

## HTTP/API and the Claw runtime

- These guides document the **CLI**; Claw’s HTTP API and integration contract are **not** assumed to live in a separate public repository.
- Do not point readers at private org repos. Summarize or reproduce here only what end users need, or send them to documentation bundled with their deployment.

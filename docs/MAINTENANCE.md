# Maintaining finclaw-cli documentation

## Audience

These notes are for people who edit documentation in the **finclaw-cli** public repository.

## Public-only rule

- **Do not link to private repositories, internal paths, or unreleased source trees.**
- End users must be able to follow every doc using only:
  - this repo (`finclaw-cli` on GitHub),
  - the published [finclaw-contract](https://github.com/Geeksfino/finclaw-contract) repo when a wire-level reference is needed,
  - the installed `finclaw` binary’s `--help` output.
- If behavior is documented only in a private monorepo, **extract and rewrite** the user-relevant material here when you make a public-facing change (presets, new flags, new subcommands).

## When the CLI changes

1. Update the topic guide (English + Chinese) for the affected area.
2. Update [reference-commands.md](reference-commands.md) (and `.zh.md`) if top-level commands or primary workflows change.
3. **Global `--security` / host isolation** — if the mapping to `AI_INFRA_RS_*` or default behavior changes upstream, update [security-and-policies.md](security-and-policies.md) and [security-and-policies.zh.md](security-and-policies.zh.md) first, then [configuration.md](configuration.md) / [configuration.zh.md](configuration.zh.md) and [chat-and-operations.md](chat-and-operations.md) / `.zh.md` cross-references as needed.
4. Add a short “as of / behavior note” in the doc if a release introduces a breaking or notable change.
5. Run through `finclaw --help` and the relevant `finclaw <cmd> --help` to avoid documenting removed flags.

## Bilingual files

- Keep [topic].md and [topic].zh.md in sync: same structure, same commands; translate prose.
- If you add a new English doc, add the Chinese counterpart in the same change when possible.

## Relationship to the wire contract

- **finclaw-contract** is the public integration contract; it is not a user manual.
- Do not duplicate the whole contract in these guides; link to it where appropriate for “what’s on the wire,” and keep day-to-day usage in these markdown files.

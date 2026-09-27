# Official hook recipes

This directory is the **git source** for recipes published to the
`hook-catalog` prerelease on this repository.

The installed `finclaw` binary does not contain these files. Recipients
run `finclaw hooks catalog` / `install` / `trust` / `remove`.

## Official recipes

| Id | Event | Role |
| --- | --- | --- |
| `tool-gate` | `PreToolUse` | Allow, deny, or ask before mutating tools |
| `turn-router` | `UserPromptSubmit` | Pick a configured model lane for safe turns |
| `turn-review` | `Stop` | Reject unsupported or empty assistant answers |

Each recipe requires finclaw CLI `--version` ≥ `0.13.0` and `node` on `PATH`
(including on Windows). Set optional `FINCLAW_HOOK_JUDGE_TOKEN` to enable
remote judgment in `tool-gate` and `turn-router`, and to enable
`turn-review`. Without that token, `tool-gate` still asks or denies matching
tool requests by its built-in rules; `turn-router` and `turn-review` emit no
output and do not change routing or review.

Do not name new recipes after external product or assistant brands.

## Layout

```text
hooks/recipes/<id>/
  recipe.json
  README.md
  src/…              # TypeScript sources and tests
  routes.json        # turn-router only
```

Published tarballs are produced by `scripts/hooks_assemble.py`, which
compiles `src/` into `scripts/main.js` plus shared `scripts/lib/` for each
recipe. `recipe.json` uses schema `hooks.recipe.v1`.

`id` is `[a-z0-9]+(?:-[a-z0-9]+)*`, max 64, and must not start with `.`.

## What does not live here

- CLI test fixtures (`echo-deny`) never belong in this tree.
- `$FINCLAW_HOME/hooks-trust.json` is per-machine trust, not a recipe.
- Do not commit `.tar.zst` archives; the `hooks` release is the fetch surface.

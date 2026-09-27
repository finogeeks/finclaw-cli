# Official hook recipes

This directory is the **git source** for recipes published to the rolling
`hooks` prerelease on this repository.

The installed `finclaw` binary does not contain these files. Recipients
run `finclaw hooks catalog` / `install` / `trust` / `remove`.

**Empty catalog.** There is no `recipe.json` here yet, so the published
index may list zero recipes. That is expected.

## Reserved id

`tool-gate` is reserved for the first official recipe: a PreToolUse
allow/block gate for mutating tools. Do not create
`hooks/recipes/tool-gate/recipe.json` until that recipe’s own plan
lands. The runner does not require Jev or any other judgment engine.

Do not name recipes after DAIR, Pi, or Jev.

## Layout (when a recipe is added)

```text
hooks/recipes/<id>/
  recipe.json
  README.md
  scripts/…
```

`id` is `[a-z0-9]+(?:-[a-z0-9]+)*`, max 64, and must not start with `.`.
`recipe.json` uses schema `hooks.recipe.v1`.

## What does not live here

- CLI test fixtures (`echo-deny`) never belong in this tree.
- `$FINCLAW_HOME/hooks-trust.json` is per-machine trust, not a recipe.
- Do not commit `.tar.zst` archives; the `hooks` release is the fetch surface.

#!/usr/bin/env python3
"""Assemble compiled hook recipes into self-contained package trees."""
from __future__ import annotations

import argparse
import shutil
import subprocess
from pathlib import Path

from hooks_pack import load_recipe

REQUIRE_REWRITE = 'require("../../../lib/'
REQUIRE_LOCAL = 'require("./lib/'


def assemble(hooks_root: Path, out_dir: Path) -> None:
    """Build and stage each recipe with its compiled entrypoint and shared library."""
    subprocess.run(["npm", "run", "build"], cwd=hooks_root, check=True)

    for recipe_json in sorted((hooks_root / "recipes").glob("*/recipe.json")):
        recipe_id = recipe_json.parent.name
        staged_recipe = out_dir / recipe_id
        staged_recipe.mkdir(parents=True, exist_ok=True)

        for name in ("recipe.json", "README.md", "routes.json"):
            source = recipe_json.parent / name
            if source.is_file():
                shutil.copy2(source, staged_recipe / name)

        source_main = hooks_root / "dist" / "recipes" / recipe_id / "src" / "main.js"
        staged_main = staged_recipe / "scripts" / "main.js"
        staged_main.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source_main, staged_main)
        staged_main.write_text(
            staged_main.read_text(encoding="utf-8").replace(
                REQUIRE_REWRITE, REQUIRE_LOCAL
            ),
            encoding="utf-8",
        )

        staged_lib = staged_recipe / "scripts" / "lib"
        staged_lib.mkdir(parents=True, exist_ok=True)
        for source_lib in sorted((hooks_root / "dist" / "lib").glob("*.js")):
            if not source_lib.name.endswith(".test.js"):
                shutil.copy2(source_lib, staged_lib / source_lib.name)

        load_recipe(staged_recipe / "recipe.json")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Assemble compiled hook recipes")
    parser.add_argument("--hooks-dir", type=Path, required=True)
    parser.add_argument("--out-dir", type=Path, required=True)
    args = parser.parse_args(argv)
    assemble(args.hooks_dir, args.out_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

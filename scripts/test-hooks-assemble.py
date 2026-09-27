#!/usr/bin/env python3
"""Unit tests for scripts/hooks_assemble.py. Run: python3 scripts/test-hooks-assemble.py"""
from __future__ import annotations

import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

_SCRIPTS = Path(__file__).resolve().parent
if str(_SCRIPTS) not in sys.path:
    sys.path.insert(0, str(_SCRIPTS))

import hooks_assemble
import hooks_pack


def _write_hooks_fixture(root: Path) -> Path:
    hooks_root = root / "hooks"
    recipe = hooks_root / "recipes" / "sample-node"
    (recipe / "src").mkdir(parents=True)
    (hooks_root / "lib").mkdir()
    (hooks_root / "package.json").write_text(
        json.dumps(
            {
                "name": "fixture-hooks",
                "private": True,
                "scripts": {"build": "node build.js"},
            }
        ),
        encoding="utf-8",
    )
    (hooks_root / "build.js").write_text(
        """\
const fs = require("fs");
fs.mkdirSync("dist/recipes/sample-node/src", { recursive: true });
fs.mkdirSync("dist/lib", { recursive: true });
fs.writeFileSync(
  "dist/recipes/sample-node/src/main.js",
  'const honour = require("../../lib/honour");\\nvoid honour;\\n',
);
fs.writeFileSync("dist/lib/honour.js", "module.exports = {};\\n");
fs.writeFileSync("dist/lib/honour.test.js", "throw new Error('not shipped');\\n");
""",
        encoding="utf-8",
    )
    (recipe / "src" / "main.ts").write_text(
        'import "../../lib/honour";\n', encoding="utf-8"
    )
    (recipe / "README.md").write_text("Fixture recipe.\n", encoding="utf-8")
    (recipe / "routes.json").write_text("{}\n", encoding="utf-8")
    (recipe / "recipe.json").write_text(
        json.dumps(
            {
                "schema": "hooks.recipe.v1",
                "id": "sample-node",
                "version": "0.1.0",
                "min_cli": "0.12.0",
                "summary": "Test-only fixture. Do not publish.",
                "hooks": {
                    "PreToolUse": [
                        {
                            "matcher": "exec",
                            "hooks": [
                                {
                                    "type": "command",
                                    "id": "sample-node",
                                    "command": "node scripts/main.js",
                                    "timeout": 5,
                                }
                            ],
                        }
                    ]
                },
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    return hooks_root


class AssembleTests(unittest.TestCase):
    def test_assembles_compiled_recipe_tree(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            hooks_root = _write_hooks_fixture(Path(tmp))
            staged = Path(tmp) / "staged"

            hooks_assemble.assemble(hooks_root, staged)

            recipe = staged / "sample-node"
            main = recipe / "scripts" / "main.js"
            self.assertTrue(main.is_file())
            self.assertTrue((recipe / "README.md").is_file())
            self.assertTrue((recipe / "routes.json").is_file())
            self.assertTrue((recipe / "scripts" / "lib" / "honour.js").is_file())
            self.assertFalse((recipe / "scripts" / "lib" / "honour.test.js").exists())
            text = main.read_text(encoding="utf-8")
            self.assertIn('require("./lib/', text)
            self.assertNotIn('require("../../lib/', text)
            hooks_pack.load_recipe(recipe / "recipe.json")

    @unittest.skipUnless(shutil.which("zstd"), "need zstd")
    def test_packs_only_staged_fixture_recipe(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            hooks_root = _write_hooks_fixture(Path(tmp))
            staged = Path(tmp) / "staged"
            dist = Path(tmp) / "dist"

            hooks_assemble.assemble(hooks_root, staged)
            subprocess.run(
                [
                    sys.executable,
                    str(_SCRIPTS / "hooks_pack.py"),
                    "--recipes-dir",
                    str(staged),
                    "--out-dir",
                    str(dist),
                    "--asset-base-url",
                    "https://example.invalid/hooks",
                    "--only",
                    "sample-node",
                ],
                check=True,
            )

            self.assertTrue((dist / "hooks-sample-node-0.1.0.tar.zst").is_file())
            index = json.loads((dist / "hooks-index.json").read_text(encoding="utf-8"))
            self.assertEqual([recipe["id"] for recipe in index["recipes"]], ["sample-node"])


if __name__ == "__main__":
    unittest.main()

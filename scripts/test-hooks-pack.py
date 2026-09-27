#!/usr/bin/env python3
"""Unit tests for scripts/hooks_pack.py. Run: python3 scripts/test-hooks-pack.py"""
from __future__ import annotations

import json
import os
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

_SCRIPTS = Path(__file__).resolve().parent
if str(_SCRIPTS) not in sys.path:
    sys.path.insert(0, str(_SCRIPTS))

import hooks_pack as pack


def _write_recipe(root: Path, recipe_id: str = "sample-gate", **overrides) -> Path:
    d = root / recipe_id
    scripts = d / "scripts"
    scripts.mkdir(parents=True)
    (scripts / "deny.py").write_text("import sys\nsys.exit(2)\n", encoding="utf-8")
    body = {
        "schema": "hooks.recipe.v1",
        "id": recipe_id,
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
                            "id": "deny-exec",
                            "command": "python3 scripts/deny.py",
                            "timeout": 5,
                        }
                    ],
                }
            ]
        },
    }
    body.update(overrides)
    (d / "recipe.json").write_text(json.dumps(body, indent=2) + "\n", encoding="utf-8")
    (d / "README.md").write_text("fixture\n", encoding="utf-8")
    return d


class VersionAndIdTests(unittest.TestCase):
    def test_parse_version_numeric(self) -> None:
        self.assertEqual(pack.parse_version("0.12.10"), (0, 12, 10))
        self.assertGreater(pack.parse_version("0.12.10"), pack.parse_version("0.12.9"))

    def test_parse_version_rejects_prerelease(self) -> None:
        with self.assertRaises(pack.PackError):
            pack.parse_version("0.13.0-rc1")

    def test_validate_recipe_id(self) -> None:
        pack.validate_recipe_id("tool-gate")
        pack.validate_recipe_id("sample-gate")
        with self.assertRaises(pack.PackError):
            pack.validate_recipe_id("DairJev")
        with self.assertRaises(pack.PackError):
            pack.validate_recipe_id(".hidden")
        with self.assertRaises(pack.PackError):
            pack.validate_recipe_id("a" * 65)


class LoadRecipeTests(unittest.TestCase):
    def test_rejects_wrong_schema(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            d = _write_recipe(Path(tmp), schema="hooks.recipe.v0")
            with self.assertRaises(pack.PackError):
                pack.load_recipe(d / "recipe.json")

    def test_rejects_missing_handler_id(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            d = _write_recipe(Path(tmp))
            raw = json.loads((d / "recipe.json").read_text(encoding="utf-8"))
            del raw["hooks"]["PreToolUse"][0]["hooks"][0]["id"]
            (d / "recipe.json").write_text(json.dumps(raw), encoding="utf-8")
            with self.assertRaises(pack.PackError):
                pack.load_recipe(d / "recipe.json")

    def test_rejects_stamped_recipe_field(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            d = _write_recipe(Path(tmp))
            raw = json.loads((d / "recipe.json").read_text(encoding="utf-8"))
            raw["hooks"]["PreToolUse"][0]["hooks"][0]["recipe"] = "sample-gate"
            (d / "recipe.json").write_text(json.dumps(raw), encoding="utf-8")
            with self.assertRaises(pack.PackError):
                pack.load_recipe(d / "recipe.json")

    def test_rejects_absolute_script(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            d = _write_recipe(Path(tmp))
            raw = json.loads((d / "recipe.json").read_text(encoding="utf-8"))
            raw["hooks"]["PreToolUse"][0]["hooks"][0]["command"] = (
                "python3 /tmp/deny.py"
            )
            (d / "recipe.json").write_text(json.dumps(raw), encoding="utf-8")
            with self.assertRaises(pack.PackError):
                pack.load_recipe(d / "recipe.json")

    def test_rejects_missing_script_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            d = _write_recipe(Path(tmp))
            (d / "scripts" / "deny.py").unlink()
            with self.assertRaises(pack.PackError):
                pack.load_recipe(d / "recipe.json")

    def test_pack_one_rejects_symlink_before_staging(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            d = _write_recipe(Path(tmp))
            os.symlink("/etc/hosts", d / "scripts" / "escaped-hosts")
            with self.assertRaises(pack.PackError):
                pack.pack_one(
                    d,
                    Path(tmp) / "dist",
                    "https://example.test/hooks",
                )

    def test_rejects_id_mismatch(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            d = _write_recipe(Path(tmp), recipe_id="sample-gate", id="other-id")
            with self.assertRaises(pack.PackError):
                pack.load_recipe(d / "recipe.json")


class EmptyAndPackTests(unittest.TestCase):
    def test_empty_recipes_dir_writes_empty_index(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            recipes = Path(tmp) / "recipes"
            recipes.mkdir()
            out = Path(tmp) / "dist"
            rc = pack.main(
                [
                    "--recipes-dir",
                    str(recipes),
                    "--out-dir",
                    str(out),
                    "--asset-base-url",
                    "https://example.test/hooks",
                    "--updated-at",
                    "2026-09-26T00:00:00Z",
                ]
            )
            self.assertEqual(rc, 0)
            index = json.loads((out / "hooks-index.json").read_text(encoding="utf-8"))
            self.assertEqual(index["schema"], "hooks.catalog.v1")
            self.assertEqual(index["recipes"], [])
            self.assertTrue((out / "SHA256SUMS").is_file())
            self.assertEqual(list(out.glob("hooks-*.tar.zst")), [])

    def test_pack_one_recipe_when_zstd_available(self) -> None:
        if shutil.which("zstd") is None:
            self.skipTest("need zstd")
        with tempfile.TemporaryDirectory() as tmp:
            recipes = Path(tmp) / "recipes"
            _write_recipe(recipes, "sample-gate")
            out = Path(tmp) / "dist"
            rc = pack.main(
                [
                    "--recipes-dir",
                    str(recipes),
                    "--out-dir",
                    str(out),
                    "--asset-base-url",
                    "https://example.test/hooks",
                    "--updated-at",
                    "2026-09-26T00:00:00Z",
                ]
            )
            self.assertEqual(rc, 0)
            archive = out / "hooks-sample-gate-0.1.0.tar.zst"
            self.assertTrue(archive.is_file())
            index = json.loads((out / "hooks-index.json").read_text(encoding="utf-8"))
            self.assertEqual(len(index["recipes"]), 1)
            rec = index["recipes"][0]
            self.assertEqual(rec["id"], "sample-gate")
            self.assertEqual(rec["latest"], "0.1.0")
            self.assertEqual(
                rec["versions"][0]["url"],
                "https://example.test/hooks/hooks-sample-gate-0.1.0.tar.zst",
            )
            self.assertEqual(len(rec["versions"][0]["sha256"]), 64)

    def test_only_writes_selected_archive_but_indexes_all_recipes(self) -> None:
        if shutil.which("zstd") is None:
            self.skipTest("need zstd")
        with tempfile.TemporaryDirectory() as tmp:
            recipes = Path(tmp) / "recipes"
            _write_recipe(recipes, "alpha-gate")
            _write_recipe(recipes, "beta-gate")
            out = Path(tmp) / "dist"
            rc = pack.main(
                [
                    "--recipes-dir",
                    str(recipes),
                    "--out-dir",
                    str(out),
                    "--asset-base-url",
                    "https://example.test/hooks",
                    "--updated-at",
                    "2026-09-26T00:00:00Z",
                    "--only",
                    "alpha-gate",
                ]
            )
            self.assertEqual(rc, 0)
            self.assertEqual(
                [p.name for p in out.glob("hooks-*.tar.zst")],
                ["hooks-alpha-gate-0.1.0.tar.zst"],
            )
            index = json.loads((out / "hooks-index.json").read_text(encoding="utf-8"))
            self.assertEqual(
                [recipe["id"] for recipe in index["recipes"]],
                ["alpha-gate", "beta-gate"],
            )


if __name__ == "__main__":
    unittest.main()

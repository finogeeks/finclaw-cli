#!/usr/bin/env python3
"""Pack official hook recipes into hooks-<id>-<version>.tar.zst + hooks-index.json."""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import stat
import subprocess
import sys
import tarfile
import tempfile
from datetime import datetime, timezone
from pathlib import Path

RECIPE_ID_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
VERSION_RE = re.compile(r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$")
SCHEMA_RECIPE = "hooks.recipe.v1"
SCHEMA_CATALOG = "hooks.catalog.v1"
INTERPRETERS = {"python3", "python", "py", "node", "bash", "sh"}


class PackError(ValueError):
    pass


def parse_version(s: str) -> tuple[int, int, int]:
    if not VERSION_RE.fullmatch(s):
        raise PackError(f"version must be MAJOR.MINOR.PATCH, got {s!r}")
    a, b, c = s.split(".")
    return int(a), int(b), int(c)


def validate_recipe_id(recipe_id: str) -> None:
    if recipe_id.startswith(".") or len(recipe_id) > 64 or not RECIPE_ID_RE.fullmatch(recipe_id):
        raise PackError(f"invalid recipe id {recipe_id!r}")


def _handler_commands(hooks_obj: object) -> list[dict]:
    if not isinstance(hooks_obj, dict):
        raise PackError("hooks must be an object")
    out: list[dict] = []
    for event, matchers in hooks_obj.items():
        if not isinstance(matchers, list):
            raise PackError(f"hooks.{event} must be an array")
        for group in matchers:
            if not isinstance(group, dict) or "hooks" not in group:
                raise PackError(f"hooks.{event} group missing hooks[]")
            for cmd in group["hooks"]:
                if not isinstance(cmd, dict):
                    raise PackError("command object must be an object")
                out.append(cmd)
    return out


def _script_word(command: str) -> str:
    words = command.split()
    if not words:
        raise PackError("empty command")
    if words[0].lower() in INTERPRETERS and len(words) > 1:
        return words[1]
    return words[0]


def load_recipe(recipe_json: Path) -> dict:
    raw = json.loads(recipe_json.read_text(encoding="utf-8"))
    if raw.get("schema") != SCHEMA_RECIPE:
        raise PackError(f"{recipe_json}: schema must be {SCHEMA_RECIPE}")
    recipe_id = raw.get("id")
    version = raw.get("version")
    min_cli = raw.get("min_cli")
    if not isinstance(recipe_id, str) or not isinstance(version, str) or not isinstance(min_cli, str):
        raise PackError(f"{recipe_json}: id, version, min_cli are required strings")
    validate_recipe_id(recipe_id)
    parse_version(version)
    parse_version(min_cli)
    if recipe_json.parent.name != recipe_id:
        raise PackError(f"{recipe_json}: directory name must match id {recipe_id!r}")
    if raw.get("id") != recipe_id:
        raise PackError(f"{recipe_json}: id mismatch")
    seen: set[str] = set()
    for cmd in _handler_commands(raw.get("hooks")):
        hid = cmd.get("id")
        if not isinstance(hid, str) or not hid:
            raise PackError(f"{recipe_json}: every command object must set id")
        if hid in seen:
            raise PackError(f"{recipe_json}: duplicate handler id {hid!r}")
        seen.add(hid)
        if "recipe" in cmd:
            raise PackError(f"{recipe_json}: command must not set recipe (install stamps it)")
        command = cmd.get("command")
        if not isinstance(command, str):
            raise PackError(f"{recipe_json}: command string required")
        if any(ch in command for ch in ('"', "'", "~", "$")):
            raise PackError(f"{recipe_json}: script command must be a bare relative path (no quotes/~/${{}})")
        script = _script_word(command)
        if script.startswith("/") or script.startswith("\\") or ".." in Path(script).parts:
            raise PackError(f"{recipe_json}: script path must be relative and inside the recipe")
        resolved = (recipe_json.parent / script).resolve()
        try:
            resolved.relative_to(recipe_json.parent.resolve())
        except ValueError as exc:
            raise PackError(f"{recipe_json}: script escapes recipe root") from exc
        if not resolved.is_file():
            raise PackError(f"{recipe_json}: script {script} is not a regular file")
    return raw


def collect_recipe_jsons(recipes_dir: Path) -> list[Path]:
    found = sorted(recipes_dir.glob("*/recipe.json"))
    return [p for p in found if p.is_file()]


def validate_recipe_tree(recipe_dir: Path) -> None:
    root_mode = recipe_dir.lstat().st_mode
    if stat.S_ISLNK(root_mode) or not stat.S_ISDIR(root_mode):
        raise PackError(f"{recipe_dir}: recipe root must be a real directory")
    for path in recipe_dir.rglob("*"):
        mode = path.lstat().st_mode
        if stat.S_ISLNK(mode):
            raise PackError(f"{path}: symlinks are not allowed in recipe packages")
        if not stat.S_ISDIR(mode) and not stat.S_ISREG(mode):
            raise PackError(f"{path}: recipe packages contain only regular files")


def _sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 16), b""):
            h.update(chunk)
    return h.hexdigest()


def _compress_tar_zst(src_dir: Path, top_name: str, dest: Path) -> None:
    tmp_tar = dest.parent / (dest.name + ".tmp.tar")
    with tarfile.open(tmp_tar, "w") as tf:
        tf.add(src_dir / top_name, arcname=top_name)
    zstd = shutil.which("zstd")
    if zstd is None:
        tmp_tar.unlink(missing_ok=True)
        raise PackError("zstd CLI is required to write .tar.zst")
    try:
        subprocess.run([zstd, "-f", "-q", "-o", str(dest), str(tmp_tar)], check=True)
    finally:
        tmp_tar.unlink(missing_ok=True)


def pack_one(
    recipe_dir: Path,
    out_dir: Path,
    asset_base_url: str,
    *,
    write_archive: bool = True,
) -> dict:
    validate_recipe_tree(recipe_dir)
    raw = load_recipe(recipe_dir / "recipe.json")
    recipe_id = raw["id"]
    version = raw["version"]
    top = f"{recipe_id}-{version}"
    archive_name = f"hooks-{recipe_id}-{version}.tar.zst"
    with tempfile.TemporaryDirectory() as tmp:
        staged = Path(tmp) / top
        shutil.copytree(recipe_dir, staged)
        packed_archive = Path(tmp) / archive_name
        _compress_tar_zst(Path(tmp), top, packed_archive)
        digest = _sha256_file(packed_archive)
        if write_archive:
            out_dir.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(packed_archive, out_dir / archive_name)
    base = asset_base_url.rstrip("/")
    url = f"{base}/{archive_name}"
    return {
        "id": recipe_id,
        "name": raw.get("name") or recipe_id,
        "summary": raw.get("summary") or "",
        "latest": version,
        "min_cli": raw["min_cli"],
        "versions": [
            {
                "version": version,
                "url": url,
                "sha256": digest,
                "min_cli": raw["min_cli"],
            }
        ],
    }


def write_index(recipes: list[dict], out_index: Path, updated_at: str) -> None:
    payload = {
        "schema": SCHEMA_CATALOG,
        "updated_at": updated_at,
        "recipes": recipes,
    }
    out_index.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def write_sha256sums(paths: list[Path], out_file: Path) -> None:
    lines = [f"{_sha256_file(p)}  {p.name}\n" for p in paths]
    out_file.write_text("".join(lines), encoding="utf-8")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Pack official hook recipes")
    parser.add_argument("--recipes-dir", type=Path, required=True)
    parser.add_argument("--out-dir", type=Path, required=True)
    parser.add_argument("--asset-base-url", required=True)
    parser.add_argument(
        "--updated-at",
        default=datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    )
    parser.add_argument(
        "--only",
        default="all",
        help="Recipe id to pack, or all",
    )
    args = parser.parse_args(argv)
    recipes_dir: Path = args.recipes_dir
    if not recipes_dir.is_dir():
        raise PackError(f"recipes dir missing: {recipes_dir}")
    jsons = collect_recipe_jsons(recipes_dir)
    selected_ids = {p.parent.name for p in jsons}
    if args.only != "all":
        selected_ids = {args.only}
        if args.only not in {p.parent.name for p in jsons}:
            raise PackError(f"recipe {args.only!r} has no recipe.json")
    args.out_dir.mkdir(parents=True, exist_ok=True)
    catalog: list[dict] = []
    archives: list[Path] = []
    for recipe_json in jsons:
        write_archive = recipe_json.parent.name in selected_ids
        rec = pack_one(
            recipe_json.parent,
            args.out_dir,
            args.asset_base_url,
            write_archive=write_archive,
        )
        catalog.append(rec)
        if write_archive:
            archives.append(
                args.out_dir / f"hooks-{rec['id']}-{rec['latest']}.tar.zst"
            )
    index_path = args.out_dir / "hooks-index.json"
    write_index(catalog, index_path, args.updated_at)
    write_sha256sums(archives + [index_path], args.out_dir / "SHA256SUMS")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except PackError as exc:
        print(f"error: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc

#!/usr/bin/env python3
"""Apply or check the repository's dependency-free text formatting contract."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[2]
TEXT_SUFFIXES = {
    ".asm", ".cfg", ".inc", ".java", ".json", ".lua", ".md", ".mk", ".py", ".txt"
}
TEXT_NAMES = {".editorconfig", ".gitattributes", ".gitignore", "Makefile"}
SKIP_PARTS = {
    ".git", ".cache", "__pycache__", "build", "fceux", "generated", "ghidra", "references"
}


class FormatError(ValueError):
    pass


def project_files() -> list[Path]:
    paths: list[Path] = []
    for path in ROOT.rglob("*"):
        if not path.is_file() or any(part in SKIP_PARTS for part in path.parts):
            continue
        if path.suffix.lower() in TEXT_SUFFIXES or path.name in TEXT_NAMES:
            paths.append(path)
    return sorted(paths)


def normalize_text(text: str) -> str:
    lines = text.replace("\r\n", "\n").replace("\r", "\n").split("\n")
    return "\n".join(line.rstrip() for line in lines).rstrip("\n") + "\n"


def formatted(path: Path) -> str:
    try:
        original = path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as exc:
        raise FormatError(f"cannot read text file {path}: {exc}") from exc
    if path.suffix.lower() == ".json":
        try:
            document = json.loads(original)
        except json.JSONDecodeError as exc:
            raise FormatError(f"invalid JSON {path}: {exc}") from exc
        return json.dumps(document, ensure_ascii=False, indent=2) + "\n"
    return normalize_text(original)


def command_write(_args: argparse.Namespace) -> None:
    changed = 0
    for path in project_files():
        original = path.read_text(encoding="utf-8")
        expected = formatted(path)
        if original == expected:
            continue
        path.write_text(expected, encoding="utf-8", newline="\n")
        changed += 1
        print(f"[FORMAT] {path.relative_to(ROOT)}")
    print(f"[OK] formatted {changed} file(s)")


def command_check(_args: argparse.Namespace) -> None:
    stale = [path.relative_to(ROOT) for path in project_files() if path.read_text(encoding="utf-8") != formatted(path)]
    if stale:
        raise FormatError("files need formatting: " + ", ".join(map(str, stale)))
    print(f"[OK] {len(project_files())} text files satisfy the formatting contract")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    write = subparsers.add_parser("write")
    write.set_defaults(handler=command_write)
    check = subparsers.add_parser("check")
    check.set_defaults(handler=command_check)
    args = parser.parse_args()
    try:
        args.handler(args)
    except (FormatError, OSError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

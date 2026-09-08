#!/usr/bin/env python3
"""Validate Python syntax and dependency-free source policy without bytecode."""

from __future__ import annotations

import argparse
import ast
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


class PythonSourceError(ValueError):
    """One or more Python sources violate the repository policy."""


def python_files(root: Path) -> list[Path]:
    paths: list[Path] = []
    for directory in (root / "scripts", root / "tests"):
        if directory.is_dir():
            paths.extend(
                path
                for path in directory.rglob("*.py")
                if "__pycache__" not in path.parts
            )
    return sorted(paths)


def validate_python_sources(root: Path) -> list[str]:
    errors: list[str] = []
    for path in python_files(root):
        relative = path.relative_to(root)
        try:
            source = path.read_text(encoding="utf-8")
            tree = ast.parse(source, filename=str(relative))
        except (OSError, UnicodeDecodeError, SyntaxError) as exc:
            errors.append(f"{relative}: {exc}")
            continue
        if relative.parts[0] == "scripts" and path.name != "__init__.py":
            if ast.get_docstring(tree) is None:
                errors.append(f"{relative}: executable module has no docstring")
        for node in ast.walk(tree):
            if isinstance(node, ast.ImportFrom) and any(
                alias.name == "*" for alias in node.names
            ):
                errors.append(
                    f"{relative}:{node.lineno}: wildcard import is not allowed"
                )
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-root", type=Path, default=ROOT)
    args = parser.parse_args()
    errors = validate_python_sources(args.project_root.resolve())
    if errors:
        for error in errors:
            print(f"[ERROR] {error}")
        return 1
    print(
        f"[OK] {len(python_files(args.project_root.resolve()))} Python files pass "
        "syntax and source policy"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

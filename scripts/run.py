#!/usr/bin/env python3
"""Run a categorized project tool with a stable repository-local import path."""

from __future__ import annotations

import runpy
import sys
from pathlib import Path


SCRIPT_ROOT = Path(__file__).resolve().parent
PUBLIC_CATEGORIES = {"authoring", "build", "runtime", "validation", "workflow"}


def available_tools() -> list[str]:
    tools: list[str] = []
    for category in sorted(PUBLIC_CATEGORIES):
        category_dir = SCRIPT_ROOT / category
        for path in category_dir.rglob("*.py"):
            if path.name == "__init__.py" or "__pycache__" in path.parts:
                continue
            tools.append(".".join(path.relative_to(SCRIPT_ROOT).with_suffix("").parts))
    return sorted(tools)


def require_tool(name: str) -> str:
    parts = name.split(".")
    if len(parts) < 2 or parts[0] not in PUBLIC_CATEGORIES:
        raise SystemExit(
            "tool must use <category.module> notation; "
            "run 'python scripts/run.py --list' to inspect available tools"
        )
    if any(not part.isidentifier() or part.startswith("_") for part in parts):
        raise SystemExit(f"invalid tool name: {name}")
    if name not in available_tools():
        raise SystemExit(f"unknown tool: {name}")
    return name


def main() -> int:
    if len(sys.argv) == 2 and sys.argv[1] == "--list":
        print("\n".join(available_tools()))
        return 0
    if len(sys.argv) < 2:
        raise SystemExit(
            "usage: python scripts/run.py <category.module> [arguments ...]"
        )

    module = require_tool(sys.argv[1])
    sys.path.insert(0, str(SCRIPT_ROOT.parent))
    sys.argv = [f"{module}.py", *sys.argv[2:]]
    runpy.run_module(f"scripts.{module}", run_name="__main__")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

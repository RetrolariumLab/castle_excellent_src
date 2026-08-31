#!/usr/bin/env python3
"""Audit semantic source ownership separately from preservation completeness."""

from __future__ import annotations

import argparse
from pathlib import Path
import re
import sys

if __package__:
    from .generate_disassembly import DisassemblyError, SourceRegion, load_source_layout
else:
    from generate_disassembly import DisassemblyError, SourceRegion, load_source_layout


ROOT = Path(__file__).resolve().parent.parent
INSTRUCTION_RE = re.compile(r"^\s+[A-Z]{3}(?:\s+(?P<operand>[^;]+?))?\s*$")
GENERIC_LABEL_RE = re.compile(r"^(?:Func|Label)_[0-9A-F]{4}(?::|\s*=)")
RAW_ADDRESS_RE = re.compile(r"(?<![#<>])(?:a:)?\$[0-9A-F]{2,4}")
MAX_SEMANTIC_LINES = 700


class ReconstructionError(ValueError):
    pass


def is_semantic(region: SourceRegion) -> bool:
    return "preservation" not in {part.lower() for part in region.path.parts}


def audit_module_text(path: Path, text: str) -> list[str]:
    issues: list[str] = []
    lines = text.splitlines()
    if len(lines) > MAX_SEMANTIC_LINES:
        issues.append(
            f"{path.as_posix()}: {len(lines)} lines exceed semantic module limit "
            f"{MAX_SEMANTIC_LINES}"
        )
    for line_number, line in enumerate(lines, 1):
        if GENERIC_LABEL_RE.match(line):
            issues.append(
                f"{path.as_posix()}:{line_number}: unresolved generic label in semantic module"
            )
        instruction = INSTRUCTION_RE.match(line)
        if instruction is None:
            continue
        operand = (instruction.group("operand") or "").strip()
        named_offsets_removed = re.sub(
            r"\b[A-Za-z_][A-Za-z0-9_]*\s*[+-]\s*\$[0-9A-F]{2,4}",
            "NamedExpression",
            operand,
        )
        if RAW_ADDRESS_RE.search(named_offsets_removed):
            issues.append(
                f"{path.as_posix()}:{line_number}: raw address operand in semantic module: "
                f"{operand}"
            )
    return issues


def audit_layout(layout_path: Path, root: Path = ROOT) -> tuple[int, int, int]:
    try:
        regions = load_source_layout(layout_path)
    except DisassemblyError as exc:
        raise ReconstructionError(str(exc)) from exc
    semantic = [region for region in regions if is_semantic(region)]
    if not semantic:
        raise ReconstructionError("source layout has no promoted semantic modules")
    issues: list[str] = []
    for region in semantic:
        path = root / region.path
        if not path.is_file():
            issues.append(f"semantic module not found: {region.path.as_posix()}")
            continue
        issues.extend(audit_module_text(region.path, path.read_text(encoding="utf-8")))
    if issues:
        raise ReconstructionError("\n".join(issues))
    semantic_bytes = sum(region.end - region.start for region in semantic)
    total_bytes = sum(region.end - region.start for region in regions)
    return len(semantic), semantic_bytes, total_bytes


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--layout", default="config/source_layout.json")
    args = parser.parse_args()
    try:
        module_count, semantic_bytes, total_bytes = audit_layout(
            ROOT / args.layout, ROOT
        )
    except (OSError, ReconstructionError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    percentage = semantic_bytes * 100 / total_bytes
    print(
        f"[OK] semantic source ownership: {module_count} module(s), "
        f"{semantic_bytes}/{total_bytes} PRG bytes ({percentage:.2f}%)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

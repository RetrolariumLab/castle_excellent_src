#!/usr/bin/env python3
"""Audit semantic source ownership separately from preservation completeness."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import sys

from scripts.workflow.generate_disassembly import (
    DisassemblyError,
    SourceRegion,
    load_known_symbols,
    load_memory_symbols,
    load_source_layout,
)


ROOT = Path(__file__).resolve().parents[2]
INSTRUCTION_RE = re.compile(r"^\s+[A-Z]{3}(?:\s+(?P<operand>[^;]+?))?\s*$")
GENERIC_LABEL_RE = re.compile(r"^(?:Func|Label)_[0-9A-F]{4}(?::|\s*=)")
RAW_ADDRESS_RE = re.compile(r"(?<![#<>])(?:a:)?\$[0-9A-F]{2,4}")
MAX_SEMANTIC_LINES = 700
MIN_SEMANTIC_LINES = 300
SYMBOL_KINDS = {"routine", "local", "data", "label", "table"}
SYMBOL_CONFIDENCE = {"confirmed", "high"}


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
    prefixes: dict[tuple[Path, str], list[Path]] = {}
    for region in semantic:
        path = root / region.path
        if not path.is_file():
            issues.append(f"semantic module not found: {region.path.as_posix()}")
            continue
        text = path.read_text(encoding="utf-8")
        line_count = len(text.splitlines())
        if line_count < MIN_SEMANTIC_LINES and not region.size_exception:
            issues.append(
                f"{region.path.as_posix()}: {line_count} lines are below the semantic "
                f"module target {MIN_SEMANTIC_LINES} without a size exception"
            )
        if line_count >= MIN_SEMANTIC_LINES and region.size_exception:
            issues.append(
                f"{region.path.as_posix()}: obsolete size exception on a "
                f"{line_count}-line module"
            )
        issues.extend(audit_module_text(region.path, text))
        prefix = region.path.stem.split("_", 1)[0].lower()
        prefixes.setdefault((region.path.parent, prefix), []).append(region.path)
    for (directory, prefix), paths in prefixes.items():
        if len(paths) > 1:
            joined = ", ".join(path.name for path in paths)
            issues.append(
                f"{directory.as_posix()}: repeated source prefix {prefix!r}: {joined}"
            )
    if issues:
        raise ReconstructionError("\n".join(issues))
    semantic_bytes = sum(region.end - region.start for region in semantic)
    total_bytes = sum(region.end - region.start for region in regions)
    return len(semantic), semantic_bytes, total_bytes


def audit_symbol_maps(
    symbols_path: Path,
    memory_symbols_path: Path,
    layout_path: Path,
) -> tuple[int, int, int, int]:
    """Validate the machine-readable PRG routine/label and RAM symbol ledgers."""
    try:
        prg_symbols = load_known_symbols(symbols_path)
        memory_symbols = load_memory_symbols(memory_symbols_path)
        symbol_document = json.loads(symbols_path.read_text(encoding="utf-8"))
        regions = load_source_layout(layout_path)
    except (DisassemblyError, json.JSONDecodeError, OSError) as exc:
        raise ReconstructionError(str(exc)) from exc

    issues: list[str] = []
    records = symbol_document.get("symbols", [])
    record_addresses: set[int] = set()
    routine_count = 0
    for item in records:
        if not isinstance(item, dict):
            issues.append("invalid PRG symbol record")
            continue
        address = int(str(item.get("address", "-1")), 0)
        kind = item.get("kind")
        confidence = item.get("confidence")
        if kind not in SYMBOL_KINDS:
            issues.append(f"PRG symbol ${address:04X} has invalid kind {kind!r}")
        if confidence not in SYMBOL_CONFIDENCE:
            issues.append(
                f"PRG symbol ${address:04X} has invalid confidence {confidence!r}"
            )
        if kind == "routine":
            routine_count += 1
        owners = [region for region in regions if region.start <= address < region.end]
        if len(owners) != 1:
            issues.append(
                f"PRG symbol ${address:04X} belongs to {len(owners)} source regions"
            )
        record_addresses.add(address)

    if record_addresses != set(prg_symbols):
        issues.append("PRG symbol metadata and address/name map disagree")
    scoped_memory_count = sum(
        symbol.start != 0x8000 or symbol.end != 0x10000
        for symbol in memory_symbols
    )
    if issues:
        raise ReconstructionError("\n".join(issues))
    return len(prg_symbols), routine_count, len(memory_symbols), scoped_memory_count


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--layout", default="config/source_layout.json")
    parser.add_argument("--symbols", default="config/symbols.json")
    parser.add_argument("--memory-symbols", default="config/memory_symbols.json")
    args = parser.parse_args()
    try:
        module_count, semantic_bytes, total_bytes = audit_layout(
            ROOT / args.layout, ROOT
        )
        prg_count, routine_count, memory_count, scoped_memory_count = (
            audit_symbol_maps(
                ROOT / args.symbols,
                ROOT / args.memory_symbols,
                ROOT / args.layout,
            )
        )
    except (OSError, ReconstructionError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    percentage = semantic_bytes * 100 / total_bytes
    print(
        f"[OK] semantic source ownership: {module_count} module(s), "
        f"{semantic_bytes}/{total_bytes} PRG bytes ({percentage:.2f}%)"
    )
    print(
        f"[OK] symbol maps: {prg_count} PRG labels ({routine_count} routines), "
        f"{memory_count} RAM/I/O aliases ({scoped_memory_count} scoped)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

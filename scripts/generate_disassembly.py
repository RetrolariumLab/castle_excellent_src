#!/usr/bin/env python3
"""Generate deterministic ca65 PRG source from Ghidra instruction facts."""

from __future__ import annotations

import argparse
import csv
from dataclasses import dataclass
import json
from pathlib import Path
import re
import sys


PRG_START = 0x8000
PRG_END = 0x10000
CONTROL_MNEMONICS = {
    "BCC", "BCS", "BEQ", "BMI", "BNE", "BPL", "BVC", "BVS", "JMP", "JSR"
}
BRANCH_MNEMONICS = {"BCC", "BCS", "BEQ", "BMI", "BNE", "BPL", "BVC", "BVS"}
HEX_RE = re.compile(r"0x([0-9a-fA-F]+)")


class DisassemblyError(ValueError):
    pass


@dataclass(frozen=True)
class InstructionFact:
    address: int
    length: int
    raw: bytes
    mnemonic: str
    operands: str
    flows: tuple[int, ...]
    flow_type: str
    symbol: str
    function: str


@dataclass(frozen=True)
class MemorySymbol:
    address: int
    name: str
    start: int
    end: int
    size: int = 1


@dataclass(frozen=True)
class SourceRegion:
    path: Path
    start: int
    end: int
    title: str
    segment: str | None
    includes_after: tuple[str, ...]


@dataclass(frozen=True)
class OperandOverride:
    expected: str
    operand: str
    evidence: str


def parse_flow(value: str) -> int:
    tail = value.rsplit("::", 1)[-1]
    return int(tail, 16)


def load_facts(path: Path, prg: bytes) -> dict[int, InstructionFact]:
    try:
        stream = path.open("r", encoding="utf-8", newline="")
    except OSError as exc:
        raise DisassemblyError(f"cannot read Ghidra facts {path}: {exc}") from exc
    facts: dict[int, InstructionFact] = {}
    occupied: set[int] = set()
    with stream:
        for row in csv.DictReader(stream, delimiter="\t"):
            address = int(row["address"], 16)
            raw = bytes.fromhex(row["bytes"])
            length = int(row["length"])
            if len(raw) != length:
                raise DisassemblyError(f"instruction ${address:04X} has inconsistent length")
            offset = address - PRG_START
            if not 0 <= offset <= len(prg) - length:
                raise DisassemblyError(f"instruction ${address:04X} is outside PRG")
            if prg[offset:offset + length] != raw:
                raise DisassemblyError(f"Ghidra bytes disagree with PRG at ${address:04X}")
            addresses = set(range(address, address + length))
            if occupied & addresses:
                raise DisassemblyError(f"overlapping instruction at ${address:04X}")
            occupied.update(addresses)
            facts[address] = InstructionFact(
                address=address,
                length=length,
                raw=raw,
                mnemonic=row["mnemonic"].upper(),
                operands=row["operands"],
                flows=tuple(parse_flow(value) for value in row["flows"].split("|") if value),
                flow_type=row["flow_type"],
                symbol=row["symbol"],
                function=row["function"],
            )
    if not facts:
        raise DisassemblyError("Ghidra facts contain no instructions")
    return facts


def load_known_symbols(path: Path) -> dict[int, str]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise DisassemblyError(f"cannot read symbols {path}: {exc}") from exc
    if document.get("schema_version") != 1 or not isinstance(document.get("symbols"), list):
        raise DisassemblyError("unsupported symbols schema")
    result: dict[int, str] = {}
    names: set[str] = set()
    for item in document["symbols"]:
        if not isinstance(item, dict):
            raise DisassemblyError("invalid symbol entry")
        address = int(str(item["address"]), 0)
        name = str(item["name"])
        if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", name):
            raise DisassemblyError(f"invalid ca65 symbol name: {name!r}")
        if address in result or name.lower() in names:
            raise DisassemblyError(f"duplicate symbol at ${address:04X}: {name}")
        result[address] = name
        names.add(name.lower())
    return result


def load_memory_symbols(path: Path) -> list[MemorySymbol]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise DisassemblyError(f"cannot read memory symbols {path}: {exc}") from exc
    if document.get("schema_version") != 1 or not isinstance(document.get("symbols"), list):
        raise DisassemblyError("unsupported memory-symbol schema")
    result: list[MemorySymbol] = []
    names: set[str] = set()
    for item in document["symbols"]:
        if not isinstance(item, dict):
            raise DisassemblyError("invalid memory-symbol entry")
        address = int(str(item["address"]), 0)
        name = str(item["name"])
        start = int(str(item.get("start", PRG_START)), 0)
        end = int(str(item.get("end", PRG_END)), 0)
        size = int(str(item.get("size", 1)), 0)
        if not 0 <= address < PRG_START:
            raise DisassemblyError(f"memory symbol is outside CPU RAM/I/O: {name}")
        if not PRG_START <= start < end <= PRG_END:
            raise DisassemblyError(f"invalid scope for memory symbol {name}")
        if size < 1 or address + size > PRG_START:
            raise DisassemblyError(f"invalid size for memory symbol {name}: {size}")
        if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", name):
            raise DisassemblyError(f"invalid ca65 memory symbol name: {name!r}")
        if name.lower() in names:
            raise DisassemblyError(f"duplicate memory symbol name: {name}")
        for existing in result:
            if existing.address == address and max(existing.start, start) < min(existing.end, end):
                raise DisassemblyError(
                    f"overlapping memory-symbol scopes at ${address:04X}: "
                    f"{existing.name} and {name}"
                )
        result.append(MemorySymbol(address, name, start, end, size))
        names.add(name.lower())
    return result


def load_source_layout(path: Path) -> list[SourceRegion]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise DisassemblyError(f"cannot read source layout {path}: {exc}") from exc
    if document.get("schema_version") != 1 or not isinstance(document.get("files"), list):
        raise DisassemblyError("unsupported source-layout schema")
    result: list[SourceRegion] = []
    expected_start = PRG_START
    seen_paths: set[Path] = set()
    for item in document["files"]:
        if not isinstance(item, dict):
            raise DisassemblyError("invalid source-layout entry")
        relative = Path(str(item["path"]))
        if relative.is_absolute() or ".." in relative.parts:
            raise DisassemblyError(f"unsafe source-layout path: {relative}")
        start = int(str(item["start"]), 0)
        end = int(str(item["end"]), 0)
        if start != expected_start or not start < end <= PRG_END:
            raise DisassemblyError(
                f"source layout must be contiguous at ${expected_start:04X}: {relative}"
            )
        if relative in seen_paths:
            raise DisassemblyError(f"duplicate source-layout path: {relative}")
        segment_value = item.get("segment")
        segment = str(segment_value) if segment_value is not None else None
        includes = item.get("includes_after", [])
        if not isinstance(includes, list) or not all(isinstance(value, str) for value in includes):
            raise DisassemblyError(f"invalid includes_after list: {relative}")
        result.append(
            SourceRegion(
                relative,
                start,
                end,
                str(item["title"]),
                segment,
                tuple(includes),
            )
        )
        expected_start = end
        seen_paths.add(relative)
    if expected_start != PRG_END:
        raise DisassemblyError("source layout does not cover the complete PRG")
    if sum(region.segment == "PRG" for region in result) != 1:
        raise DisassemblyError("source layout must declare the PRG segment exactly once")
    return result


def load_operand_overrides(path: Path) -> dict[int, OperandOverride]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise DisassemblyError(f"cannot read operand overrides {path}: {exc}") from exc
    if document.get("schema_version") != 1 or not isinstance(document.get("overrides"), list):
        raise DisassemblyError("unsupported operand-override schema")
    result: dict[int, OperandOverride] = {}
    for item in document["overrides"]:
        if not isinstance(item, dict):
            raise DisassemblyError("invalid operand-override entry")
        address = int(str(item["instruction"]), 0)
        expected = str(item["expected"])
        operand = str(item["operand"])
        evidence = str(item["evidence"])
        if address in result:
            raise DisassemblyError(f"duplicate operand override at ${address:04X}")
        if not PRG_START <= address < PRG_END:
            raise DisassemblyError(f"operand override is outside PRG: ${address:04X}")
        if not evidence.strip():
            raise DisassemblyError(f"operand override lacks evidence at ${address:04X}")
        if not re.fullmatch(r"[#<>()>+,$ A-Za-z0-9_-]+", operand):
            raise DisassemblyError(f"unsafe ca65 operand override at ${address:04X}")
        result[address] = OperandOverride(expected, operand, evidence)
    return result


def make_labels(
    facts: dict[int, InstructionFact], known: dict[int, str]
) -> dict[int, str]:
    labels = dict(known)
    function_entries = {fact.address for fact in facts.values() if fact.function}
    call_targets: set[int] = set()
    branch_targets: set[int] = set()
    jump_targets: set[int] = set()
    for fact in facts.values():
        for target in fact.flows:
            if not PRG_START <= target < PRG_END:
                continue
            if fact.mnemonic == "JSR":
                call_targets.add(target)
            elif fact.mnemonic in BRANCH_MNEMONICS:
                branch_targets.add(target)
            elif (
                fact.mnemonic == "JMP"
                and not fact.operands.replace("PRG0::", "").startswith("(")
            ):
                jump_targets.add(target)
    for address in sorted(function_entries | call_targets):
        labels.setdefault(address, f"Func_{address:04X}")
    for address in sorted(branch_targets | jump_targets):
        labels.setdefault(address, f"Label_{address:04X}")
    return labels


def numeric_operand(fact: InstructionFact) -> str:
    operand = fact.operands.replace("PRG0::", "")

    def replace(match: re.Match[str]) -> str:
        value = int(match.group(1), 16)
        width = 2 if fact.length == 2 else 4
        return f"${value:0{width}X}"

    operand = HEX_RE.sub(replace, operand)
    if fact.length == 3 and fact.mnemonic not in ("JMP", "JSR"):
        if re.fullmatch(r"\$[0-9A-F]{4}(?:,[XY])?", operand):
            operand = "a:" + operand
    return operand


def memory_operand(
    fact: InstructionFact, operand: str, symbols: list[MemorySymbol]
) -> str:
    if operand.startswith("#"):
        return operand

    def replace(match: re.Match[str]) -> str:
        address = int(match.group(1), 16)
        matches = [
            (symbol, address - symbol.address)
            for symbol in symbols
            if symbol.address <= address < symbol.address + symbol.size
            and symbol.start <= fact.address < symbol.end
        ]
        exact = [candidate for candidate in matches if candidate[1] == 0]
        if exact:
            matches = exact
        if len(matches) > 1:
            raise DisassemblyError(
                f"ambiguous memory symbol at ${fact.address:04X} for ${address:04X}"
            )
        if not matches:
            return match.group(0)
        symbol, offset = matches[0]
        return symbol.name if offset == 0 else f"{symbol.name} + ${offset:02X}"

    result = re.sub(r"\$([0-9A-F]{2,4})", replace, operand)
    if result != operand and result.startswith("a:"):
        original_address = re.search(r"\$([0-9A-F]{2,4})", operand)
        if original_address is not None and int(original_address.group(1), 16) >= 0x100:
            result = result[2:]
    return result


def program_operand(operand: str, labels: dict[int, str]) -> str:
    if operand.startswith("#"):
        return operand

    def replace(match: re.Match[str]) -> str:
        address = int(match.group(1), 16)
        return labels.get(address, match.group(0))

    result = re.sub(r"\$([89A-F][0-9A-F]{3})", replace, operand)
    if result != operand and result.startswith("a:"):
        result = result[2:]
    return result


def format_instruction(
    fact: InstructionFact,
    labels: dict[int, str],
    memory_symbols: list[MemorySymbol] | None = None,
    operand_overrides: dict[int, OperandOverride] | None = None,
) -> str:
    operand = numeric_operand(fact)
    internal_flows = [target for target in fact.flows if PRG_START <= target < PRG_END]
    direct_control = (
        fact.mnemonic in CONTROL_MNEMONICS and
        (fact.mnemonic != "JMP" or not operand.startswith("("))
    )
    override = (operand_overrides or {}).get(fact.address)
    if override is not None:
        if operand != override.expected:
            raise DisassemblyError(
                f"operand override at ${fact.address:04X} expected "
                f"{override.expected}, got {operand}"
            )
        operand = override.operand
    elif direct_control:
        if len(internal_flows) != 1:
            raise DisassemblyError(
                f"direct control transfer ${fact.address:04X} has {len(internal_flows)} PRG targets"
            )
        target = internal_flows[0]
        if target not in labels:
            raise DisassemblyError(f"control target ${target:04X} has no label")
        operand = labels[target]
    else:
        operand = program_operand(operand, labels)
        operand = memory_operand(fact, operand, memory_symbols or [])
    statement = fact.mnemonic.upper()
    if operand:
        statement += " " + operand
    return "    " + statement


def data_line(address: int, payload: bytes) -> str:
    values = ", ".join(f"${value:02X}" for value in payload)
    return f"    .byte {values}"


def generate(
    prg: bytes,
    facts: dict[int, InstructionFact],
    labels: dict[int, str],
    memory_symbols: list[MemorySymbol] | None = None,
    operand_overrides: dict[int, OperandOverride] | None = None,
    *,
    start: int = PRG_START,
    end: int = PRG_END,
    title: str = "Address-ordered 32 KiB Castle Excellent PRG preservation listing",
    segment: str | None = "PRG",
    includes_after: tuple[str, ...] = (),
) -> str:
    lines = [
        f"; {title}",
        f"; CPU range ${start:04X}-${end - 1:04X}",
        "; Generated deterministically from pinned Ghidra/GhidraNes facts",
        "; Keep byte-identical through make verify",
        "",
    ]
    if segment is not None:
        lines.extend((f'.segment "{segment}"', ""))
    byte_owner: dict[int, int] = {}
    for fact in facts.values():
        for owned in range(fact.address, fact.address + fact.length):
            byte_owner[owned] = fact.address
    interior_labels: dict[int, list[tuple[int, str]]] = {}
    for label_address, label_name in labels.items():
        owner = byte_owner.get(label_address)
        if owner is not None and owner != label_address:
            interior_labels.setdefault(owner, []).append((label_address, label_name))

    address = start
    while address < end:
        aliases = interior_labels.get(address, [])
        if aliases:
            if lines[-1] != "":
                lines.append("")
            for alias_address, alias_name in sorted(aliases):
                lines.append(
                    f"{alias_name} = * + {alias_address - address}"
                    f"  ; overlapping entry ${alias_address:04X}"
                )
        label = labels.get(address)
        if label:
            if len(lines) > 0 and lines[-1] != "":
                lines.append("")
            lines.append(label + ":")
        if address == 0xFFFA:
            expected = bytes((0x69, 0xC5, 0x25, 0x82, 0xB8, 0xC6))
            if prg[address - PRG_START:address - PRG_START + 6] != expected:
                raise DisassemblyError("interrupt vectors differ from the named baseline")
            lines.append("    .addr Nmi")
            lines.append("")
            lines.append("ResetVector:")
            lines.append("    .addr Reset")
            lines.append("")
            lines.append("IrqVector:")
            lines.append("    .addr Irq")
            address += 6
            continue
        fact = facts.get(address)
        if fact is not None:
            if address + fact.length > end:
                raise DisassemblyError(f"source boundary splits instruction at ${address:04X}")
            lines.append(
                format_instruction(fact, labels, memory_symbols, operand_overrides)
            )
            address += fact.length
            continue
        data_start = address
        limit = min(address + 16, end)
        while address < limit:
            if address != data_start and (
                address in labels or address in facts or address == 0xFFFA
            ):
                break
            address += 1
        if address == data_start:
            raise DisassemblyError(f"generator made no progress at ${address:04X}")
        lines.append(
            data_line(data_start, prg[data_start - PRG_START:address - PRG_START])
        )
    if includes_after:
        if lines[-1] != "":
            lines.append("")
        lines.extend(f'.include "{include}"' for include in includes_after)
    text = "\n".join(lines).rstrip() + "\n"
    for address, label in labels.items():
        if not start <= address < end:
            continue
        if f"{label}:" not in text and f"{label} = " not in text:
            raise DisassemblyError(f"label {label} was not emitted")
    return text


def build_sources(args: argparse.Namespace) -> dict[Path, str]:
    prg = Path(args.prg).read_bytes()
    if len(prg) != PRG_END - PRG_START:
        raise DisassemblyError(f"PRG must be 32768 bytes, got {len(prg)}")
    facts = load_facts(Path(args.facts), prg)
    known = load_known_symbols(Path(args.symbols))
    labels = make_labels(facts, known)
    memory_symbols = load_memory_symbols(Path(args.memory_symbols))
    operand_overrides = load_operand_overrides(Path(args.operand_overrides))
    missing_overrides = sorted(set(operand_overrides) - set(facts))
    if missing_overrides:
        raise DisassemblyError(
            "operand override has no instruction fact: "
            + ", ".join(f"${address:04X}" for address in missing_overrides)
        )
    if args.layout:
        sources: dict[Path, str] = {}
        for region in load_source_layout(Path(args.layout)):
            sources[region.path] = generate(
                prg,
                facts,
                labels,
                memory_symbols,
                operand_overrides,
                start=region.start,
                end=region.end,
                title=region.title,
                segment=region.segment,
                includes_after=region.includes_after,
            )
        return sources
    if not args.output:
        raise DisassemblyError("either --output or --layout is required")
    return {
        Path(args.output): generate(
            prg, facts, labels, memory_symbols, operand_overrides
        )
    }


def command_write(args: argparse.Namespace) -> None:
    for output, text in build_sources(args).items():
        output.parent.mkdir(parents=True, exist_ok=True)
        if output.is_file() and output.read_text(encoding="utf-8") == text:
            print(f"[OK] unchanged {output}")
            continue
        output.write_text(text, encoding="utf-8", newline="\n")
        print(f"[WRITE] {output} ({len(text.splitlines())} lines)")


def command_check(args: argparse.Namespace) -> None:
    sources = build_sources(args)
    for output, expected in sources.items():
        if not output.is_file() or output.read_text(encoding="utf-8") != expected:
            raise DisassemblyError(
                f"generated disassembly is stale: {output}; run make disassemble"
            )
        numeric_control = re.search(
            r"^\s*(?:bcc|bcs|beq|bmi|bne|bpl|bvc|bvs|jmp|jsr)\s+(?:\$|0x)[0-9a-f]",
            expected,
            re.IGNORECASE | re.MULTILINE,
        )
        if numeric_control:
            raise DisassemblyError(
                f"numeric control-flow operand remains: {numeric_control.group(0).strip()}"
            )
        print(f"[OK] deterministic source and symbolic control flow: {output}")


def add_common(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--prg", required=True)
    parser.add_argument("--facts", required=True)
    parser.add_argument("--symbols", required=True)
    parser.add_argument("--memory-symbols", required=True)
    parser.add_argument("--operand-overrides", required=True)
    parser.add_argument("--output")
    parser.add_argument("--layout")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    write = subparsers.add_parser("write")
    add_common(write)
    write.set_defaults(handler=command_write)
    check = subparsers.add_parser("check")
    add_common(check)
    check.set_defaults(handler=command_check)
    args = parser.parse_args()
    try:
        args.handler(args)
    except (DisassemblyError, OSError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

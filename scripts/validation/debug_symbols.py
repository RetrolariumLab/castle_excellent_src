#!/usr/bin/env python3
"""Validate ld65 source mappings and export live FCEUX symbol artifacts."""

from __future__ import annotations

import argparse
from collections import defaultdict
import json
from pathlib import Path
import posixpath
import re


RECORD_FIELD_RE = re.compile(r'(?:^|,)([a-z]+)=("(?:[^"]|"")*"|[^,]*)')
VICE_LABEL_RE = re.compile(r"^al ([0-9A-Fa-f]{6}) \.([A-Za-z_][A-Za-z0-9_]*)$")
EXPECTED_SEGMENT_OFFSETS = {
    "HEADER": 0,
    "PRG": 16,
    "CHR": 16 + 32_768,
}
EXPECTED_SOURCE_SYMBOLS = {
    "Reset": "src/system/famicom_platform.asm",
    "MainFrameLoop": "src/system/famicom_platform.asm",
    "HandleLiftControlBlockHorizontalCollision": (
        "src/game/objects/lifts/linked_control.asm"
    ),
    "UpdateRuntimeObjects": "src/game/runtime/frame_pipeline.asm",
    "DecodeRoom": "src/rendering/rooms/upload_and_decode.asm",
    "UpdateAudioStreams": "src/audio/music_engine.asm",
    "Nmi": "src/rendering/frame_pipeline.asm",
}
REQUIRED_RAM_SYMBOLS = {
    "RuntimeObjectRecords": 0x004A,
    "RoomCells": 0x0400,
    "NmiFrameCountdown": 0x00FC,
}


def parse_record(line: str) -> tuple[str, dict[str, str]]:
    kind, separator, payload = line.partition("\t")
    if not separator:
        return kind, {}
    fields: dict[str, str] = {}
    for match in RECORD_FIELD_RE.finditer(payload.rstrip("\n")):
        value = match.group(2)
        if value.startswith('"') and value.endswith('"'):
            value = value[1:-1].replace('""', '"')
        fields[match.group(1)] = value
    return kind, fields


def load_vice_labels(path: Path) -> list[tuple[int, str]]:
    labels: list[tuple[int, str]] = []
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        match = VICE_LABEL_RE.fullmatch(line)
        if match:
            labels.append((int(match.group(1), 16), match.group(2)))
        elif line.strip():
            raise ValueError(f"unsupported label line {path}:{line_number}: {line}")
    return labels


def load_debug_records(path: Path) -> list[tuple[str, dict[str, str]]]:
    return [parse_record(line) for line in path.read_text(encoding="utf-8").splitlines()]


def load_debug_symbols(records: list[tuple[str, dict[str, str]]]) -> list[tuple[int, str, str]]:
    symbols: list[tuple[int, str, str]] = []
    for kind, fields in records:
        if kind != "sym" or "val" not in fields or "name" not in fields:
            continue
        symbols.append((int(fields["val"], 0), fields["name"], fields.get("type", "")))
    return symbols


def load_source_layout_paths(path: Path) -> set[str]:
    document = json.loads(path.read_text(encoding="utf-8"))
    files = document.get("files")
    if document.get("schema_version") != 1 or not isinstance(files, list):
        raise ValueError(f"unsupported source-layout schema: {path}")
    result = {str(item.get("path", "")).replace("\\", "/") for item in files}
    if not result or "" in result:
        raise ValueError(f"source layout contains an invalid path: {path}")
    return result


def validate_debug_file_coverage(
    records: list[tuple[str, dict[str, str]]], expected_paths: set[str]
) -> None:
    files: dict[int, str] = {}
    line_file_ids: set[int] = set()
    for kind, fields in records:
        if kind == "file" and "id" in fields and "name" in fields:
            files[int(fields["id"], 0)] = posixpath.normpath(
                fields["name"].replace("\\", "/")
            )
        elif kind == "line" and "file" in fields:
            line_file_ids.add(int(fields["file"], 0))
    covered = {
        expected
        for expected in expected_paths
        if any(
            file_id in line_file_ids and source.endswith(expected)
            for file_id, source in files.items()
        )
    }
    missing = sorted(expected_paths - covered)
    if missing:
        raise ValueError(
            "debug file lacks source-line mappings for: " + ", ".join(missing)
        )


def choose_unique_addresses(
    labels: list[tuple[int, str]], preferred_names: set[str] | None = None
) -> list[tuple[int, str]]:
    preferred_names = preferred_names or set()
    by_address: dict[int, list[str]] = defaultdict(list)
    for address, name in labels:
        by_address[address].append(name)
    selected: list[tuple[int, str]] = []
    for address, names in sorted(by_address.items()):
        preferred = sorted(set(names) & preferred_names)
        selected.append((address, preferred[0] if preferred else sorted(names)[0]))
    return selected


def load_config(path: Path, collection: str) -> list[dict[str, object]]:
    document = json.loads(path.read_text(encoding="utf-8"))
    if document.get("schema_version") != 1:
        raise ValueError(f"unsupported debugger config schema: {path}")
    entries = document.get(collection)
    if not isinstance(entries, list) or not entries:
        raise ValueError(f"missing non-empty {collection} list: {path}")
    if not all(isinstance(entry, dict) for entry in entries):
        raise ValueError(f"invalid {collection} entry: {path}")
    return entries


def resolve_config(
    entries: list[dict[str, object]],
    symbol_addresses: dict[str, int],
    path: Path,
) -> list[dict[str, object]]:
    resolved: list[dict[str, object]] = []
    for entry in entries:
        symbol = entry.get("symbol", entry.get("name"))
        if not isinstance(symbol, str) or symbol not in symbol_addresses:
            raise ValueError(f"unknown debugger symbol in {path}: {symbol!r}")
        configured = entry.get("address")
        if not isinstance(configured, str):
            raise ValueError(f"debugger entry has no fixed address in {path}: {symbol}")
        expected_address = int(configured, 0)
        actual_address = symbol_addresses[symbol]
        if actual_address != expected_address:
            raise ValueError(
                f"stale debugger address for {symbol}: "
                f"${expected_address:04X} != ${actual_address:04X}"
            )
        item = dict(entry)
        item["symbol"] = symbol
        item["resolved_address"] = actual_address
        item["resolved_address_hex"] = f"${actual_address:04X}"
        resolved.append(item)
    return resolved


def validate_source_mappings(
    records: list[tuple[str, dict[str, str]]],
    required: dict[str, str],
) -> None:
    files: dict[int, str] = {}
    lines: dict[int, tuple[int, int]] = {}
    symbols: dict[str, dict[str, str]] = {}
    for kind, fields in records:
        if kind == "file" and "id" in fields and "name" in fields:
            files[int(fields["id"], 0)] = fields["name"]
        elif kind == "line" and {"id", "file", "line"} <= fields.keys():
            lines[int(fields["id"], 0)] = (
                int(fields["file"], 0),
                int(fields["line"], 0),
            )
        elif kind == "sym" and "name" in fields:
            symbols[fields["name"]] = fields
    for symbol, expected_suffix in required.items():
        fields = symbols.get(symbol)
        if not fields or "def" not in fields:
            raise ValueError(f"symbol lacks source definition: {symbol}")
        definition_id = int(fields["def"].split("+")[0], 0)
        if definition_id not in lines:
            raise ValueError(f"definition line missing for symbol: {symbol}")
        file_id, source_line = lines[definition_id]
        source_path = Path(files.get(file_id, ""))
        source_name = source_path.resolve().as_posix()
        if not source_name.endswith(expected_suffix):
            raise ValueError(
                f"unexpected source mapping for {symbol}: "
                f"{source_name}:{source_line}"
            )
        if source_path.is_file():
            source_text = source_path.read_text(encoding="utf-8").splitlines()
            if (
                source_line < 1
                or source_line > len(source_text)
                or not source_text[source_line - 1].startswith(f"{symbol}:")
            ):
                raise ValueError(
                    f"stale source line for {symbol}: {source_path}:{source_line}"
                )


def write_fceux_labels(
    debug_symbols: list[tuple[int, str, str]],
    linker_labels: list[tuple[int, str]],
    rom_path: Path,
    output_dir: Path,
    preferred_ram_names: set[str],
) -> tuple[Path, Path, int, int]:
    rom_labels = [(address, name) for address, name in linker_labels if address >= 0x8000]
    ram_labels = [
        (address, name)
        for address, name, symbol_type in debug_symbols
        if address < 0x8000 and symbol_type in {"equ", "lab"}
    ]
    selected_rom = choose_unique_addresses(rom_labels)
    selected_ram = choose_unique_addresses(ram_labels, preferred_ram_names)
    output_dir.mkdir(parents=True, exist_ok=True)
    rom_output = output_dir / f"{rom_path.name}.0.nl"
    ram_output = output_dir / f"{rom_path.name}.ram.nl"
    for output, selected in ((rom_output, selected_rom), (ram_output, selected_ram)):
        output.write_text(
            "".join(f"${address:04X}#{name}#\n" for address, name in selected),
            encoding="utf-8",
            newline="\n",
        )
    return rom_output, ram_output, len(selected_rom), len(selected_ram)


def build_summary(args: argparse.Namespace) -> dict[str, object]:
    records = load_debug_records(args.debug)
    counts: dict[str, int] = defaultdict(int)
    segment_offsets: dict[str, int] = {}
    for kind, fields in records:
        counts[kind] += 1
        if kind == "seg" and Path(fields.get("oname", "")).name == args.rom.name:
            segment_offsets[fields["name"]] = int(fields["ooffs"], 0)
    if not counts["file"] or not counts["line"] or not counts["span"]:
        raise ValueError("debug file lacks complete source-line mappings")
    expected_source_paths = load_source_layout_paths(args.source_layout)
    validate_debug_file_coverage(records, expected_source_paths)
    if segment_offsets != EXPECTED_SEGMENT_OFFSETS:
        raise ValueError(f"unexpected iNES segment offsets: {segment_offsets}")
    rom = args.rom.read_bytes()
    if len(rom) != 65_552 or rom[:4] != b"NES\x1a":
        raise ValueError(f"debugger ROM is not the expected complete iNES image: {args.rom}")
    map_text = args.map.read_text(encoding="utf-8")
    if not all(name in map_text for name in EXPECTED_SEGMENT_OFFSETS):
        raise ValueError("map file lacks HEADER/PRG/CHR segments")

    debug_symbols = load_debug_symbols(records)
    symbol_addresses: dict[str, int] = {}
    for address, name, _ in debug_symbols:
        symbol_addresses.setdefault(name, address)
    linker_labels = load_vice_labels(args.labels)
    linker_names = {name: address for address, name in linker_labels}
    for symbol in EXPECTED_SOURCE_SYMBOLS:
        if symbol not in linker_names:
            raise ValueError(f"required linker label missing: {symbol}")
    for symbol, address in REQUIRED_RAM_SYMBOLS.items():
        if symbol_addresses.get(symbol) != address:
            raise ValueError(f"required RAM symbol missing or moved: {symbol}")
    validate_source_mappings(records, EXPECTED_SOURCE_SYMBOLS)

    breakpoints = resolve_config(
        load_config(args.breakpoints, "breakpoints"), symbol_addresses, args.breakpoints
    )
    watches = resolve_config(
        load_config(args.watches, "watches"), symbol_addresses, args.watches
    )
    preferred_ram_names = {str(item["symbol"]) for item in watches}
    rom_nl, ram_nl, rom_label_count, ram_label_count = write_fceux_labels(
        debug_symbols,
        linker_labels,
        args.rom,
        args.output_dir,
        preferred_ram_names,
    )
    return {
        "debug_file": str(args.debug),
        "map_file": str(args.map),
        "labels_file": str(args.labels),
        "rom_file": str(args.rom),
        "fceux_rom_labels": str(rom_nl),
        "fceux_ram_labels": str(ram_nl),
        "record_counts": dict(counts),
        "source_module_count": len(expected_source_paths),
        "rom_label_count": rom_label_count,
        "ram_label_count": ram_label_count,
        "breakpoints": breakpoints,
        "watches": watches,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--debug", required=True, type=Path)
    parser.add_argument("--map", required=True, type=Path)
    parser.add_argument("--labels", required=True, type=Path)
    parser.add_argument("--rom", required=True, type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    parser.add_argument("--breakpoints", required=True, type=Path)
    parser.add_argument("--watches", required=True, type=Path)
    parser.add_argument("--summary", required=True, type=Path)
    parser.add_argument(
        "--source-layout", default="config/source_layout.json", type=Path
    )
    args = parser.parse_args()
    try:
        summary = build_summary(args)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"[ERROR] {exc}")
        return 1
    args.summary.parent.mkdir(parents=True, exist_ok=True)
    args.summary.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    print(
        "[OK] debugger artifacts: "
        f"{summary['record_counts'].get('sym', 0)} symbols, "
        f"{summary['record_counts'].get('file', 0)} files, "
        f"{summary['record_counts'].get('line', 0)} source lines"
    )
    print(
        "[OK] FCEUX labels: "
        f"{summary['rom_label_count']} ROM, {summary['ram_label_count']} RAM"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Capture FCEUX CDL and reconcile runtime PRG coverage with Ghidra facts."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys


CPU_BASE = 0x8000
ROOT = Path(__file__).resolve().parent.parent


class CoverageError(ValueError):
    pass


def digest(path: Path, algorithm: str = "sha1") -> str:
    checksum = hashlib.new(algorithm)
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            checksum.update(block)
    return checksum.hexdigest()


def load_json(path: Path) -> dict[str, object]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise CoverageError(f"cannot read {path}: {exc}") from exc
    if not isinstance(document, dict):
        raise CoverageError(f"expected JSON object in {path}")
    return document


def read_facts(path: Path) -> dict[int, int]:
    facts: dict[int, int] = {}
    try:
        with path.open(encoding="utf-8", newline="") as stream:
            for row in csv.DictReader(stream, delimiter="\t"):
                address = int(row["address"], 16)
                facts[address] = int(row["length"])
    except (OSError, KeyError, ValueError) as exc:
        raise CoverageError(f"cannot parse instruction facts {path}: {exc}") from exc
    if not facts:
        raise CoverageError(f"instruction facts are empty: {path}")
    return facts


def semantic_symbols(path: Path) -> dict[int, str]:
    document = load_json(path)
    symbols = document.get("symbols")
    if not isinstance(symbols, list):
        raise CoverageError(f"symbols array is missing from {path}")
    result: dict[int, str] = {}
    for item in symbols:
        if not isinstance(item, dict) or item.get("kind") != "routine":
            continue
        result[int(str(item["address"]), 0)] = str(item["name"])
    return result


def address_list(offsets: set[int], limit: int = 64) -> list[str]:
    return [f"0x{CPU_BASE + offset:04X}" for offset in sorted(offsets)[:limit]]


def contiguous_ranges(offsets: set[int]) -> list[tuple[int, int]]:
    if not offsets:
        return []
    ordered = sorted(offsets)
    ranges: list[tuple[int, int]] = []
    start = previous = ordered[0]
    for offset in ordered[1:]:
        if offset != previous + 1:
            ranges.append((start, previous))
            start = offset
        previous = offset
    ranges.append((start, previous))
    return ranges


def merge_cdls(payloads: list[bytes]) -> bytes:
    if not payloads:
        raise CoverageError("at least one CDL is required")
    size = len(payloads[0])
    if any(len(payload) != size for payload in payloads):
        raise CoverageError("cannot merge CDL files with different sizes")
    merged = bytearray(size)
    for payload in payloads:
        for offset, value in enumerate(payload):
            merged[offset] |= value
    return bytes(merged)


def write_evidence(cdl: bytes, prg_size: int, output: Path, rom_sha1: str) -> None:
    if len(cdl) < prg_size:
        raise CoverageError(f"CDL size is {len(cdl)}, smaller than PRG size {prg_size}")
    prg_cdl = cdl[:prg_size]
    kinds = {
        "code": {offset for offset, value in enumerate(prg_cdl) if value & 0x01},
        "data": {offset for offset, value in enumerate(prg_cdl) if value & 0x02},
    }
    lines = [
        "# Castle Excellent runtime evidence v1",
        f"# rom_sha1 {rom_sha1}",
        f"# cdl_sha256 {hashlib.sha256(cdl).hexdigest()}",
        "# kind start end (inclusive CPU addresses)",
    ]
    for kind, offsets in kinds.items():
        for start, end in contiguous_ranges(offsets):
            lines.append(f"{kind} {CPU_BASE + start:04X} {CPU_BASE + end:04X}")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
    print(f"[OK] runtime evidence {output}")


def analyze_cdl(
    cdl: bytes,
    prg_size: int,
    facts: dict[int, int],
    symbols: dict[int, str],
) -> dict[str, object]:
    if len(cdl) < prg_size:
        raise CoverageError(f"CDL size is {len(cdl)}, smaller than PRG size {prg_size}")
    prg_cdl = cdl[:prg_size]
    runtime_code = {offset for offset, value in enumerate(prg_cdl) if value & 0x01}
    runtime_data = {offset for offset, value in enumerate(prg_cdl) if value & 0x02}
    static_code: set[int] = set()
    valid_starts: set[int] = set()
    for address, length in facts.items():
        offset = address - CPU_BASE
        if offset < 0 or offset + length > prg_size:
            continue
        valid_starts.add(offset)
        static_code.update(range(offset, offset + length))
    runtime_starts = runtime_code & valid_starts
    missing_static = runtime_code - static_code
    hit_symbols = [
        {"address": f"0x{address:04X}", "name": name}
        for address, name in sorted(symbols.items())
        if address - CPU_BASE in runtime_code
    ]
    return {
        "prg_size": prg_size,
        "cdl_size": len(cdl),
        "runtime_code_bytes": len(runtime_code),
        "runtime_data_bytes": len(runtime_data),
        "runtime_code_and_data_bytes": len(runtime_code & runtime_data),
        "ghidra_instruction_count": len(valid_starts),
        "ghidra_code_bytes": len(static_code),
        "executed_instruction_starts": len(runtime_starts),
        "executed_bytes_outside_ghidra_code": len(missing_static),
        "executed_bytes_outside_ghidra_code_addresses": address_list(missing_static),
        "hit_semantic_routines": hit_symbols,
    }


def validate_reference(image: Path, manifest: dict[str, object]) -> None:
    reference = manifest.get("reference_rom")
    if not isinstance(reference, dict):
        raise CoverageError("manifest has no reference_rom object")
    expected = str(reference["file_sha1"]).lower()
    actual = digest(image)
    if actual != expected:
        raise CoverageError(f"ROM SHA-1 is {actual}, expected {expected}")


def read_metadata(path: Path) -> dict[str, list[str]]:
    result: dict[str, list[str]] = {}
    for line_number, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not raw_line:
            continue
        key, separator, value = raw_line.partition("=")
        if not separator or not key or not value:
            raise CoverageError(f"invalid metadata line {path}:{line_number}")
        result.setdefault(key, []).append(value)
    return result


def validate_runtime_metadata(
    path: Path, scenario: str, required_hooks: list[str]
) -> dict[str, list[str]]:
    metadata = read_metadata(path)
    if metadata.get("scenario") != [scenario]:
        raise CoverageError(f"runtime metadata scenario does not match {scenario}")
    if metadata.get("status") != ["ok"]:
        misses = ", ".join(metadata.get("miss", [])) or "unknown"
        raise CoverageError(f"runtime scenario {scenario} incomplete; missed {misses}")
    hit_names = {entry.partition("@")[0] for entry in metadata.get("hit", [])}
    missing = [name for name in required_hooks if name not in hit_names]
    if missing:
        raise CoverageError(
            f"runtime scenario {scenario} omitted required hooks: {', '.join(missing)}"
        )
    return metadata


def write_report(args: argparse.Namespace) -> dict[str, object]:
    manifest = load_json(args.manifest)
    reference = manifest["reference_rom"]
    assert isinstance(reference, dict)
    facts = read_facts(args.facts)
    symbols = semantic_symbols(args.symbols)
    cdl = args.cdl.read_bytes()
    report = analyze_cdl(cdl, int(reference["prg_size"]), facts, symbols)
    report.update(
        {
            "schema_version": 1,
            "scenario": args.scenario,
            "rom_sha1": str(reference["file_sha1"]),
            "cdl_sha256": hashlib.sha256(cdl).hexdigest(),
        }
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    if report["executed_bytes_outside_ghidra_code"]:
        addresses = ", ".join(report["executed_bytes_outside_ghidra_code_addresses"])
        raise CoverageError(f"runtime executed bytes outside Ghidra code: {addresses}")
    print(
        "[OK] runtime/Ghidra agreement: "
        f"{report['runtime_code_bytes']} code bytes, "
        f"{report['executed_instruction_starts']} instruction starts"
    )
    print(f"[OK] report {args.output}")
    return report


def command_analyze(args: argparse.Namespace) -> None:
    write_report(args)


def command_run(args: argparse.Namespace) -> None:
    for path in (args.fceux, args.image, args.lua, args.facts, args.symbols, args.manifest):
        if not path.is_file():
            raise CoverageError(f"required input not found: {path}")
    manifest = load_json(args.manifest)
    validate_reference(args.image, manifest)
    args.cdl.parent.mkdir(parents=True, exist_ok=True)
    args.cdl.unlink(missing_ok=True)
    args.metadata.unlink(missing_ok=True)
    environment = os.environ.copy()
    environment.update(
        CASTLE_CDL_OUTPUT=str(args.cdl.resolve()).replace("\\", "/"),
        CASTLE_CDL_METADATA=str(args.metadata.resolve()).replace("\\", "/"),
        CASTLE_CDL_MAX_FRAMES=str(args.frames),
    )
    if args.runtime_scenario:
        environment["CASTLE_RUNTIME_SCENARIO"] = args.runtime_scenario
    command = [
        str(args.fceux.resolve()),
        "-lua",
        str(args.lua.resolve()),
        "-max-frames",
        str(args.frames + 10),
        "-turbo",
        "1",
        "-nothrottle",
        "1",
        str(args.image.resolve()),
    ]
    print(f"[RUN] FCEUX CDL {args.scenario} ({args.frames} frames)", flush=True)
    completed = subprocess.run(command, cwd=ROOT, env=environment, check=False)
    if completed.returncode:
        raise CoverageError(f"FCEUX exited with status {completed.returncode}")
    for path in (args.cdl, args.metadata):
        if not path.is_file() or path.stat().st_size == 0:
            raise CoverageError(f"FCEUX did not create {path}")
    if args.runtime_scenario:
        validate_runtime_metadata(
            args.metadata, args.runtime_scenario, args.required_hook
        )
    write_report(args)


def command_promote(args: argparse.Namespace) -> None:
    manifest = load_json(args.manifest)
    reference = manifest["reference_rom"]
    assert isinstance(reference, dict)
    write_evidence(
        args.cdl.read_bytes(),
        int(reference["prg_size"]),
        args.output,
        str(reference["file_sha1"]),
    )


def command_merge(args: argparse.Namespace) -> None:
    missing = [path for path in args.cdl if not path.is_file()]
    if missing:
        raise CoverageError("required CDL not found: " + ", ".join(map(str, missing)))
    merged = merge_cdls([path.read_bytes() for path in args.cdl])
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(merged)
    print(f"[OK] merged {len(args.cdl)} CDL files into {args.output}")


def add_analysis_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--cdl", required=True, type=Path)
    parser.add_argument("--facts", required=True, type=Path)
    parser.add_argument("--symbols", required=True, type=Path)
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--scenario", default="boot-gameplay")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    analyze = subparsers.add_parser("analyze")
    add_analysis_arguments(analyze)
    analyze.set_defaults(handler=command_analyze)
    run = subparsers.add_parser("run")
    add_analysis_arguments(run)
    run.add_argument("--fceux", required=True, type=Path)
    run.add_argument("--image", required=True, type=Path)
    run.add_argument("--lua", required=True, type=Path)
    run.add_argument("--metadata", required=True, type=Path)
    run.add_argument("--frames", type=int, default=900)
    run.add_argument("--runtime-scenario")
    run.add_argument("--required-hook", action="append", default=[])
    run.set_defaults(handler=command_run)
    promote = subparsers.add_parser("promote-evidence")
    promote.add_argument("--cdl", required=True, type=Path)
    promote.add_argument("--manifest", required=True, type=Path)
    promote.add_argument("--output", required=True, type=Path)
    promote.set_defaults(handler=command_promote)
    merge = subparsers.add_parser("merge", help="bitwise-union multiple CDL files")
    merge.add_argument("--cdl", required=True, action="append", type=Path)
    merge.add_argument("--output", required=True, type=Path)
    merge.set_defaults(handler=command_merge)
    args = parser.parse_args()
    try:
        args.handler(args)
    except (CoverageError, KeyError, OSError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

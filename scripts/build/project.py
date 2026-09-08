#!/usr/bin/env python3
"""Build-support commands for the Castle Excellent source reconstruction."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import subprocess
import sys
import zlib

from scripts.workflow.generate_disassembly import (
    load_memory_symbols,
    load_operand_overrides,
    load_source_layout,
)


ROOT = Path(__file__).resolve().parents[2]


class ProjectError(ValueError):
    """A validation error that should be shown without a traceback."""


PRG_DATA_KINDS = {"data", "padding", "table", "text", "vectors"}


def load_prg_data_ranges(path: Path) -> list[tuple[str, int, int, str]]:
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError as exc:
        raise ProjectError(f"cannot read typed PRG ranges {path}: {exc}") from exc
    ranges: list[tuple[str, int, int, str]] = []
    previous_end = 0x7FFF
    for line_number, raw in enumerate(lines, 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        fields = line.split()
        if len(fields) != 4 or fields[0] not in PRG_DATA_KINDS:
            raise ProjectError(f"invalid typed PRG range at {path}:{line_number}")
        try:
            start, end = int(fields[1], 16), int(fields[2], 16)
        except ValueError as exc:
            raise ProjectError(
                f"invalid typed PRG address at {path}:{line_number}"
            ) from exc
        if not 0x8000 <= start <= end <= 0xFFFF:
            raise ProjectError(f"typed PRG range is out of bounds at {path}:{line_number}")
        if start <= previous_end:
            raise ProjectError(
                f"typed PRG ranges overlap or are unsorted at {path}:{line_number}"
            )
        if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", fields[3]):
            raise ProjectError(f"invalid typed PRG range name at {path}:{line_number}")
        ranges.append((fields[0], start, end, fields[3]))
        previous_end = end
    if not ranges:
        raise ProjectError(f"typed PRG range registry is empty: {path}")
    return ranges


def load_code_evidence(
    evidence_path: Path, provenance: str
) -> list[tuple[int, int]]:
    try:
        lines = evidence_path.read_text(encoding="utf-8").splitlines()
    except OSError as exc:
        raise ProjectError(
            f"cannot read {provenance} code evidence {evidence_path}: {exc}"
        ) from exc
    ranges: list[tuple[int, int]] = []
    previous_end = 0x7FFF
    for line_number, raw in enumerate(lines, 1):
        fields = raw.split()
        if not fields or fields[0].startswith("#"):
            continue
        if len(fields) != 3:
            raise ProjectError(
                f"invalid {provenance} code evidence at {evidence_path}:{line_number}"
            )
        if fields[0] != "code":
            continue
        try:
            start, end = int(fields[1], 16), int(fields[2], 16)
        except ValueError as exc:
            raise ProjectError(
                f"invalid {provenance} code address at {evidence_path}:{line_number}"
            ) from exc
        if not 0x8000 <= start <= end <= 0xFFFF:
            raise ProjectError(
                f"{provenance} code range is out of bounds at "
                f"{evidence_path}:{line_number}"
            )
        if start <= previous_end:
            raise ProjectError(
                f"{provenance} code ranges overlap or are unsorted at "
                f"{evidence_path}:{line_number}"
            )
        ranges.append((start, end))
        previous_end = end
    if not ranges:
        raise ProjectError(f"{provenance} code evidence is empty: {evidence_path}")
    return ranges


def load_false_instruction_starts(path: Path) -> list[tuple[int, str]]:
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError as exc:
        raise ProjectError(
            f"cannot read false-instruction registry {path}: {exc}"
        ) from exc
    entries: list[tuple[int, str]] = []
    previous = 0x7FFF
    for line_number, raw in enumerate(lines, 1):
        fields = raw.split()
        if not fields or fields[0].startswith("#"):
            continue
        if len(fields) != 3 or fields[0] != "instruction":
            raise ProjectError(
                f"invalid false-instruction entry at {path}:{line_number}"
            )
        try:
            address = int(fields[1], 16)
        except ValueError as exc:
            raise ProjectError(
                f"invalid false-instruction address at {path}:{line_number}"
            ) from exc
        if not 0x8000 <= address <= 0xFFFF:
            raise ProjectError(
                f"false-instruction address is out of bounds at {path}:{line_number}"
            )
        if address <= previous:
            raise ProjectError(
                f"false-instruction entries overlap or are unsorted at "
                f"{path}:{line_number}"
            )
        if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", fields[2]):
            raise ProjectError(
                f"invalid false-instruction name at {path}:{line_number}"
            )
        entries.append((address, fields[2]))
        previous = address
    if not entries:
        raise ProjectError(f"false-instruction registry is empty: {path}")
    return entries


def validate_code_data_separation(
    data_ranges: list[tuple[str, int, int, str]],
    evidence_path: Path,
    provenance: str,
) -> None:
    for start, end in load_code_evidence(evidence_path, provenance):
        for _kind, data_start, data_end, name in data_ranges:
            if max(start, data_start) <= min(end, data_end):
                raise ProjectError(
                    f"{provenance} code ${start:04X}-${end:04X} overlaps typed data {name}"
                )


def validate_runtime_data_separation(
    data_ranges: list[tuple[str, int, int, str]], evidence_path: Path
) -> None:
    """Backward-compatible runtime-evidence validation entrypoint."""
    validate_code_data_separation(data_ranges, evidence_path, "runtime")


def digest(data: bytes, algorithm: str = "sha1") -> str:
    return hashlib.new(algorithm, data).hexdigest()


def crc32(data: bytes) -> str:
    return f"{zlib.crc32(data) & 0xFFFFFFFF:08x}"


def parse_number(value: object, field: str) -> int:
    if isinstance(value, int):
        return value
    if isinstance(value, str):
        try:
            return int(value, 0)
        except ValueError:
            pass
    raise ProjectError(f"invalid integer for {field}: {value!r}")


def load_manifest(path: Path) -> dict[str, object]:
    try:
        manifest = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ProjectError(f"cannot read manifest {path}: {exc}") from exc
    if manifest.get("schema_version") != 1:
        raise ProjectError("unsupported manifest schema")
    return manifest


def parse_ines(data: bytes) -> dict[str, object]:
    if len(data) < 16 or data[:4] != b"NES\x1a":
        raise ProjectError("image is not an iNES ROM")
    trainer_size = 512 if data[6] & 0x04 else 0
    prg_size = data[4] * 16_384
    chr_size = data[5] * 8_192
    prg_start = 16 + trainer_size
    chr_start = prg_start + prg_size
    expected_size = chr_start + chr_size
    if len(data) != expected_size:
        raise ProjectError(
            f"image size is {len(data)}, expected exactly {expected_size}"
        )
    return {
        "header": data[:prg_start],
        "prg": data[prg_start:chr_start],
        "chr": data[chr_start:],
        "payload": data[prg_start:],
        "trainer_size": trainer_size,
        "prg_size": prg_size,
        "chr_size": chr_size,
        "mapper": (data[6] >> 4) | (data[7] & 0xF0),
        "mirroring": "vertical" if data[6] & 0x01 else "horizontal",
    }


def image_facts(data: bytes) -> tuple[dict[str, object], dict[str, object]]:
    parsed = parse_ines(data)
    facts: dict[str, object] = {
        "file_size": len(data),
        "file_sha1": digest(data),
        "file_md5": digest(data, "md5"),
        "file_crc32": crc32(data),
        "payload_sha1": digest(parsed["payload"]),
        "payload_crc32": crc32(parsed["payload"]),
        "header_size": len(parsed["header"]),
        "header_sha1": digest(parsed["header"]),
        "header_crc32": crc32(parsed["header"]),
        "prg_size": parsed["prg_size"],
        "prg_sha1": digest(parsed["prg"]),
        "prg_crc32": crc32(parsed["prg"]),
        "chr_size": parsed["chr_size"],
        "chr_sha1": digest(parsed["chr"]),
        "chr_crc32": crc32(parsed["chr"]),
        "trainer_size": parsed["trainer_size"],
        "mapper": parsed["mapper"],
        "mirroring": parsed["mirroring"],
    }
    return parsed, facts


def validate_image(data: bytes, manifest: dict[str, object]) -> dict[str, object]:
    reference = manifest.get("reference_rom")
    if not isinstance(reference, dict):
        raise ProjectError("manifest has no reference_rom object")
    parsed, facts = image_facts(data)
    for field, expected in reference.items():
        if field not in facts:
            continue
        actual = facts[field]
        if isinstance(actual, int):
            expected = parse_number(expected, field)
        elif isinstance(expected, str):
            expected = expected.lower()
        if actual != expected:
            raise ProjectError(
                f"{field} mismatch: got {actual!r}, expected {expected!r}"
            )
    return parsed


def safe_asset_path(root: Path, relative: str) -> Path:
    posix = PurePosixPath(relative)
    if posix.is_absolute() or not posix.parts or ".." in posix.parts:
        raise ProjectError(f"unsafe asset path: {relative!r}")
    destination = root.joinpath(*posix.parts)
    try:
        destination.resolve().relative_to(root.resolve())
    except ValueError as exc:
        raise ProjectError(f"asset path escapes output directory: {relative!r}") from exc
    return destination


def write_if_changed(path: Path, data: bytes) -> str:
    if path.is_file() and path.read_bytes() == data:
        return "OK"
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_bytes(data)
    os.replace(temporary, path)
    return "WRITE"


def validate_asset(payload: bytes, entry: dict[str, object]) -> None:
    label = str(entry.get("region", entry.get("path", "asset")))
    expected_size = parse_number(entry.get("size"), f"{label}.size")
    if len(payload) != expected_size:
        raise ProjectError(
            f"{label} size mismatch: got {len(payload)}, expected {expected_size}"
        )
    for algorithm in ("sha1", "crc32"):
        expected = entry.get(algorithm)
        if expected is None:
            continue
        actual = digest(payload) if algorithm == "sha1" else crc32(payload)
        if actual != str(expected).lower():
            raise ProjectError(
                f"{label} {algorithm} mismatch: got {actual}, expected {expected}"
            )


def manifest_assets(manifest: dict[str, object]) -> list[dict[str, object]]:
    assets = manifest.get("extracted_assets")
    if not isinstance(assets, list):
        raise ProjectError("manifest has no extracted_assets list")
    if not all(isinstance(entry, dict) for entry in assets):
        raise ProjectError("invalid asset entry")
    return assets


def command_verify(args: argparse.Namespace) -> None:
    image = Path(args.image)
    if not image.is_file():
        raise ProjectError(f"image not found: {image}")
    manifest = load_manifest(Path(args.manifest))
    validate_image(image.read_bytes(), manifest)
    print(f"[OK] byte-identical Castle Excellent image: {image}")


def command_inspect(args: argparse.Namespace) -> None:
    image = Path(args.image)
    if not image.is_file():
        raise ProjectError(f"image not found: {image}")
    _parsed, facts = image_facts(image.read_bytes())
    print(json.dumps(facts, indent=2))


def command_split(args: argparse.Namespace) -> None:
    image = Path(args.image)
    if not image.is_file():
        raise ProjectError(f"reference ROM not found: {image}")
    manifest = load_manifest(Path(args.manifest))
    parsed = validate_image(image.read_bytes(), manifest)
    output_root = Path(args.output_dir)
    for entry in manifest_assets(manifest):
        region = str(entry.get("region", ""))
        if region not in ("header", "prg", "chr"):
            raise ProjectError(f"unsupported asset region: {region!r}")
        payload = parsed[region]
        validate_asset(payload, entry)
        destination = safe_asset_path(output_root, str(entry.get("path", "")))
        action = write_if_changed(destination, payload)
        print(f"[{action}] {destination} ({len(payload)} bytes)")


def command_check_assets(args: argparse.Namespace) -> None:
    manifest = load_manifest(Path(args.manifest))
    root = Path(args.asset_dir)
    for entry in manifest_assets(manifest):
        path = safe_asset_path(root, str(entry.get("path", "")))
        if not path.is_file():
            raise ProjectError(f"required generated asset not found: {path}; run make split")
        validate_asset(path.read_bytes(), entry)
        print(f"[OK] {path}")


def command_mkdir(args: argparse.Namespace) -> None:
    Path(args.path).mkdir(parents=True, exist_ok=True)


def command_require(args: argparse.Namespace) -> None:
    path = Path(args.path)
    if not path.is_file():
        raise ProjectError(f"required generated asset not found: {path}; {args.hint}")


def command_clean(args: argparse.Namespace) -> None:
    target = Path(args.path).resolve()
    build_root = (ROOT / "build").resolve()
    if target != build_root and build_root not in target.parents:
        raise ProjectError(f"refusing to clean outside {build_root}: {target}")
    if target.exists():
        shutil.rmtree(target)
        print(f"[CLEAN] {target}")


def validate_test_layout(root: Path) -> None:
    from scripts.validation import repository_policy

    repository_policy.validate_test_layout(root)


def validate_config_layout(root: Path) -> None:
    from scripts.validation import repository_policy

    repository_policy.validate_config_layout(root)


def validate_documentation(root: Path) -> None:
    from scripts.validation import repository_policy

    repository_policy.validate_documentation(root)


def command_lint(args: argparse.Namespace) -> None:
    from scripts.validation import repository_policy

    repository_policy.command_lint(args)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    verify = subparsers.add_parser("verify", help="verify a complete built image")
    verify.add_argument("--image", required=True)
    verify.add_argument("--manifest", required=True)
    verify.set_defaults(handler=command_verify)

    inspect = subparsers.add_parser("inspect", help="print complete iNES hashes")
    inspect.add_argument("--image", required=True)
    inspect.set_defaults(handler=command_inspect)

    split = subparsers.add_parser("split", help="validate and split a reference ROM")
    split.add_argument("--image", required=True)
    split.add_argument("--manifest", required=True)
    split.add_argument("--output-dir", required=True)
    split.set_defaults(handler=command_split)

    check_assets = subparsers.add_parser("check-assets", help="validate private assets")
    check_assets.add_argument("--manifest", required=True)
    check_assets.add_argument("--asset-dir", required=True)
    check_assets.set_defaults(handler=command_check_assets)

    mkdir = subparsers.add_parser("mkdir", help="create a build directory")
    mkdir.add_argument("--path", required=True)
    mkdir.set_defaults(handler=command_mkdir)

    require = subparsers.add_parser("require", help="require a generated asset")
    require.add_argument("--path", required=True)
    require.add_argument("--hint", required=True)
    require.set_defaults(handler=command_require)

    clean = subparsers.add_parser("clean", help="remove a path below build/")
    clean.add_argument("--path", required=True)
    clean.set_defaults(handler=command_clean)

    lint = subparsers.add_parser("lint", help="check the repository contract")
    lint.set_defaults(handler=command_lint)
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    try:
        args.handler(args)
    except (OSError, ProjectError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

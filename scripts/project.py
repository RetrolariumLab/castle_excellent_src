#!/usr/bin/env python3
"""Build-support commands for the Castle Excellent preservation project."""

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

from generate_disassembly import (
    load_memory_symbols,
    load_operand_overrides,
    load_source_layout,
)


ROOT = Path(__file__).resolve().parent.parent


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


def validate_runtime_data_separation(
    data_ranges: list[tuple[str, int, int, str]], evidence_path: Path
) -> None:
    try:
        lines = evidence_path.read_text(encoding="utf-8").splitlines()
    except OSError as exc:
        raise ProjectError(f"cannot read runtime evidence {evidence_path}: {exc}") from exc
    for line_number, raw in enumerate(lines, 1):
        fields = raw.split()
        if not fields or fields[0].startswith("#") or fields[0] != "code":
            continue
        if len(fields) != 3:
            raise ProjectError(f"invalid runtime evidence at {evidence_path}:{line_number}")
        try:
            start, end = int(fields[1], 16), int(fields[2], 16)
        except ValueError as exc:
            raise ProjectError(
                f"invalid runtime address at {evidence_path}:{line_number}"
            ) from exc
        for _kind, data_start, data_end, name in data_ranges:
            if max(start, data_start) <= min(end, data_end):
                raise ProjectError(
                    f"runtime code ${start:04X}-${end:04X} overlaps typed data {name}"
                )


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


def command_lint(_args: argparse.Namespace) -> None:
    required = (
        "README.md",
        "Makefile",
        "assets/manifest.json",
        "config/linker/cnrom.cfg",
        "config/memory_symbols.json",
        "config/operand_overrides.json",
        "config/source_layout.json",
        "config/symbols.json",
        "config/runtime_evidence.txt",
        "config/prg_data_ranges.txt",
        "docs/code_quality.md",
        "docs/source_reconstruction.md",
        "docs/verification.md",
        "tools/disassembly.lock.json",
        "tools/runtime.lock.json",
        "src/main.asm",
        "src/input/controllers.asm",
        "src/system/ppu.asm",
        "src/system/startup.asm",
        "src/game/objects/runtime_record_offsets.asm",
        "src/preservation/prg_8180_8224.asm",
        "src/preservation/prg_82ce_8f0f.asm",
        "src/preservation/prg_8f29_9577.asm",
        "src/system/nmi_tasks.asm",
        "src/preservation/prg_9583_a35b.asm",
        "src/game/rooms/load_room.asm",
        "src/preservation/prg_a3ac_a6d7.asm",
        "src/game/rooms/mutable_cell_predicates.asm",
        "src/preservation/prg_a70a_ab49.asm",
        "src/game/rooms/room_metadata.asm",
        "src/preservation/prg_ac13_b64b.asm",
        "src/rendering/room_screen.asm",
        "src/preservation/prg_b7fd_c55c.asm",
        "src/system/nmi.asm",
        "src/rendering/oam_dma.asm",
        "src/rendering/status_upload.asm",
        "src/rendering/room_rows_00_04.asm",
        "src/rendering/room_rows_05_09.asm",
        "src/rendering/room_rows_10_14.asm",
        "src/rendering/room_rows_15_19.asm",
        "src/rendering/room_attribute_upload.asm",
        "src/game/rooms/decoder.asm",
        "src/rendering/room_attributes.asm",
        "src/ui/castle_map.asm",
        "src/game/rooms/finalize_room.asm",
        "src/game/objects/room_loader.asm",
        "src/game/rooms/state_orchestration.asm",
        "src/game/rooms/persistent_state_apply.asm",
        "src/game/objects/stream_seek.asm",
        "src/game/rooms/mutable_cell_state_apply.asm",
        "src/game/rooms/persistent_state_load.asm",
        "src/game/objects/room_data.asm",
        "src/preservation/prg_f8fc_fdc4.asm",
        "src/game/rooms/persistent_state_save.asm",
        "src/preservation/prg_fe31_ffff.asm",
        "scripts/asm_style.py",
        "scripts/verify_rom.py",
        "scripts/format_project.py",
        "scripts/generate_disassembly.py",
        "scripts/run_ghidra.py",
        "scripts/bootstrap_fceux.py",
        "scripts/runtime_coverage.py",
        "scripts/source_reconstruction.py",
        "scripts/capture_boot_cdl.lua",
        "scripts/capture_title_demo_cdl.lua",
        "scripts/capture_timeout_cdl.lua",
        "scripts/controller_input.py",
        "scripts/startup_state.py",
        "scripts/nmi_scheduler.py",
        "scripts/oam_dma.py",
        "scripts/status_upload.py",
        "scripts/room_row_upload.py",
        "scripts/room_attribute_upload.py",
        "scripts/castle_map.py",
        "scripts/room_data.py",
        "scripts/room_screen_data.py",
        "scripts/audio_data.py",
        "tools/ghidra_scripts/ClearKnownData.java",
    )
    missing = [name for name in required if not (ROOT / name).is_file()]
    if missing:
        raise ProjectError("missing project files: " + ", ".join(missing))
    load_manifest(ROOT / "assets/manifest.json")
    memory_symbols = load_memory_symbols(ROOT / "config/memory_symbols.json")
    load_operand_overrides(ROOT / "config/operand_overrides.json")
    source_regions = load_source_layout(ROOT / "config/source_layout.json")
    definitions = "\n".join(
        (ROOT / relative).read_text(encoding="utf-8")
        for relative in ("src/memory/ram.inc", "src/memory/hardware.inc")
    )
    for symbol in memory_symbols:
        definition = re.compile(
            rf"^{re.escape(symbol.name)}\s*=\s*\${symbol.address:04X}$",
            re.MULTILINE,
        )
        short_definition = re.compile(
            rf"^{re.escape(symbol.name)}\s*=\s*\${symbol.address:02X}$",
            re.MULTILINE,
        )
        if not definition.search(definitions) and not short_definition.search(definitions):
            raise ProjectError(
                f"memory operand symbol has no matching ca65 definition: {symbol.name}"
            )
    for region in source_regions:
        if not (ROOT / region.path).is_file():
            raise ProjectError(f"source-layout module not found: {region.path}")
    data_ranges = load_prg_data_ranges(ROOT / "config/prg_data_ranges.txt")
    validate_runtime_data_separation(
        data_ranges, ROOT / "config/runtime_evidence.txt"
    )
    for relative in (
        "config/symbols.json",
        "tools/disassembly.lock.json",
        "tools/runtime.lock.json",
    ):
        try:
            document = json.loads((ROOT / relative).read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            raise ProjectError(f"cannot read {relative}: {exc}") from exc
        if document.get("schema_version") != 1:
            raise ProjectError(f"unsupported schema in {relative}")
    for relative in ("config/debugger_watches.json", "config/debugger_breakpoints.json"):
        try:
            config = json.loads((ROOT / relative).read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            raise ProjectError(f"cannot read {relative}: {exc}") from exc
        if config.get("schema_version") != 1:
            raise ProjectError(f"unsupported schema in {relative}")
    source_contract = {
        "src/main.asm": ('.setcpu "6502"', '.segment "HEADER"'),
        "src/preservation/prg.asm": (
            '.segment "PRG"',
            '.include "../input/controllers.asm"',
            '.include "../system/ppu.asm"',
            '.include "prg_8180_8224.asm"',
            '.include "../system/startup.asm"',
            '.include "prg_82ce_8f0f.asm"',
            '.include "../game/objects/runtime_record_offsets.asm"',
            '.include "prg_8f29_9577.asm"',
            '.include "../system/nmi_tasks.asm"',
            '.include "prg_9583_a35b.asm"',
            '.include "../game/rooms/load_room.asm"',
            '.include "prg_a3ac_a6d7.asm"',
            '.include "../game/rooms/mutable_cell_predicates.asm"',
            '.include "prg_a70a_ab49.asm"',
            '.include "../game/rooms/room_metadata.asm"',
            '.include "prg_ac13_b64b.asm"',
            '.include "../rendering/room_screen.asm"',
            '.include "prg_b7fd_c55c.asm"',
            '.include "../system/nmi.asm"',
            '.include "../rendering/oam_dma.asm"',
            '.include "../rendering/status_upload.asm"',
            '.include "../rendering/room_rows_00_04.asm"',
            '.include "../rendering/room_rows_05_09.asm"',
            '.include "../rendering/room_rows_10_14.asm"',
            '.include "../rendering/room_rows_15_19.asm"',
            '.include "../rendering/room_attribute_upload.asm"',
            '.include "../game/rooms/decoder.asm"',
            '.include "../rendering/room_attributes.asm"',
            '.include "../ui/castle_map.asm"',
            '.include "../game/rooms/finalize_room.asm"',
            '.include "../game/objects/room_loader.asm"',
            '.include "../game/rooms/state_orchestration.asm"',
            '.include "../game/rooms/persistent_state_apply.asm"',
            '.include "../game/objects/stream_seek.asm"',
            '.include "../game/rooms/mutable_cell_state_apply.asm"',
            '.include "../game/rooms/persistent_state_load.asm"',
            '.include "../game/objects/room_data.asm"',
            '.include "prg_f8fc_fdc4.asm"',
            '.include "../game/rooms/persistent_state_save.asm"',
            '.include "prg_fe31_ffff.asm"',
        ),
        "src/input/controllers.asm": (
            "ReadController1:",
            "PollController1:",
            "ReadController2:",
            "PollController2:",
        ),
        "src/system/ppu.asm": (
            "DisableNmi:",
            "EnableNmi:",
            "DisableRendering:",
            "WaitForVblankAndEnableRendering:",
            "SelectChrBank:",
            "ChrBankSelectValues:",
        ),
        "src/system/startup.asm": (
            "Reset:",
            "CheckPowerOnSignature:",
            "MainFrameLoop:",
            "PowerOnSignature:",
        ),
        "src/system/nmi.asm": (
            "ResetPpuScroll:",
            "Nmi:",
            "NmiFrame:",
            "Irq:",
        ),
        "src/rendering/oam_dma.asm": (
            "BuildDmaOam:",
            "OamRotationOffsets:",
            "ReverseDmaOam:",
        ),
        "src/rendering/status_upload.asm": (
            "UploadStatusTiles:",
            "NmiTaskHandlerHighBytes:",
            "NmiTaskHandlerLowBytes:",
        ),
        "src/rendering/room_rows_00_04.asm": (
            "UploadRoomCellRow00:",
            "UploadRoomCellRow04:",
        ),
        "src/rendering/room_rows_05_09.asm": (
            "UploadRoomCellRow05:",
            "UploadRoomCellRow09:",
        ),
        "src/rendering/room_rows_10_14.asm": (
            "UploadRoomCellRow10:",
            "UploadRoomCellRow14:",
        ),
        "src/rendering/room_rows_15_19.asm": (
            "UploadRoomCellRow15:",
            "UploadRoomCellRow19:",
        ),
        "src/rendering/room_attribute_upload.asm": (
            "UploadLeftRoomAttributesTask:",
            "UploadRightRoomAttributesTask:",
        ),
        "src/system/nmi_tasks.asm": (
            "ResetNmiTaskRequests:",
        ),
        "src/game/rooms/load_room.asm": (
            "LoadRoom:",
            "SelectRoomAudio:",
        ),
        "src/rendering/room_screen.asm": (
            "ClearRoomNametablesAndSprites:",
            "InitializeRoomStatusDisplay:",
            "WriteTerminatedPpuTiles:",
            "UploadRoomAttributeTables:",
        ),
        "src/game/rooms/state_orchestration.asm": (
            "LoadRoomObjectsAndState:",
            "SelectAndApplyRoomState:",
        ),
        "src/game/objects/runtime_record_offsets.asm": (
            "RuntimeObjectOffsetByCount:",
        ),
        "src/game/rooms/mutable_cell_predicates.asm": (
            "IsPersistentMutableCell:",
            "IsPersistentMutableRightCell:",
        ),
        "src/game/rooms/room_metadata.asm": (
            "RoomObjectCounts:",
            "RoomMutableCellStateOffsets:",
        ),
        "src/game/rooms/decoder.asm": (
            "DecodeRoom:",
            "RoomCodebook:",
            "RoomPointerTable:",
        ),
        "src/rendering/room_attributes.asm": (
            "GetRoomAttributeMaskAndOffset:",
            "RoomAttributeQuadrantMasks:",
            "RoomCellAttributeValues:",
        ),
        "src/ui/castle_map.asm": (
            "HandleCastleMapInput:",
            "DrawCastleMap:",
            "PositionCurrentRoomMapSprite:",
        ),
        "src/game/rooms/finalize_room.asm": (
            "FinalizeRoomLoad:",
            "RequestAllNmiTasks:",
        ),
        "src/game/objects/room_loader.asm": (
            "RuntimeObjectTypeByEncodedType:",
            "RuntimeObjectStateByEncodedType:",
            "LoadRoomObjects:",
        ),
        "src/game/objects/stream_seek.asm": (
            "SeekRoomObjectStream:",
            "ScanRoomObjectList:",
        ),
        "src/game/rooms/persistent_state_apply.asm": (
            "ApplyRoomPersistentState:",
            "SpawnRoomCellObject:",
        ),
        "src/game/rooms/mutable_cell_state_apply.asm": (
            "ApplyMutableCellStateBit:",
            "ScanMutableCellCandidates:",
        ),
        "src/game/objects/room_data.asm": (
            "RoomObjectStateOffsets:",
            "RoomObjectStream:",
        ),
        "src/game/rooms/persistent_state_load.asm": (
            "RestoreRoomStateSnapshotA:",
            "RestoreRoomStateSnapshotB:",
            "LoadRoomPersistentState:",
        ),
        "src/game/rooms/persistent_state_save.asm": (
            "SaveRoomStateSnapshotB:",
            "SaveRoomMutableCellState:",
        ),
        "src/graphics/chr.asm": ('.segment "CHR"',),
    }
    for relative, markers in source_contract.items():
        path = ROOT / relative
        if not path.is_file():
            raise ProjectError(f"missing source module: {relative}")
        source = path.read_text(encoding="utf-8")
        for marker in markers:
            if marker not in source:
                raise ProjectError(f"{relative} is missing required marker: {marker}")
    disassembly = "\n".join(
        (ROOT / region.path).read_text(encoding="utf-8")
        for region in source_regions
    )
    if ".incbin" in disassembly.lower():
        raise ProjectError("PRG disassembly must not contain .incbin")
    numeric_control = re.search(
        r"^\s*(?:bcc|bcs|beq|bmi|bne|bpl|bvc|bvs|jmp|jsr)\s+(?:\$|0x)[0-9a-f]",
        disassembly,
        re.IGNORECASE | re.MULTILINE,
    )
    if numeric_control:
        raise ProjectError(
            "numeric control-flow operand remains: " + numeric_control.group(0).strip()
        )
    try:
        tracked = subprocess.run(
            [
                "git", "ls-files", "*.nes", "*.chr", "*.hdr", "*.prg", "*.o",
                "tools/ghidra/**", "tools/fceux/**", "tools/.cache/**",
            ],
            cwd=ROOT,
            check=True,
            capture_output=True,
            text=True,
        ).stdout.splitlines()
    except (OSError, subprocess.CalledProcessError) as exc:
        raise ProjectError(f"cannot inspect tracked binary files: {exc}") from exc
    if tracked:
        raise ProjectError("ROM/build binaries must not be tracked: " + ", ".join(tracked))
    print("[OK] project structure, manifest, source contract, and binary policy")


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

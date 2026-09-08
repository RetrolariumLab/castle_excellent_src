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
    scripts_root = root / "scripts"
    tests_root = root / "tests"
    package_dirs = {
        scripts_root,
        tests_root,
        *(path.parent for path in scripts_root.rglob("*.py")),
        *(path.parent for path in tests_root.rglob("*.py")),
    }
    missing_markers = sorted(
        path.relative_to(root).as_posix()
        for path in package_dirs
        if "__pycache__" not in path.parts and not (path / "__init__.py").is_file()
    )
    if missing_markers:
        raise ProjectError(
            "Python package directories need __init__.py: "
            + ", ".join(missing_markers)
        )

    unexpected_root_tests = sorted(
        path.name
        for path in tests_root.glob("test_*.py")
        if path.name != "test_script_runner.py"
    )
    if unexpected_root_tests:
        raise ProjectError(
            "tests must mirror categorized script packages: "
            + ", ".join(unexpected_root_tests)
        )

    tools_by_stem: dict[str, Path] = {}
    for path in scripts_root.rglob("*.py"):
        if path.name in {"__init__.py", "run.py"}:
            continue
        if path.stem in tools_by_stem:
            raise ProjectError(f"ambiguous script module name for tests: {path.stem}")
        tools_by_stem[path.stem] = path

    mismatches: list[str] = []
    for test_path in tests_root.rglob("test_*.py"):
        if test_path == tests_root / "test_script_runner.py":
            continue
        module_name = test_path.stem.removeprefix("test_")
        tool_path = tools_by_stem.get(module_name)
        if tool_path is None:
            mismatches.append(f"{test_path.relative_to(root)} has no matching tool")
            continue
        expected = (
            tests_root
            / tool_path.relative_to(scripts_root).parent
            / test_path.name
        )
        if test_path != expected:
            mismatches.append(
                f"{test_path.relative_to(root)} should be {expected.relative_to(root)}"
            )
    if mismatches:
        raise ProjectError("test layout mismatch: " + "; ".join(mismatches))


def validate_config_layout(root: Path) -> None:
    config_root = root / "config"
    expected_root_files = {
        "fixed_layout_variants.json",
        "revision_profiles.json",
        "source_reconstruction_1_0.json",
        "source_reconstruction_2_0.json",
        "source_reconstruction_2_1.json",
    }
    expected_directories = {"authoring", "debugger", "linker", "reconstruction"}
    actual_root_files = {path.name for path in config_root.iterdir() if path.is_file()}
    actual_directories = {path.name for path in config_root.iterdir() if path.is_dir()}
    if actual_root_files != expected_root_files:
        missing = sorted(expected_root_files - actual_root_files)
        unexpected = sorted(actual_root_files - expected_root_files)
        raise ProjectError(
            f"config root manifest mismatch; missing={missing}, unexpected={unexpected}"
        )
    if actual_directories != expected_directories:
        missing = sorted(expected_directories - actual_directories)
        unexpected = sorted(actual_directories - expected_directories)
        raise ProjectError(
            f"config responsibility directories mismatch; "
            f"missing={missing}, unexpected={unexpected}"
        )


def validate_documentation(root: Path) -> None:
    docs_root = root / "docs"
    repository_root = root.resolve()
    root_documents = (root / "README.md", root / "CONTRIBUTING.md")
    documents = {
        path.relative_to(docs_root).as_posix()
        for path in docs_root.rglob("*.md")
        if path.is_file()
    }
    if "index.md" not in documents:
        raise ProjectError("documentation index not found: docs/index.md")

    link_pattern = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
    indexed: list[str] = []
    sources = [*root_documents, *sorted(docs_root.rglob("*.md"))]
    for source in sources:
        if not source.is_file():
            raise ProjectError(
                f"repository documentation not found: {source.relative_to(root)}"
            )
        text = source.read_text(encoding="utf-8")
        for raw_target in link_pattern.findall(text):
            target = raw_target.split("#", 1)[0].strip()
            if not target or re.match(r"^[A-Za-z][A-Za-z0-9+.-]*:", target):
                continue
            target_path = (source.parent / target).resolve()
            try:
                target_path.relative_to(repository_root)
            except ValueError as exc:
                raise ProjectError(
                    f"documentation link escapes repository: {source}: {raw_target}"
                ) from exc
            if not target_path.is_file():
                raise ProjectError(
                    f"broken documentation link: {source}: {raw_target}"
                )
            if source == docs_root / "index.md":
                try:
                    relative = target_path.relative_to(docs_root.resolve()).as_posix()
                except ValueError as exc:
                    raise ProjectError(
                        f"documentation index link escapes docs/: {raw_target}"
                    ) from exc
                if relative.endswith(".md"):
                    indexed.append(relative)

    duplicates = sorted({path for path in indexed if indexed.count(path) > 1})
    expected = documents - {"index.md"}
    missing = sorted(expected - set(indexed))
    unexpected = sorted(set(indexed) - expected)
    if duplicates or missing or unexpected:
        raise ProjectError(
            "documentation index mismatch; "
            f"missing={missing}, unexpected={unexpected}, duplicates={duplicates}"
        )


def command_lint(_args: argparse.Namespace) -> None:
    required = (
        "README.md",
        "Makefile",
        "assets/manifest.json",
        "config/authoring/audio.json",
        "config/authoring/graphics.json",
        "config/authoring/levels.json",
        "config/debugger/breakpoints.json",
        "config/debugger/watches.json",
        "config/fixed_layout_variants.json",
        "config/linker/cnrom.cfg",
        "config/reconstruction/memory_symbols.json",
        "config/reconstruction/operand_overrides.json",
        "config/reconstruction/source_layout.json",
        "config/reconstruction/symbols.json",
        "config/reconstruction/static_code_evidence.txt",
        "config/reconstruction/runtime_evidence.txt",
        "config/reconstruction/prg_data_ranges.txt",
        "config/reconstruction/false_instruction_starts.txt",
        "config/revision_profiles.json",
        "config/source_reconstruction_1_0.json",
        "config/source_reconstruction_2_0.json",
        "config/source_reconstruction_2_1.json",
        "docs/development.md",
        "docs/source_reconstruction.md",
        "docs/source_reconstruction_2_1.md",
        "docs/resolved_unknowns.md",
        "docs/verification.md",
        "mk/authoring.mk",
        "mk/runtime.mk",
        "mk/validation.mk",
        "tools/disassembly.lock.json",
        "tools/runtime.lock.json",
        "src/main.asm",
        "src/graphics/chr.asm",
        "scripts/run.py",
        "scripts/authoring/__init__.py",
        "scripts/build/__init__.py",
        "scripts/runtime/__init__.py",
        "scripts/validation/__init__.py",
        "scripts/workflow/__init__.py",
        "scripts/validation/asm_style.py",
        "scripts/build/verify_rom.py",
        "scripts/validation/format_project.py",
        "scripts/workflow/generate_disassembly.py",
        "scripts/workflow/run_ghidra.py",
        "scripts/runtime/bootstrap_fceux.py",
        "scripts/runtime/runtime_coverage.py",
        "scripts/validation/debug_symbols.py",
        "scripts/runtime/validate_debug_runtime.py",
        "scripts/runtime/validate_debug_symbols.lua",
        "scripts/validation/source_reconstruction.py",
        "scripts/runtime/capture_boot_cdl.lua",
        "scripts/runtime/capture_title_demo_cdl.lua",
        "scripts/runtime/capture_timeout_cdl.lua",
        "scripts/validation/gameplay/controller_input.py",
        "scripts/validation/gameplay/startup_state.py",
        "scripts/validation/system/nmi_scheduler.py",
        "scripts/validation/system/oam_dma.py",
        "scripts/validation/system/status_upload.py",
        "scripts/validation/rooms/room_row_upload.py",
        "scripts/validation/rooms/room_attribute_upload.py",
        "scripts/validation/rooms/castle_map.py",
        "scripts/validation/gameplay/famicom_data_io.py",
        "scripts/validation/gameplay/save_data.py",
        "scripts/validation/rooms/room_cell_coordinates.py",
        "scripts/validation/collision/room_cell_sample_address.py",
        "scripts/validation/player/player_collision_sample.py",
        "scripts/validation/player/player_collision_dispatch.py",
        "scripts/validation/rooms/room_object_state_save.py",
        "scripts/validation/player/player_animated_cell_displacement.py",
        "scripts/validation/objects/collectible_collision_handlers.py",
        "scripts/validation/objects/inventory_collectible_handlers.py",
        "scripts/validation/gameplay/score_award.py",
        "scripts/validation/objects/runtime_type9f_collision.py",
        "scripts/validation/objects/runtime_types81_82_collision.py",
        "scripts/validation/preservation/unreferenced_nmi_task_index_bytes.py",
        "scripts/validation/preservation/unreferenced_runtime_object_clear_tail.py",
        "scripts/validation/preservation/unreferenced_runtime_only_sample.py",
        "scripts/validation/gameplay/title_sub_command.py",
        "scripts/validation/gameplay/demo_playback.py",
        "scripts/validation/audio/audio_track_selection.py",
        "scripts/validation/audio/audio_stream_engine.py",
        "scripts/validation/audio/sound_effect_engine.py",
        "scripts/validation/system/scroll_math_palette.py",
        "scripts/validation/gameplay/end_sequences.py",
        "scripts/validation/preservation/prg_tail_data.py",
        "scripts/validation/system/palette_data.py",
        "scripts/validation/player/x_coordinates.py",
        "scripts/validation/rooms/room_transition.py",
        "scripts/validation/collision/collision_cells.py",
        "scripts/validation/objects/runtime_object_dispatch.py",
        "scripts/validation/player/player_object_span.py",
        "scripts/validation/objects/transient_object_lifecycle.py",
        "scripts/validation/objects/object_collision_filters.py",
        "scripts/validation/collision/collision_point_sample.py",
        "scripts/validation/collision/room_collision_sample.py",
        "scripts/validation/objects/runtime_object_overlap.py",
        "scripts/validation/gameplay/new_game_state.py",
        "scripts/validation/rooms/room_runtime_reset.py",
        "scripts/validation/rooms/room_cell_animation.py",
        "scripts/validation/system/status_format.py",
        "scripts/validation/rooms/mutable_cell_actions.py",
        "scripts/validation/rooms/room_navigation.py",
        "scripts/validation/player/player_input_movement.py",
        "scripts/validation/player/player_object_push.py",
        "scripts/validation/rooms/room_boundary_transitions.py",
        "scripts/validation/player/player_hazard_state.py",
        "scripts/validation/objects/object_player_proximity.py",
        "scripts/validation/gameplay/pause_input.py",
        "scripts/validation/collision/collision_tables.py",
        "scripts/validation/player/player_movement_collision_tables.py",
        "scripts/authoring/frame_sprites.py",
        "scripts/authoring/metasprites.py",
        "scripts/validation/objects/object_catalog.py",
        "scripts/authoring/room_data.py",
        "scripts/validation/rooms/room_screen_data.py",
        "scripts/authoring/audio_data.py",
        "tools/ghidra_scripts/ApplyCodeEvidence.java",
        "tools/ghidra_scripts/ClearFalseInstructions.java",
        "tools/ghidra_scripts/ClearKnownData.java",
    )
    missing = [name for name in required if not (ROOT / name).is_file()]
    if missing:
        raise ProjectError("missing project files: " + ", ".join(missing))
    scripts_root = ROOT / "scripts"
    unexpected_root_tools = sorted(
        path.name
        for path in scripts_root.iterdir()
        if path.is_file()
        and path.suffix in {".py", ".lua"}
        and path.name not in {"__init__.py", "run.py"}
    )
    if unexpected_root_tools:
        raise ProjectError(
            "scripts must live in responsibility packages: "
            + ", ".join(unexpected_root_tools)
        )
    validate_test_layout(ROOT)
    validate_config_layout(ROOT)
    validate_documentation(ROOT)
    load_manifest(ROOT / "assets/manifest.json")
    memory_symbols = load_memory_symbols(ROOT / "config/reconstruction/memory_symbols.json")
    load_operand_overrides(ROOT / "config/reconstruction/operand_overrides.json")
    source_regions = load_source_layout(ROOT / "config/reconstruction/source_layout.json")
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
    data_ranges = load_prg_data_ranges(ROOT / "config/reconstruction/prg_data_ranges.txt")
    load_false_instruction_starts(ROOT / "config/reconstruction/false_instruction_starts.txt")
    validate_code_data_separation(
        data_ranges, ROOT / "config/reconstruction/static_code_evidence.txt", "static"
    )
    validate_code_data_separation(data_ranges, ROOT / "config/reconstruction/runtime_evidence.txt", "runtime")
    for relative in (
        "config/reconstruction/symbols.json",
        "tools/disassembly.lock.json",
        "tools/runtime.lock.json",
    ):
        try:
            document = json.loads((ROOT / relative).read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            raise ProjectError(f"cannot read {relative}: {exc}") from exc
        if document.get("schema_version") != 1:
            raise ProjectError(f"unsupported schema in {relative}")
    for relative in ("config/debugger/watches.json", "config/debugger/breakpoints.json"):
        try:
            config = json.loads((ROOT / relative).read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            raise ProjectError(f"cannot read {relative}: {exc}") from exc
        if config.get("schema_version") != 1:
            raise ProjectError(f"unsupported schema in {relative}")
    source_contract = {
        "src/main.asm": (
            ".setcpu \"6502\"",
            ".segment \"HEADER\"",
            ".include \"system/famicom_platform.asm\"",
        ),
        "src/system/famicom_platform.asm": (
            ".segment \"PRG\"",
            "WaitForPulseEdge:",
            "Reset:",
            "PowerOnSignature:",
        ),
        "src/game/player/input_and_movement.asm": (
            "UpdatePlayerInputAndMovement:",
            "RememberPlayerInputAndReturn:",
        ),
        "src/game/player/transitions_and_push.asm": (
            "TransitionToRoomAbove:",
            "ReturnPlayerObjectPush:",
        ),
        "src/game/objects/lifts/linked_control.asm": (
            "HandleLiftControlBlockHorizontalCollision:",
            "ReturnFromLinkedLiftUpdate:",
        ),
        "src/game/collectibles/pickups_and_rewards.asm": (
            "CollectInventoryRuntimeType90:",
            "ReturnFromRuntimeType81Collision:",
        ),
        "src/game/collision/player_pipeline.asm": (
            "HandleAnimatedPlayerHazard:",
            "ReturnFromPlayerCollisionUpdate:",
        ),
        "src/game/runtime/frame_pipeline.asm": (
            "AdvancePlayerTransitionCountdown:",
            "ReturnPlayerOutsideObjectSpan:",
        ),
        "src/game/objects/lifts/movement.asm": (
            "UpdateLiftControlBlock:",
            "ClearNextLiftOccupantFlag:",
        ),
        "src/game/objects/enemies/patrol.asm": (
            "UpdateFlyingBlock:",
            "ReturnFromFighterUpdate:",
        ),
        "src/game/objects/enemies/special.asm": (
            "UpdateFlame:",
            "TickRuntimeObjectType41Lifetime:",
        ),
        "src/game/collision/sampling.asm": (
            "ClassifyAnimatedCollisionCell:",
            "UnreferencedNmiTaskIndexFromYBytes:",
        ),
        "src/game/session_initialization.asm": (
            "InitializeNewGame:",
            "UnreferencedBitIndexHelperBytes:",
        ),
        "src/game/rooms/mutable_cells.asm": (
            "ConvertPixelPositionToTileCoordinates:",
            "ReturnMutableCellNotFound:",
        ),
        "src/game/rooms/navigation_and_rules.asm": (
            "MoveToRoomAbove:",
            "RoomMutableCellStateOffsets:",
        ),
        "src/rendering/sprites/frame.asm": (
            "BuildFrameSprites:",
            "DrawPlayerLeftActionSprite:",
        ),
        "src/rendering/sprites/selectors.asm": (
            "DrawRuntimeObjectType01Sprite:",
            "FinishType41Sprite:",
        ),
        "src/rendering/sprites/metasprites.asm": (
            "DrawTwoObjectSprites:",
            "PlayerTransitionMetasprite3:",
        ),
        "src/rendering/scenes.asm": (
            "ClearRoomNametablesAndSprites:",
            "TitleDemoInputScript:",
        ),
        "src/audio/music_engine.asm": (
            "LoadAudioTrackSet0:",
            "Track7TriangleMusicStream:",
        ),
        "src/audio/sound_effects.asm": (
            "StartPulse1SoundEffect1:",
            "NoiseSoundEffect4Length:",
        ),
        "src/rendering/frame_pipeline.asm": (
            "UpdateHorizontalScroll:",
            "NmiTaskHandlerLowBytes:",
        ),
        "src/rendering/room_rows/top.asm": (
            "UploadRoomCellRow00:",
            "UploadRoomCellRow04:",
        ),
        "src/rendering/room_rows/upper_middle.asm": (
            "UploadRoomCellRow05:",
            "UploadRoomCellRow09:",
        ),
        "src/rendering/room_rows/lower_middle.asm": (
            "UploadRoomCellRow10:",
            "UploadRoomCellRow14:",
        ),
        "src/rendering/room_rows/bottom.asm": (
            "UploadRoomCellRow15:",
            "UploadRoomCellRow19:",
        ),
        "src/rendering/rooms/upload_and_decode.asm": (
            "UploadLeftRoomAttributesTask:",
            "CheckRoomDecodeComplete:",
        ),
        "src/rendering/rooms/attributes_and_map.asm": (
            "GetRoomAttributeMaskAndOffset:",
            "ReturnFromCastleMapDraw:",
        ),
        "src/game/rooms/load_pipeline.asm": (
            "FinalizeRoomLoad:",
            "ReturnRoomObjectStreamPointer:",
        ),
        "src/game/rooms/state_and_data.asm": (
            "ApplyMutableCellStateBit:",
            "RoomObjectStream:",
        ),
        "src/ui/title_and_subcommands.asm": (
            "RunTitleScreen:",
            "CopySubCommandPreviousRoomState:",
        ),
        "src/game/persistence_and_endings.asm": (
            "SaveGameState:",
            "ReturnFromHighScoreUpdate:",
        ),
        "src/system/prg_tail.asm": (
            "PaddingBeforeTileTables:",
            "IrqVector:",
        ),
        "src/graphics/chr.asm": (
            ".segment \"CHR\"",
        ),
    }
    for relative, markers in source_contract.items():
        path = ROOT / relative
        if not path.is_file():
            raise ProjectError(f"missing source module: {relative}")
        source = path.read_text(encoding="utf-8")
        for marker in markers:
            if marker not in source:
                raise ProjectError(f"{relative} is missing required marker: {marker}")
    source_text = {
        region.path.as_posix(): (ROOT / region.path).read_text(encoding="utf-8")
        for region in source_regions
    }
    allowed_prg_incbins = {
        "src/rendering/frame_pipeline.asm": {
            ".incbin RevisionTitlePaletteAsset",
        },
        "src/ui/title_and_subcommands.asm": {
            ".incbin RevisionSubCommandTextAsset, 0, 12",
            ".incbin RevisionSubCommandTextAsset, 12, 5",
            ".incbin RevisionSubCommandTextAsset, 17, 5",
            ".incbin RevisionSubCommandTextAsset, 22, 6",
            ".incbin RevisionSubCommandTextAsset, 28, 5",
            ".incbin RevisionSubCommandTextAsset, 33, 5",
            ".incbin RevisionSubCommandTextAsset, 38, 8",
            ".incbin RevisionSubCommandTextAsset, 46, 7",
        },
    }
    for relative, source in source_text.items():
        actual = {
            line.strip()
            for line in source.splitlines()
            if line.lstrip().lower().startswith(".incbin")
        }
        expected = allowed_prg_incbins.get(relative, set())
        if actual != expected:
            raise ProjectError(
                f"undeclared or missing typed PRG binary include in {relative}: "
                f"got {sorted(actual)}, expected {sorted(expected)}"
            )
    disassembly = "\n".join(source_text.values())
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

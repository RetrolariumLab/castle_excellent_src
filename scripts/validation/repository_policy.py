#!/usr/bin/env python3
"""Validate repository layout, documentation, source, and binary policy."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import subprocess

from scripts.build.project import (
    ProjectError,
    load_false_instruction_starts,
    load_manifest,
    load_prg_data_ranges,
    validate_code_data_separation,
)
from scripts.validation.documentation_contract import (
    validate_documentation_review,
    validate_label_renames,
)
from scripts.workflow.generate_disassembly import (
    load_memory_symbols,
    load_operand_overrides,
    load_source_layout,
)


ROOT = Path(__file__).resolve().parents[2]


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
        "game_profile.json",
        "lint.json",
        "names.json",
        "revision_profiles.json",
        "source_reconstruction_1_0.json",
        "source_reconstruction_2_0.json",
        "source_reconstruction_2_1.json",
        "source_reconstruction_3_0.json",
    }
    expected_directories = {"debugger", "linker", "reconstruction"}
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


def validate_tool_layout(root: Path) -> None:
    path = root / "config/reconstruction/tool_layout.json"
    try:
        contract = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ProjectError(f"cannot read tool layout contract: {exc}") from exc
    if contract.get("schema_version") != 1:
        raise ProjectError("unsupported tool layout schema")
    target_maximum = contract.get("python_target_lines", {}).get("maximum")
    if not isinstance(target_maximum, int) or target_maximum <= 0:
        raise ProjectError("tool layout has no positive Python maximum")
    exceptions = contract.get("size_exceptions", [])
    declared = {
        item.get("path"): item for item in exceptions if isinstance(item, dict)
    }
    if len(declared) != len(exceptions) or None in declared:
        raise ProjectError("tool layout size exceptions are duplicated or incomplete")
    oversized: dict[str, int] = {}
    for source in sorted((root / "scripts").rglob("*.py")):
        if source.name == "__init__.py":
            continue
        lines = len(source.read_text(encoding="utf-8").splitlines())
        relative = source.relative_to(root).as_posix()
        if lines > target_maximum:
            oversized[relative] = lines
    if set(oversized) != set(declared):
        raise ProjectError(
            "tool layout exception mismatch; "
            f"missing={sorted(set(oversized) - set(declared))}, "
            f"stale={sorted(set(declared) - set(oversized))}"
        )
    for relative, lines in oversized.items():
        item = declared[relative]
        if item.get("lines") != lines:
            raise ProjectError(
                f"tool layout line count is stale for {relative}: "
                f"declared {item.get('lines')}, actual {lines}"
            )
        maximum = item.get("maximum")
        if not isinstance(maximum, int) or lines > maximum:
            raise ProjectError(f"tool layout maximum is exceeded for {relative}")
        if not item.get("reason"):
            raise ProjectError(f"tool layout exception lacks a reason: {relative}")


def command_lint(_args: argparse.Namespace) -> None:
    required = (
        "README.md",
        "Makefile",
        "assets/manifest.json",
        "config/debugger/breakpoints.json",
        "config/debugger/watches.json",
        "config/fixed_layout_variants.json",
        "config/linker/cnrom.cfg",
        "config/reconstruction/memory_symbols.json",
        "config/reconstruction/documentation_review.json",
        "config/reconstruction/label_renames.json",
        "config/reconstruction/operand_overrides.json",
        "config/reconstruction/source_layout.json",
        "config/reconstruction/tool_layout.json",
        "config/reconstruction/symbols.json",
        "config/reconstruction/static_code_evidence.txt",
        "config/reconstruction/runtime_evidence.txt",
        "config/reconstruction/prg_data_ranges.txt",
        "config/reconstruction/false_instruction_starts.txt",
        "config/revision_profiles.json",
        "config/source_reconstruction_1_0.json",
        "config/source_reconstruction_2_0.json",
        "config/source_reconstruction_2_1.json",
        "config/source_reconstruction_3_0.json",
        "docs/development.md",
        "docs/source_reconstruction.md",
        "docs/source_reconstruction_2_1.md",
        "docs/resolved_unknowns.md",
        "docs/verification.md",
        "mk/runtime.mk",
        "mk/validation.mk",
        "tools/disassembly.lock.json",
        "tools/runtime.lock.json",
        "src/main.asm",
        "src/graphics/chr.asm",
        "scripts/run.py",
        "scripts/build/__init__.py",
        "scripts/runtime/__init__.py",
        "scripts/validation/__init__.py",
        "scripts/workflow/__init__.py",
        "config/lint.json",
        "scripts/build/verify_rom.py",
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
        "scripts/validation/frame_sprites.py",
        "scripts/validation/metasprites.py",
        "scripts/validation/objects/object_catalog.py",
        "scripts/validation/room_data.py",
        "scripts/validation/rooms/room_screen_data.py",
        "scripts/validation/audio_data.py",
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
    validate_documentation_review(ROOT)
    validate_label_renames(ROOT)
    validate_tool_layout(ROOT)
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
            "HandlePulleyHorizontalCollision:",
            "ReturnFromDraggableLiftUpdate:",
        ),
        "src/game/collectibles/pickups_and_rewards.asm": (
            "CollectDarkBlueKey:",
            "ReturnFromFairyCollision:",
        ),
        "src/game/collision/player_pipeline.asm": (
            "HandleAnimatedPlayerHazard:",
            "PlayerDownwardRoomCellCollisionHandlerPointers:",
        ),
        "src/game/collision/handlers.asm": (
            "PlayerUpwardRoomCellCollisionHandlerPointers:",
            "ReturnFromPlayerCollisionUpdate:",
        ),
        "src/game/runtime/frame_pipeline.asm": (
            "AdvancePlayerTransitionCountdown:",
            "ReturnPlayerOutsideObjectSpan:",
        ),
        "src/game/objects/lifts/movement.asm": (
            "UpdatePulley:",
            "ClearNextLiftOccupantFlag:",
        ),
        "src/game/objects/enemies/patrol.asm": (
            "UpdateFloatingPlatform:",
            "ReturnFromFighterUpdate:",
        ),
        "src/game/objects/enemies/special.asm": (
            "UpdateFlame:",
            "TickCollectedItemEffectLifetime:",
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
            "DrawFairySprite:",
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

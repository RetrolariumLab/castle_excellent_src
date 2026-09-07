#!/usr/bin/env python3
"""Launch or smoke-test an authored Castle Excellent room in pinned FCEUX."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import subprocess
import sys

from scripts.authoring import level_studio_model
from scripts.build import revision_profiles
from scripts.build.project import ProjectError, safe_asset_path


ROOT = Path(__file__).resolve().parents[2]


class LevelPlaytestError(ValueError):
    """The point-playtest inputs or observed runtime state are invalid."""


def playtest_environment(
    room: int, player_x: int, player_y: int, *, result: Path | None = None
) -> dict[str, str]:
    level_studio_model.validate_playtest_position(room, player_x, player_y)
    environment = os.environ.copy()
    environment.update(
        CASTLE_PLAYTEST_ROOM=str(room),
        CASTLE_PLAYTEST_X=str(player_x),
        CASTLE_PLAYTEST_Y=str(player_y),
    )
    if result is not None:
        environment.update(
            CASTLE_PLAYTEST_RESULT=str(result.resolve()).replace("\\", "/"),
            CASTLE_PLAYTEST_EXIT="1",
        )
    return environment


def require_inputs(fceux: Path, rom: Path, lua: Path) -> None:
    for path in (fceux, rom, lua):
        if not path.is_file():
            raise LevelPlaytestError(f"required playtest input not found: {path}")


def parse_result(path: Path) -> dict[str, str]:
    try:
        fields = dict(
            field.split("=", 1)
            for field in path.read_text(encoding="utf-8").strip().split()
        )
    except (OSError, ValueError) as exc:
        raise LevelPlaytestError(f"invalid playtest result {path}: {exc}") from exc
    return fields


def validate_result(
    path: Path, room: int, player_x: int, player_y: int
) -> dict[str, str]:
    fields = parse_result(path)
    expected = {
        "status": "ok",
        "room": str(room),
        "x": str(player_x),
        "y": str(player_y),
    }
    for field, value in expected.items():
        if fields.get(field) != value:
            raise LevelPlaytestError(
                f"playtest {field} is {fields.get(field)!r}, expected {value!r}"
            )
    return fields


def launch_interactive(
    fceux: Path,
    rom: Path,
    lua: Path,
    room: int,
    player_x: int,
    player_y: int,
) -> None:
    require_inputs(fceux, rom, lua)
    subprocess.Popen(
        [str(fceux.resolve()), "-lua", str(lua.resolve()), str(rom.resolve())],
        cwd=rom.parent,
        env=playtest_environment(room, player_x, player_y),
    )


def run_check(args: argparse.Namespace) -> None:
    require_inputs(args.fceux, args.rom, args.lua)
    args.result.parent.mkdir(parents=True, exist_ok=True)
    args.result.unlink(missing_ok=True)
    command = [
        str(args.fceux.resolve()),
        "-lua",
        str(args.lua.resolve()),
        "-max-frames",
        "910",
        "-turbo",
        "1",
        "-nothrottle",
        "1",
        str(args.rom.resolve()),
    ]
    completed = subprocess.run(
        command,
        cwd=args.rom.parent,
        env=playtest_environment(
            args.room, args.player_x, args.player_y, result=args.result
        ),
        check=False,
    )
    if completed.returncode:
        raise LevelPlaytestError(f"FCEUX exited with status {completed.returncode}")
    fields = validate_result(args.result, args.room, args.player_x, args.player_y)
    print(
        f"[OK] point playtest entered room {args.room} at "
        f"({args.player_x},{args.player_y}) on frame {fields['frame']}"
    )


def resolve_rom(args: argparse.Namespace) -> Path:
    if args.rom is not None:
        return args.rom
    if args.profile is None:
        raise LevelPlaytestError("provide --rom or --profile")
    manifest = revision_profiles.load_profiles(args.revisions)
    profile = revision_profiles.select_profile(manifest, args.profile)
    try:
        return safe_asset_path(ROOT, str(profile["output_rom"]))
    except ProjectError as exc:
        raise LevelPlaytestError(str(exc)) from exc


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fceux", required=True, type=Path)
    parser.add_argument("--rom", type=Path)
    parser.add_argument(
        "--revisions", type=Path, default=Path("config/revision_profiles.json")
    )
    parser.add_argument("--profile")
    parser.add_argument("--lua", required=True, type=Path)
    parser.add_argument("--room", required=True, type=int)
    parser.add_argument("--player-x", type=int, default=16)
    parser.add_argument("--player-y", type=int, default=152)
    parser.add_argument("--result", type=Path)
    parser.add_argument("--check", action="store_true")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        args.rom = resolve_rom(args)
        if args.check:
            if args.result is None:
                raise LevelPlaytestError("--check requires --result")
            run_check(args)
        else:
            launch_interactive(
                args.fceux,
                args.rom,
                args.lua,
                args.room,
                args.player_x,
                args.player_y,
            )
    except (
        OSError,
        ProjectError,
        LevelPlaytestError,
        level_studio_model.LevelStudioModelError,
    ) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

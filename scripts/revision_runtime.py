#!/usr/bin/env python3
"""Run and validate direct runtime evidence for a declared revision profile."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import subprocess
import sys

from project import ProjectError
import revision_profiles


class RevisionRuntimeError(ValueError):
    """Revision runtime inputs or observations disagree with their manifest."""


def load_scenario(path: Path, profile_id: str) -> dict[str, object]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise RevisionRuntimeError(f"cannot read runtime manifest: {exc}") from exc
    if document.get("schema_version") != 1 or document.get("profile_id") != profile_id:
        raise RevisionRuntimeError("runtime manifest profile identity disagrees")
    scenarios = document.get("scenarios")
    if not isinstance(scenarios, list) or len(scenarios) != 1:
        raise RevisionRuntimeError("expected exactly one revision runtime scenario")
    scenario = scenarios[0]
    if scenario.get("id") != "castlequest-startup-menu":
        raise RevisionRuntimeError("unexpected revision runtime scenario")
    return scenario


def parse_result(path: Path) -> dict[str, str]:
    try:
        return dict(
            field.split("=", 1)
            for field in path.read_text(encoding="utf-8").strip().split()
        )
    except (OSError, ValueError) as exc:
        raise RevisionRuntimeError(f"invalid revision runtime result: {exc}") from exc


def validate_result(path: Path) -> dict[str, str]:
    fields = parse_result(path)
    expected = {
        "status": "ok",
        "lives": "50",
        "room": "71",
        "menu_open": "1",
        "selections": "0,1,2,0",
        "load": "0",
        "save": "0",
    }
    for name, value in expected.items():
        if fields.get(name) != value:
            raise RevisionRuntimeError(
                f"runtime {name} is {fields.get(name)!r}, expected {value!r}"
            )
    return fields


def run(args: argparse.Namespace) -> None:
    manifest = revision_profiles.load_profiles(args.revisions)
    profile = revision_profiles.select_profile(manifest, args.profile)
    runtime = profile.get("runtime")
    if not isinstance(runtime, dict) or runtime.get("mode") != "direct":
        raise RevisionRuntimeError("profile has no direct runtime contract")
    scenario_path = Path(str(runtime.get("manifest", "")))
    scenario = load_scenario(scenario_path, args.profile)
    image = Path(str(profile["output_rom"]))
    for path in (args.fceux, image, args.lua):
        if not path.is_file():
            raise RevisionRuntimeError(f"required runtime input not found: {path}")
    revision_profiles.validate_reference(image.read_bytes(), profile)
    if scenario.get("capture") != args.lua.as_posix():
        raise RevisionRuntimeError("runtime capture path disagrees with its manifest")
    maximum_frames = scenario.get("maximum_frames")
    if not isinstance(maximum_frames, int) or maximum_frames < 1:
        raise RevisionRuntimeError("invalid runtime frame limit")
    args.result.parent.mkdir(parents=True, exist_ok=True)
    args.result.unlink(missing_ok=True)
    environment = os.environ.copy()
    environment["CASTLEQUEST_RUNTIME_RESULT"] = str(args.result.resolve()).replace(
        "\\", "/"
    )
    completed = subprocess.run(
        [
            str(args.fceux.resolve()),
            "-lua",
            str(args.lua.resolve()),
            "-max-frames",
            str(maximum_frames + 10),
            "-turbo",
            "1",
            "-nothrottle",
            "1",
            str(image.resolve()),
        ],
        env=environment,
        check=False,
    )
    if completed.returncode:
        raise RevisionRuntimeError(f"FCEUX exited with status {completed.returncode}")
    fields = validate_result(args.result)
    print(
        "[OK] Castlequest direct runtime: 50 lives, room 71, "
        f"three menu selections on frame {fields['frame']}"
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--revisions", type=Path, default=Path("config/revision_profiles.json"))
    parser.add_argument("--profile", default="castlequest-usa")
    parser.add_argument("--fceux", type=Path, required=True)
    parser.add_argument("--lua", type=Path, required=True)
    parser.add_argument("--result", type=Path, required=True)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        run(args)
    except (OSError, ProjectError, RevisionRuntimeError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Exercise public editor actions against disposable workstation outputs."""

from __future__ import annotations

import argparse
from copy import deepcopy
from pathlib import Path
import sys
import tempfile
from tkinter import messagebox
from unittest import mock

from scripts.authoring import graphics_studio
from scripts.authoring import level_studio
from scripts.authoring import sound_studio


ROOT = Path(__file__).resolve().parents[2]
REQUIRED_ACTIONS = {
    "level": {"save", "build", "play", "preview", "dirty-close"},
    "sound": {"save", "build", "play", "preview", "dirty-close"},
    "graphics": {"save", "build", "preview", "dirty-close"},
}


class EditorWorkstationSmokeError(RuntimeError):
    """A workstation editor action failed its observable contract."""


def _temporary_profile(
    profile: dict[str, object], directory: Path, stem: str
) -> dict[str, object]:
    result = deepcopy(profile)
    result["output_rom"] = (directory / f"{stem}.nes").relative_to(ROOT).as_posix()
    result["report"] = (directory / f"{stem}.json").relative_to(ROOT).as_posix()
    result["workspace"] = (directory / f"{stem}-workspace.json").relative_to(
        ROOT
    ).as_posix()
    return result


def _verify_outputs(profile: dict[str, object]) -> None:
    for field in ("output_rom", "report"):
        path = ROOT / str(profile[field])
        if not path.is_file() or path.stat().st_size == 0:
            raise EditorWorkstationSmokeError(f"editor did not create {field}: {path}")


def _exercise_dirty_close(application: object) -> None:
    application.dirty = True
    with mock.patch.object(
        messagebox, "askyesno", side_effect=(False, True)
    ) as prompt, mock.patch.object(application, "destroy") as destroy:
        application.close()
        if destroy.called:
            raise EditorWorkstationSmokeError(
                "editor closed after rejecting dirty-state confirmation"
            )
        application.close()
        if destroy.call_count != 1 or prompt.call_count != 2:
            raise EditorWorkstationSmokeError(
                "editor did not honor both dirty-state close decisions"
            )
    application.dirty = False


def exercise_level(args: argparse.Namespace, directory: Path) -> set[str]:
    loaded = level_studio.load_studio(args)
    config, profile, _revision, image, prg, chr_data, _path, document = loaded
    profile = _temporary_profile(profile, directory, "levels")
    workspace = directory / "levels-workspace.json"
    application = level_studio.LevelStudio(
        deepcopy(document),
        config,
        profile,
        image,
        prg,
        chr_data,
        workspace,
        args.profile,
    )
    try:
        application.map_notebook.select(application.overview_frame)
        application.draw_castle_overview()
        application.update_idletasks()
        if len(application.overview_image_cache) != 100:
            raise EditorWorkstationSmokeError("level overview omitted one or more rooms")
        application._save()
        application._build_rom()
        with mock.patch.object(level_studio.level_playtest, "launch_interactive") as play:
            application._play()
            if play.call_count != 1:
                raise EditorWorkstationSmokeError("level Play did not launch the adapter")
        _verify_outputs(profile)
        if not workspace.is_file():
            raise EditorWorkstationSmokeError("level Save did not create the workspace")
        _exercise_dirty_close(application)
    finally:
        application.destroy()
    return REQUIRED_ACTIONS["level"]


def exercise_sound(args: argparse.Namespace, directory: Path) -> set[str]:
    profile, image, prg, chr_data, _path, document = sound_studio.load_studio(args)
    profile = _temporary_profile(profile, directory, "music")
    workspace = directory / "music-workspace.json"
    application = sound_studio.SoundStudio(
        deepcopy(document), profile, image, prg, chr_data, workspace, args.profile
    )
    try:
        application._save()
        application._build_rom()
        application.draw_lanes()
        if sys.platform == "win32":
            with mock.patch("winsound.PlaySound") as play:
                application._preview_track()
                if play.call_count != 1:
                    raise EditorWorkstationSmokeError(
                        "sound preview did not invoke workstation playback"
                    )
        else:
            application._preview_track()
        preview = workspace.with_name("preview.wav")
        if not preview.is_file() or preview.stat().st_size <= 44:
            raise EditorWorkstationSmokeError("sound preview did not create an audible WAV")
        _verify_outputs(profile)
        if not workspace.is_file():
            raise EditorWorkstationSmokeError("sound Save did not create the workspace")
        if sys.platform == "win32":
            with mock.patch("winsound.PlaySound"):
                _exercise_dirty_close(application)
        else:
            _exercise_dirty_close(application)
    finally:
        application.destroy()
    return REQUIRED_ACTIONS["sound"]


def exercise_graphics(args: argparse.Namespace, directory: Path) -> set[str]:
    profile, image, prg, chr_data, _path, document = graphics_studio.load_studio(args)
    profile = _temporary_profile(profile, directory, "graphics")
    workspace = directory / "graphics-workspace.json"
    application = graphics_studio.GraphicsStudio(
        deepcopy(document), profile, image, prg, chr_data, workspace, args.profile
    )
    try:
        application._save()
        application._build_rom()
        application.draw_tile()
        application.draw_atlas()
        application.draw_descriptor()
        application.update_idletasks()
        _verify_outputs(profile)
        if not workspace.is_file():
            raise EditorWorkstationSmokeError("graphics Save did not create the workspace")
        _exercise_dirty_close(application)
    finally:
        application.destroy()
    return REQUIRED_ACTIONS["graphics"]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--levels", default="config/authoring/levels.json")
    parser.add_argument("--audio", default="config/authoring/audio.json")
    parser.add_argument("--graphics", default="config/authoring/graphics.json")
    parser.add_argument("--revisions", default="config/revision_profiles.json")
    parser.add_argument("--profile", required=True)
    args = parser.parse_args()
    args.authoring = args.levels
    try:
        actions: dict[str, set[str]] = {}
        build = ROOT / "build"
        build.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix="editor-smoke-", dir=build) as temporary:
            directory = Path(temporary)
            actions["level"] = exercise_level(args, directory)
            args.authoring = args.audio
            actions["sound"] = exercise_sound(args, directory)
            args.authoring = args.graphics
            actions["graphics"] = exercise_graphics(args, directory)
        if actions != REQUIRED_ACTIONS:
            raise EditorWorkstationSmokeError(
                f"editor action coverage mismatch: {actions!r}"
            )
    except Exception as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    summary = "; ".join(
        f"{name}={','.join(sorted(values))}" for name, values in actions.items()
    )
    print(f"[OK] editor workstation actions: {summary}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

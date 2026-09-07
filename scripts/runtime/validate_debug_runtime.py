#!/usr/bin/env python3
"""Run and validate the live FCEUX semantic-symbol smoke test."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import subprocess


EXPECTED_SYMBOLS = {
    "Nmi": 0xC569,
    "MainFrameLoop": 0x8282,
    "DecodeRoom": 0xE830,
    "UpdateRuntimeObjects": 0x9583,
    "UpdateAudioStreams": 0xB923,
    "RuntimeObjectRecords": 0x004A,
    "RoomCells": 0x0400,
}


def validate_result(path: Path) -> tuple[int, int]:
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[-1] != "OK":
        raise ValueError(f"live debugger validation failed: {lines[-1:]}")
    seen: dict[str, int] = {}
    breakpoint_frame: int | None = None
    for line in lines:
        fields = line.split(",")
        if fields[0] == "symbol" and len(fields) == 4:
            name = fields[1]
            actual = int(fields[2], 16)
            expected = int(fields[3], 16)
            if actual != expected:
                raise ValueError(
                    f"live symbol mismatch for {name}: ${actual:04X} != ${expected:04X}"
                )
            seen[name] = actual
        elif fields[0] == "break" and len(fields) == 4:
            if (
                fields[1] != "MainFrameLoop"
                or int(fields[2], 16) != EXPECTED_SYMBOLS["MainFrameLoop"]
            ):
                raise ValueError(f"unexpected live breakpoint record: {line}")
            breakpoint_frame = int(fields[3])
        elif line != "OK":
            raise ValueError(f"unexpected live debugger record: {line}")
    if seen != EXPECTED_SYMBOLS:
        raise ValueError(f"live symbol set changed: {seen}")
    if breakpoint_frame is None or not 0 <= breakpoint_frame <= 900:
        raise ValueError("MainFrameLoop execution hook was not reached within 900 frames")
    return len(seen), breakpoint_frame


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fceux", required=True, type=Path)
    parser.add_argument("--rom", required=True, type=Path)
    parser.add_argument("--lua", required=True, type=Path)
    parser.add_argument("--result", required=True, type=Path)
    args = parser.parse_args()
    try:
        for path in (args.fceux, args.rom, args.lua):
            if not path.is_file():
                raise ValueError(f"required debugger input is missing: {path}")
        args.result.parent.mkdir(parents=True, exist_ok=True)
        args.result.unlink(missing_ok=True)
        environment = os.environ.copy()
        environment["CASTLE_DEBUG_SYMBOL_RESULT"] = str(args.result.resolve()).replace(
            "\\", "/"
        )
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
        completed = subprocess.run(command, env=environment, check=False)
        if completed.returncode:
            raise ValueError(f"FCEUX exited with status {completed.returncode}")
        if not args.result.is_file():
            raise ValueError("FCEUX did not write the live debugger result")
        symbol_count, frame = validate_result(args.result)
    except (OSError, ValueError) as exc:
        print(f"[ERROR] {exc}")
        return 1
    print(
        f"[OK] live FCEUX lookup for {symbol_count} semantic symbols; "
        f"MainFrameLoop breakpoint reached at frame {frame}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

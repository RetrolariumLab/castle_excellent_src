#!/usr/bin/env python3
"""Model Castle Excellent's title-demo controller playback stream."""

from __future__ import annotations

import argparse
from collections import Counter
from dataclasses import dataclass
import hashlib
import json
from pathlib import Path
import sys


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
INITIALIZE_CPU = 0xB7FD
INITIALIZE_END = 0xB80A
READER_CPU = 0xB80A
READER_END = 0xB82C
SCRIPT_CPU = 0xB82C
SCRIPT_END = 0xB875
SCRIPT_TERMINATOR = 0xFF
COMMAND_HOLD_READS = 12
CONTROLLER_OUTPUT_MASK = 0xF3

RANGE_HASHES = (
    (INITIALIZE_CPU, INITIALIZE_END, "6b4e5315e41bd9f158082edb677e15b5657e9002b20e3ffee0368e2d7fb0f734", "demo initialization"),
    (READER_CPU, READER_END, "4900b743b50d76b95cfd78e47bbdf04e54ecc621567f3530f9e9af92f53b1d57", "demo reader"),
    (SCRIPT_CPU, SCRIPT_END, "17ae656fce51ee9fa92b2b179aa3728fc4a3ff520a9da37f42e2a85de3ce8cee", "demo script"),
    (INITIALIZE_CPU, SCRIPT_END, "49ea3a6b3a48b0a4cf99cec401f0587a737a65e0632dfcde6874748ee38e03b3", "complete demo playback range"),
)

CALLERS = (
    (0xF91E, INITIALIZE_CPU),
    (0xC613, READER_CPU),
)

EXPECTED_COMMAND_DISTRIBUTION = {
    0x00: 1,
    0x01: 6,
    0x40: 7,
    0x41: 7,
    0x43: 2,
    0x80: 41,
    0x81: 7,
    0x82: 1,
}

NMI_DEMO_PATH_CPU = 0xC5FF
EXPECTED_NMI_DEMO_PATH = bytes.fromhex(
    "AD C7 07 D0 0F "
    "20 FF 80 8D 75 07 20 29 81 8D 76 07 4C 1E C6 "
    "20 0A B8 8D 75 07 A9 00 8D 76 07 "
    "20 FF 80 8D CE 07"
)


class DemoPlaybackError(ValueError):
    pass


@dataclass(frozen=True)
class DemoState:
    pointer: int
    repeat_counter: int


@dataclass(frozen=True)
class DemoReadResult:
    state: DemoState
    controller_buttons: int | None
    reset: bool


@dataclass(frozen=True)
class NmiControllerState:
    controller1_buttons: int
    controller2_buttons: int
    physical_controller1_buttons: int


def initial_state() -> DemoState:
    return DemoState(SCRIPT_CPU, 0)


def mask_demo_buttons(buttons: int) -> int:
    if not 0 <= buttons <= 0xFF:
        raise DemoPlaybackError(f"controller byte outside 0-255: {buttons}")
    return buttons & CONTROLLER_OUTPUT_MASK


def advance_pointer(pointer: int) -> int:
    if not 0 <= pointer <= 0xFFFF:
        raise DemoPlaybackError(f"pointer outside 0-65535: {pointer}")
    return (pointer + 1) & 0xFFFF


def read_demo_input(prg: bytes, state: DemoState) -> DemoReadResult:
    if len(prg) != PRG_SIZE:
        raise DemoPlaybackError("expected a 32 KiB PRG region")
    if not PRG_BASE <= state.pointer <= 0xFFFF:
        raise DemoPlaybackError(f"demo pointer outside PRG: ${state.pointer:04X}")
    if not 0 <= state.repeat_counter <= 0xFF:
        raise DemoPlaybackError("repeat counter outside 0-255")
    counter = (state.repeat_counter + 1) & 0xFF
    pointer = state.pointer
    if counter >= COMMAND_HOLD_READS:
        pointer = advance_pointer(pointer)
        counter = 0
    value = prg[pointer - PRG_BASE]
    next_state = DemoState(pointer, counter)
    if value == SCRIPT_TERMINATOR:
        return DemoReadResult(next_state, None, True)
    return DemoReadResult(next_state, mask_demo_buttons(value), False)


def apply_demo_nmi_input(result: DemoReadResult, physical_buttons: int) -> NmiControllerState:
    if result.reset or result.controller_buttons is None:
        raise DemoPlaybackError("terminal demo marker resets before NMI controller stores")
    if not 0 <= physical_buttons <= 0xFF:
        raise DemoPlaybackError("physical controller byte outside 0-255")
    return NmiControllerState(result.controller_buttons, 0, physical_buttons)


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise DemoPlaybackError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    start = 16 + trainer_size
    end = start + prg_size
    if prg_size != PRG_SIZE or end > len(image):
        raise DemoPlaybackError("expected a complete 32 KiB PRG region")
    return image[start:end]


def _slice(prg: bytes, start: int, end: int) -> bytes:
    return prg[start - PRG_BASE:end - PRG_BASE]


def _require_call(prg: bytes, source: int, target: int) -> None:
    expected = bytes((0x20, target & 0xFF, target >> 8))
    if _slice(prg, source, source + 3) != expected:
        raise DemoPlaybackError(f"JSR at ${source:04X} changed")


def script_bytes(prg: bytes) -> bytes:
    data = _slice(prg, SCRIPT_CPU, SCRIPT_END)
    if len(data) != 73 or data[-1] != SCRIPT_TERMINATOR:
        raise DemoPlaybackError("demo script boundary or terminator changed")
    if SCRIPT_TERMINATOR in data[:-1]:
        raise DemoPlaybackError("demo script contains an early terminator")
    return data


def expand_demo(prg: bytes) -> tuple[bytes, int]:
    state = initial_state()
    output = bytearray()
    reads = 0
    while True:
        result = read_demo_input(prg, state)
        reads += 1
        if result.reset:
            return bytes(output), reads
        assert result.controller_buttons is not None
        output.append(result.controller_buttons)
        state = result.state


def validate_rom_contract(prg: bytes) -> dict[str, object]:
    if len(prg) != PRG_SIZE:
        raise DemoPlaybackError("expected a 32 KiB PRG region")
    for start, end, expected_hash, name in RANGE_HASHES:
        if hashlib.sha256(_slice(prg, start, end)).hexdigest() != expected_hash:
            raise DemoPlaybackError(f"{name} bytes changed")
    for source, target in CALLERS:
        _require_call(prg, source, target)
    data = script_bytes(prg)
    distribution = Counter(data[:-1])
    if dict(distribution) != EXPECTED_COMMAND_DISTRIBUTION:
        raise DemoPlaybackError("demo command distribution changed")
    actual_nmi = _slice(
        prg, NMI_DEMO_PATH_CPU, NMI_DEMO_PATH_CPU + len(EXPECTED_NMI_DEMO_PATH)
    )
    if actual_nmi != EXPECTED_NMI_DEMO_PATH:
        raise DemoPlaybackError("NMI demo/physical controller topology changed")
    expanded, reset_read = expand_demo(prg)
    if len(expanded) != 863 or reset_read != 864:
        raise DemoPlaybackError("expanded demo duration changed")
    if expanded[:11] != bytes((data[0],)) * 11:
        raise DemoPlaybackError("first demo command duration changed")
    offset = 11
    for command in data[1:-1]:
        if expanded[offset:offset + 12] != bytes((mask_demo_buttons(command),)) * 12:
            raise DemoPlaybackError("later demo command duration changed")
        offset += 12
    return {
        "range": [INITIALIZE_CPU, SCRIPT_END - 1],
        "bytes": SCRIPT_END - INITIALIZE_CPU,
        "callers": len(CALLERS),
        "commands": len(data) - 1,
        "returned_samples": len(expanded),
        "reset_read": reset_read,
        "distribution": {f"${key:02X}": value for key, value in sorted(distribution.items())},
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()
    try:
        report = validate_rom_contract(extract_prg(args.image.read_bytes()))
    except (OSError, DemoPlaybackError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        print(
            "[OK] validated 120 demo-playback bytes, 72 commands, "
            "863 returned samples, and reset on read 864"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Model Castle Excellent's title screen and Famicom sub-command menu."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import hashlib
import json
from pathlib import Path
import sys


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
CHR_BANK_SIZE = 0x2000

TITLE_CPU = 0xF8FC
TITLE_END = 0xF973
NAMETABLE_COPY_CPU = 0xF973
NAMETABLE_COPY_END = 0xF9AD
SUB_COMMAND_INPUT_CPU = 0xF9AD
SUB_COMMAND_INPUT_END = 0xF9CC
SUB_COMMAND_MENU_CPU = 0xF9CC
SUB_COMMAND_MENU_END = 0xFB77
SUB_COMMAND_TEXT_CPU = 0xFB77
SUB_COMMAND_TEXT_END = 0xFBAC
SUB_COMMAND_ROOM_ACTIONS_CPU = 0xFBAC
SUB_COMMAND_ROOM_ACTIONS_END = 0xFBFE

RANGE_HASHES = (
    (TITLE_CPU, TITLE_END, "8e638519d560293261bde582ed4c4aed331a1101de648416d5fa029dc92f3950", "title screen"),
    (NAMETABLE_COPY_CPU, NAMETABLE_COPY_END, "81d61f232c649aa60ca0edc38139e3e4b12bb1d294748e252d9dbe7de3e49f37", "nametable copy"),
    (SUB_COMMAND_INPUT_CPU, SUB_COMMAND_INPUT_END, "f817750cf1a6d18bb9f6ceaa3b803a4610b65cefdb2bdfc92bfc5e2f4a2577e8", "sub-command entry"),
    (SUB_COMMAND_MENU_CPU, SUB_COMMAND_MENU_END, "a9a5e721a909718c5a4ce5380049056addb1345a2cd232b24eb29ea050257884", "sub-command menu"),
    (SUB_COMMAND_TEXT_CPU, SUB_COMMAND_TEXT_END, "faed03825de474eefdd0f4716873243c303a7eab59b1829daeb614c1210ff284", "sub-command text"),
    (SUB_COMMAND_ROOM_ACTIONS_CPU, SUB_COMMAND_ROOM_ACTIONS_END, "2de4bd11bbd50aa65efcc2a0621964831c2ec2eec5a45e1dbf20e9cf0df03450", "sub-command room actions"),
)
WHOLE_SHA256 = "fc12a9bf475d85e967d07e57bd582f35c23fbb1107afcb30c7537113177bb9a7"

CONTROLLER_A = 0x01
CONTROLLER_B = 0x02
CONTROLLER_SELECT = 0x04
CONTROLLER_START = 0x08
CONTROLLER_UP = 0x10
CONTROLLER_DOWN = 0x20

TITLE_TIMEOUT_FRAMES = 0x300
TITLE_START_PAGE = 0x18
NAMETABLE_DESTINATION = 0x2000
NAMETABLE_COPY_SIZE = 0x400

SUB_COMMAND_COUNT = 5
SUB_COMMAND_CURSOR_BASE = 0x218B
SUB_COMMAND_CURSOR_ROW_STRIDE = 0x40
SUB_COMMAND_CURSOR_TILE = 0x6B
SUB_COMMAND_ENTRY_BUTTONS = CONTROLLER_A | CONTROLLER_B
SUB_COMMAND_NEXT_BUTTONS = CONTROLLER_SELECT | CONTROLLER_DOWN

SUB_COMMAND_TARGETS = (
    ("reset", 0xFBAC),
    ("back", 0xFBD6),
    ("load", 0xFD06),
    ("save", 0xFBFE),
    ("game", 0xFB51),
)

EXPECTED_STRINGS = (
    (0xFB77, "SUB COMMAND"),
    (0xFB83, "LOAD"),
    (0xFB88, "SAVE"),
    (0xFB8D, "RESET"),
    (0xFB93, "BACK"),
    (0xFB98, "GAME"),
    (0xFB9D, "LOADING"),
    (0xFBA5, "SAVING"),
)

TEXT_POINTER_LOADS = (
    (0xF9E9, 0xFB77),
    (0xFA01, 0xFB8D),
    (0xFA19, 0xFB93),
    (0xFA31, 0xFB83),
    (0xFA49, 0xFB88),
    (0xFA61, 0xFB98),
    (0xFC15, 0xFBA5),
    (0xFD11, 0xFB9D),
)

ABSOLUTE_TRANSFERS = (
    (0x826E, 0xF8FC, 0x20),
    (0x82B4, 0xF9AD, 0x20),
    (0xEA83, 0xF973, 0x20),
    (0xF8FE, 0xF973, 0x20),
    (0xFE93, 0xF973, 0x20),
    (0xFCE7, 0xF9CC, 0x4C),
    (0xFB1B, 0xFA74, 0x4C),
    (0xFB24, 0xFA74, 0x4C),
    (0xFB4E, 0xFA74, 0x4C),
    (0xFBB0, 0xFA74, 0x4C),
    (0xFBDA, 0xFA74, 0x4C),
    (0xFBE2, 0xFA74, 0x4C),
    (0xFC05, 0xFA74, 0x4C),
    (0xFC0D, 0xFA74, 0x4C),
    (0xFC7F, 0xFB51, 0x4C),
    (0xFDC2, 0xFB51, 0x4C),
    (0xFB71, 0xFD06, 0x4C),
    (0xFB74, 0xFBFE, 0x4C),
    (0xFBD3, 0xFD96, 0x4C),
)

RELATIVE_TRANSFERS = (
    (0xF9C3, 0xF9CC, 0xD0),
    (0xFA77, 0xFA74, 0x10),
    (0xFB30, 0xFB62, 0xF0),
    (0xFB3B, 0xFB62, 0xD0),
    (0xFB64, 0xFBAC, 0xF0),
    (0xFB67, 0xFBD6, 0xF0),
    (0xFB6A, 0xFB71, 0xF0),
    (0xFB6D, 0xFB74, 0xF0),
    (0xFB6F, 0xFB51, 0xD0),
    (0xFBFC, 0xFBC0, 0xF0),
)

COPY_CALL_SITES = (
    (0xEA81, 0x1C),
    (0xF8FC, 0x18),
    (0xFE91, 0x14),
)


class TitleSubCommandError(ValueError):
    pass


@dataclass(frozen=True)
class TitleFrameResult:
    counter: int
    previous_buttons_inverted: int
    demo_active: int
    exited: bool
    reason: str | None


@dataclass(frozen=True)
class SubCommandEntryResult:
    opened: bool
    previous_controller2_buttons: int


@dataclass(frozen=True)
class MenuFrameResult:
    selection: int
    previous_buttons_inverted: int
    command: str | None
    target: int | None
    transport_mode: int | None


@dataclass(frozen=True)
class RoomActionResult:
    allowed: bool
    lives: int
    room_number: int | None
    runtime_state: bytes | None
    player_x_lo: int | None
    player_x_hi: int | None
    player_y: int | None
    snapshot_a_room: int | None
    snapshot_b_room: int | None
    persistent_state_loaded: bool
    target: int | None


def _byte(value: int, name: str) -> int:
    if not 0 <= value <= 0xFF:
        raise TitleSubCommandError(f"{name} outside 0-255: {value}")
    return value


def title_frame(counter: int, current_buttons: int, previous_buttons_inverted: int) -> TitleFrameResult:
    if not 0 <= counter < TITLE_TIMEOUT_FRAMES:
        raise TitleSubCommandError(f"title counter outside 0-{TITLE_TIMEOUT_FRAMES - 1}: {counter}")
    current_buttons = _byte(current_buttons, "current buttons")
    previous_buttons_inverted = _byte(previous_buttons_inverted, "inverted previous buttons")
    counter += 1
    if counter >= TITLE_TIMEOUT_FRAMES:
        return TitleFrameResult(counter, previous_buttons_inverted, 0xFF, True, "timeout")
    start_edge = current_buttons & previous_buttons_inverted & CONTROLLER_START
    previous_buttons_inverted = (~current_buttons) & 0xFF
    if start_edge:
        return TitleFrameResult(counter, previous_buttons_inverted, 0x00, True, "start")
    return TitleFrameResult(counter, previous_buttons_inverted, 0xFF, False, None)


def initialize_title_buttons(current_buttons: int) -> int:
    return (~_byte(current_buttons, "current buttons")) & 0xFF


def nametable_copy_plan(source_page: int) -> tuple[tuple[int, int], ...]:
    source_page = _byte(source_page, "source page")
    source = source_page << 8
    if source + NAMETABLE_COPY_SIZE > CHR_BANK_SIZE:
        raise TitleSubCommandError("four-page source extends past the selected CHR bank")
    return tuple((source + offset, NAMETABLE_DESTINATION + offset) for offset in range(NAMETABLE_COPY_SIZE))


def copy_four_chr_pages(chr_bank: bytes, source_page: int) -> bytes:
    if len(chr_bank) != CHR_BANK_SIZE:
        raise TitleSubCommandError(f"expected one {CHR_BANK_SIZE}-byte CHR bank")
    plan = nametable_copy_plan(source_page)
    return bytes(chr_bank[source] for source, _destination in plan)


def sub_command_entry(
    game_over_active: int,
    demo_active: int,
    current_controller2_buttons: int,
    previous_controller2_buttons: int,
) -> SubCommandEntryResult:
    game_over_active = _byte(game_over_active, "game-over state")
    demo_active = _byte(demo_active, "demo state")
    current = _byte(current_controller2_buttons, "controller-2 buttons")
    previous = _byte(previous_controller2_buttons, "previous controller-2 buttons")
    if game_over_active or demo_active:
        return SubCommandEntryResult(False, previous)
    opened = bool(current & ((~previous) & 0xFF) & SUB_COMMAND_ENTRY_BUTTONS)
    return SubCommandEntryResult(opened, previous if opened else current)


def cursor_address(selection: int) -> int:
    if not 0 <= selection < SUB_COMMAND_COUNT:
        raise TitleSubCommandError(f"sub-command selection outside 0-{SUB_COMMAND_COUNT - 1}: {selection}")
    return SUB_COMMAND_CURSOR_BASE + selection * SUB_COMMAND_CURSOR_ROW_STRIDE


def menu_frame(selection: int, current_buttons: int, previous_buttons_inverted: int) -> MenuFrameResult:
    cursor_address(selection)
    current = _byte(current_buttons, "current buttons")
    previous_inverted = _byte(previous_buttons_inverted, "inverted previous buttons")
    pressed = current & previous_inverted
    next_previous_inverted = (~current) & 0xFF
    if pressed & SUB_COMMAND_NEXT_BUTTONS:
        return MenuFrameResult((selection + 1) % SUB_COMMAND_COUNT, next_previous_inverted, None, None, None)
    if pressed & CONTROLLER_START:
        command, target = SUB_COMMAND_TARGETS[selection]
        return MenuFrameResult(selection, next_previous_inverted, command, target, 0x00)
    if pressed & CONTROLLER_A:
        command, target = SUB_COMMAND_TARGETS[selection]
        return MenuFrameResult(selection, next_previous_inverted, command, target, 0xFF)
    if pressed & CONTROLLER_UP:
        return MenuFrameResult((selection - 1) % SUB_COMMAND_COUNT, next_previous_inverted, None, None, None)
    return MenuFrameResult(selection, next_previous_inverted, None, None, None)


def reset_current_room(lives: int, current_room: int, runtime_load_mirror: bytes) -> RoomActionResult:
    lives = _byte(lives, "lives")
    current_room = _byte(current_room, "current room")
    if len(runtime_load_mirror) < 14:
        raise TitleSubCommandError("room runtime load mirror must contain at least 14 bytes")
    if not lives:
        return RoomActionResult(False, lives, current_room, None, None, None, None, None, None, False, None)
    runtime = bytes(runtime_load_mirror[:14])
    return RoomActionResult(
        True, lives - 1, current_room, runtime, runtime[11], runtime[12], runtime[13], None, None, True, 0xFD96
    )


def back_to_previous_room(
    lives: int,
    snapshot_a_room: int,
    snapshot_b_room: int,
    runtime_snapshot_a: bytes,
) -> RoomActionResult:
    lives = _byte(lives, "lives")
    snapshot_a_room = _byte(snapshot_a_room, "snapshot-A room")
    snapshot_b_room = _byte(snapshot_b_room, "snapshot-B room")
    if len(runtime_snapshot_a) < 14:
        raise TitleSubCommandError("room runtime snapshot A must contain at least 14 bytes")
    if not lives or not snapshot_a_room:
        return RoomActionResult(
            False, lives, snapshot_a_room or None, None, None, None, None,
            snapshot_a_room, snapshot_b_room, False, None
        )
    runtime = bytes(runtime_snapshot_a[:14])
    return RoomActionResult(
        True, lives - 1, snapshot_a_room, runtime, runtime[11], runtime[12], runtime[13], 0, 0, False, 0xFD96
    )


def decode_tile_string(data: bytes) -> str:
    if not data or data[-1] != 0:
        raise TitleSubCommandError("tile string is not zero terminated")
    decoded = []
    for tile in data[:-1]:
        if tile == 0xFF:
            decoded.append(" ")
        elif 0x71 <= tile <= 0x8A:
            decoded.append(chr(ord("A") + tile - 0x71))
        else:
            raise TitleSubCommandError(f"unsupported text tile ${tile:02X}")
    return "".join(decoded)


def extract_regions(image: bytes) -> tuple[bytes, tuple[bytes, ...]]:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise TitleSubCommandError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    chr_size = image[5] * CHR_BANK_SIZE
    prg_start = 16 + trainer_size
    chr_start = prg_start + prg_size
    image_end = chr_start + chr_size
    if prg_size != PRG_SIZE or image_end > len(image):
        raise TitleSubCommandError("expected a complete 32 KiB PRG and CHR region")
    chr_data = image[chr_start:image_end]
    banks = tuple(chr_data[index:index + CHR_BANK_SIZE] for index in range(0, chr_size, CHR_BANK_SIZE))
    return image[prg_start:chr_start], banks


def _slice(prg: bytes, start: int, end: int) -> bytes:
    return prg[start - PRG_BASE:end - PRG_BASE]


def _require_absolute_transfer(prg: bytes, source: int, target: int, opcode: int) -> None:
    expected = bytes((opcode, target & 0xFF, target >> 8))
    if _slice(prg, source, source + 3) != expected:
        raise TitleSubCommandError(f"absolute transfer at ${source:04X} changed")


def _require_relative_transfer(prg: bytes, source: int, target: int, opcode: int) -> None:
    displacement = (target - (source + 2)) & 0xFF
    if _slice(prg, source, source + 2) != bytes((opcode, displacement)):
        raise TitleSubCommandError(f"relative transfer at ${source:04X} changed")


def _terminated_string(prg: bytes, start: int) -> bytes:
    offset = start - PRG_BASE
    try:
        end = prg.index(0, offset, SUB_COMMAND_TEXT_END - PRG_BASE) + 1
    except ValueError as exc:
        raise TitleSubCommandError(f"unterminated tile string at ${start:04X}") from exc
    return prg[offset:end]


def validate_rom_contract(prg: bytes, chr_banks: tuple[bytes, ...]) -> dict[str, object]:
    if len(prg) != PRG_SIZE:
        raise TitleSubCommandError("expected a 32 KiB PRG region")
    for start, end, expected_hash, name in RANGE_HASHES:
        if hashlib.sha256(_slice(prg, start, end)).hexdigest() != expected_hash:
            raise TitleSubCommandError(f"{name} bytes changed")
    whole = _slice(prg, TITLE_CPU, SUB_COMMAND_ROOM_ACTIONS_END)
    if hashlib.sha256(whole).hexdigest() != WHOLE_SHA256:
        raise TitleSubCommandError("combined title/sub-command bytes changed")
    for source, target, opcode in ABSOLUTE_TRANSFERS:
        _require_absolute_transfer(prg, source, target, opcode)
    for source, target, opcode in RELATIVE_TRANSFERS:
        _require_relative_transfer(prg, source, target, opcode)
    for source, page in COPY_CALL_SITES:
        if _slice(prg, source, source + 5) != bytes((0xA9, page, 0x20, 0x73, 0xF9)):
            raise TitleSubCommandError(f"nametable-copy call at ${source:04X} changed")
    decoded_strings = []
    for address, expected in EXPECTED_STRINGS:
        actual = decode_tile_string(_terminated_string(prg, address))
        if actual != expected:
            raise TitleSubCommandError(f"text at ${address:04X} changed: {actual!r}")
        decoded_strings.append(actual)
    for source, target in TEXT_POINTER_LOADS:
        expected = bytes((0xA9, target >> 8, 0x85, 0x22, 0xA9, target & 0xFF, 0x85, 0x21))
        if _slice(prg, source, source + len(expected)) != expected:
            raise TitleSubCommandError(f"text pointer load at ${source:04X} changed")
    if len(chr_banks) <= 3:
        raise TitleSubCommandError("title copy requires CHR bank 3")
    copied = {}
    for _source, page in COPY_CALL_SITES:
        block = copy_four_chr_pages(chr_banks[3], page)
        plan = nametable_copy_plan(page)
        if len(block) != NAMETABLE_COPY_SIZE or plan[0] != (page << 8, 0x2000):
            raise TitleSubCommandError("nametable-copy plan changed")
        if plan[-1] != ((page << 8) + 0x3FF, 0x23FF):
            raise TitleSubCommandError("nametable-copy final address changed")
        copied[f"${page:02X}"] = hashlib.sha256(block).hexdigest()
    return {
        "range": [TITLE_CPU, SUB_COMMAND_ROOM_ACTIONS_END - 1],
        "bytes": len(whole),
        "range_hashes": len(RANGE_HASHES),
        "absolute_transfers": len(ABSOLUTE_TRANSFERS),
        "relative_transfers": len(RELATIVE_TRANSFERS),
        "strings": decoded_strings,
        "copied_chr_pages": copied,
    }


def validate_behavior_contract() -> dict[str, int]:
    timeout = title_frame(TITLE_TIMEOUT_FRAMES - 1, 0xFF, 0xFF)
    if not timeout.exited or timeout.reason != "timeout" or timeout.demo_active != 0xFF:
        raise TitleSubCommandError("title timeout behavior changed")
    start = title_frame(0, CONTROLLER_START, 0xFF)
    if not start.exited or start.reason != "start" or start.demo_active:
        raise TitleSubCommandError("title Start-edge behavior changed")

    menu_cases = 0
    for selection in range(SUB_COMMAND_COUNT):
        for current in range(0x100):
            for previous_inverted in range(0x100):
                result = menu_frame(selection, current, previous_inverted)
                pressed = current & previous_inverted
                if pressed & SUB_COMMAND_NEXT_BUTTONS:
                    expected_selection = (selection + 1) % SUB_COMMAND_COUNT
                    expected_mode = None
                elif pressed & CONTROLLER_START:
                    expected_selection = selection
                    expected_mode = 0x00
                elif pressed & CONTROLLER_A:
                    expected_selection = selection
                    expected_mode = 0xFF
                elif pressed & CONTROLLER_UP:
                    expected_selection = (selection - 1) % SUB_COMMAND_COUNT
                    expected_mode = None
                else:
                    expected_selection = selection
                    expected_mode = None
                if result.selection != expected_selection or result.transport_mode != expected_mode:
                    raise TitleSubCommandError("sub-command input priority changed")
                if result.previous_buttons_inverted != ((~current) & 0xFF):
                    raise TitleSubCommandError("sub-command edge history changed")
                if expected_mode is None and result.command is not None:
                    raise TitleSubCommandError("sub-command dispatched without confirmation")
                if expected_mode is not None and (result.command, result.target) != SUB_COMMAND_TARGETS[selection]:
                    raise TitleSubCommandError("sub-command dispatch map changed")
                menu_cases += 1

    entry_cases = 0
    for game_over in (0, 1):
        for demo in (0, 1):
            for current in range(0x100):
                for previous in range(0x100):
                    result = sub_command_entry(game_over, demo, current, previous)
                    expected_open = not (game_over or demo) and bool(
                        current & ((~previous) & 0xFF) & SUB_COMMAND_ENTRY_BUTTONS
                    )
                    if result.opened != expected_open:
                        raise TitleSubCommandError("sub-command entry gating changed")
                    expected_previous = previous if game_over or demo or expected_open else current
                    if result.previous_controller2_buttons != expected_previous:
                        raise TitleSubCommandError("controller-2 history behavior changed")
                    entry_cases += 1
    return {"menu_cases": menu_cases, "entry_cases": entry_cases}


def room_action_report(result: RoomActionResult) -> dict[str, object]:
    report = asdict(result)
    runtime_state = report["runtime_state"]
    if isinstance(runtime_state, bytes):
        report["runtime_state"] = runtime_state.hex()
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()
    try:
        prg, chr_banks = extract_regions(args.image.read_bytes())
        report = validate_rom_contract(prg, chr_banks)
        report["behavior"] = validate_behavior_contract()
        report["dispatch"] = [
            {"selection": index, "command": command, "target": target}
            for index, (command, target) in enumerate(SUB_COMMAND_TARGETS)
        ]
        report["room_examples"] = {
            "reset": room_action_report(reset_current_room(3, 0x47, bytes(range(14)))),
            "back": room_action_report(back_to_previous_room(3, 0x46, 0x47, bytes(range(14)))),
        }
    except (OSError, TitleSubCommandError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        print(
            "[OK] validated 770 title/sub-command bytes, 8 strings, "
            f"{report['behavior']['menu_cases']} menu cases, and "
            f"{report['behavior']['entry_cases']} entry-gating cases"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

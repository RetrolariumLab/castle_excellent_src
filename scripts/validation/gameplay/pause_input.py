#!/usr/bin/env python3
"""Model pause toggling and paused horizontal scrolling at $A8E3-$A959."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import json
from pathlib import Path
import sys


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
ROUTINE_CPU = 0xA8E3
CALL_SITE_CPU = 0x8291
BUTTON_A = 0x01
BUTTON_B = 0x02
BUTTON_START = 0x08
BUTTON_LEFT = 0x40
BUTTON_RIGHT = 0x80
RESUME_BUTTONS = BUTTON_A | BUTTON_B
PAUSE_INACTIVE = 0x00
PAUSE_ACTIVE = 0xFF
SCROLL_STEP = 4
SCROLL_MINIMUM = 0x00
SCROLL_MAXIMUM = 0x80
SCROLL_UPDATE_REQUESTED = 0xFF
APU_CHANNELS_DISABLED = 0x00
EXPECTED_ROUTINE_BYTES = bytes.fromhex(
    "AD 75 07 29 03 F0 0C AD 77 07 29 03 D0 05 AD C4 07 D0 1C "
    "AD 75 07 29 08 F0 21 AD 77 07 29 08 D0 1A AD C4 07 D0 09 "
    "A9 00 8D 15 40 A9 FF D0 02 A9 00 8D C4 07 AD 75 07 8D 77 "
    "07 60 AD C4 07 D0 01 60 AD 75 07 29 40 F0 12 A5 34 38 E9 "
    "04 B0 02 A9 00 85 34 A9 FF 85 36 4C 53 A9 AD 75 07 29 80 "
    "F0 0F A5 34 18 69 04 10 02 A9 80 85 34 A9 FF 85 36 AD 75 "
    "07 8D 77 07 60"
)


class PauseInputError(ValueError):
    pass


@dataclass(frozen=True)
class PauseInputResult:
    pause_mode: int
    previous_buttons: int
    scroll_x: int
    scroll_update_pending: int
    apu_status_write: int | None
    action: str


def _validate_byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise PauseInputError(f"{name} outside 0-255: {value}")


def update_pause_input(
    *,
    current_buttons: int,
    previous_buttons: int,
    pause_mode: int,
    scroll_x: int,
    scroll_update_pending: int,
) -> PauseInputResult:
    for value, name in (
        (current_buttons, "current buttons"),
        (previous_buttons, "previous buttons"),
        (pause_mode, "pause mode"),
        (scroll_x, "scroll X"),
        (scroll_update_pending, "scroll update flag"),
    ):
        _validate_byte(value, name)

    resume_edge = bool(current_buttons & RESUME_BUTTONS) and not bool(
        previous_buttons & RESUME_BUTTONS
    )
    if resume_edge and pause_mode != PAUSE_INACTIVE:
        return PauseInputResult(
            PAUSE_INACTIVE,
            current_buttons,
            scroll_x,
            scroll_update_pending,
            None,
            "resume_ab",
        )

    start_edge = bool(current_buttons & BUTTON_START) and not bool(
        previous_buttons & BUTTON_START
    )
    if start_edge:
        if pause_mode != PAUSE_INACTIVE:
            return PauseInputResult(
                PAUSE_INACTIVE,
                current_buttons,
                scroll_x,
                scroll_update_pending,
                None,
                "resume_start",
            )
        return PauseInputResult(
            PAUSE_ACTIVE,
            current_buttons,
            scroll_x,
            scroll_update_pending,
            APU_CHANNELS_DISABLED,
            "pause_start",
        )

    if pause_mode == PAUSE_INACTIVE:
        return PauseInputResult(
            pause_mode,
            previous_buttons,
            scroll_x,
            scroll_update_pending,
            None,
            "unpaused_idle",
        )

    next_scroll = scroll_x
    next_update = scroll_update_pending
    action = "paused_idle"
    if current_buttons & BUTTON_LEFT:
        next_scroll = max(SCROLL_MINIMUM, scroll_x - SCROLL_STEP)
        next_update = SCROLL_UPDATE_REQUESTED
        action = "scroll_left"
    elif current_buttons & BUTTON_RIGHT:
        candidate = (scroll_x + SCROLL_STEP) & 0xFF
        next_scroll = SCROLL_MAXIMUM if candidate & 0x80 else candidate
        next_update = SCROLL_UPDATE_REQUESTED
        action = "scroll_right"
    return PauseInputResult(
        pause_mode,
        current_buttons,
        next_scroll,
        next_update,
        None,
        action,
    )


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise PauseInputError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    prg_start = 16 + trainer_size
    prg_end = prg_start + prg_size
    if prg_size != PRG_SIZE or prg_end > len(image):
        raise PauseInputError("expected a complete 32 KiB PRG region")
    return image[prg_start:prg_end]


def validate_rom_contract(prg: bytes) -> dict[str, object]:
    start = ROUTINE_CPU - PRG_BASE
    observed = prg[start:start + len(EXPECTED_ROUTINE_BYTES)]
    if observed != EXPECTED_ROUTINE_BYTES:
        raise PauseInputError("pause-input routine bytes changed")
    call_offset = CALL_SITE_CPU - PRG_BASE
    expected_call = bytes((0x20, ROUTINE_CPU & 0xFF, ROUTINE_CPU >> 8))
    if prg[call_offset:call_offset + 3] != expected_call:
        raise PauseInputError("main-loop pause-input call changed")
    return {
        "routine_range": [ROUTINE_CPU, ROUTINE_CPU + len(observed) - 1],
        "routine_bytes": len(observed),
        "call_site": CALL_SITE_CPU,
    }


def validate_exhaustive_contract() -> dict[str, object]:
    button_pair_cases = 0
    actions: dict[str, int] = {}
    for pause_mode in (PAUSE_INACTIVE, PAUSE_ACTIVE):
        for current_buttons in range(0x100):
            for previous_buttons in range(0x100):
                result = update_pause_input(
                    current_buttons=current_buttons,
                    previous_buttons=previous_buttons,
                    pause_mode=pause_mode,
                    scroll_x=0x40,
                    scroll_update_pending=0x5A,
                )
                actions[result.action] = actions.get(result.action, 0) + 1
                if result.action.startswith("resume") and result.pause_mode != 0:
                    raise PauseInputError("resume action left pause active")
                if result.action == "pause_start" and (
                    result.pause_mode != PAUSE_ACTIVE
                    or result.apu_status_write != APU_CHANNELS_DISABLED
                ):
                    raise PauseInputError("pause entry did not disable APU channels")
                if result.action == "unpaused_idle" and (
                    result.previous_buttons != previous_buttons
                ):
                    raise PauseInputError("unpaused idle changed edge history")
                button_pair_cases += 1

    pause_mode_cases = 0
    for pause_mode in range(0x100):
        ab_edge = update_pause_input(
            current_buttons=BUTTON_A,
            previous_buttons=0,
            pause_mode=pause_mode,
            scroll_x=0,
            scroll_update_pending=0,
        )
        expected_ab_action = "unpaused_idle" if pause_mode == 0 else "resume_ab"
        if ab_edge.pause_mode != PAUSE_INACTIVE or ab_edge.action != expected_ab_action:
            raise PauseInputError("A edge pause-mode domain mismatch")
        start_edge = update_pause_input(
            current_buttons=BUTTON_START,
            previous_buttons=0,
            pause_mode=pause_mode,
            scroll_x=0,
            scroll_update_pending=0,
        )
        expected_start_mode = PAUSE_ACTIVE if pause_mode == 0 else PAUSE_INACTIVE
        if start_edge.pause_mode != expected_start_mode:
            raise PauseInputError("Start edge pause-mode domain mismatch")
        idle = update_pause_input(
            current_buttons=0,
            previous_buttons=0,
            pause_mode=pause_mode,
            scroll_x=0,
            scroll_update_pending=0,
        )
        if idle.pause_mode != pause_mode:
            raise PauseInputError("idle path changed pause mode")
        pause_mode_cases += 3

    scroll_cases = 0
    wrapped_right_inputs: list[int] = []
    for scroll_x in range(0x100):
        for buttons in (0, BUTTON_LEFT, BUTTON_RIGHT, BUTTON_LEFT | BUTTON_RIGHT):
            result = update_pause_input(
                current_buttons=buttons,
                previous_buttons=buttons,
                pause_mode=PAUSE_ACTIVE,
                scroll_x=scroll_x,
                scroll_update_pending=0x5A,
            )
            if buttons & BUTTON_LEFT:
                expected = max(0, scroll_x - SCROLL_STEP)
                if result.scroll_x != expected or result.action != "scroll_left":
                    raise PauseInputError("paused Left scroll mismatch")
            elif buttons & BUTTON_RIGHT:
                candidate = (scroll_x + SCROLL_STEP) & 0xFF
                expected = SCROLL_MAXIMUM if candidate & 0x80 else candidate
                if result.scroll_x != expected or result.action != "scroll_right":
                    raise PauseInputError("paused Right scroll mismatch")
                if scroll_x >= 0xFC:
                    wrapped_right_inputs.append(scroll_x)
            elif result.scroll_x != scroll_x or result.action != "paused_idle":
                raise PauseInputError("paused idle scroll mismatch")
            scroll_cases += 1
    if wrapped_right_inputs != [0xFC, 0xFD, 0xFE, 0xFF]:
        raise PauseInputError("unexpected right-scroll wrap domain")

    return {
        "button_pair_cases": button_pair_cases,
        "pause_mode_cases": pause_mode_cases,
        "scroll_cases": scroll_cases,
        "actions": actions,
        "right_wrap_inputs": wrapped_right_inputs,
    }


def build_report(image_path: Path, validate: bool) -> dict[str, object]:
    prg = extract_prg(image_path.read_bytes())
    report: dict[str, object] = {"rom": validate_rom_contract(prg)}
    if validate:
        report["exhaustive"] = validate_exhaustive_contract()
    else:
        report["example"] = asdict(
            update_pause_input(
                current_buttons=BUTTON_START,
                previous_buttons=0,
                pause_mode=PAUSE_INACTIVE,
                scroll_x=0,
                scroll_update_pending=0,
            )
        )
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()
    try:
        report = build_report(args.image, args.validate)
    except (OSError, PauseInputError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        exhaustive = report["exhaustive"]
        print(
            f"[OK] validated {exhaustive['button_pair_cases']:,} button pairs, "
            "all pause-mode and scroll bytes, and the exact APU/scroll effects"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

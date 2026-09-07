#!/usr/bin/env python3
"""Model and validate Castle Excellent's reset signature and frame gate."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import json
from pathlib import Path
import sys


INES_HEADER_SIZE = 16
PRG_CPU_BASE = 0x8000
POWER_ON_SIGNATURE_ADDRESS = 0x82C9
POWER_ON_SIGNATURE = b"POWER"
CHECKED_POWER_ON_SIGNATURE = POWER_ON_SIGNATURE[:3]
NMI_FRAMES_PER_MAIN_UPDATE = 2


class StartupStateError(ValueError):
    pass


@dataclass(frozen=True)
class ResetState:
    signature: bytes
    high_score_lo: int
    high_score_hi: int
    counter_lo: int
    counter_hi: int

    def __post_init__(self) -> None:
        if len(self.signature) != len(CHECKED_POWER_ON_SIGNATURE):
            raise StartupStateError("reset signature RAM must contain exactly 3 bytes")
        for field_name in (
            "high_score_lo",
            "high_score_hi",
            "counter_lo",
            "counter_hi",
        ):
            value = getattr(self, field_name)
            if not 0 <= value <= 0xFF:
                raise StartupStateError(f"{field_name} is not a byte: {value}")


@dataclass(frozen=True)
class ResetResult:
    state: ResetState
    cold_boot: bool


def apply_reset(state: ResetState) -> ResetResult:
    """Reproduce $823A-$8267, including the post-reset counter increment."""
    cold_boot = state.signature != CHECKED_POWER_ON_SIGNATURE
    if cold_boot:
        state = ResetState(CHECKED_POWER_ON_SIGNATURE, 0, 0, 0, 0)
    counter = ((state.counter_hi << 8) | state.counter_lo) + 1
    counter &= 0xFFFF
    return ResetResult(
        ResetState(
            state.signature,
            state.high_score_lo,
            state.high_score_hi,
            counter & 0xFF,
            counter >> 8,
        ),
        cold_boot,
    )


def nmi_tick_frame_countdown(countdown: int) -> int:
    """Reproduce the saturating decrement at $C5F9-$C5FE."""
    if not 0 <= countdown <= 0xFF:
        raise StartupStateError(f"frame countdown is not a byte: {countdown}")
    return countdown - 1 if countdown else 0


def nmis_until_main_update(countdown: int) -> int:
    ticks = 0
    while countdown:
        countdown = nmi_tick_frame_countdown(countdown)
        ticks += 1
    return ticks


def read_power_on_signature(image: Path) -> bytes:
    data = image.read_bytes()
    if len(data) < INES_HEADER_SIZE or data[:4] != b"NES\x1a":
        raise StartupStateError(f"{image} is not an iNES image")
    prg_size = data[4] * 0x4000
    offset = INES_HEADER_SIZE + POWER_ON_SIGNATURE_ADDRESS - PRG_CPU_BASE
    if offset + len(POWER_ON_SIGNATURE) > INES_HEADER_SIZE + prg_size:
        raise StartupStateError("power-on signature falls outside PRG-ROM")
    return data[offset : offset + len(POWER_ON_SIGNATURE)]


def validate_startup_contract(image: Path) -> dict[str, object]:
    signature = read_power_on_signature(image)
    if signature != POWER_ON_SIGNATURE:
        raise StartupStateError(
            f"power-on signature is {signature!r}, expected {POWER_ON_SIGNATURE!r}"
        )
    cold = apply_reset(ResetState(b"BAD", 0x12, 0x34, 0x56, 0x78))
    if not cold.cold_boot or cold.state != ResetState(b"POW", 0, 0, 1, 0):
        raise StartupStateError("cold-boot state transition does not match Reset")
    warm = apply_reset(ResetState(b"POW", 0x12, 0x34, 0xFF, 0x7A))
    if warm.cold_boot or warm.state != ResetState(b"POW", 0x12, 0x34, 0, 0x7B):
        raise StartupStateError("warm-reset state transition does not match Reset")
    if nmis_until_main_update(NMI_FRAMES_PER_MAIN_UPDATE) != 2:
        raise StartupStateError("main update is not gated by exactly two NMI ticks")
    return {
        "power_on_signature_address": f"0x{POWER_ON_SIGNATURE_ADDRESS:04X}",
        "power_on_signature": signature.decode("ascii"),
        "checked_signature": CHECKED_POWER_ON_SIGNATURE.decode("ascii"),
        "nmi_frames_per_main_update": NMI_FRAMES_PER_MAIN_UPDATE,
        "cold_boot": _state_document(cold),
        "warm_reset": _state_document(warm),
    }


def _state_document(result: ResetResult) -> dict[str, object]:
    document = asdict(result.state)
    document["signature"] = result.state.signature.decode("ascii")
    document["cold_boot"] = result.cold_boot
    return document


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--pretty", action="store_true")
    parser.add_argument("--validate", action="store_true")
    args = parser.parse_args()
    try:
        document = validate_startup_contract(args.image)
    except (OSError, StartupStateError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    if args.pretty:
        print(json.dumps(document, indent=2))
    else:
        print(
            "[OK] validated POWER/POW cold-warm reset state and "
            "two-NMI main-loop pacing"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

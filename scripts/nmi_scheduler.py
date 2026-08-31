#!/usr/bin/env python3
"""Model Castle Excellent's NMI request scan and modular frame counters."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
from typing import Sequence


INES_HEADER_SIZE = 16
PRG_CPU_BASE = 0x8000
NMI_TASK_COUNT = 23
NMI_HANDLER_HIGH_ADDRESS = 0xC88E
NMI_HANDLER_LOW_ADDRESS = 0xC8A5
FRAME_COUNTER_PERIODS = (3, 5, 6, 7, 3, 10, 11, 30)
EXPECTED_TASK_HANDLERS = (
    0xC804,
    *(0xC8BC + row * 0x143 for row in range(20)),
    0xE1F8,
    0xE358,
)


class NmiSchedulerError(ValueError):
    pass


def advance_task_scheduler(requests: Sequence[int], current: int) -> tuple[list[int], int]:
    """Reproduce the request clear and forward scan at $C5DA-$C5F8."""
    if len(requests) != NMI_TASK_COUNT:
        raise NmiSchedulerError(
            f"NMI request array has {len(requests)} bytes, expected {NMI_TASK_COUNT}"
        )
    if not 0 <= current < NMI_TASK_COUNT:
        raise NmiSchedulerError(f"invalid current NMI task index: {current}")
    updated = list(requests)
    if any(not 0 <= request <= 0xFF for request in updated):
        raise NmiSchedulerError("NMI request values must be bytes")
    updated[current] = 0
    if current >= NMI_TASK_COUNT - 1:
        return updated, 0
    for index in range(current + 1, NMI_TASK_COUNT):
        if updated[index] != 0:
            return updated, index
    return updated, 0


def tick_modulo_counter(value: int, period: int) -> int:
    if not 0 <= value <= 0xFF:
        raise NmiSchedulerError(f"frame counter is not a byte: {value}")
    if not 1 <= period <= 0xFF:
        raise NmiSchedulerError(f"invalid frame-counter period: {period}")
    incremented = (value + 1) & 0xFF
    return incremented if incremented < period else 0


def tick_frame_counters(values: Sequence[int]) -> tuple[int, ...]:
    if len(values) != len(FRAME_COUNTER_PERIODS):
        raise NmiSchedulerError(
            f"received {len(values)} frame counters, expected {len(FRAME_COUNTER_PERIODS)}"
        )
    return tuple(
        tick_modulo_counter(value, period)
        for value, period in zip(values, FRAME_COUNTER_PERIODS, strict=True)
    )


def read_handler_table(image: Path) -> tuple[int, ...]:
    data = image.read_bytes()
    if len(data) < INES_HEADER_SIZE or data[:4] != b"NES\x1a":
        raise NmiSchedulerError(f"{image} is not an iNES image")
    prg_size = data[4] * 0x4000
    prg = data[INES_HEADER_SIZE : INES_HEADER_SIZE + prg_size]
    high_offset = NMI_HANDLER_HIGH_ADDRESS - PRG_CPU_BASE
    low_offset = NMI_HANDLER_LOW_ADDRESS - PRG_CPU_BASE
    high = prg[high_offset : high_offset + NMI_TASK_COUNT]
    low = prg[low_offset : low_offset + NMI_TASK_COUNT]
    if len(high) != NMI_TASK_COUNT or len(low) != NMI_TASK_COUNT:
        raise NmiSchedulerError("NMI handler tables fall outside PRG-ROM")
    return tuple((high_byte << 8) | low_byte for high_byte, low_byte in zip(high, low, strict=True))


def validate_nmi_contract(image: Path) -> dict[str, object]:
    handlers = read_handler_table(image)
    if handlers != EXPECTED_TASK_HANDLERS:
        raise NmiSchedulerError(f"unexpected NMI handler table: {handlers}")
    requests = [0] * NMI_TASK_COUNT
    requests[4] = 0xFF
    requests[17] = 0x01
    cleared, selected = advance_task_scheduler(requests, 4)
    if selected != 17 or cleared[4] != 0:
        raise NmiSchedulerError("NMI request scheduler scan does not match the handler")
    if tick_frame_counters(tuple(period - 1 for period in FRAME_COUNTER_PERIODS)) != (0,) * 8:
        raise NmiSchedulerError("modular NMI counters do not wrap at their periods")
    return {
        "task_count": NMI_TASK_COUNT,
        "handler_high_table": f"0x{NMI_HANDLER_HIGH_ADDRESS:04X}",
        "handler_low_table": f"0x{NMI_HANDLER_LOW_ADDRESS:04X}",
        "handlers": [f"0x{address:04X}" for address in handlers],
        "frame_counter_periods": list(FRAME_COUNTER_PERIODS),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--pretty", action="store_true")
    parser.add_argument("--validate", action="store_true")
    args = parser.parse_args()
    try:
        document = validate_nmi_contract(args.image)
    except (OSError, NmiSchedulerError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    if args.pretty:
        print(json.dumps(document, indent=2))
    else:
        print(
            "[OK] validated 23 NMI handlers, request scheduling, and "
            "eight modular frame counters"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Model Castle Excellent's sound-effect engine at $C20D-$C43C."""

from __future__ import annotations

import argparse
from dataclasses import dataclass, replace
import hashlib
import json
from pathlib import Path
import sys


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
ENGINE_START_CPU = 0xC20D
STARTERS_END_CPU = 0xC2F9
UPDATER_START_CPU = 0xC2F9
TABLES_START_CPU = 0xC429
ENGINE_END_CPU = 0xC43D

APU_PULSE1_VOLUME = 0x4000
APU_PULSE1_SWEEP = 0x4001
APU_PULSE1_PERIOD_LOW = 0x4002
APU_PULSE1_PERIOD_HIGH = 0x4003
APU_PULSE2_VOLUME = 0x4004
APU_PULSE2_SWEEP = 0x4005
APU_PULSE2_PERIOD_LOW = 0x4006
APU_PULSE2_PERIOD_HIGH = 0x4007
APU_TRIANGLE_LINEAR = 0x4008
APU_TRIANGLE_PERIOD_LOW = 0x400A
APU_TRIANGLE_PERIOD_HIGH = 0x400B
APU_NOISE_VOLUME = 0x400C
APU_NOISE_PERIOD = 0x400E
APU_NOISE_LENGTH = 0x400F
APU_STATUS = 0x4015

PULSE1_REQUEST = 0x00EC
PULSE2_REQUEST = 0x00EF
PULSE2_STEP = 0x00F0
TRIANGLE_REQUEST = 0x00F2
TRIANGLE_STEP = 0x00F3
NOISE_REQUEST = 0x00F5
NOISE_STEP = 0x00F6
PULSE1_BUSY = 0x07D0
PULSE2_BUSY = 0x07D1
TRIANGLE_BUSY = 0x07D2
NOISE_BUSY = 0x07D3

TRIANGLE_TYPE2_PERIOD_LOW = (0xF0, 0xE0, 0xD0, 0xC0)
PULSE2_TYPE3_PERIOD_LOW = (0x50, 0x3F, 0x3D, 0x35)
NOISE_TYPE4_VOLUME = (0x18, 0x1B, 0x1E, 0x03)
NOISE_TYPE4_PERIOD = (0x0C, 0x09, 0x06, 0x02)
NOISE_TYPE4_LENGTH = (0x38, 0x38, 0x58, 0x38)

RANGE_HASHES = (
    (
        0xC20D,
        0xC233,
        "1a16664c98737d433c3b4f7b2927a6b8deea6c9495a0395592d7fce4ef84fa3a",
        "pulse 1 type-1 starter",
    ),
    (
        0xC233,
        0xC272,
        "7d99959088bc863891ff7278660a00bc3121504908b4797ad9d5c93b53e2bc6b",
        "pulse 2/noise type-2 starter",
    ),
    (
        0xC272,
        0xC29A,
        "9649d98dca5f235947fe95b964c7219617e164cac93c65b47b3da218e912cbb0",
        "inventory type-3 starter",
    ),
    (
        0xC29A,
        0xC2BD,
        "81caa6eef9427c1af68ef4d9a714a90857e6e78bcf5efa237230051b1d303e38",
        "noise type-4 starter",
    ),
    (
        0xC2BD,
        0xC2F9,
        "f908517c76698b106698a11e61fb7ff51b86813745f748b7b20871d6b87e9f6b",
        "mutable-cell type-5 starter",
    ),
    (
        ENGINE_START_CPU,
        STARTERS_END_CPU,
        "fd3b8b96adaacbb66d0616c9a87f573e25ed882e018b31fc2fb226b956dbfab2",
        "complete sound-effect starters",
    ),
    (
        UPDATER_START_CPU,
        TABLES_START_CPU,
        "538dd8a31955ac9aa155792a8283bea2cc46eb8d74b37fd6fd72bec5d6eba861",
        "sound-effect updater",
    ),
    (
        TABLES_START_CPU,
        ENGINE_END_CPU,
        "9da08e0bf43f4dcc54155a62aee0dd8da4d13bd3556f48131e2eb9bf1c273020",
        "sound-effect tables",
    ),
    (
        ENGINE_START_CPU,
        ENGINE_END_CPU,
        "2b6896f26216f955fbecafb82ae3dab7e4df2e3965d57670c3ac40c0e12faebd",
        "complete sound-effect engine",
    ),
)

EXPECTED_ENTRYPOINT_CALLERS = {
    0xC20D: ((0x832E, 0x20), (0x8475, 0x20)),
    0xC233: ((0x8664, 0x20), (0x8998, 0x20), (0x978E, 0x4C)),
    0xC272: ((0x8C69, 0x20),),
    0xC29A: ((0x9D69, 0x20),),
    0xC2BD: ((0xA649, 0x20),),
    0xC2F9: ((0xC6A4, 0x20),),
}
NMI_AUDIO_UPDATE_CPU = 0xC6A1
EXPECTED_NMI_AUDIO_UPDATE = bytes.fromhex("20 23 B9 20 F9 C2")


class SoundEffectEngineError(ValueError):
    pass


@dataclass(frozen=True)
class SoundEffectState:
    pulse1_request: int = 0
    pulse2_request: int = 0
    pulse2_step: int = 0
    triangle_request: int = 0
    triangle_step: int = 0
    noise_request: int = 0
    noise_step: int = 0
    pulse1_busy: int = 0
    pulse2_busy: int = 0
    triangle_busy: int = 0
    noise_busy: int = 0


@dataclass(frozen=True)
class SoundEffectResult:
    state: SoundEffectState
    ram_writes: tuple[tuple[int, int], ...]
    apu_writes: tuple[tuple[int, int], ...]


RAM_FIELDS = {
    PULSE1_REQUEST: "pulse1_request",
    PULSE2_REQUEST: "pulse2_request",
    PULSE2_STEP: "pulse2_step",
    TRIANGLE_REQUEST: "triangle_request",
    TRIANGLE_STEP: "triangle_step",
    NOISE_REQUEST: "noise_request",
    NOISE_STEP: "noise_step",
    PULSE1_BUSY: "pulse1_busy",
    PULSE2_BUSY: "pulse2_busy",
    TRIANGLE_BUSY: "triangle_busy",
    NOISE_BUSY: "noise_busy",
}


def _validate_byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise SoundEffectEngineError(f"{name} outside 0-255: {value}")


def _validate_state(state: SoundEffectState) -> None:
    for name, value in vars(state).items():
        _validate_byte(value, name.replace("_", " "))


def _apply_ram_writes(
    state: SoundEffectState, writes: tuple[tuple[int, int], ...]
) -> SoundEffectState:
    result = state
    for address, value in writes:
        result = replace(result, **{RAM_FIELDS[address]: value})
    return result


def _starter_result(
    state: SoundEffectState,
    ram_writes: tuple[tuple[int, int], ...],
    apu_writes: tuple[tuple[int, int], ...],
) -> SoundEffectResult:
    _validate_state(state)
    return SoundEffectResult(_apply_ram_writes(state, ram_writes), ram_writes, apu_writes)


def start_pulse1_type1(state: SoundEffectState) -> SoundEffectResult:
    return _starter_result(
        state,
        ((PULSE1_BUSY, 1), (PULSE1_REQUEST, 1), (PULSE1_BUSY, 0)),
        (
            (APU_STATUS, 0x0F),
            (APU_PULSE1_VOLUME, 0xDF),
            (APU_PULSE1_SWEEP, 0xBA),
            (APU_PULSE1_PERIOD_LOW, 0x40),
            (APU_PULSE1_PERIOD_HIGH, 0xA0),
        ),
    )


def start_pulse2_noise_type2(state: SoundEffectState) -> SoundEffectResult:
    return _starter_result(
        state,
        (
            (PULSE2_BUSY, 2),
            (NOISE_BUSY, 2),
            (PULSE2_REQUEST, 2),
            (NOISE_REQUEST, 2),
            (PULSE2_STEP, 0),
            (PULSE2_BUSY, 0),
            (NOISE_BUSY, 0),
        ),
        (
            (APU_STATUS, 0x0F),
            (APU_PULSE2_VOLUME, 0x83),
            (APU_PULSE2_SWEEP, 0x96),
            (APU_PULSE2_PERIOD_LOW, 0xFF),
            (APU_PULSE2_PERIOD_HIGH, 0xF1),
            (APU_NOISE_VOLUME, 0xC1),
            (APU_NOISE_PERIOD, 0x0F),
            (APU_NOISE_LENGTH, 0xF8),
        ),
    )


def start_inventory_type3(state: SoundEffectState) -> SoundEffectResult:
    return _starter_result(
        state,
        (
            (PULSE2_BUSY, 3),
            (PULSE2_REQUEST, 3),
            (PULSE2_STEP, 0),
            (PULSE2_BUSY, 0),
        ),
        (
            (APU_STATUS, 0x0F),
            (APU_PULSE2_VOLUME, 0x40),
            (APU_PULSE2_SWEEP, 0x08),
            (APU_PULSE2_PERIOD_LOW, 0x50),
            (APU_PULSE2_PERIOD_HIGH, 0x48),
        ),
    )


def start_noise_type4(state: SoundEffectState) -> SoundEffectResult:
    return _starter_result(
        state,
        (
            (NOISE_BUSY, 4),
            (NOISE_REQUEST, 4),
            (NOISE_STEP, 0),
            (NOISE_BUSY, 0),
        ),
        (
            (APU_STATUS, 0x0F),
            (APU_NOISE_VOLUME, 0x18),
            (APU_NOISE_PERIOD, 0x0C),
            (APU_NOISE_LENGTH, 0x38),
        ),
    )


def start_mutable_cell_type5(state: SoundEffectState) -> SoundEffectResult:
    return _starter_result(
        state,
        (
            (TRIANGLE_BUSY, 5),
            (NOISE_BUSY, 5),
            (TRIANGLE_REQUEST, 5),
            (NOISE_REQUEST, 5),
            (TRIANGLE_STEP, 0),
            (NOISE_STEP, 0),
            (TRIANGLE_BUSY, 0),
            (NOISE_BUSY, 0),
        ),
        (
            (APU_STATUS, 0x0F),
            (APU_TRIANGLE_LINEAR, 0x30),
            (APU_TRIANGLE_PERIOD_LOW, 0xF0),
            (APU_TRIANGLE_PERIOD_HIGH, 0x60),
            (APU_NOISE_VOLUME, 0x04),
            (APU_NOISE_PERIOD, 0x0F),
            (APU_NOISE_LENGTH, 0x60),
        ),
    )


def update_sound_effects(
    state: SoundEffectState, *, apu_status_read: int
) -> SoundEffectResult:
    _validate_state(state)
    _validate_byte(apu_status_read, "APU status")
    ram: list[tuple[int, int]] = []
    apu: list[tuple[int, int]] = [(APU_STATUS, 0x0F)]

    if (
        state.pulse1_busy == 0
        and state.pulse1_request == 1
        and apu_status_read & 0x01 == 0
    ):
        ram.append((PULSE1_REQUEST, 0))

    if state.pulse2_busy == 0 and state.pulse2_request:
        if state.pulse2_request == 3 and apu_status_read & 0x02 == 0:
            step = (state.pulse2_step + 1) & 0xFF
            ram.append((PULSE2_STEP, step))
            if step >= 4:
                ram.append((PULSE2_REQUEST, 0))
            else:
                apu.extend(
                    (
                        (APU_PULSE2_PERIOD_LOW, PULSE2_TYPE3_PERIOD_LOW[step]),
                        (APU_PULSE2_PERIOD_HIGH, 0x48),
                    )
                )
        elif state.pulse2_request == 2 and apu_status_read & 0x02 == 0:
            ram.append((PULSE2_REQUEST, 0))

    if state.triangle_busy == 0 and state.triangle_request:
        if state.triangle_request == 2 and apu_status_read & 0x04 == 0:
            step = (state.triangle_step + 1) & 0xFF
            ram.append((TRIANGLE_STEP, step))
            if step >= 4:
                ram.append((TRIANGLE_REQUEST, 0))
            else:
                apu.extend(
                    (
                        (APU_TRIANGLE_LINEAR, 0x3F),
                        (APU_TRIANGLE_PERIOD_LOW, TRIANGLE_TYPE2_PERIOD_LOW[step]),
                        (APU_TRIANGLE_PERIOD_HIGH, 0x59),
                    )
                )
        elif state.triangle_request == 5 and apu_status_read & 0x04 == 0:
            step = (state.triangle_step + 1) & 0xFF
            ram.append((TRIANGLE_STEP, step))
            if step >= 2:
                ram.append((TRIANGLE_REQUEST, 0))
            else:
                apu.extend(
                    (
                        (APU_TRIANGLE_LINEAR, 0x30),
                        (APU_TRIANGLE_PERIOD_LOW, 0xA0),
                        (APU_TRIANGLE_PERIOD_HIGH, 0x60),
                    )
                )

    if state.noise_busy == 0 and state.noise_request:
        if state.noise_request == 4 and apu_status_read & 0x08 == 0:
            step = (state.noise_step + 1) & 0xFF
            ram.append((NOISE_STEP, step))
            if step >= 4:
                ram.append((NOISE_REQUEST, 0))
            else:
                index = step & 0x03
                apu.extend(
                    (
                        (APU_NOISE_VOLUME, NOISE_TYPE4_VOLUME[index]),
                        (APU_NOISE_PERIOD, NOISE_TYPE4_PERIOD[index]),
                        (APU_NOISE_LENGTH, NOISE_TYPE4_LENGTH[index]),
                    )
                )
        elif state.noise_request == 5 and apu_status_read & 0x08 == 0:
            step = (state.noise_step + 1) & 0xFF
            ram.append((NOISE_STEP, step))
            if step >= 2:
                ram.append((NOISE_REQUEST, 0))
            else:
                apu.extend(
                    (
                        (APU_NOISE_VOLUME, 0x04),
                        (APU_NOISE_PERIOD, 0x0D),
                        (APU_NOISE_LENGTH, 0x60),
                    )
                )
        elif state.noise_request == 2 and apu_status_read & 0x08 == 0:
            ram.append((NOISE_REQUEST, 0))

    ram_writes = tuple(ram)
    return SoundEffectResult(_apply_ram_writes(state, ram_writes), ram_writes, tuple(apu))


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise SoundEffectEngineError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    start = 16 + trainer_size
    end = start + prg_size
    if prg_size != PRG_SIZE or end > len(image):
        raise SoundEffectEngineError("expected a complete 32 KiB PRG region")
    return image[start:end]


def _slice(prg: bytes, start: int, end: int) -> bytes:
    return prg[start - PRG_BASE:end - PRG_BASE]


def _find_opcode_target(prg: bytes, opcode: int, target: int) -> list[int]:
    needle = bytes((opcode, target & 0xFF, target >> 8))
    return [
        PRG_BASE + offset
        for offset in range(len(prg) - len(needle) + 1)
        if prg[offset:offset + len(needle)] == needle
    ]


def validate_rom_contract(prg: bytes) -> dict[str, object]:
    if len(prg) != PRG_SIZE:
        raise SoundEffectEngineError("expected a 32 KiB PRG region")
    for start, end, expected_hash, name in RANGE_HASHES:
        if hashlib.sha256(_slice(prg, start, end)).hexdigest() != expected_hash:
            raise SoundEffectEngineError(f"{name} bytes changed")
    for target, callers in EXPECTED_ENTRYPOINT_CALLERS.items():
        for source, opcode in callers:
            expected = bytes((opcode, target & 0xFF, target >> 8))
            if _slice(prg, source, source + 3) != expected:
                raise SoundEffectEngineError(
                    f"sound-effect caller at ${source:04X} changed"
                )
        for opcode in (0x20, 0x4C):
            expected_sources = [
                source
                for source, expected_opcode in callers
                if expected_opcode == opcode
            ]
            if _find_opcode_target(prg, opcode, target) != expected_sources:
                raise SoundEffectEngineError(
                    f"sound-effect topology for ${target:04X} changed"
                )
    if _slice(
        prg,
        NMI_AUDIO_UPDATE_CPU,
        NMI_AUDIO_UPDATE_CPU + len(EXPECTED_NMI_AUDIO_UPDATE),
    ) != EXPECTED_NMI_AUDIO_UPDATE:
        raise SoundEffectEngineError("NMI audio-update order changed")
    tables = _slice(prg, TABLES_START_CPU, ENGINE_END_CPU)
    expected_tables = bytes(
        TRIANGLE_TYPE2_PERIOD_LOW
        + PULSE2_TYPE3_PERIOD_LOW
        + NOISE_TYPE4_VOLUME
        + NOISE_TYPE4_PERIOD
        + NOISE_TYPE4_LENGTH
    )
    if tables != expected_tables:
        raise SoundEffectEngineError("sound-effect lookup tables changed")
    return {
        "range": [ENGINE_START_CPU, ENGINE_END_CPU - 1],
        "bytes": ENGINE_END_CPU - ENGINE_START_CPU,
        "starter_bytes": STARTERS_END_CPU - ENGINE_START_CPU,
        "updater_bytes": TABLES_START_CPU - UPDATER_START_CPU,
        "table_bytes": ENGINE_END_CPU - TABLES_START_CPU,
        "entrypoints": len(EXPECTED_ENTRYPOINT_CALLERS),
        "callers": sum(len(callers) for callers in EXPECTED_ENTRYPOINT_CALLERS.values()),
        "nmi_update": [0xB923, 0xC2F9],
    }


def _single_channel_state(channel: str, request: int, step: int, busy: int) -> SoundEffectState:
    values: dict[str, int] = {f"{channel}_request": request, f"{channel}_busy": busy}
    if channel != "pulse1":
        values[f"{channel}_step"] = step
    return SoundEffectState(**values)


def validate_exhaustive_contract() -> dict[str, object]:
    relevant = {
        "pulse1": {1},
        "pulse2": {2, 3},
        "triangle": {2, 5},
        "noise": {2, 4, 5},
    }
    status_bits = {"pulse1": 0x01, "pulse2": 0x02, "triangle": 0x04, "noise": 0x08}
    arbitration_cases = 0
    for channel, request_types in relevant.items():
        for request in range(0x100):
            for busy in (0, 1):
                for active in (0, 1):
                    state = _single_channel_state(channel, request, 0x80, busy)
                    result = update_sound_effects(
                        state,
                        apu_status_read=status_bits[channel] if active else 0,
                    )
                    changes = result.ram_writes or len(result.apu_writes) > 1
                    expected_changes = busy == 0 and active == 0 and request in request_types
                    if bool(changes) != expected_changes:
                        raise SoundEffectEngineError(
                            f"{channel} request arbitration mismatch"
                        )
                    arbitration_cases += 1

    step_specs = (
        ("pulse2", 3, 4),
        ("triangle", 2, 4),
        ("triangle", 5, 2),
        ("noise", 4, 4),
        ("noise", 5, 2),
    )
    step_cases = 0
    table_indices: set[int] = set()
    for channel, request, threshold in step_specs:
        for step in range(0x100):
            state = _single_channel_state(channel, request, step, 0)
            result = update_sound_effects(state, apu_status_read=0)
            next_step = (step + 1) & 0xFF
            if getattr(result.state, f"{channel}_step") != next_step:
                raise SoundEffectEngineError(f"{channel} step increment mismatch")
            expected_request = 0 if next_step >= threshold else request
            if getattr(result.state, f"{channel}_request") != expected_request:
                raise SoundEffectEngineError(f"{channel} completion threshold mismatch")
            if next_step < threshold and request in (2, 3, 4):
                table_indices.add(next_step & 0x03)
            step_cases += 1
    if table_indices != {0, 1, 2, 3}:
        raise SoundEffectEngineError("sound-effect table index domain changed")
    return {
        "arbitration_cases": arbitration_cases,
        "step_cases": step_cases,
        "table_indices": sorted(table_indices),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()
    try:
        report = validate_rom_contract(extract_prg(args.image.read_bytes()))
        report["exhaustive"] = validate_exhaustive_contract()
    except (OSError, SoundEffectEngineError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        print(
            "[OK] validated 560 sound-effect bytes, six entrypoints, "
            "nine callers, and all request/step arbitration domains"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

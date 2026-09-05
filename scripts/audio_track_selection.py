#!/usr/bin/env python3
"""Validate and model the audio track selectors at $B875-$B905."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import hashlib
import json
from pathlib import Path
import sys


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
SELECTOR_START_CPU = 0xB875
SELECTOR_END_CPU = 0xB8C6
TRACK_TABLE_CPU = 0xB8C6
TRACK_RECORD_SIZE = 8
TRACK_RECORD_COUNT = 8
TRACK_TABLE_END_CPU = TRACK_TABLE_CPU + TRACK_RECORD_SIZE * TRACK_RECORD_COUNT
SELECTOR_SHA256 = "d4ec6913ce3f1844506fecabd786a863d30d5ef04c582bbe4732c12a6eb13fac"
TRACK_TABLE_SHA256 = "7a501f307839f7a4097709969610acf1679422a083aefe36e920535c1d75dca6"

SELECTOR_ENTRYPOINTS = {
    0: 0xB875,
    1: 0xB879,
    2: 0xB87D,
    3: 0xB881,
    4: 0xB885,
    5: 0xB889,
    7: 0xB88D,
}
SELECTOR_RECORD_OFFSETS = {
    track_set: track_set * TRACK_RECORD_SIZE for track_set in SELECTOR_ENTRYPOINTS
}
DEMO_GUARDED_TRACK_SETS = frozenset({0, 1, 2, 3, 4, 7})

AUDIO_STREAM_POINTER_LO = 0xDB
AUDIO_STREAM_POINTER_HI = 0xDC
AUDIO_STREAM_TICKS_REMAINING = 0xDD
AUDIO_STREAM_STATE_SIZE = 4
AUDIO_PULSE1_PARAMETERS = 0xE7
AUDIO_PULSE2_PARAMETERS = 0xE8

MML_STREAM_STARTS = frozenset(
    {
        0xBBE7,
        0xBC3F,
        0xBCEE,
        0xBD4F,
        0xBD80,
        0xBDB9,
        0xBDF4,
        0xBE17,
        0xBE38,
        0xBE5D,
        0xBEBC,
        0xBF1B,
        0xBF92,
        0xBFFB,
        0xC05D,
        0xC0A1,
        0xC0DE,
        0xC117,
        0xC158,
        0xC185,
        0xC1C2,
    }
)

EXPECTED_RECORD_VALUES = (
    (0xBBE7, 0xBC3F, 0xBCEE, 0xBF, 0xBB),
    (0xBD4F, 0xBD80, 0xBDB9, 0xBF, 0xBB),
    (0xBDF4, 0xBDF4, 0xBE38, 0xA9, 0xA9),
    (0xBE5D, 0xBEBC, 0xBF1B, 0x2F, 0x2B),
    (0xBF92, 0xBFFB, 0xC05D, 0x3F, 0x3B),
    (0xC0A1, 0xC0DE, 0xC117, 0x3F, 0xBB),
    (0x0000, 0xC158, 0xC158, 0x02, 0x02),
    (0xC158, 0xC185, 0xC1C2, 0x7F, 0x7F),
)

EXPECTED_CALL_SITES = {
    0x8C92: (0x20, 0xB879),
    0x8D4F: (0x20, 0xB881),
    0x8D61: (0x20, 0xB885),
    0x8D75: (0x20, 0xB88D),
    0x8DD0: (0x4C, 0xB87D),
    0xA39F: (0x4C, 0xB881),
    0xA3A6: (0x4C, 0xB879),
    0xA3A9: (0x4C, 0xB875),
    0xF921: (0x20, 0xB889),
    0xFE5B: (0x20, 0xB87D),
    0xFEAF: (0x20, 0xB885),
}


class AudioTrackSelectionError(ValueError):
    pass


@dataclass(frozen=True)
class AudioTrackRecord:
    pulse1_pointer: int
    pulse2_pointer: int
    triangle_pointer: int
    pulse1_parameters: int
    pulse2_parameters: int


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise AudioTrackSelectionError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    start = 16 + trainer_size
    end = start + prg_size
    if prg_size != PRG_SIZE or end > len(image):
        raise AudioTrackSelectionError("expected a complete 32 KiB PRG region")
    return image[start:end]


def _slice(prg: bytes, start: int, end: int) -> bytes:
    return prg[start - PRG_BASE:end - PRG_BASE]


def _word(data: bytes, offset: int) -> int:
    return data[offset] | data[offset + 1] << 8


def parse_track_records(prg: bytes) -> tuple[AudioTrackRecord, ...]:
    table = _slice(prg, TRACK_TABLE_CPU, TRACK_TABLE_END_CPU)
    if len(table) != TRACK_RECORD_SIZE * TRACK_RECORD_COUNT:
        raise AudioTrackSelectionError("audio track table is truncated")
    records = []
    for offset in range(0, len(table), TRACK_RECORD_SIZE):
        record = table[offset:offset + TRACK_RECORD_SIZE]
        records.append(
            AudioTrackRecord(
                _word(record, 0),
                _word(record, 2),
                _word(record, 4),
                record[6],
                record[7],
            )
        )
    return tuple(records)


def selector_record_offset(track_set: int, demo_playback_active: int) -> int | None:
    if track_set not in SELECTOR_RECORD_OFFSETS:
        raise AudioTrackSelectionError(f"track set has no selector: {track_set}")
    if not 0 <= demo_playback_active <= 0xFF:
        raise AudioTrackSelectionError(
            f"demo playback flag outside 0-255: {demo_playback_active}"
        )
    if track_set in DEMO_GUARDED_TRACK_SETS and demo_playback_active:
        return None
    return SELECTOR_RECORD_OFFSETS[track_set]


def track_record_ram_writes(record: AudioTrackRecord) -> dict[int, int]:
    pointers = (
        record.pulse1_pointer,
        record.pulse2_pointer,
        record.triangle_pointer,
    )
    writes: dict[int, int] = {}
    for channel_index, pointer in enumerate(pointers):
        state_offset = channel_index * AUDIO_STREAM_STATE_SIZE
        writes[AUDIO_STREAM_POINTER_LO + state_offset] = pointer & 0xFF
        writes[AUDIO_STREAM_POINTER_HI + state_offset] = pointer >> 8
        writes[AUDIO_STREAM_TICKS_REMAINING + state_offset] = 1
    writes[AUDIO_PULSE1_PARAMETERS] = record.pulse1_parameters
    writes[AUDIO_PULSE2_PARAMETERS] = record.pulse2_parameters
    return writes


def select_track_set(
    records: tuple[AudioTrackRecord, ...],
    track_set: int,
    demo_playback_active: int,
) -> dict[int, int] | None:
    offset = selector_record_offset(track_set, demo_playback_active)
    if offset is None:
        return None
    if len(records) != TRACK_RECORD_COUNT:
        raise AudioTrackSelectionError(
            f"audio track record count is {len(records)}, expected {TRACK_RECORD_COUNT}"
        )
    return track_record_ram_writes(records[offset // TRACK_RECORD_SIZE])


def _find_opcode_target(prg: bytes, opcode: int, target: int) -> list[int]:
    needle = bytes((opcode, target & 0xFF, target >> 8))
    return [
        PRG_BASE + offset
        for offset in range(len(prg) - len(needle) + 1)
        if prg[offset:offset + len(needle)] == needle
    ]


def validate_rom_contract(prg: bytes) -> dict[str, object]:
    selector_bytes = _slice(prg, SELECTOR_START_CPU, SELECTOR_END_CPU)
    table_bytes = _slice(prg, TRACK_TABLE_CPU, TRACK_TABLE_END_CPU)
    if hashlib.sha256(selector_bytes).hexdigest() != SELECTOR_SHA256:
        raise AudioTrackSelectionError("audio selector bytes changed")
    if hashlib.sha256(table_bytes).hexdigest() != TRACK_TABLE_SHA256:
        raise AudioTrackSelectionError("audio track table bytes changed")

    records = parse_track_records(prg)
    record_values = tuple(
        (
            record.pulse1_pointer,
            record.pulse2_pointer,
            record.triangle_pointer,
            record.pulse1_parameters,
            record.pulse2_parameters,
        )
        for record in records
    )
    if record_values != EXPECTED_RECORD_VALUES:
        raise AudioTrackSelectionError("audio track records changed")

    pointers = [
        pointer
        for record in records
        for pointer in (
            record.pulse1_pointer,
            record.pulse2_pointer,
            record.triangle_pointer,
        )
    ]
    nonzero_pointers = [pointer for pointer in pointers if pointer]
    invalid_pointers = sorted(set(nonzero_pointers) - MML_STREAM_STARTS)
    if invalid_pointers:
        values = ", ".join(f"${pointer:04X}" for pointer in invalid_pointers)
        raise AudioTrackSelectionError(f"track table has invalid MML pointers: {values}")
    if len(nonzero_pointers) != 23:
        raise AudioTrackSelectionError("audio track table no longer has 23 valid pointers")

    for source, (opcode, target) in EXPECTED_CALL_SITES.items():
        expected = bytes((opcode, target & 0xFF, target >> 8))
        if _slice(prg, source, source + 3) != expected:
            raise AudioTrackSelectionError(f"audio selector call at ${source:04X} changed")
    for track_set, target in SELECTOR_ENTRYPOINTS.items():
        expected_jsr = sorted(
            source
            for source, (opcode, expected_target) in EXPECTED_CALL_SITES.items()
            if opcode == 0x20 and expected_target == target
        )
        expected_jmp = sorted(
            source
            for source, (opcode, expected_target) in EXPECTED_CALL_SITES.items()
            if opcode == 0x4C and expected_target == target
        )
        if _find_opcode_target(prg, 0x20, target) != expected_jsr:
            raise AudioTrackSelectionError(f"track set {track_set} JSR sites changed")
        if _find_opcode_target(prg, 0x4C, target) != expected_jmp:
            raise AudioTrackSelectionError(f"track set {track_set} JMP sites changed")

    return {
        "selector_range": [SELECTOR_START_CPU, SELECTOR_END_CPU - 1],
        "selector_bytes": len(selector_bytes),
        "table_range": [TRACK_TABLE_CPU, TRACK_TABLE_END_CPU - 1],
        "track_records": len(records),
        "pointer_slots": len(pointers),
        "valid_nonzero_pointers": len(nonzero_pointers),
        "distinct_referenced_streams": len(set(nonzero_pointers)),
        "selector_entrypoints": SELECTOR_ENTRYPOINTS,
        "call_sites": len(EXPECTED_CALL_SITES),
    }


def validate_exhaustive_contract(
    records: tuple[AudioTrackRecord, ...],
) -> dict[str, int]:
    cases = 0
    loaded = 0
    suppressed = 0
    for demo_playback_active in range(0x100):
        for track_set, record_offset in SELECTOR_RECORD_OFFSETS.items():
            writes = select_track_set(records, track_set, demo_playback_active)
            should_load = track_set == 5 or demo_playback_active == 0
            if (writes is not None) != should_load:
                raise AudioTrackSelectionError("demo audio gate mismatch")
            if writes is not None:
                expected = track_record_ram_writes(
                    records[record_offset // TRACK_RECORD_SIZE]
                )
                if writes != expected or len(writes) != 11:
                    raise AudioTrackSelectionError("audio track RAM copy mismatch")
                loaded += 1
            else:
                suppressed += 1
            cases += 1
    return {
        "demo_gate_cases": cases,
        "loaded_cases": loaded,
        "suppressed_cases": suppressed,
        "record_copies": len(records),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()
    try:
        prg = extract_prg(args.image.read_bytes())
        records = parse_track_records(prg)
        report = validate_rom_contract(prg)
        report["exhaustive"] = validate_exhaustive_contract(records)
    except (OSError, AudioTrackSelectionError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        print(
            "[OK] validated seven audio selectors, eight track records, "
            "24 pointer slots, and 1,792 demo-gate cases"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

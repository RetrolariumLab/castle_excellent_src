#!/usr/bin/env python3
"""Model Castle Excellent's music stream engine at $B906-$BB15."""

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
ENGINE_START_CPU = 0xB906
ENGINE_END_CPU = 0xBB16
ORPHAN_DATA_START_CPU = 0xBADE
ORPHAN_DATA_END_CPU = 0xBAE9
NOTE_SEMITONE_TABLE_CPU = 0xBB16
NOTE_LENGTH_TABLE_CPU = 0xBB1D
APU_PERIOD_TABLE_CPU = 0xBB55
MML_END_CPU = 0xC20D

APU_STATUS = 0x4015
APU_PULSE1_VOLUME = 0x4000
APU_PULSE1_SWEEP = 0x4001
APU_PULSE1_PERIOD_LOW = 0x4002
APU_TRIANGLE_LINEAR = 0x4008

AUDIO_STREAM_POINTER_LO = 0xDB
AUDIO_STREAM_POINTER_HI = 0xDC
AUDIO_STREAM_TICKS_REMAINING = 0xDD
AUDIO_STREAM_STATE_SIZE = 4
SOUND_EFFECT_REQUEST_ADDRESSES = (0xEC, 0xEF, 0xF2, 0xF5)
CHANNEL_OFFSETS = (0, 4, 8)
CHANNEL_GATE_MASKS = {0: 0x0E, 4: 0x0D, 8: 0x0B}

NOTE_OFFSETS = {
    ord("a"): 9,
    ord("b"): 11,
    ord("c"): 0,
    ord("d"): 2,
    ord("e"): 4,
    ord("f"): 5,
    ord("g"): 7,
}
DEFAULT_LENGTH_INDICES = {
    ord("@"): 0,
    ord("8"): 1,
    ord("4"): 2,
    ord("2"): 3,
    ord("1"): 4,
}
MML_STREAM_STARTS = (
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
)

RANGE_HASHES = (
    (
        0xB906,
        0xBADE,
        "187d5a14426bb03dbc1bcc501ebb0d4f0debed9b852b339465e7006dbdf4b8a1",
        "stream engine",
    ),
    (
        0xBADE,
        0xBAE9,
        "8d6456ed3ac8fcec18f00a3f93d80f0867101c28fe73ed3083ae58cf7ea9fd8f",
        "orphan decode bytes",
    ),
    (
        0xBAE9,
        0xBB16,
        "d08b749d3beb56153b9c3505d2ae40d90894f1bf371ae0c7376e91a6786eb6b6",
        "channel configuration",
    ),
    (
        ENGINE_START_CPU,
        ENGINE_END_CPU,
        "60e2279093db19132ad340e0d731b5870421f6d75cab64eccee5d0a48a1c032a",
        "complete audio stream engine",
    ),
)

EXPECTED_CALL_SITES = {
    0xB906: (0x8268, 0xA38F, 0xFB59, 0xFE55, 0xFEA9),
    0xB918: (0x826B, 0xA392, 0xFB5C, 0xFE58, 0xFEAC),
    0xB923: (0xC6A1, 0xEA5F, 0xEB68, 0xF941, 0xFE6E, 0xFECA),
}


class AudioStreamEngineError(ValueError):
    pass


@dataclass(frozen=True)
class AudioStreamState:
    pointer: int
    ticks_remaining: int
    octave_offset: int
    default_length_index: int


@dataclass(frozen=True)
class AudioTickResult:
    ticks_remaining: int
    apu_status_write: int | None
    parse_event: bool


@dataclass(frozen=True)
class AudioEventResult:
    state: AudioStreamState
    tempo_offset: int
    apu_writes: dict[int, int]
    event: str | None
    period_table_index: int | None
    ended: bool
    restart_address: int | None
    commands_consumed: int


def _validate_byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise AudioStreamEngineError(f"{name} outside 0-255: {value}")


def _validate_pointer(pointer: int) -> None:
    if not 0 <= pointer <= 0xFFFF:
        raise AudioStreamEngineError(f"pointer outside 0-65535: {pointer}")


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise AudioStreamEngineError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    start = 16 + trainer_size
    end = start + prg_size
    if prg_size != PRG_SIZE or end > len(image):
        raise AudioStreamEngineError("expected a complete 32 KiB PRG region")
    return image[start:end]


def _slice(prg: bytes, start: int, end: int) -> bytes:
    return prg[start - PRG_BASE:end - PRG_BASE]


def _read_prg_byte(prg: bytes, address: int) -> int:
    if len(prg) != PRG_SIZE:
        raise AudioStreamEngineError("expected a 32 KiB PRG region")
    if not PRG_BASE <= address < PRG_BASE + PRG_SIZE:
        raise AudioStreamEngineError(f"stream read outside PRG: ${address:04X}")
    return prg[address - PRG_BASE]


def stop_audio_stream_writes() -> dict[int, int]:
    writes = {APU_STATUS: 0}
    for offset in CHANNEL_OFFSETS:
        writes[AUDIO_STREAM_POINTER_LO + offset] = 0
        writes[AUDIO_STREAM_POINTER_HI + offset] = 0
    return writes


def clear_sound_effect_request_writes() -> dict[int, int]:
    return {address: 0 for address in SOUND_EFFECT_REQUEST_ADDRESSES}


def read_channel_sound_request(
    x: int,
    *,
    pulse1: int,
    pulse2: int,
    triangle: int,
) -> int:
    for value, name in (
        (x, "X register"),
        (pulse1, "pulse 1 request"),
        (pulse2, "pulse 2 request"),
        (triangle, "triangle request"),
    ):
        _validate_byte(value, name)
    return {0: pulse1, 4: pulse2, 8: triangle}.get(x, 0xFF)


def advance_audio_stream(pointer: int) -> int:
    _validate_pointer(pointer)
    return (pointer + 1) & 0xFFFF


def configure_audio_channel(
    x: int,
    *,
    pulse1_parameters: int,
    pulse2_parameters: int,
) -> dict[int, int]:
    for value, name in (
        (x, "X register"),
        (pulse1_parameters, "pulse 1 parameters"),
        (pulse2_parameters, "pulse 2 parameters"),
    ):
        _validate_byte(value, name)
    writes = {APU_STATUS: 0x0F}
    if x == 0:
        writes[APU_PULSE1_VOLUME] = pulse1_parameters
        writes[APU_PULSE1_SWEEP] = 0x08
    elif x == 4:
        writes[APU_PULSE1_VOLUME + x] = pulse2_parameters
        writes[APU_PULSE1_SWEEP + x] = 0x08
    elif x == 8:
        writes[APU_TRIANGLE_LINEAR] = 0xFF
    return writes


def tick_audio_stream(
    *, pointer: int, ticks_remaining: int, x: int, sound_effect_request: int
) -> AudioTickResult:
    _validate_pointer(pointer)
    for value, name in (
        (ticks_remaining, "ticks remaining"),
        (x, "X register"),
        (sound_effect_request, "sound-effect request"),
    ):
        _validate_byte(value, name)
    if pointer == 0:
        return AudioTickResult(ticks_remaining, None, False)
    ticks = (ticks_remaining - 1) & 0xFF
    if ticks == 0:
        return AudioTickResult(ticks, None, True)
    gate = None
    if ticks == 3 and sound_effect_request == 0:
        gate = CHANNEL_GATE_MASKS.get(x, 0)
    return AudioTickResult(ticks, gate, False)


def _length_table_value(prg: bytes, tempo_offset: int, length_index: int) -> int:
    index = (tempo_offset + length_index) & 0xFF
    return _read_prg_byte(prg, NOTE_LENGTH_TABLE_CPU + index)


def _event_period_index(prg: bytes, note: int, octave_offset: int, x: int) -> int:
    semitone = _read_prg_byte(prg, NOTE_SEMITONE_TABLE_CPU + note - ord("a"))
    index = (semitone + octave_offset) & 0xFF
    return ((index + 1) << 1) & 0xFF


def decode_next_audio_event(
    prg: bytes,
    state: AudioStreamState,
    *,
    tempo_offset: int,
    x: int,
    sound_effect_request: int,
    pulse1_parameters: int = 0,
    pulse2_parameters: int = 0,
    follow_restart: bool = True,
) -> AudioEventResult:
    for value, name in (
        (state.ticks_remaining, "ticks remaining"),
        (state.octave_offset, "octave offset"),
        (state.default_length_index, "default length index"),
        (tempo_offset, "tempo offset"),
        (x, "X register"),
        (sound_effect_request, "sound-effect request"),
        (pulse1_parameters, "pulse 1 parameters"),
        (pulse2_parameters, "pulse 2 parameters"),
    ):
        _validate_byte(value, name)
    _validate_pointer(state.pointer)
    if x not in CHANNEL_OFFSETS:
        raise AudioStreamEngineError(f"unsupported audio channel offset: {x}")
    if state.pointer < PRG_BASE:
        raise AudioStreamEngineError("active audio stream pointer is outside PRG")

    pointer = state.pointer
    octave_offset = state.octave_offset
    default_length_index = state.default_length_index
    commands_consumed = 0
    visited_restarts: set[int] = set()
    while True:
        command = _read_prg_byte(prg, pointer)
        if command == 0:
            low_address = advance_audio_stream(pointer)
            low = _read_prg_byte(prg, low_address)
            high_address = advance_audio_stream(low_address)
            high = _read_prg_byte(prg, high_address)
            restart_address = low | high << 8
            if restart_address == 0 or not follow_restart:
                next_pointer = 0 if restart_address == 0 else restart_address
                return AudioEventResult(
                    AudioStreamState(
                        next_pointer,
                        state.ticks_remaining,
                        octave_offset,
                        default_length_index,
                    ),
                    tempo_offset,
                    {},
                    None,
                    None,
                    True,
                    restart_address or None,
                    commands_consumed,
                )
            if restart_address in visited_restarts:
                raise AudioStreamEngineError("audio stream restart loop has no event")
            visited_restarts.add(restart_address)
            pointer = restart_address
            continue

        pointer = advance_audio_stream(pointer)
        if command == ord("o"):
            argument = _read_prg_byte(prg, pointer)
            pointer = advance_audio_stream(pointer)
            octave_offset = ((argument - 0x32) * 12) & 0xFF
            commands_consumed += 1
            continue
        if command == ord("t"):
            argument = _read_prg_byte(prg, pointer)
            pointer = advance_audio_stream(pointer)
            tempo_offset = ((argument - ord("0")) * 8) & 0xFF
            commands_consumed += 1
            continue
        if command == ord("l"):
            argument = _read_prg_byte(prg, pointer)
            pointer = advance_audio_stream(pointer)
            default_length_index = DEFAULT_LENGTH_INDICES.get(argument, 4)
            commands_consumed += 1
            continue
        if command == ord("v"):
            pointer = advance_audio_stream(pointer)
            commands_consumed += 1
            continue

        event = "rest"
        period_index = 0
        if command in NOTE_OFFSETS:
            event = "note"
            period_index = _event_period_index(prg, command, octave_offset, x)
            accidental = _read_prg_byte(prg, pointer)
            if accidental == ord("+"):
                period_index = (period_index + 2) & 0xFF
                pointer = advance_audio_stream(pointer)
            elif accidental == ord("-"):
                period_index = (period_index - 2) & 0xFF
                pointer = advance_audio_stream(pointer)
            if x == 8:
                period_index = (period_index + 0x18) & 0xFF
        elif command != ord("r"):
            raise AudioStreamEngineError(
                f"unsupported stream command ${command:02X} at ${pointer - 1:04X}"
            )

        writes: dict[int, int] = {}
        if sound_effect_request == 0:
            writes.update(
                configure_audio_channel(
                    x,
                    pulse1_parameters=pulse1_parameters,
                    pulse2_parameters=pulse2_parameters,
                )
            )
            writes[APU_PULSE1_PERIOD_LOW + x] = _read_prg_byte(
                prg, APU_PERIOD_TABLE_CPU + period_index
            )
            writes[APU_PULSE1_PERIOD_LOW + x + 1] = _read_prg_byte(
                prg, APU_PERIOD_TABLE_CPU + period_index + 1
            )

        length_index = default_length_index
        duration_command = _read_prg_byte(prg, pointer)
        if duration_command == ord("@") or ord("0") <= duration_command < ord(":"):
            length_index = DEFAULT_LENGTH_INDICES.get(
                duration_command, (tempo_offset + default_length_index) & 0xFF
            )
            pointer = advance_audio_stream(pointer)
            if duration_command not in DEFAULT_LENGTH_INDICES:
                ticks = _read_prg_byte(
                    prg, NOTE_LENGTH_TABLE_CPU + length_index
                )
            else:
                ticks = _length_table_value(prg, tempo_offset, length_index)
        else:
            ticks = _length_table_value(prg, tempo_offset, length_index)
        if _read_prg_byte(prg, pointer) == ord("."):
            ticks = (ticks + (ticks >> 1)) & 0xFF
            pointer = advance_audio_stream(pointer)

        return AudioEventResult(
            AudioStreamState(pointer, ticks, octave_offset, default_length_index),
            tempo_offset,
            writes,
            event,
            period_index,
            False,
            None,
            commands_consumed,
        )


def walk_music_stream(prg: bytes, address: int, *, x: int = 0) -> dict[str, int]:
    state = AudioStreamState(address, 1, 0, 0)
    tempo_offset = 0
    counts: Counter[str] = Counter()
    character_count = 0
    while True:
        start = state.pointer
        result = decode_next_audio_event(
            prg,
            state,
            tempo_offset=tempo_offset,
            x=x,
            sound_effect_request=1,
            follow_restart=False,
        )
        counts["commands"] += result.commands_consumed
        if result.ended:
            character_count += result.commands_consumed * 2
            break
        assert result.event is not None
        counts[result.event] += 1
        character_count += result.state.pointer - start
        state = result.state
        tempo_offset = result.tempo_offset
    counts["characters"] = character_count
    return dict(counts)


def _find_opcode_target(prg: bytes, opcode: int, target: int) -> list[int]:
    needle = bytes((opcode, target & 0xFF, target >> 8))
    return [
        PRG_BASE + offset
        for offset in range(len(prg) - len(needle) + 1)
        if prg[offset:offset + len(needle)] == needle
    ]


def validate_music_streams(prg: bytes) -> dict[str, int]:
    totals: Counter[str] = Counter()
    for address in MML_STREAM_STARTS:
        totals.update(walk_music_stream(prg, address))
    if totals["note"] != 772 or totals["rest"] != 29:
        raise AudioStreamEngineError("music stream event counts changed")
    if totals["characters"] != 1_511:
        raise AudioStreamEngineError("music stream character count changed")
    return {
        "streams": len(MML_STREAM_STARTS),
        "characters": totals["characters"],
        "events": totals["note"] + totals["rest"],
        "notes": totals["note"],
        "rests": totals["rest"],
    }


def validate_rom_contract(prg: bytes) -> dict[str, object]:
    if len(prg) != PRG_SIZE:
        raise AudioStreamEngineError("expected a 32 KiB PRG region")
    for start, end, expected_hash, name in RANGE_HASHES:
        if hashlib.sha256(_slice(prg, start, end)).hexdigest() != expected_hash:
            raise AudioStreamEngineError(f"{name} bytes changed")
    for target, sources in EXPECTED_CALL_SITES.items():
        for source in sources:
            expected = bytes((0x20, target & 0xFF, target >> 8))
            if _slice(prg, source, source + 3) != expected:
                raise AudioStreamEngineError(f"JSR at ${source:04X} changed")
        if _find_opcode_target(prg, 0x20, target) != list(sources):
            raise AudioStreamEngineError(f"call topology for ${target:04X} changed")
        if _find_opcode_target(prg, 0x4C, target):
            raise AudioStreamEngineError(f"unexpected JMP to ${target:04X}")
    for target in range(ORPHAN_DATA_START_CPU, ORPHAN_DATA_END_CPU):
        if _find_opcode_target(prg, 0x20, target) or _find_opcode_target(
            prg, 0x4C, target
        ):
            raise AudioStreamEngineError(f"control flow enters orphan data ${target:04X}")
    streams = validate_music_streams(prg)
    return {
        "range": [ENGINE_START_CPU, ENGINE_END_CPU - 1],
        "bytes": ENGINE_END_CPU - ENGINE_START_CPU,
        "code_bytes": ENGINE_END_CPU - ENGINE_START_CPU - (
            ORPHAN_DATA_END_CPU - ORPHAN_DATA_START_CPU
        ),
        "orphan_data_bytes": ORPHAN_DATA_END_CPU - ORPHAN_DATA_START_CPU,
        "call_sites": sum(len(sources) for sources in EXPECTED_CALL_SITES.values()),
        "music_streams": streams,
    }


def validate_exhaustive_contract() -> dict[str, int]:
    pointer_cases = 0
    for x in CHANNEL_OFFSETS:
        for pointer in range(0x10000):
            if advance_audio_stream(pointer) != (pointer + 1) & 0xFFFF:
                raise AudioStreamEngineError(f"pointer advance mismatch for X=${x:02X}")
            pointer_cases += 1

    request_cases = 0
    for x in range(0x100):
        observed = read_channel_sound_request(
            x, pulse1=0x11, pulse2=0x22, triangle=0x33
        )
        expected = {0: 0x11, 4: 0x22, 8: 0x33}.get(x, 0xFF)
        if observed != expected:
            raise AudioStreamEngineError("sound-effect request routing mismatch")
        request_cases += 1

    configure_cases = 0
    for x in range(0x100):
        writes = configure_audio_channel(
            x, pulse1_parameters=0xA1, pulse2_parameters=0xB2
        )
        if writes.get(APU_STATUS) != 0x0F:
            raise AudioStreamEngineError("channel configuration omitted APU status")
        expected_size = 3 if x in (0, 4) else 2 if x == 8 else 1
        if len(writes) != expected_size:
            raise AudioStreamEngineError("channel configuration write set mismatch")
        configure_cases += 1

    gate_cases = 0
    for x in CHANNEL_OFFSETS:
        for ticks in range(0x100):
            for request in (0, 1):
                result = tick_audio_stream(
                    pointer=0xBBE7,
                    ticks_remaining=ticks,
                    x=x,
                    sound_effect_request=request,
                )
                expected_ticks = (ticks - 1) & 0xFF
                expected_gate = (
                    CHANNEL_GATE_MASKS[x]
                    if expected_ticks == 3 and request == 0
                    else None
                )
                if (
                    result.ticks_remaining != expected_ticks
                    or result.apu_status_write != expected_gate
                    or result.parse_event != (expected_ticks == 0)
                ):
                    raise AudioStreamEngineError("audio tick/gate mismatch")
                gate_cases += 1
    return {
        "pointer_cases": pointer_cases,
        "request_cases": request_cases,
        "configure_cases": configure_cases,
        "gate_cases": gate_cases,
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
    except (OSError, AudioStreamEngineError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        print(
            "[OK] validated 528 audio-engine bytes, 16 callers, "
            "21 music streams, and 198,656 exhaustive cases"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

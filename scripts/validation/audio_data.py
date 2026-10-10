#!/usr/bin/env python3
"""Validate and describe Castle Excellent's textual music data."""

from __future__ import annotations

import argparse
from collections import Counter
from dataclasses import dataclass
import json
from pathlib import Path
import sys

from scripts.validation.room_data import extract_rom


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
TRACK_TABLE_CPU = 0xB8C6
TRACK_RECORD_SIZE = 8
TRACK_RECORD_COUNT = 8
MML_START_CPU = 0xBBE7
MML_END_CPU = 0xC20D
LENGTH_BYTES = frozenset(b"@1248")
NOTE_BYTES = frozenset(b"abcdefg")
COMMAND_BYTES = frozenset(b"oltv")


class AudioDataError(ValueError):
    pass


@dataclass(frozen=True)
class MusicStream:
    address: int
    text: str
    end_address: int
    restart_address: int
    token_counts: dict[str, int]

    @property
    def next_address(self) -> int:
        return self.end_address + 3

    def as_dict(self, referenced: bool) -> dict[str, object]:
        return {
            "address": f"0x{self.address:04X}",
            "end_address": f"0x{self.end_address:04X}",
            "restart_address": (
                f"0x{self.restart_address:04X}" if self.restart_address else None
            ),
            "referenced_by_track_table": referenced,
            "text": self.text,
            "token_counts": self.token_counts,
        }


def cpu_offset(address: int) -> int:
    if not PRG_BASE <= address < PRG_BASE + PRG_SIZE:
        raise AudioDataError(f"CPU address outside fixed PRG: ${address:04X}")
    return address - PRG_BASE


def parse_track_table(prg: bytes) -> list[dict[str, object]]:
    if len(prg) != PRG_SIZE:
        raise AudioDataError(f"PRG size is {len(prg)}, expected {PRG_SIZE}")
    records: list[dict[str, object]] = []
    for index in range(TRACK_RECORD_COUNT):
        address = TRACK_TABLE_CPU + index * TRACK_RECORD_SIZE
        offset = cpu_offset(address)
        record = prg[offset:offset + TRACK_RECORD_SIZE]
        pointers = [int.from_bytes(record[pos:pos + 2], "little") for pos in (0, 2, 4)]
        for pointer in pointers:
            if pointer and not MML_START_CPU <= pointer < MML_END_CPU:
                raise AudioDataError(
                    f"track set {index} points outside MML data: ${pointer:04X}"
                )
        records.append(
            {
                "index": index,
                "address": f"0x{address:04X}",
                "streams": [f"0x{pointer:04X}" if pointer else None for pointer in pointers],
                "channel_parameters": [record[6], record[7]],
            }
        )
    return records


def _need_argument(data: bytes, cursor: int, command: str, address: int) -> int:
    if cursor >= len(data) or data[cursor] == 0:
        raise AudioDataError(f"missing {command!r} argument in stream ${address:04X}")
    return data[cursor]


def validate_mml_text(data: bytes, address: int) -> dict[str, int]:
    """Follow the byte consumption performed by UpdateAudioStream at $B92F."""
    cursor = 0
    counts: Counter[str] = Counter()
    while cursor < len(data):
        value = data[cursor]
        cursor += 1
        if value in COMMAND_BYTES:
            command = chr(value)
            argument = _need_argument(data, cursor, command, address)
            cursor += 1
            if command in "ot" and argument not in range(ord("0"), ord("9") + 1):
                raise AudioDataError(
                    f"invalid {command!r} argument ${argument:02X} in stream ${address:04X}"
                )
            if command == "l" and argument not in LENGTH_BYTES:
                raise AudioDataError(
                    f"invalid default length {chr(argument)!r} in stream ${address:04X}"
                )
            if command == "v" and argument not in b"0123456789abcdef":
                raise AudioDataError(
                    f"invalid volume argument ${argument:02X} in stream ${address:04X}"
                )
            counts[command] += 1
            continue
        if value not in NOTE_BYTES and value != ord("r"):
            raise AudioDataError(
                f"invalid MML byte ${value:02X} at ${address + cursor - 1:04X}"
            )
        token = "rest" if value == ord("r") else "note"
        if value in NOTE_BYTES and cursor < len(data) and data[cursor] in b"+-":
            cursor += 1
            counts["accidental"] += 1
        if cursor < len(data) and data[cursor] in LENGTH_BYTES:
            cursor += 1
            counts["explicit_length"] += 1
        if cursor < len(data) and data[cursor] == ord("."):
            cursor += 1
            counts["dotted"] += 1
        counts[token] += 1
    return dict(sorted(counts.items()))


def parse_stream(prg: bytes, address: int) -> MusicStream:
    if not MML_START_CPU <= address < MML_END_CPU:
        raise AudioDataError(f"stream address outside MML data: ${address:04X}")
    start = cpu_offset(address)
    limit = cpu_offset(MML_END_CPU)
    try:
        end = prg.index(0, start, limit)
    except ValueError as exc:
        raise AudioDataError(f"unterminated MML stream at ${address:04X}") from exc
    if end + 2 >= limit:
        raise AudioDataError(f"truncated restart pointer after stream ${address:04X}")
    text_bytes = prg[start:end]
    try:
        text = text_bytes.decode("ascii")
    except UnicodeDecodeError as exc:
        raise AudioDataError(f"non-ASCII byte in stream ${address:04X}") from exc
    end_address = PRG_BASE + end
    return MusicStream(
        address=address,
        text=text,
        end_address=end_address,
        restart_address=prg[end + 1] | (prg[end + 2] << 8),
        token_counts=validate_mml_text(text_bytes, address),
    )


def analyze_audio(prg: bytes) -> dict[str, object]:
    records = parse_track_table(prg)
    referenced = {
        int(pointer, 0)
        for record in records
        for pointer in record["streams"]
        if pointer is not None
    }
    streams: list[MusicStream] = []
    cursor = MML_START_CPU
    while cursor < MML_END_CPU:
        stream = parse_stream(prg, cursor)
        streams.append(stream)
        cursor = stream.next_address
    if cursor != MML_END_CPU:
        raise AudioDataError(
            f"MML streams end at ${cursor:04X}, expected ${MML_END_CPU:04X}"
        )
    starts = {stream.address for stream in streams}
    unknown_pointers = referenced - starts
    if unknown_pointers:
        values = ", ".join(f"${value:04X}" for value in sorted(unknown_pointers))
        raise AudioDataError(f"track table points into stream bodies: {values}")
    for stream in streams:
        if stream.restart_address not in starts | {0}:
            raise AudioDataError(
                f"stream ${stream.address:04X} has invalid restart "
                f"${stream.restart_address:04X}"
            )
    character_count = sum(len(stream.text) for stream in streams)
    return {
        "track_table_address": f"0x{TRACK_TABLE_CPU:04X}",
        "track_sets": records,
        "mml_range": f"0x{MML_START_CPU:04X}-0x{MML_END_CPU - 1:04X}",
        "stream_count": len(streams),
        "referenced_stream_count": len(referenced),
        "unreferenced_streams": [
            f"0x{stream.address:04X}" for stream in streams if stream.address not in referenced
        ],
        "character_count": character_count,
        "streams": [stream.as_dict(stream.address in referenced) for stream in streams],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", required=True, help="Castle Excellent iNES image")
    parser.add_argument("--pretty", action="store_true")
    parser.add_argument(
        "--validate",
        action="store_true",
        help="validate the complete table and stream region and print a summary",
    )
    args = parser.parse_args()
    try:
        prg, _chr_data = extract_rom(Path(args.image).read_bytes())
        result = analyze_audio(prg)
    except (OSError, AudioDataError, ValueError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        print(
            "[OK] validated "
            f"{len(result['track_sets'])} track sets, {result['stream_count']} MML streams, "
            f"and {result['character_count']} command bytes"
        )
        return 0
    print(json.dumps(result, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

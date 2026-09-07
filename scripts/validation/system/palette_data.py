#!/usr/bin/env python3
"""Validate the four named PPU palette views in the Castle Excellent PRG."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
PALETTE_BYTES = 0x20
SCREEN_STORAGE_CPU = 0xC4FD
SCREEN_STORAGE_BYTES = 0x40
ROOM_PALETTE_CPU = 0xC53D
UPLOADER_CPU = 0xC4CD
UPLOADER_END_CPU = 0xC4FD
UPLOADER_SHA256 = "f623ae2577bcbffc5e2bbbd62e240564b83cbb8c306aa76798821c96035cddbb"
SCREEN_STORAGE_SHA256 = "79ded8385e088ef56c76a458a12cf3dd2be6f38fcbb3c60c7f93666d3e6f45e0"
ROOM_PALETTE_SHA256 = "1411bac58795c387e09f306e09e18d0919d888e17e2a2686e98f7435598d2907"
PALETTE_VIEWS = {
    "completion": (0xC4FD, "d30a3f01b8ffd480789430caa93823489ba339b8b449be5d8f6d8be9db5ad255"),
    "title": (0xC50D, "d25bc66bbd1c9f32198de00802b0a68ebe9f3a81ae304364c8252401bf83aa91"),
    "castle_map": (0xC51D, "451b105bb6abd644e1e09121e4c6bb98251135352ef77c6ba233e5029a3a4a65"),
}
POINTER_CALLS = {
    "completion": (0xFE96, bytes.fromhex("A9 C4 85 22 A9 FD 85 21 20 CD C4")),
    "title": (0xF901, bytes.fromhex("A9 C5 85 22 A9 0D 85 21 20 CD C4")),
    "castle_map": (0xEA8B, bytes.fromhex("A9 C5 85 22 A9 1D 85 21 20 CD C4")),
}


class PaletteDataError(ValueError):
    pass


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise PaletteDataError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    start = 16 + trainer_size
    end = start + prg_size
    if prg_size != PRG_SIZE or end > len(image):
        raise PaletteDataError("expected a complete 32 KiB PRG region")
    return image[start:end]


def _slice(prg: bytes, start: int, end: int) -> bytes:
    return prg[start - PRG_BASE:end - PRG_BASE]


def palette_view(prg: bytes, name: str) -> bytes:
    try:
        address, _ = PALETTE_VIEWS[name]
    except KeyError as exc:
        raise PaletteDataError(f"unknown palette view: {name}") from exc
    return _slice(prg, address, address + PALETTE_BYTES)


def find_opcode_target(prg: bytes, opcode: int, target: int) -> list[int]:
    needle = bytes((opcode, target & 0xFF, target >> 8))
    return [
        PRG_BASE + offset
        for offset in range(len(prg) - len(needle) + 1)
        if prg[offset:offset + len(needle)] == needle
    ]


def validate_contract(prg: bytes) -> dict[str, object]:
    screen_storage = _slice(
        prg, SCREEN_STORAGE_CPU, SCREEN_STORAGE_CPU + SCREEN_STORAGE_BYTES
    )
    room_palette = _slice(prg, ROOM_PALETTE_CPU, ROOM_PALETTE_CPU + PALETTE_BYTES)
    uploader = _slice(prg, UPLOADER_CPU, UPLOADER_END_CPU)
    expected_hashes = (
        (screen_storage, SCREEN_STORAGE_SHA256, "shared screen palette storage"),
        (room_palette, ROOM_PALETTE_SHA256, "room palette"),
        (uploader, UPLOADER_SHA256, "palette uploader"),
    )
    for data, expected, name in expected_hashes:
        if hashlib.sha256(data).hexdigest() != expected:
            raise PaletteDataError(f"{name} bytes changed")

    views = {name: palette_view(prg, name) for name in PALETTE_VIEWS}
    for name, data in views.items():
        expected = PALETTE_VIEWS[name][1]
        if hashlib.sha256(data).hexdigest() != expected:
            raise PaletteDataError(f"{name} palette bytes changed")
    if views["completion"][16:] != views["title"][:16]:
        raise PaletteDataError("completion/title palette overlap changed")
    if views["title"][16:] != views["castle_map"][:16]:
        raise PaletteDataError("title/castle-map palette overlap changed")

    for name, (address, expected) in POINTER_CALLS.items():
        actual = _slice(prg, address, address + len(expected))
        if actual != expected:
            raise PaletteDataError(f"{name} palette pointer/call sequence changed")
    jsr_calls = find_opcode_target(prg, 0x20, UPLOADER_CPU)
    jmp_calls = find_opcode_target(prg, 0x4C, UPLOADER_CPU)
    if jsr_calls != [0xEA93, 0xF909, 0xFE9E] or jmp_calls != [0xA359]:
        raise PaletteDataError("palette uploader call sites changed")
    if bytes.fromhex("A0 00") not in uploader or bytes.fromhex("C0 20 90") not in uploader:
        raise PaletteDataError("palette uploader no longer iterates exactly 32 bytes")

    return {
        "screen_storage": [SCREEN_STORAGE_CPU, SCREEN_STORAGE_CPU + SCREEN_STORAGE_BYTES - 1],
        "screen_storage_bytes": len(screen_storage),
        "palette_bytes": PALETTE_BYTES,
        "views": {name: address for name, (address, _) in PALETTE_VIEWS.items()},
        "room_palette": ROOM_PALETTE_CPU,
        "uploader_calls": {"jsr": jsr_calls, "jmp": jmp_calls},
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()
    try:
        report = validate_contract(extract_prg(args.image.read_bytes()))
    except (OSError, PaletteDataError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        print(
            "[OK] validated three overlapping screen palettes, the room palette, "
            "and four uploader call sites"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

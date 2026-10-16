#!/usr/bin/env python3
"""Write a relocated copy of the source: one $EA byte at the start of PRG and
one more after every module that src/system/famicom_platform.asm includes, so
each module moves one byte further than the one before. The padding before
the fixed tile tables (src/system/prg_tail.asm, $48 bytes in the original)
absorbs them, so the tail tables and the vectors stay put. The bytes are never
executed; a build that still plays the attract mode shows that nothing
depends on the original addresses."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import re

INCLUDE_RE = re.compile(r'^(?P<indent>\s*)\.include "(?P<path>[^"]+)"(?P<tail>.*)$')
EA_DIRECTIVE = "    .byte $EA"
PLATFORM = "system/famicom_platform.asm"
ORIGIN = "PrgStart:"
TAIL = "../system/prg_tail.asm"


class RelocationError(ValueError):
    """The source does not have the shape the relocation expects."""


def include_path(path: Path, including: Path) -> str:
    """ca65 opens an include relative to the including file."""
    return Path(os.path.relpath(path.resolve(), including.resolve().parent)).as_posix()


def relocate(main_source: Path, output: Path) -> int:
    """Write the relocated main source and its platform module next to output;
    return the number of bytes inserted."""
    source_root = main_source.resolve().parent
    output.parent.mkdir(parents=True, exist_ok=True)
    platform_source = source_root / PLATFORM
    platform_copy = output.parent / Path(PLATFORM).name
    inserted = 0
    lines: list[str] = []
    for line in platform_source.read_text(encoding="utf-8").splitlines():
        match = INCLUDE_RE.fullmatch(line)
        if match is None:
            lines.append(line)
            if line.strip() == ORIGIN:
                lines.append(EA_DIRECTIVE)
                inserted += 1
            continue
        target = (platform_source.parent / match.group("path")).resolve()
        lines.append(f'{match.group("indent")}.include "{include_path(target, platform_copy)}"{match.group("tail")}')
        if match.group("path") != TAIL:
            lines.append(EA_DIRECTIVE)
            inserted += 1
    if inserted < 2:
        raise RelocationError(f"{PLATFORM} has no {ORIGIN} or no modules")
    platform_copy.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")

    main_lines: list[str] = []
    for line in main_source.read_text(encoding="utf-8").splitlines():
        match = INCLUDE_RE.fullmatch(line)
        if match is None:
            main_lines.append(line)
            continue
        target = platform_copy if match.group("path") == PLATFORM else source_root / match.group("path")
        main_lines.append(f'{match.group("indent")}.include "{include_path(target, output)}"{match.group("tail")}')
    output.write_text("\n".join(main_lines) + "\n", encoding="utf-8", newline="\n")
    return inserted


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument("--main", type=Path, required=True, help="src/main.asm")
    parser.add_argument("--output", type=Path, required=True, help="the relocated main source")
    args = parser.parse_args()
    try:
        count = relocate(args.main, args.output)
    except (OSError, RelocationError) as exc:
        print(f"[ERROR] {exc}")
        return 1
    print(f"[OK] Relocated source: modules moved by 1 to {count} bytes.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

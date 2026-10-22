#!/usr/bin/env python3
"""Write a relocated copy of a revision's source: one $EA byte at PrgStart and
one more after every PRG module src/main.asm includes, so each module moves
one byte further than the one before. The padding before the fixed tile
tables (src/system/prg_tail.asm, $48 bytes in the original) absorbs them, so
the tail tables and the vectors stay put. The bytes are never executed; the
attract mode playing on such a build shows the moved code does not depend on
its original addresses (as far as that mode runs it)."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import re

INCLUDE_RE = re.compile(r'^(?P<indent>\s*)\.include "(?P<path>[^"]+)"(?P<tail>.*)$')
EA_DIRECTIVE = "    .byte $EA"
ORIGIN = "PrgStart:"
FIRST = "system/famicom_platform.asm"
TAIL = "system/prg_tail.asm"
AFTER_TAIL = "graphics/chr.asm"


class RelocationError(ValueError):
    """The source does not have the shape the relocation expects."""


def include_path(path: Path, including: Path) -> str:
    """ca65 opens an include relative to the including file (or by its full
    path when the two are on different drives)."""
    try:
        return Path(os.path.relpath(path.resolve(), including.resolve().parent)).as_posix()
    except ValueError:
        return path.resolve().as_posix()


def relocated_main(main_source: Path, output: Path) -> tuple[list[str], int]:
    """The lines of the relocated main and the bytes they insert. The modules
    are the includes from the platform module to the tail; only the CHR may
    follow the tail."""
    lines = main_source.read_text(encoding="utf-8").splitlines()
    includes = [(i, m.group("path")) for i, line in enumerate(lines) if (m := INCLUDE_RE.fullmatch(line))]
    paths = [path for _, path in includes]
    if lines.count(ORIGIN) != 1:
        raise RelocationError(f"{main_source.name} must have one {ORIGIN}")
    for required in (FIRST, TAIL, AFTER_TAIL):
        if paths.count(required) != 1:
            raise RelocationError(f"{main_source.name} must include {required} once")
    first, tail = paths.index(FIRST), paths.index(TAIL)
    if not lines.index(ORIGIN) < includes[first][0] < includes[tail][0] or paths[tail + 1 :] != [AFTER_TAIL]:
        raise RelocationError(f"{main_source.name} must have {ORIGIN}, then {FIRST} ... {TAIL}, then {AFTER_TAIL}")
    moved = {index for index, _ in includes[first:tail]}
    result, inserted = [], 0
    for index, line in enumerate(lines):
        match = INCLUDE_RE.fullmatch(line)
        if match is None:
            result.append(line)
        else:
            target = main_source.resolve().parent / match.group("path")
            result.append(f'{match.group("indent")}.include "{include_path(target, output)}"{match.group("tail")}')
        if line == ORIGIN or index in moved:
            result.append(EA_DIRECTIVE)
            inserted += 1
    return result, inserted


def relocate(entry: Path, output_dir: Path) -> int:
    """Write output_dir/<entry's name> (including the relocated main) and
    output_dir/main.asm; return the number of bytes inserted."""
    main_source = entry.resolve().parent.parent / "main.asm"
    if not main_source.is_file():
        raise RelocationError(f"{entry} is not in src/revisions/ beside src/main.asm")
    output_dir.mkdir(parents=True, exist_ok=True)
    main_output = output_dir / "main.asm"
    lines, inserted = relocated_main(main_source, main_output)
    main_output.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
    entry_lines = []
    for line in entry.read_text(encoding="utf-8").splitlines():
        match = INCLUDE_RE.fullmatch(line)
        if match is not None:
            target = (entry.resolve().parent / match.group("path")).resolve()
            target = main_output if target == main_source.resolve() else target
            line = f'{match.group("indent")}.include "{include_path(target, output_dir / entry.name)}"{match.group("tail")}'
        entry_lines.append(line)
    (output_dir / entry.name).write_text("\n".join(entry_lines) + "\n", encoding="utf-8", newline="\n")
    return inserted


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument("--entry", type=Path, required=True, help="a revision's src/revisions/<id>.asm")
    parser.add_argument("--output-dir", type=Path, required=True, help="where the relocated sources go")
    args = parser.parse_args()
    try:
        count = relocate(args.entry, args.output_dir)
    except (OSError, RelocationError) as exc:
        print(f"[ERROR] {exc}")
        return 1
    print(f"[OK] Relocated source: modules moved by 1 to {count} bytes.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Command-line surface for deterministic ca65 source generation."""

from __future__ import annotations

import argparse
import sys

from scripts.workflow import generate_disassembly


def add_common(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--prg", required=True)
    parser.add_argument("--facts", required=True)
    parser.add_argument("--symbols", required=True)
    parser.add_argument("--memory-symbols", required=True)
    parser.add_argument("--operand-overrides", required=True)
    parser.add_argument("--output")
    parser.add_argument("--layout")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    write = subparsers.add_parser("write")
    add_common(write)
    write.set_defaults(handler=generate_disassembly.command_write)
    check = subparsers.add_parser("check")
    add_common(check)
    check.set_defaults(handler=generate_disassembly.command_check)
    args = parser.parse_args()
    try:
        args.handler(args)
    except (generate_disassembly.DisassemblyError, OSError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

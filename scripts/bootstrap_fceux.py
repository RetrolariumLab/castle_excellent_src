#!/usr/bin/env python3
"""Install and verify the exact local FCEUX runtime used for CDL capture."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import sys


ROOT = Path(__file__).resolve().parent.parent
LOCK_PATH = ROOT / "tools" / "runtime.lock.json"
INSTALL = ROOT / "tools" / "fceux"


class BootstrapError(ValueError):
    pass


def sha256_file(path: Path) -> str:
    checksum = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            checksum.update(block)
    return checksum.hexdigest()


def load_entry() -> dict[str, object]:
    try:
        document = json.loads(LOCK_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise BootstrapError(f"cannot read {LOCK_PATH}: {exc}") from exc
    if document.get("schema_version") != 1:
        raise BootstrapError("unsupported runtime lock schema")
    entry = document.get("fceux")
    if not isinstance(entry, dict) or not isinstance(entry.get("files"), list):
        raise BootstrapError("runtime lock has no fceux files")
    return entry


def verify_file(path: Path, specification: dict[str, object]) -> None:
    if not path.is_file():
        raise BootstrapError(f"runtime file not found: {path}")
    expected_size = int(specification["size"])
    if path.stat().st_size != expected_size:
        raise BootstrapError(
            f"{path.name} size is {path.stat().st_size}, expected {expected_size}"
        )
    actual = sha256_file(path)
    expected = str(specification["sha256"]).lower()
    if actual != expected:
        raise BootstrapError(f"{path.name} SHA-256 is {actual}, expected {expected}")


def specifications(entry: dict[str, object]) -> list[dict[str, object]]:
    files = entry["files"]
    assert isinstance(files, list)
    result: list[dict[str, object]] = []
    for item in files:
        if not isinstance(item, dict):
            raise BootstrapError("runtime file entry is not an object")
        for field in ("source", "install", "size", "sha256"):
            if field not in item:
                raise BootstrapError(f"runtime file entry has no {field}")
        result.append(item)
    return result


def command_install(args: argparse.Namespace) -> None:
    entry = load_entry()
    default_source = ROOT / str(entry["source_directory"])
    source_root = (args.source_dir or default_source).resolve()
    specs = specifications(entry)
    for specification in specs:
        source = source_root / str(specification["source"])
        verify_file(source, specification)
        print(f"[OK] source artifact {source}")
    INSTALL.mkdir(parents=True, exist_ok=True)
    for specification in specs:
        source = source_root / str(specification["source"])
        destination = INSTALL / str(specification["install"])
        shutil.copy2(source, destination)
        verify_file(destination, specification)
        print(f"[INSTALL] {destination}")
    command_status(args)


def command_status(_args: argparse.Namespace) -> None:
    entry = load_entry()
    for specification in specifications(entry):
        path = INSTALL / str(specification["install"])
        verify_file(path, specification)
        print(f"[OK] {path} ({specification['sha256']})")
    print(f"[OK] pinned FCEUX source revision {entry['commit']}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    install = subparsers.add_parser("install")
    install.add_argument("--source-dir", type=Path)
    install.set_defaults(handler=command_install)
    status = subparsers.add_parser("status")
    status.set_defaults(handler=command_status)
    args = parser.parse_args()
    try:
        args.handler(args)
    except (BootstrapError, KeyError, OSError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

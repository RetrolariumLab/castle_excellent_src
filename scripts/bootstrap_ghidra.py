#!/usr/bin/env python3
"""Download, verify, and install the pinned local Ghidra toolchain."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import sys
import urllib.request
import zipfile


ROOT = Path(__file__).resolve().parent.parent
TOOLS = ROOT / "tools"
LOCK_PATH = TOOLS / "disassembly.lock.json"
CACHE = TOOLS / ".cache"
INSTALL = TOOLS / "ghidra"


class BootstrapError(ValueError):
    pass


def load_lock() -> dict[str, object]:
    try:
        lock = json.loads(LOCK_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise BootstrapError(f"cannot read {LOCK_PATH}: {exc}") from exc
    if lock.get("schema_version") != 1:
        raise BootstrapError("unsupported disassembly lock schema")
    return lock


def sha256_file(path: Path) -> str:
    checksum = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            checksum.update(block)
    return checksum.hexdigest()


def checked_entry(lock: dict[str, object], key: str) -> dict[str, object]:
    entry = lock.get(key)
    if not isinstance(entry, dict):
        raise BootstrapError(f"lock has no {key} object")
    for field in ("archive", "url", "size", "sha256"):
        if field not in entry:
            raise BootstrapError(f"{key} has no {field}")
    return entry


def verify_archive(path: Path, entry: dict[str, object]) -> None:
    expected_size = int(entry["size"])
    if not path.is_file():
        raise BootstrapError(f"archive not found: {path}")
    if path.stat().st_size != expected_size:
        raise BootstrapError(
            f"{path.name} size is {path.stat().st_size}, expected {expected_size}"
        )
    actual = sha256_file(path)
    expected = str(entry["sha256"]).lower()
    if actual != expected:
        raise BootstrapError(
            f"{path.name} SHA-256 is {actual}, expected {expected}"
        )


def download(entry: dict[str, object]) -> Path:
    CACHE.mkdir(parents=True, exist_ok=True)
    destination = CACHE / str(entry["archive"])
    if destination.is_file():
        try:
            verify_archive(destination, entry)
            print(f"[OK] cached {destination.name}")
            return destination
        except BootstrapError:
            destination.unlink()
    temporary = destination.with_suffix(destination.suffix + ".part")
    request = urllib.request.Request(
        str(entry["url"]), headers={"User-Agent": "castle-excellent-disassembly"}
    )
    print(f"[DOWNLOAD] {entry['url']}")
    try:
        with urllib.request.urlopen(request) as response, temporary.open("wb") as output:
            shutil.copyfileobj(response, output, length=1024 * 1024)
    except Exception:
        temporary.unlink(missing_ok=True)
        raise
    os.replace(temporary, destination)
    verify_archive(destination, entry)
    print(f"[OK] SHA-256 {entry['sha256']}")
    return destination


def install_ghidra(archive: Path, entry: dict[str, object]) -> None:
    expected_directory = str(entry.get("install_directory", ""))
    marker = INSTALL / "Ghidra" / "application.properties"
    if marker.is_file():
        print(f"[OK] Ghidra already installed at {INSTALL}")
        return
    temporary = TOOLS / ".install-ghidra"
    if temporary.exists():
        shutil.rmtree(temporary)
    temporary.mkdir(parents=True)
    print(f"[EXTRACT] {archive.name}")
    with zipfile.ZipFile(archive) as bundle:
        bundle.extractall(temporary)
    source = temporary / expected_directory
    if not source.is_dir():
        roots = [item for item in temporary.iterdir() if item.is_dir()]
        if len(roots) != 1:
            raise BootstrapError("cannot identify Ghidra archive root")
        source = roots[0]
    if INSTALL.exists():
        shutil.rmtree(INSTALL)
    source.replace(INSTALL)
    shutil.rmtree(temporary)
    if not marker.is_file():
        raise BootstrapError("Ghidra installation marker is missing after extraction")
    print(f"[OK] installed Ghidra at {INSTALL}")


def install_loader(archive: Path) -> None:
    extensions = INSTALL / "Ghidra" / "Extensions"
    marker = extensions / "GhidraNes" / "extension.properties"
    if marker.is_file():
        print(f"[OK] GhidraNes already installed at {marker.parent}")
        return
    extensions.mkdir(parents=True, exist_ok=True)
    temporary = TOOLS / ".install-ghidranes"
    if temporary.exists():
        shutil.rmtree(temporary)
    temporary.mkdir(parents=True)
    print(f"[EXTRACT] {archive.name}")
    with zipfile.ZipFile(archive) as bundle:
        bundle.extractall(temporary)
    candidates = list(temporary.rglob("extension.properties"))
    if len(candidates) != 1:
        raise BootstrapError(
            f"expected one GhidraNes extension root, found {len(candidates)}"
        )
    source = candidates[0].parent
    destination = extensions / "GhidraNes"
    if destination.exists():
        shutil.rmtree(destination)
    shutil.move(str(source), destination)
    shutil.rmtree(temporary)
    print(f"[OK] installed GhidraNes at {destination}")


def status(lock: dict[str, object]) -> None:
    for key in ("ghidra", "nes_loader"):
        entry = checked_entry(lock, key)
        archive = CACHE / str(entry["archive"])
        verify_archive(archive, entry)
        print(f"[OK] {key} archive: {archive}")
    headless = INSTALL / "support" / "analyzeHeadless.bat"
    loader = INSTALL / "Ghidra" / "Extensions" / "GhidraNes" / "extension.properties"
    for path in (headless, loader):
        if not path.is_file():
            raise BootstrapError(f"installed component not found: {path}")
        print(f"[OK] {path}")


def command_install(_args: argparse.Namespace) -> None:
    lock = load_lock()
    ghidra_entry = checked_entry(lock, "ghidra")
    loader_entry = checked_entry(lock, "nes_loader")
    ghidra_archive = download(ghidra_entry)
    loader_archive = download(loader_entry)
    install_ghidra(ghidra_archive, ghidra_entry)
    install_loader(loader_archive)
    status(lock)


def command_status(_args: argparse.Namespace) -> None:
    status(load_lock())


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    install = subparsers.add_parser("install")
    install.set_defaults(handler=command_install)
    check = subparsers.add_parser("status")
    check.set_defaults(handler=command_status)
    args = parser.parse_args()
    try:
        args.handler(args)
    except (BootstrapError, OSError, urllib.error.URLError, zipfile.BadZipFile) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

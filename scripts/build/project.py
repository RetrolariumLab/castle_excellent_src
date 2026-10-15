#!/usr/bin/env python3
"""Build-support commands for the Castle Excellent source reconstruction."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import shutil
import sys
import zlib

from scripts.build import atomic_io


ROOT = Path(__file__).resolve().parents[2]


class ProjectError(ValueError):
    """A validation error that should be shown without a traceback."""


PRG_DATA_KINDS = {"data", "padding", "table", "text", "vectors"}


def digest(data: bytes, algorithm: str = "sha1") -> str:
    return hashlib.new(algorithm, data).hexdigest()


def crc32(data: bytes) -> str:
    return f"{zlib.crc32(data) & 0xFFFFFFFF:08x}"


def parse_number(value: object, field: str) -> int:
    if isinstance(value, int):
        return value
    if isinstance(value, str):
        try:
            return int(value, 0)
        except ValueError:
            pass
    raise ProjectError(f"invalid integer for {field}: {value!r}")


def load_manifest(path: Path) -> dict[str, object]:
    try:
        manifest = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ProjectError(f"cannot read manifest {path}: {exc}") from exc
    if manifest.get("schema_version") != 1:
        raise ProjectError("unsupported manifest schema")
    return manifest


def parse_ines(data: bytes) -> dict[str, object]:
    if len(data) < 16 or data[:4] != b"NES\x1a":
        raise ProjectError("image is not an iNES ROM")
    trainer_size = 512 if data[6] & 0x04 else 0
    prg_size = data[4] * 16_384
    chr_size = data[5] * 8_192
    prg_start = 16 + trainer_size
    chr_start = prg_start + prg_size
    expected_size = chr_start + chr_size
    if len(data) != expected_size:
        raise ProjectError(
            f"image size is {len(data)}, expected exactly {expected_size}"
        )
    return {
        "header": data[:prg_start],
        "prg": data[prg_start:chr_start],
        "chr": data[chr_start:],
        "payload": data[prg_start:],
        "trainer_size": trainer_size,
        "prg_size": prg_size,
        "chr_size": chr_size,
        "mapper": (data[6] >> 4) | (data[7] & 0xF0),
        "mirroring": "vertical" if data[6] & 0x01 else "horizontal",
    }


def image_facts(data: bytes) -> tuple[dict[str, object], dict[str, object]]:
    parsed = parse_ines(data)
    facts: dict[str, object] = {
        "file_size": len(data),
        "file_sha1": digest(data),
        "file_md5": digest(data, "md5"),
        "file_crc32": crc32(data),
        "payload_sha1": digest(parsed["payload"]),
        "payload_crc32": crc32(parsed["payload"]),
        "header_size": len(parsed["header"]),
        "header_sha1": digest(parsed["header"]),
        "header_crc32": crc32(parsed["header"]),
        "prg_size": parsed["prg_size"],
        "prg_sha1": digest(parsed["prg"]),
        "prg_crc32": crc32(parsed["prg"]),
        "chr_size": parsed["chr_size"],
        "chr_sha1": digest(parsed["chr"]),
        "chr_crc32": crc32(parsed["chr"]),
        "trainer_size": parsed["trainer_size"],
        "mapper": parsed["mapper"],
        "mirroring": parsed["mirroring"],
    }
    return parsed, facts


def validate_image(data: bytes, manifest: dict[str, object]) -> dict[str, object]:
    reference = manifest.get("reference_rom")
    if not isinstance(reference, dict):
        raise ProjectError("manifest has no reference_rom object")
    parsed, facts = image_facts(data)
    for field, expected in reference.items():
        if field not in facts:
            continue
        actual = facts[field]
        if isinstance(actual, int):
            expected = parse_number(expected, field)
        elif isinstance(expected, str):
            expected = expected.lower()
        if actual != expected:
            raise ProjectError(
                f"{field} mismatch: got {actual!r}, expected {expected!r}"
            )
    return parsed


def safe_asset_path(root: Path, relative: str) -> Path:
    posix = PurePosixPath(relative)
    if posix.is_absolute() or not posix.parts or ".." in posix.parts:
        raise ProjectError(f"unsafe asset path: {relative!r}")
    destination = root.joinpath(*posix.parts)
    try:
        destination.resolve().relative_to(root.resolve())
    except ValueError as exc:
        raise ProjectError(f"asset path escapes output directory: {relative!r}") from exc
    return destination


def write_if_changed(path: Path, data: bytes) -> str:
    if path.is_file() and path.read_bytes() == data:
        return "OK"
    atomic_io.atomic_write_bytes(path, data)
    return "WRITE"


def validate_asset(payload: bytes, entry: dict[str, object]) -> None:
    label = str(entry.get("region", entry.get("path", "asset")))
    expected_size = parse_number(entry.get("size"), f"{label}.size")
    if len(payload) != expected_size:
        raise ProjectError(
            f"{label} size mismatch: got {len(payload)}, expected {expected_size}"
        )
    for algorithm in ("sha1", "crc32"):
        expected = entry.get(algorithm)
        if expected is None:
            continue
        actual = digest(payload) if algorithm == "sha1" else crc32(payload)
        if actual != str(expected).lower():
            raise ProjectError(
                f"{label} {algorithm} mismatch: got {actual}, expected {expected}"
            )


def manifest_assets(manifest: dict[str, object]) -> list[dict[str, object]]:
    assets = manifest.get("extracted_assets")
    if not isinstance(assets, list):
        raise ProjectError("manifest has no extracted_assets list")
    if not all(isinstance(entry, dict) for entry in assets):
        raise ProjectError("invalid asset entry")
    return assets


def command_verify(args: argparse.Namespace) -> None:
    image = Path(args.image)
    if not image.is_file():
        raise ProjectError(f"image not found: {image}")
    manifest = load_manifest(Path(args.manifest))
    validate_image(image.read_bytes(), manifest)
    print(f"[OK] byte-identical Castle Excellent image: {image}")


def command_inspect(args: argparse.Namespace) -> None:
    image = Path(args.image)
    if not image.is_file():
        raise ProjectError(f"image not found: {image}")
    _parsed, facts = image_facts(image.read_bytes())
    print(json.dumps(facts, indent=2))


def command_split(args: argparse.Namespace) -> None:
    image = Path(args.image)
    if not image.is_file():
        raise ProjectError(f"reference ROM not found: {image}")
    manifest = load_manifest(Path(args.manifest))
    parsed = validate_image(image.read_bytes(), manifest)
    output_root = Path(args.output_dir)
    for entry in manifest_assets(manifest):
        region = str(entry.get("region", ""))
        if region not in ("header", "prg", "chr"):
            raise ProjectError(f"unsupported asset region: {region!r}")
        payload = parsed[region]
        validate_asset(payload, entry)
        destination = safe_asset_path(output_root, str(entry.get("path", "")))
        action = write_if_changed(destination, payload)
        print(f"[{action}] {destination} ({len(payload)} bytes)")


def command_check_assets(args: argparse.Namespace) -> None:
    manifest = load_manifest(Path(args.manifest))
    root = Path(args.asset_dir)
    for entry in manifest_assets(manifest):
        path = safe_asset_path(root, str(entry.get("path", "")))
        if not path.is_file():
            raise ProjectError(f"required generated asset not found: {path}; run make split")
        validate_asset(path.read_bytes(), entry)
        print(f"[OK] {path}")


def command_mkdir(args: argparse.Namespace) -> None:
    Path(args.path).mkdir(parents=True, exist_ok=True)


def command_require(args: argparse.Namespace) -> None:
    path = Path(args.path)
    if not path.is_file():
        raise ProjectError(f"required generated asset not found: {path}; {args.hint}")


def command_clean(args: argparse.Namespace) -> None:
    target = Path(args.path).resolve()
    build_root = (ROOT / "build").resolve()
    if target != build_root and build_root not in target.parents:
        raise ProjectError(f"refusing to clean outside {build_root}: {target}")
    if target.exists():
        shutil.rmtree(target)
        print(f"[CLEAN] {target}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    verify = subparsers.add_parser("verify", help="verify a complete built image")
    verify.add_argument("--image", required=True)
    verify.add_argument("--manifest", required=True)
    verify.set_defaults(handler=command_verify)

    inspect = subparsers.add_parser("inspect", help="print complete iNES hashes")
    inspect.add_argument("--image", required=True)
    inspect.set_defaults(handler=command_inspect)

    split = subparsers.add_parser("split", help="validate and split a reference ROM")
    split.add_argument("--image", required=True)
    split.add_argument("--manifest", required=True)
    split.add_argument("--output-dir", required=True)
    split.set_defaults(handler=command_split)

    check_assets = subparsers.add_parser("check-assets", help="validate private assets")
    check_assets.add_argument("--manifest", required=True)
    check_assets.add_argument("--asset-dir", required=True)
    check_assets.set_defaults(handler=command_check_assets)

    mkdir = subparsers.add_parser("mkdir", help="create a build directory")
    mkdir.add_argument("--path", required=True)
    mkdir.set_defaults(handler=command_mkdir)

    require = subparsers.add_parser("require", help="require a generated asset")
    require.add_argument("--path", required=True)
    require.add_argument("--hint", required=True)
    require.set_defaults(handler=command_require)

    clean = subparsers.add_parser("clean", help="remove a path below build/")
    clean.add_argument("--path", required=True)
    clean.set_defaults(handler=command_clean)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    try:
        args.handler(args)
    except (OSError, ProjectError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

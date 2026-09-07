#!/usr/bin/env python3
"""Build and verify manifest-owned fixed-layout Castle Excellent variants."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
from typing import Any

from scripts.build.project import ProjectError, safe_asset_path, write_if_changed


ROOT = Path(__file__).resolve().parents[2]


class FixedLayoutError(ValueError):
    """A fixed-layout manifest, patch, or runtime observation is invalid."""


def project_path(value: str) -> Path:
    try:
        return safe_asset_path(ROOT, value)
    except ProjectError as exc:
        raise FixedLayoutError(str(exc)) from exc


def integer(value: object, name: str) -> int:
    if isinstance(value, int):
        return value
    if isinstance(value, str):
        try:
            return int(value, 0)
        except ValueError:
            pass
    raise FixedLayoutError(f"invalid {name}: {value!r}")


def hex_bytes(value: object, name: str) -> bytes:
    if not isinstance(value, str):
        raise FixedLayoutError(f"invalid {name}")
    try:
        payload = bytes.fromhex(value)
    except ValueError as exc:
        raise FixedLayoutError(f"invalid {name}: {value!r}") from exc
    if not payload:
        raise FixedLayoutError(f"empty {name}")
    return payload


def load_variant(path: Path, variant_id: str) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise FixedLayoutError(f"cannot read fixed-layout manifest: {exc}") from exc
    if document.get("schema_version") != 1 or not isinstance(
        document.get("variants"), list
    ):
        raise FixedLayoutError("unsupported fixed-layout manifest")
    matches = [entry for entry in document["variants"] if entry.get("id") == variant_id]
    if len(matches) != 1:
        raise FixedLayoutError(f"unknown or duplicate fixed-layout variant: {variant_id}")
    return matches[0]


def file_region(image: bytes, region: str) -> tuple[int, int]:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise FixedLayoutError("base image is not iNES")
    trainer = 512 if image[6] & 4 else 0
    prg_start = 16 + trainer
    prg_size = image[4] * 16_384
    chr_start = prg_start + prg_size
    chr_size = image[5] * 8_192
    regions = {
        "header": (0, 16 + trainer),
        "prg": (prg_start, prg_start + prg_size),
        "chr": (chr_start, chr_start + chr_size),
    }
    if region not in regions:
        raise FixedLayoutError(f"unsupported fixed-layout region: {region!r}")
    start, end = regions[region]
    if end > len(image):
        raise FixedLayoutError(f"truncated {region} region")
    return start, end


def apply_variant(image: bytes, variant: dict[str, Any]) -> bytes:
    expected_base = variant.get("base_sha256")
    actual_base = hashlib.sha256(image).hexdigest()
    if actual_base != expected_base:
        raise FixedLayoutError(
            f"base SHA-256 mismatch: got {actual_base}, expected {expected_base}"
        )
    changes = variant.get("changes")
    if not isinstance(changes, list) or not changes:
        raise FixedLayoutError("fixed-layout variant has no changes")
    output = bytearray(image)
    owned_offsets: set[int] = set()
    for change in changes:
        if not isinstance(change, dict):
            raise FixedLayoutError("invalid fixed-layout change")
        region = str(change.get("region", ""))
        region_start, region_end = file_region(image, region)
        offset = integer(change.get("offset"), "change offset")
        original = hex_bytes(change.get("original_hex"), "original bytes")
        replacement = hex_bytes(change.get("replacement_hex"), "replacement bytes")
        if len(original) != len(replacement):
            raise FixedLayoutError("fixed-layout replacement changes region length")
        start = region_start + offset
        end = start + len(original)
        if start < region_start or end > region_end:
            raise FixedLayoutError("fixed-layout change exceeds its region")
        if region == "prg" and integer(change.get("cpu_address"), "CPU address") != 0x8000 + offset:
            raise FixedLayoutError("PRG offset and CPU address disagree")
        indexes = set(range(start, end))
        if indexes & owned_offsets:
            raise FixedLayoutError("fixed-layout changes overlap")
        owned_offsets.update(indexes)
        if image[start:end] != original:
            raise FixedLayoutError(
                f"original bytes disagree at file offset ${start:04X}"
            )
        output[start:end] = replacement
    changed = {
        index for index, (before, after) in enumerate(zip(image, output)) if before != after
    }
    expected_changed = {
        index
        for change in changes
        for index in range(
            file_region(image, str(change["region"]))[0]
            + integer(change["offset"], "change offset"),
            file_region(image, str(change["region"]))[0]
            + integer(change["offset"], "change offset")
            + len(hex_bytes(change["original_hex"], "original bytes")),
        )
        if image[index] != output[index]
    }
    if changed != expected_changed:
        raise FixedLayoutError("changed-byte set exceeds the manifest allowlist")
    result = bytes(output)
    for algorithm in ("sha1", "sha256"):
        expected = variant.get(f"output_{algorithm}")
        actual = hashlib.new(algorithm, result).hexdigest()
        if actual != expected:
            raise FixedLayoutError(
                f"output {algorithm} mismatch: got {actual}, expected {expected}"
            )
    return result


def build_variant(variant: dict[str, Any]) -> Path:
    base = project_path(str(variant["base_rom"]))
    if not base.is_file():
        raise FixedLayoutError(f"base image not found: {base}")
    output = project_path(str(variant["output_rom"]))
    action = write_if_changed(output, apply_variant(base.read_bytes(), variant))
    print(f"[{action}] fixed-layout variant {variant['id']}: {output}")
    return output


def validate_runtime_result(path: Path, variant: dict[str, Any]) -> None:
    try:
        fields = dict(
            field.split("=", 1)
            for field in path.read_text(encoding="utf-8").strip().split()
        )
    except (OSError, ValueError) as exc:
        raise FixedLayoutError(f"invalid runtime result: {exc}") from exc
    expected = integer(variant["runtime"]["expected"], "runtime expected value")
    if fields.get("status") != "ok" or fields.get("room") != str(expected):
        raise FixedLayoutError(f"fixed-layout runtime observation failed: {fields}")


def run_runtime(args: argparse.Namespace, variant: dict[str, Any], output: Path) -> None:
    for path in (args.fceux, args.lua, output):
        if not path.is_file():
            raise FixedLayoutError(f"required runtime input not found: {path}")
    args.result.parent.mkdir(parents=True, exist_ok=True)
    args.result.unlink(missing_ok=True)
    environment = os.environ.copy()
    environment.update(
        CASTLE_FIXED_LAYOUT_RESULT=str(args.result.resolve()).replace("\\", "/")
    )
    completed = subprocess.run(
        [
            str(args.fceux.resolve()),
            "-lua",
            str(args.lua.resolve()),
            "-max-frames",
            "910",
            "-turbo",
            "1",
            "-nothrottle",
            "1",
            str(output.resolve()),
        ],
        cwd=ROOT,
        env=environment,
        check=False,
    )
    if completed.returncode:
        raise FixedLayoutError(f"FCEUX exited with status {completed.returncode}")
    validate_runtime_result(args.result, variant)
    print(f"[OK] live fixed-layout observation for {variant['id']}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("build", "verify", "runtime"))
    parser.add_argument("--manifest", type=Path, default=Path("config/fixed_layout_variants.json"))
    parser.add_argument("--variant", default="start-room-1")
    parser.add_argument("--fceux", type=Path)
    parser.add_argument("--lua", type=Path)
    parser.add_argument("--result", type=Path)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        variant = load_variant(args.manifest, args.variant)
        output = build_variant(variant)
        if args.command in {"verify", "runtime"}:
            apply_variant(project_path(str(variant["base_rom"])).read_bytes(), variant)
            print(f"[OK] exact changed-byte allowlist for {variant['id']}")
        if args.command == "runtime":
            if args.fceux is None or args.lua is None or args.result is None:
                raise FixedLayoutError("runtime requires --fceux, --lua, and --result")
            run_runtime(args, variant, output)
    except (OSError, KeyError, ProjectError, FixedLayoutError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

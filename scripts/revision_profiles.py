#!/usr/bin/env python3
"""Build and verify declared Castle Excellent cartridge revisions."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys

from project import ProjectError, parse_ines, safe_asset_path, write_if_changed


ROOT = Path(__file__).resolve().parent.parent
REQUIRED_HASH_REGIONS = ("rom", "header", "prg", "chr")


def load_profiles(path: Path) -> dict[str, object]:
    try:
        manifest = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ProjectError(f"cannot read profile manifest {path}: {exc}") from exc
    if manifest.get("schema_version") != 1:
        raise ProjectError("unsupported revision-profile schema")
    profiles = manifest.get("profiles")
    if not isinstance(profiles, list) or not profiles:
        raise ProjectError("revision-profile manifest has no profiles")
    return manifest


def select_profile(manifest: dict[str, object], profile_id: str) -> dict[str, object]:
    profiles = manifest.get("profiles", [])
    matches = [entry for entry in profiles if entry.get("id") == profile_id]
    if len(matches) != 1:
        raise ProjectError(f"unknown or duplicate revision profile: {profile_id}")
    profile = matches[0]
    for field in (
        "reference_rom",
        "entrypoint",
        "linker_config",
        "output_rom",
        "chr_asset",
    ):
        if not isinstance(profile.get(field), str) or not profile[field]:
            raise ProjectError(f"profile {profile_id} has no {field}")
    defines = profile.get("defines")
    if not isinstance(defines, list) or not all(isinstance(item, str) for item in defines):
        raise ProjectError(f"profile {profile_id} has invalid defines")
    return profile


def resolve_project_path(relative: str) -> Path:
    path = safe_asset_path(ROOT, relative)
    return path


def profile_regions(data: bytes) -> dict[str, bytes]:
    parsed = parse_ines(data)
    return {
        "rom": data,
        "header": parsed["header"],
        "prg": parsed["prg"],
        "chr": parsed["chr"],
    }


def validate_reference(data: bytes, profile: dict[str, object]) -> None:
    regions = profile_regions(data)
    expected_sizes = {
        "rom": "rom_size",
        "header": "header_size",
        "prg": "prg_size",
        "chr": "chr_size",
    }
    for region_name in REQUIRED_HASH_REGIONS:
        payload = regions[region_name]
        size_field = expected_sizes[region_name]
        if len(payload) != profile.get(size_field):
            raise ProjectError(
                f"{region_name} size mismatch: got {len(payload)}, "
                f"expected {profile.get(size_field)!r}"
            )
        for algorithm in ("sha1", "sha256"):
            field = f"{region_name}_{algorithm}"
            expected = profile.get(field)
            if not isinstance(expected, str):
                raise ProjectError(f"profile {profile['id']} has no {field}")
            actual = hashlib.new(algorithm, payload).hexdigest()
            if actual != expected.lower():
                raise ProjectError(
                    f"{region_name} {algorithm} mismatch: got {actual}, expected {expected}"
                )


def require_reference(profile: dict[str, object]) -> tuple[Path, bytes]:
    path = resolve_project_path(str(profile["reference_rom"]))
    if not path.is_file():
        raise ProjectError(f"reference ROM not found: {path}")
    data = path.read_bytes()
    validate_reference(data, profile)
    return path, data


def binary_assets(profile: dict[str, object]) -> list[dict[str, object]]:
    entries = profile.get("binary_assets", [])
    if not isinstance(entries, list) or not all(isinstance(item, dict) for item in entries):
        raise ProjectError(f"profile {profile['id']} has invalid binary_assets")
    identifiers = [entry.get("id") for entry in entries]
    if len(set(identifiers)) != len(identifiers):
        raise ProjectError(f"profile {profile['id']} has duplicate binary asset IDs")
    return entries


def asset_payload(
    entry: dict[str, object], regions: dict[str, bytes]
) -> tuple[Path, bytes]:
    asset_id = str(entry.get("id", "binary asset"))
    region_name = str(entry.get("region", ""))
    if region_name not in regions:
        raise ProjectError(f"{asset_id} has unsupported region {region_name!r}")
    offset = entry.get("offset")
    if isinstance(offset, str):
        try:
            offset = int(offset, 0)
        except ValueError as exc:
            raise ProjectError(f"{asset_id} has invalid offset") from exc
    size = entry.get("size")
    if not isinstance(offset, int) or not isinstance(size, int) or offset < 0 or size < 1:
        raise ProjectError(f"{asset_id} has invalid offset or size")
    region = regions[region_name]
    if offset + size > len(region):
        raise ProjectError(f"{asset_id} exceeds its {region_name} region")
    payload = region[offset:offset + size]
    validate_asset_bytes(entry, payload)
    path_value = entry.get("path")
    if not isinstance(path_value, str) or not path_value:
        raise ProjectError(f"{asset_id} has no output path")
    return resolve_project_path(path_value), payload


def validate_asset_bytes(entry: dict[str, object], payload: bytes) -> None:
    asset_id = str(entry.get("id", "binary asset"))
    size = entry.get("size")
    if len(payload) != size:
        raise ProjectError(
            f"{asset_id} size mismatch: got {len(payload)}, expected {size!r}"
        )
    for algorithm in ("sha1", "sha256"):
        expected = entry.get(algorithm)
        if not isinstance(expected, str):
            raise ProjectError(f"{asset_id} has no {algorithm}")
        actual = hashlib.new(algorithm, payload).hexdigest()
        if actual != expected.lower():
            raise ProjectError(
                f"{asset_id} {algorithm} mismatch: got {actual}, expected {expected}"
            )


def command_split(args: argparse.Namespace) -> None:
    profile = select_profile(load_profiles(Path(args.manifest)), args.profile)
    reference_path, data = require_reference(profile)
    chr_data = profile_regions(data)["chr"]
    destination = resolve_project_path(str(profile["chr_asset"]))
    action = write_if_changed(destination, chr_data)
    print(f"[{action}] {destination} ({len(chr_data)} bytes from {reference_path})")
    regions = profile_regions(data)
    for entry in binary_assets(profile):
        destination, payload = asset_payload(entry, regions)
        action = write_if_changed(destination, payload)
        print(f"[{action}] {destination} ({len(payload)} bytes from {reference_path})")


def command_build(args: argparse.Namespace) -> None:
    profile = select_profile(load_profiles(Path(args.manifest)), args.profile)
    chr_asset = resolve_project_path(str(profile["chr_asset"]))
    if not chr_asset.is_file():
        raise ProjectError(
            f"profile CHR asset not found: {chr_asset}; run split-profile first"
        )
    for entry in binary_assets(profile):
        path_value = entry.get("path")
        if not isinstance(path_value, str):
            raise ProjectError(f"profile {profile['id']} has an invalid binary asset path")
        asset_path = resolve_project_path(path_value)
        if not asset_path.is_file():
            raise ProjectError(
                f"profile binary asset not found: {asset_path}; run split-profile first"
            )
        validate_asset_bytes(entry, asset_path.read_bytes())
    output = resolve_project_path(str(profile["output_rom"]))
    output.parent.mkdir(parents=True, exist_ok=True)
    object_path = output.with_suffix(".o")
    ca65_command = [
        args.ca65,
        "--debug-info",
        "-g",
        "-o",
        str(object_path),
        "-l",
        str(output.with_suffix(".lst")),
    ]
    for define in profile["defines"]:
        ca65_command.extend(("-D", define))
    ca65_command.append(str(resolve_project_path(str(profile["entrypoint"]))))
    subprocess.run(ca65_command, cwd=ROOT, check=True)
    subprocess.run(
        [
            args.ld65,
            "-C",
            str(resolve_project_path(str(profile["linker_config"]))),
            "-o",
            str(output),
            str(object_path),
            "-Ln",
            str(output.with_suffix(".lbl")),
            "-m",
            str(output.with_suffix(".map")),
            "--dbgfile",
            str(output.with_suffix(".dbg")),
        ],
        cwd=ROOT,
        check=True,
    )
    print(f"[OK] built profile {profile['id']}: {output}")


def first_difference(left: bytes, right: bytes) -> int | None:
    for offset, (left_byte, right_byte) in enumerate(zip(left, right)):
        if left_byte != right_byte:
            return offset
    if len(left) != len(right):
        return min(len(left), len(right))
    return None


def command_verify(args: argparse.Namespace) -> None:
    profile = select_profile(load_profiles(Path(args.manifest)), args.profile)
    reference_path, reference = require_reference(profile)
    built_path = resolve_project_path(str(profile["output_rom"]))
    if not built_path.is_file():
        raise ProjectError(f"built profile ROM not found: {built_path}")
    built = built_path.read_bytes()
    validate_reference(built, profile)
    difference = first_difference(built, reference)
    if difference is not None:
        raise ProjectError(
            f"built profile differs from {reference_path} at file offset ${difference:04X}"
        )
    print(f"[OK] byte-identical profile {profile['id']}: {built_path}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", default="config/revision_profiles.json")
    parser.add_argument("--profile", required=True)
    subparsers = parser.add_subparsers(dest="command", required=True)

    split = subparsers.add_parser("split", help="extract the profile's private CHR")
    split.set_defaults(handler=command_split)

    build = subparsers.add_parser("build", help="build a declared revision profile")
    build.add_argument("--ca65", default="bin/ca65.exe")
    build.add_argument("--ld65", default="bin/ld65.exe")
    build.set_defaults(handler=command_build)

    verify = subparsers.add_parser("verify", help="verify profile identity byte for byte")
    verify.set_defaults(handler=command_verify)
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    try:
        args.handler(args)
    except (OSError, ProjectError, subprocess.CalledProcessError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

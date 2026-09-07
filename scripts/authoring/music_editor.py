#!/usr/bin/env python3
"""Decode, validate, and rebuild Castle Excellent textual music streams."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import sys
from typing import Any

from scripts.authoring import audio_data
from scripts.authoring import room_data
from scripts.build import revision_profiles
from scripts.build.project import ProjectError, safe_asset_path


ROOT = Path(__file__).resolve().parents[2]


class MusicEditorError(ValueError):
    """Invalid music configuration, workspace, or fixed-layout encoding."""


def load_json(path: Path) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise MusicEditorError(f"cannot read JSON document {path}: {exc}") from exc
    if not isinstance(document, dict):
        raise MusicEditorError(f"expected a JSON object in {path}")
    return document


def project_path(relative: str) -> Path:
    try:
        return safe_asset_path(ROOT, relative)
    except ProjectError as exc:
        raise MusicEditorError(str(exc)) from exc


def parse_number(value: object, field: str) -> int:
    if isinstance(value, int):
        return value
    if isinstance(value, str):
        try:
            return int(value, 0)
        except ValueError:
            pass
    raise MusicEditorError(f"invalid integer for {field}: {value!r}")


def load_authoring(path: Path, profile_id: str) -> tuple[dict[str, Any], dict[str, Any]]:
    document = load_json(path)
    if document.get("schema_version") != 1 or document.get("format") != "castle-excellent-music":
        raise MusicEditorError("unsupported music-authoring manifest")
    expected = {
        "track_table_cpu": audio_data.TRACK_TABLE_CPU,
        "track_record_count": audio_data.TRACK_RECORD_COUNT,
        "track_record_size": audio_data.TRACK_RECORD_SIZE,
        "mml_start_cpu": audio_data.MML_START_CPU,
        "mml_end_cpu": audio_data.MML_END_CPU,
    }
    for field, value in expected.items():
        if parse_number(document.get(field), field) != value:
            raise MusicEditorError(f"{field} disagrees with the reconstructed source")
    profiles = document.get("profiles")
    if not isinstance(profiles, list):
        raise MusicEditorError("music-authoring profiles are missing")
    matches = [entry for entry in profiles if entry.get("id") == profile_id]
    if len(matches) != 1 or matches[0].get("status") != "supported":
        raise MusicEditorError(f"music authoring is not supported for {profile_id}")
    profile = matches[0]
    for field in ("workspace", "output_rom", "report"):
        if not isinstance(profile.get(field), str) or not profile[field]:
            raise MusicEditorError(f"authoring profile {profile_id} has no {field}")
    return document, profile


def load_base_image(
    revisions: Path, profile_id: str
) -> tuple[dict[str, Any], bytes, bytes, bytes]:
    manifest = revision_profiles.load_profiles(revisions)
    profile = revision_profiles.select_profile(manifest, profile_id)
    image_path = project_path(str(profile["output_rom"]))
    if not image_path.is_file():
        raise MusicEditorError(f"built profile image not found: {image_path}")
    image = image_path.read_bytes()
    revision_profiles.validate_reference(image, profile)
    prg, chr_data = room_data.extract_rom(image)
    return profile, image, prg, chr_data


def stream_id(index: int) -> str:
    return f"stream_{index:02d}"


def decode_workspace(profile_id: str, prg: bytes) -> dict[str, Any]:
    analysis = audio_data.analyze_audio(prg)
    streams = analysis["streams"]
    address_to_id = {
        int(stream["address"], 0): stream_id(index)
        for index, stream in enumerate(streams)
    }
    workspace_streams = []
    for index, stream in enumerate(streams):
        restart = stream["restart_address"]
        workspace_streams.append({
            "id": stream_id(index),
            "original_address": stream["address"],
            "text": stream["text"],
            "restart": address_to_id[int(restart, 0)] if restart is not None else None,
        })
    track_sets = []
    for record in analysis["track_sets"]:
        track_sets.append({
            "index": record["index"],
            "streams": [
                address_to_id[int(pointer, 0)] if pointer is not None else None
                for pointer in record["streams"]
            ],
            "channel_parameters": record["channel_parameters"],
        })
    return {
        "schema_version": 1,
        "format": "castle-excellent-music",
        "profile": profile_id,
        "track_sets": track_sets,
        "streams": workspace_streams,
    }


def byte_value(value: object, field: str) -> int:
    if not isinstance(value, int) or not 0 <= value <= 0xFF:
        raise MusicEditorError(f"{field} must be a byte")
    return value


def validate_workspace(document: dict[str, Any], profile_id: str) -> dict[str, Any]:
    expected_header = {
        "schema_version": 1,
        "format": "castle-excellent-music",
        "profile": profile_id,
    }
    for field, value in expected_header.items():
        if document.get(field) != value:
            raise MusicEditorError(f"workspace {field} must be {value!r}")
    raw_streams = document.get("streams")
    if not isinstance(raw_streams, list) or len(raw_streams) != 21:
        raise MusicEditorError("workspace must contain exactly 21 MML streams")
    streams = []
    identifiers = []
    for index, stream in enumerate(raw_streams):
        expected_id = stream_id(index)
        if not isinstance(stream, dict) or stream.get("id") != expected_id:
            raise MusicEditorError(f"music stream {index} must be {expected_id}")
        if set(stream) != {"id", "original_address", "text", "restart"}:
            raise MusicEditorError(f"music stream {expected_id} has invalid fields")
        text = stream["text"]
        if not isinstance(text, str) or "\x00" in text:
            raise MusicEditorError(f"music stream {expected_id} must be NUL-free text")
        try:
            payload = text.encode("ascii")
        except UnicodeEncodeError as exc:
            raise MusicEditorError(f"music stream {expected_id} is not ASCII") from exc
        audio_data.validate_mml_text(payload, audio_data.MML_START_CPU)
        identifiers.append(expected_id)
        streams.append({
            "id": expected_id,
            "original_address": str(stream["original_address"]),
            "text": text,
            "restart": stream["restart"],
        })
    identifier_set = set(identifiers)
    for stream in streams:
        if stream["restart"] is not None and stream["restart"] not in identifier_set:
            raise MusicEditorError(f"{stream['id']} has an unknown restart stream")
    raw_tracks = document.get("track_sets")
    if not isinstance(raw_tracks, list) or len(raw_tracks) != audio_data.TRACK_RECORD_COUNT:
        raise MusicEditorError("workspace must contain exactly eight track sets")
    tracks = []
    for index, track in enumerate(raw_tracks):
        if not isinstance(track, dict) or track.get("index") != index:
            raise MusicEditorError(f"track set {index} has an invalid identity")
        if set(track) != {"index", "streams", "channel_parameters"}:
            raise MusicEditorError(f"track set {index} has invalid fields")
        pointers = track["streams"]
        parameters = track["channel_parameters"]
        if not isinstance(pointers, list) or len(pointers) != 3:
            raise MusicEditorError(f"track set {index} must contain three stream slots")
        if any(pointer is not None and pointer not in identifier_set for pointer in pointers):
            raise MusicEditorError(f"track set {index} references an unknown stream")
        if not isinstance(parameters, list) or len(parameters) != 2:
            raise MusicEditorError(f"track set {index} must contain two channel parameters")
        tracks.append({
            "index": index,
            "streams": list(pointers),
            "channel_parameters": [
                byte_value(value, f"track {index} channel parameter")
                for value in parameters
            ],
        })
    capacity = audio_data.MML_END_CPU - audio_data.MML_START_CPU
    used = sum(len(stream["text"].encode("ascii")) + 3 for stream in streams)
    if used > capacity:
        raise MusicEditorError(f"MML arena needs {used} bytes, capacity is {capacity}")
    return {"streams": streams, "track_sets": tracks, "used": used, "capacity": capacity}


def write_cpu(prg: bytearray, address: int, payload: bytes) -> None:
    start = audio_data.cpu_offset(address)
    end = start + len(payload)
    if end > len(prg):
        raise MusicEditorError(f"write at CPU ${address:04X} exceeds PRG")
    prg[start:end] = payload


def compose_music(
    image: bytes,
    prg: bytes,
    chr_data: bytes,
    validated: dict[str, Any],
) -> tuple[bytes, dict[str, Any]]:
    streams = validated["streams"]
    starts: dict[str, int] = {}
    cursor = audio_data.MML_START_CPU
    for stream in streams:
        starts[stream["id"]] = cursor
        cursor += len(stream["text"].encode("ascii")) + 3
    if cursor > audio_data.MML_END_CPU:
        raise MusicEditorError("MML arena capacity changed during composition")
    arena = bytearray()
    for stream in streams:
        restart = stream["restart"]
        restart_address = starts[restart] if restart is not None else 0
        arena.extend(stream["text"].encode("ascii"))
        arena.append(0)
        arena.extend(restart_address.to_bytes(2, "little"))
    capacity = audio_data.MML_END_CPU - audio_data.MML_START_CPU
    arena.extend(bytes(capacity - len(arena)))

    track_table = bytearray()
    for track in validated["track_sets"]:
        for pointer in track["streams"]:
            address = starts[pointer] if pointer is not None else 0
            track_table.extend(address.to_bytes(2, "little"))
        track_table.extend(track["channel_parameters"])
    if len(track_table) != audio_data.TRACK_RECORD_COUNT * audio_data.TRACK_RECORD_SIZE:
        raise MusicEditorError("track table size changed")

    output_prg = bytearray(prg)
    write_cpu(output_prg, audio_data.TRACK_TABLE_CPU, bytes(track_table))
    write_cpu(output_prg, audio_data.MML_START_CPU, bytes(arena))
    header_size = len(image) - len(prg) - len(chr_data)
    output = image[:header_size] + bytes(output_prg) + chr_data
    report = {
        "schema_version": 1,
        "format": "castle-excellent-music-build",
        "rom_size": len(output),
        "rom_sha256": hashlib.sha256(output).hexdigest(),
        "changed_bytes": sum(left != right for left, right in zip(image, output)),
        "stream_count": len(streams),
        "track_set_count": len(validated["track_sets"]),
        "mml_used_bytes": validated["used"],
        "mml_capacity_bytes": validated["capacity"],
        "mml_free_bytes": validated["capacity"] - validated["used"],
    }
    return output, report


def atomic_write(path: Path, payload: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_bytes(payload)
    os.replace(temporary, path)


def atomic_write_json(path: Path, document: dict[str, Any]) -> None:
    atomic_write(path, (json.dumps(document, indent=2) + "\n").encode("utf-8"))


def run(args: argparse.Namespace) -> None:
    _config, authoring_profile = load_authoring(Path(args.authoring), args.profile)
    _revision, image, prg, chr_data = load_base_image(Path(args.revisions), args.profile)
    workspace_path = project_path(authoring_profile["workspace"])
    if args.command in {"init", "export"}:
        document = decode_workspace(args.profile, prg)
        if args.command == "init" and workspace_path.exists():
            validate_workspace(load_json(workspace_path), args.profile)
            print(f"[OK] existing music workspace: {workspace_path}")
            return
        atomic_write_json(workspace_path, document)
        print(f"[WRITE] {workspace_path} (21 MML streams)")
        return
    if args.command == "roundtrip":
        document = decode_workspace(args.profile, prg)
    else:
        if not workspace_path.is_file():
            raise MusicEditorError(
                f"music workspace not found: {workspace_path}; run init-music first"
            )
        document = load_json(workspace_path)
    validated = validate_workspace(document, args.profile)
    output, report = compose_music(image, prg, chr_data, validated)
    if args.command == "roundtrip":
        if output != image:
            difference = revision_profiles.first_difference(output, image)
            raise MusicEditorError(
                f"zero-edit music round trip differs at file offset ${difference:04X}"
            )
        print("[OK] zero-edit music round trip: 8 track sets, 21 MML streams")
        return
    if args.command == "validate":
        print(
            f"[OK] valid music workspace: {report['mml_used_bytes']}/"
            f"{report['mml_capacity_bytes']} MML bytes, "
            f"{report['changed_bytes']} changed ROM bytes"
        )
        return
    output_path = project_path(authoring_profile["output_rom"])
    report_path = project_path(authoring_profile["report"])
    atomic_write(output_path, output)
    report["profile"] = args.profile
    report["workspace"] = authoring_profile["workspace"]
    atomic_write_json(report_path, report)
    print(f"[WRITE] {output_path}: {report['changed_bytes']} changed bytes")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("init", "export", "validate", "build", "roundtrip"))
    parser.add_argument("--authoring", default="config/authoring/audio.json")
    parser.add_argument("--revisions", default="config/revision_profiles.json")
    parser.add_argument("--profile", required=True)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        run(args)
    except (
        OSError,
        ProjectError,
        MusicEditorError,
        audio_data.AudioDataError,
        room_data.RoomDataError,
    ) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Display model shared by the Castle Excellent Sound Studio and its tests."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import music_editor


class SoundStudioModelError(ValueError):
    """The visual model cannot be derived from the music workspace."""


@dataclass(frozen=True)
class StudioSummary:
    stream_count: int
    track_count: int
    active_track_slots: int
    restart_count: int
    used_bytes: int
    capacity_bytes: int

    @property
    def free_bytes(self) -> int:
        return self.capacity_bytes - self.used_bytes


def parse_byte(text: str, field: str) -> int:
    value = text.strip()
    if value.startswith("$"):
        value = "0x" + value[1:]
    try:
        number = int(value, 0)
    except ValueError as exc:
        raise SoundStudioModelError(f"invalid {field}: {text!r}") from exc
    if not 0 <= number <= 0xFF:
        raise SoundStudioModelError(f"{field} must be between 0 and 255")
    return number


def summarize(document: dict[str, Any], profile_id: str) -> StudioSummary:
    validated = music_editor.validate_workspace(document, profile_id)
    streams = validated["streams"]
    tracks = validated["track_sets"]
    return StudioSummary(
        stream_count=len(streams),
        track_count=len(tracks),
        active_track_slots=sum(
            pointer is not None for track in tracks for pointer in track["streams"]
        ),
        restart_count=sum(stream["restart"] is not None for stream in streams),
        used_bytes=validated["used"],
        capacity_bytes=validated["capacity"],
    )


def stream_label(stream: dict[str, Any]) -> str:
    identifier = stream.get("id")
    text = stream.get("text")
    if not isinstance(identifier, str) or not isinstance(text, str):
        raise SoundStudioModelError("invalid stream display record")
    return f"{identifier}  {len(text.encode('ascii')):4d} bytes"

#!/usr/bin/env python3
"""Display model shared by the Castle Excellent Sound Studio and its tests."""

from __future__ import annotations

from dataclasses import dataclass
import math
from pathlib import Path
import struct
from typing import Any
import wave

import audio_stream_engine
import audio_track_selection
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


NTSC_FRAME_RATE = 60.0988
CPU_FREQUENCY = 1_789_773.0
DEFAULT_SAMPLE_RATE = 44_100
DEFAULT_PREVIEW_FRAMES = 1_202
PREVIEW_GAIN = 1.25
CHANNELS = (("Pulse 1", 0), ("Pulse 2", 4), ("Triangle", 8))
TRACK_NAMES = (
    "Room music",
    "Hazard protection",
    "Death / game over",
    "Invulnerability",
    "Castle completion",
    "Title screen",
    "Unreferenced selector",
    "Type $81 event",
)


@dataclass(frozen=True)
class LaneEvent:
    start_frame: int
    duration_frames: int
    frequency: float
    note: str


@dataclass(frozen=True)
class ChannelLane:
    name: str
    events: tuple[LaneEvent, ...]
    frames: int


def track_label(index: int) -> str:
    if not 0 <= index < len(TRACK_NAMES):
        raise SoundStudioModelError(f"track index outside 0-{len(TRACK_NAMES) - 1}")
    return f"Track {index}: {TRACK_NAMES[index]}"


def _period(prg: bytes, period_index: int) -> int:
    address = audio_stream_engine.APU_PERIOD_TABLE_CPU + period_index
    offset = address - audio_stream_engine.PRG_BASE
    if not 0 <= offset < len(prg) - 1:
        raise SoundStudioModelError("MML note points outside the APU period table")
    return prg[offset] | prg[offset + 1] << 8


def _note_name(frequency: float) -> str:
    if frequency <= 0:
        return "rest"
    midi = round(69 + 12 * math.log2(frequency / 440.0))
    names = ("C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B")
    return f"{names[midi % 12]}{midi // 12 - 1}"


def track_lanes(
    prg: bytes,
    track_index: int,
    *,
    max_frames: int = DEFAULT_PREVIEW_FRAMES,
) -> tuple[ChannelLane, ...]:
    if not 0 <= track_index < audio_track_selection.TRACK_RECORD_COUNT:
        raise SoundStudioModelError("selected track is outside the track table")
    if max_frames <= 0:
        raise SoundStudioModelError("preview frame limit must be positive")
    record = audio_track_selection.parse_track_records(prg)[track_index]
    pointers = (record.pulse1_pointer, record.pulse2_pointer, record.triangle_pointer)
    states = [
        audio_stream_engine.AudioStreamState(pointer, 1, 0, 0)
        for pointer in pointers
    ]
    events: list[list[LaneEvent]] = [[], [], []]
    tempo_offset = 0
    for frame in range(max_frames):
        for lane_index, (_name, channel_offset) in enumerate(CHANNELS):
            state = states[lane_index]
            if state.pointer == 0:
                continue
            tick = audio_stream_engine.tick_audio_stream(
                pointer=state.pointer,
                ticks_remaining=state.ticks_remaining,
                x=channel_offset,
                sound_effect_request=1,
            )
            state = audio_stream_engine.AudioStreamState(
                state.pointer,
                tick.ticks_remaining,
                state.octave_offset,
                state.default_length_index,
            )
            if not tick.parse_event:
                states[lane_index] = state
                continue
            result = audio_stream_engine.decode_next_audio_event(
                prg,
                state,
                tempo_offset=tempo_offset,
                x=channel_offset,
                sound_effect_request=1,
                follow_restart=True,
            )
            tempo_offset = result.tempo_offset
            states[lane_index] = result.state
            if result.ended:
                continue
            duration = max(1, int(result.state.ticks_remaining))
            frequency = 0.0
            if result.event == "note" and result.period_table_index is not None:
                period = _period(prg, result.period_table_index)
                divisor = 32 if channel_offset == 8 else 16
                frequency = CPU_FREQUENCY / (divisor * (period + 1))
            events[lane_index].append(
                LaneEvent(
                    frame,
                    min(duration, max_frames - frame),
                    frequency,
                    _note_name(frequency),
                )
            )
        if not any(state.pointer for state in states):
            break
    return tuple(
        ChannelLane(
            name,
            tuple(events[index]),
            min(
                max_frames,
                max(
                    (
                        event.start_frame + event.duration_frames
                        for event in events[index]
                    ),
                    default=0,
                ),
            ),
        )
        for index, (name, _offset) in enumerate(CHANNELS)
    )


def _pulse_sample(frequency: float, elapsed: float, parameter: int) -> float:
    if frequency <= 0:
        return 0.0
    duties = (0.125, 0.25, 0.5, 0.75)
    duty = duties[(parameter >> 6) & 3]
    return float(parameter & 0x0F) if (elapsed * frequency) % 1.0 < duty else 0.0


def _triangle_sample(frequency: float, elapsed: float) -> float:
    if frequency <= 0:
        return 0.0
    phase = (elapsed * frequency) % 1.0
    return abs(phase * 4.0 - 2.0) * 7.5


def _apu_mix(pulse1: float, pulse2: float, triangle: float) -> float:
    pulse_sum = pulse1 + pulse2
    pulse = 0.0 if pulse_sum == 0 else 95.88 / ((8128.0 / pulse_sum) + 100.0)
    tnd_input = triangle / 8227.0
    tnd = 0.0 if tnd_input == 0 else 159.79 / ((1.0 / tnd_input) + 100.0)
    return pulse + tnd


class ApuOutputFilter:
    """Approximate the NES coupling and reconstruction filters."""

    def __init__(self, sample_rate: int) -> None:
        self.high_pass_90 = self._high_pass_coefficient(90.0, sample_rate)
        self.high_pass_440 = self._high_pass_coefficient(440.0, sample_rate)
        self.low_pass_14000 = self._low_pass_coefficient(14_000.0, sample_rate)
        self.hp90_input = 0.0
        self.hp90_output = 0.0
        self.hp440_input = 0.0
        self.hp440_output = 0.0
        self.lp_output = 0.0

    @staticmethod
    def _high_pass_coefficient(cutoff: float, sample_rate: int) -> float:
        time_constant = 1.0 / (2.0 * math.pi * cutoff)
        interval = 1.0 / sample_rate
        return time_constant / (time_constant + interval)

    @staticmethod
    def _low_pass_coefficient(cutoff: float, sample_rate: int) -> float:
        time_constant = 1.0 / (2.0 * math.pi * cutoff)
        interval = 1.0 / sample_rate
        return interval / (time_constant + interval)

    def prime(self, value: float) -> None:
        self.hp90_input = value
        self.hp90_output = 0.0
        self.hp440_input = 0.0
        self.hp440_output = 0.0
        self.lp_output = 0.0

    def process(self, value: float) -> float:
        hp90 = self.high_pass_90 * (
            self.hp90_output + value - self.hp90_input
        )
        self.hp90_input = value
        self.hp90_output = hp90
        hp440 = self.high_pass_440 * (
            self.hp440_output + hp90 - self.hp440_input
        )
        self.hp440_input = hp90
        self.hp440_output = hp440
        self.lp_output += self.low_pass_14000 * (hp440 - self.lp_output)
        return self.lp_output


def render_track_pcm(
    prg: bytes,
    track_index: int,
    *,
    enabled_channels: set[str] | None = None,
    max_frames: int = DEFAULT_PREVIEW_FRAMES,
    sample_rate: int = DEFAULT_SAMPLE_RATE,
) -> tuple[bytes, tuple[ChannelLane, ...]]:
    if sample_rate <= 0:
        raise SoundStudioModelError("sample rate must be positive")
    lanes = track_lanes(prg, track_index, max_frames=max_frames)
    total_frames = max((lane.frames for lane in lanes), default=0)
    total_samples = max(1, round(total_frames * sample_rate / NTSC_FRAME_RATE))
    record = audio_track_selection.parse_track_records(prg)[track_index]
    parameters = (record.pulse1_parameters, record.pulse2_parameters, 0)
    cursors = [0, 0, 0]
    output_filter = ApuOutputFilter(sample_rate)
    filter_primed = False
    pcm = bytearray()
    for sample_index in range(total_samples):
        frame = sample_index * NTSC_FRAME_RATE / sample_rate
        values = [0.0, 0.0, 0.0]
        for lane_index, lane in enumerate(lanes):
            if enabled_channels is not None and lane.name not in enabled_channels:
                continue
            while (
                cursors[lane_index] + 1 < len(lane.events)
                and frame
                >= lane.events[cursors[lane_index]].start_frame
                + lane.events[cursors[lane_index]].duration_frames
            ):
                cursors[lane_index] += 1
            if not lane.events:
                continue
            event = lane.events[cursors[lane_index]]
            if not event.start_frame <= frame < event.start_frame + event.duration_frames:
                continue
            audible = event.duration_frames <= 3 or frame < event.start_frame + event.duration_frames - 3
            if not audible:
                continue
            elapsed = (frame - event.start_frame) / NTSC_FRAME_RATE
            values[lane_index] = (
                _triangle_sample(event.frequency, elapsed)
                if lane_index == 2
                else _pulse_sample(event.frequency, elapsed, parameters[lane_index])
            )
        mixed = _apu_mix(*values)
        if not filter_primed:
            output_filter.prime(mixed)
            filter_primed = True
        sample = max(-1.0, min(1.0, output_filter.process(mixed) * PREVIEW_GAIN))
        pcm.extend(struct.pack("<h", round(sample * 32767)))
    return bytes(pcm), lanes


def write_track_preview(
    prg: bytes,
    track_index: int,
    path: Path,
    *,
    enabled_channels: set[str] | None = None,
    max_frames: int = DEFAULT_PREVIEW_FRAMES,
    sample_rate: int = DEFAULT_SAMPLE_RATE,
) -> Path:
    pcm, _lanes = render_track_pcm(
        prg,
        track_index,
        enabled_channels=enabled_channels,
        max_frames=max_frames,
        sample_rate=sample_rate,
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(sample_rate)
        output.writeframes(pcm)
    return path


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

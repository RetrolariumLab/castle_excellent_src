from __future__ import annotations

from copy import deepcopy
from pathlib import Path
import sys
import tempfile
import unittest
import wave
import struct


ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))

import music_editor
import room_data
import sound_studio_model as model


class SoundStudioModelTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        image = (ROOT / "Castle Excellent (J).nes").read_bytes()
        prg, _chr_data = room_data.extract_rom(image)
        cls.prg = prg
        cls.workspace = music_editor.decode_workspace(
            "castle-excellent-japan-hsp-05", prg
        )

    def test_summary_covers_complete_music_workspace(self) -> None:
        summary = model.summarize(
            self.workspace, "castle-excellent-japan-hsp-05"
        )
        self.assertEqual(summary.stream_count, 21)
        self.assertEqual(summary.track_count, 8)
        self.assertEqual(summary.active_track_slots, 23)
        self.assertEqual(summary.used_bytes, summary.capacity_bytes)
        self.assertEqual(summary.free_bytes, 0)

    def test_byte_parser_accepts_editor_notation(self) -> None:
        self.assertEqual(model.parse_byte("$2A", "parameter"), 0x2A)
        self.assertEqual(model.parse_byte("0x2a", "parameter"), 0x2A)
        self.assertEqual(model.parse_byte("42", "parameter"), 42)
        for value in ("", "256", "-1", "wrong"):
            with self.assertRaises(model.SoundStudioModelError):
                model.parse_byte(value, "parameter")

    def test_stream_label_tracks_repacked_text_size(self) -> None:
        workspace = deepcopy(self.workspace)
        stream = workspace["streams"][0]
        label = model.stream_label(stream)
        self.assertIn(stream["id"], label)
        self.assertIn(f"{len(stream['text']):4d} bytes", label)

    def test_track_lanes_decode_all_three_runtime_channels(self) -> None:
        lanes = model.track_lanes(self.prg, 0, max_frames=300)
        self.assertEqual([lane.name for lane in lanes], ["Pulse 1", "Pulse 2", "Triangle"])
        self.assertTrue(all(lane.events for lane in lanes))
        self.assertTrue(all(lane.frames == 300 for lane in lanes))
        self.assertTrue(any(event.note != "rest" for lane in lanes for event in lane.events))

    def test_track_zero_shares_pulse_one_tempo_with_later_channels(self) -> None:
        pulse1, pulse2, triangle = model.track_lanes(
            self.prg, 0, max_frames=80
        )
        self.assertEqual(pulse1.events[0].duration_frames, 20)
        self.assertEqual(pulse2.events[0].duration_frames, 10)
        self.assertEqual(triangle.events[0].duration_frames, 20)
        self.assertEqual(pulse2.events[1].start_frame, 10)

    def test_all_track_records_have_named_sequencer_views(self) -> None:
        for index in range(8):
            self.assertIn(model.TRACK_NAMES[index], model.track_label(index))
            lanes = model.track_lanes(self.prg, index, max_frames=120)
            self.assertEqual(len(lanes), 3)

    def test_preview_renderer_writes_audible_mono_wav(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "preview.wav"
            model.write_track_preview(
                self.prg,
                0,
                path,
                max_frames=30,
                sample_rate=3_000,
            )
            with wave.open(str(path), "rb") as preview:
                self.assertEqual(preview.getnchannels(), 1)
                self.assertEqual(preview.getsampwidth(), 2)
                self.assertEqual(preview.getframerate(), 3_000)
                frames = preview.readframes(preview.getnframes())
            self.assertTrue(any(frames))
            samples = struct.unpack(f"<{len(frames) // 2}h", frames)
            self.assertLess(max(abs(sample) for sample in samples), 15_000)


if __name__ == "__main__":
    unittest.main()

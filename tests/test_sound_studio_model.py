from __future__ import annotations

from copy import deepcopy
from pathlib import Path
import sys
import unittest


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


if __name__ == "__main__":
    unittest.main()

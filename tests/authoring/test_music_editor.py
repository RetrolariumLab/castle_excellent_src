from __future__ import annotations

from copy import deepcopy
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]

from scripts.authoring import music_editor
from scripts.authoring import room_data
class MusicEditorTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.image = (ROOT / "Castle Excellent (J).nes").read_bytes()
        cls.prg, cls.chr_data = room_data.extract_rom(cls.image)
        cls.workspace = music_editor.decode_workspace(
            "castle-excellent-japan-hsp-05", cls.prg
        )

    def test_zero_edit_workspace_rebuilds_the_complete_rom(self) -> None:
        validated = music_editor.validate_workspace(
            self.workspace, "castle-excellent-japan-hsp-05"
        )
        output, report = music_editor.compose_music(
            self.image, self.prg, self.chr_data, validated
        )
        self.assertEqual(output, self.image)
        self.assertEqual(report["mml_used_bytes"], report["mml_capacity_bytes"])

    def test_valid_note_edit_changes_only_authored_prg_data(self) -> None:
        workspace = deepcopy(self.workspace)
        text = workspace["streams"][0]["text"]
        note = next(index for index, value in enumerate(text) if value in "abcdefg")
        replacement = "d" if text[note] != "d" else "e"
        workspace["streams"][0]["text"] = text[:note] + replacement + text[note + 1:]
        validated = music_editor.validate_workspace(
            workspace, "castle-excellent-japan-hsp-05"
        )
        output, report = music_editor.compose_music(
            self.image, self.prg, self.chr_data, validated
        )
        self.assertNotEqual(output, self.image)
        self.assertEqual(output[:16], self.image[:16])
        self.assertEqual(output[-len(self.chr_data):], self.chr_data)
        self.assertGreater(report["changed_bytes"], 0)

    def test_rejects_mml_arena_overflow(self) -> None:
        workspace = deepcopy(self.workspace)
        workspace["streams"][0]["text"] += "c" * 1_600
        with self.assertRaisesRegex(music_editor.MusicEditorError, "capacity"):
            music_editor.validate_workspace(
                workspace, "castle-excellent-japan-hsp-05"
            )


if __name__ == "__main__":
    unittest.main()

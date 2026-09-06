from __future__ import annotations

from pathlib import Path
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))

import level_playtest


class LevelPlaytestTests(unittest.TestCase):
    def test_environment_exposes_validated_runtime_coordinates(self) -> None:
        environment = level_playtest.playtest_environment(71, 319, 159)
        self.assertEqual(environment["CASTLE_PLAYTEST_ROOM"], "71")
        self.assertEqual(environment["CASTLE_PLAYTEST_X"], "319")
        self.assertEqual(environment["CASTLE_PLAYTEST_Y"], "159")

    def test_result_requires_the_requested_runtime_state(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "result.txt"
            path.write_text(
                "status=ok room=71 x=16 y=152 frame=43\n", encoding="utf-8"
            )
            fields = level_playtest.validate_result(path, 71, 16, 152)
            self.assertEqual(fields["frame"], "43")
            with self.assertRaisesRegex(level_playtest.LevelPlaytestError, "room"):
                level_playtest.validate_result(path, 72, 16, 152)

    def test_manifest_profile_resolves_built_rom(self) -> None:
        args = type(
            "Arguments",
            (),
            {
                "rom": None,
                "profile": "castle-excellent-japan-hsp-05",
                "revisions": ROOT / "config" / "revision_profiles.json",
            },
        )()
        self.assertEqual(
            level_playtest.resolve_rom(args),
            ROOT / "build" / "native" / "castle_excellent.nes",
        )


if __name__ == "__main__":
    unittest.main()

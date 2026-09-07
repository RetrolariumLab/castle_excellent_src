from __future__ import annotations

from pathlib import Path
import tempfile
import unittest


ROOT = Path(__file__).resolve().parent.parent

from scripts.runtime import revision_runtime
class RevisionRuntimeTests(unittest.TestCase):
    def test_castlequest_manifest_declares_direct_scenario(self) -> None:
        scenario = revision_runtime.load_scenario(
            ROOT / "scenarios/source_2_castlequest.json", "castlequest-usa"
        )
        self.assertEqual(scenario["maximum_frames"], 900)
        self.assertEqual(len(scenario["forbidden_hooks"]), 2)

    def test_result_requires_lives_room_and_three_entry_wrap(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "result.txt"
            path.write_text(
                "status=ok lives=50 room=71 menu_open=1 "
                "selections=0,1,2,0 load=0 save=0 frame=65\n",
                encoding="utf-8",
            )
            self.assertEqual(revision_runtime.validate_result(path)["frame"], "65")
            path.write_text(
                "status=ok lives=3 room=71 menu_open=1 "
                "selections=0,1,2,0 load=0 save=0 frame=65\n",
                encoding="utf-8",
            )
            with self.assertRaisesRegex(revision_runtime.RevisionRuntimeError, "lives"):
                revision_runtime.validate_result(path)


if __name__ == "__main__":
    unittest.main()

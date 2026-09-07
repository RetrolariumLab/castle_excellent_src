from __future__ import annotations

from pathlib import Path
import tempfile
import unittest



from scripts.workflow import run_ghidra
class GhidraProjectCleanupTests(unittest.TestCase):
    def test_removes_only_disposable_project_pair(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            project_dir = Path(temporary)
            marker = project_dir / "castle_excellent.gpr"
            repository = project_dir / "castle_excellent.rep"
            exported_facts = project_dir / "instructions.tsv"
            marker.write_text("marker", encoding="utf-8")
            repository.mkdir()
            (repository / "state").write_text("state", encoding="utf-8")
            exported_facts.write_text("facts", encoding="utf-8")

            run_ghidra.clear_project_state(project_dir, "castle_excellent")

            self.assertFalse(marker.exists())
            self.assertFalse(repository.exists())
            self.assertEqual(exported_facts.read_text(encoding="utf-8"), "facts")

    def test_rejects_repository_path_that_is_not_a_directory(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            project_dir = Path(temporary)
            repository = project_dir / "castle_excellent.rep"
            repository.write_text("not a directory", encoding="utf-8")
            with self.assertRaisesRegex(run_ghidra.PipelineError, "not a directory"):
                run_ghidra.clear_project_state(project_dir, "castle_excellent")


if __name__ == "__main__":
    unittest.main()

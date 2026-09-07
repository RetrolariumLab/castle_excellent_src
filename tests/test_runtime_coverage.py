from __future__ import annotations

from pathlib import Path
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parent.parent

from scripts.runtime import runtime_coverage
class RuntimeCoverageTests(unittest.TestCase):
    def test_builds_contiguous_ranges(self) -> None:
        self.assertEqual(
            runtime_coverage.contiguous_ranges({1, 2, 3, 7, 9, 10}),
            [(1, 3), (7, 7), (9, 10)],
        )

    def test_classifies_code_data_and_symbol_hits(self) -> None:
        cdl = bytes((0x01, 0x01, 0x03, 0x02, 0x00))
        report = runtime_coverage.analyze_cdl(
            cdl,
            5,
            {0x8000: 2, 0x8002: 1},
            {0x8000: "Reset", 0x8004: "Unused"},
        )
        self.assertEqual(report["runtime_code_bytes"], 3)
        self.assertEqual(report["runtime_data_bytes"], 2)
        self.assertEqual(report["runtime_code_and_data_bytes"], 1)
        self.assertEqual(report["executed_instruction_starts"], 2)
        self.assertEqual(report["executed_bytes_outside_ghidra_code"], 0)
        self.assertEqual(report["hit_semantic_routines"][0]["name"], "Reset")

    def test_reports_runtime_code_outside_static_classification(self) -> None:
        report = runtime_coverage.analyze_cdl(
            bytes((0x01, 0x00, 0x01)),
            3,
            {0x8000: 1},
            {},
        )
        self.assertEqual(report["executed_bytes_outside_ghidra_code"], 1)
        self.assertEqual(
            report["executed_bytes_outside_ghidra_code_addresses"],
            ["0x8002"],
        )

    def test_rejects_short_cdl(self) -> None:
        with self.assertRaises(runtime_coverage.CoverageError):
            runtime_coverage.analyze_cdl(b"\x00", 2, {0x8000: 1}, {})

    def test_merges_cdl_bits(self) -> None:
        self.assertEqual(
            runtime_coverage.merge_cdls([b"\x01\x00\x02", b"\x02\x01\x00"]),
            b"\x03\x01\x02",
        )

    def test_rejects_different_cdl_sizes(self) -> None:
        with self.assertRaisesRegex(runtime_coverage.CoverageError, "different sizes"):
            runtime_coverage.merge_cdls([b"\x01", b"\x01\x02"])

    def test_validates_runtime_metadata_and_required_hooks(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "scenario.txt"
            path.write_text(
                "scenario=room-transition\n"
                "status=ok\n"
                "hit=TransitionToRoomAbove@800\n"
                "hit=FinishRoomTransition@801\n",
                encoding="utf-8",
            )
            metadata = runtime_coverage.validate_runtime_metadata(
                path,
                "room-transition",
                ["TransitionToRoomAbove", "FinishRoomTransition"],
            )
            self.assertEqual(metadata["status"], ["ok"])

    def test_rejects_incomplete_runtime_metadata(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "scenario.txt"
            path.write_text(
                "scenario=death-game-over\n"
                "status=incomplete\n"
                "miss=RunGameOverSequence\n",
                encoding="utf-8",
            )
            with self.assertRaisesRegex(runtime_coverage.CoverageError, "incomplete"):
                runtime_coverage.validate_runtime_metadata(
                    path, "death-game-over", ["RunGameOverSequence"]
                )


if __name__ == "__main__":
    unittest.main()

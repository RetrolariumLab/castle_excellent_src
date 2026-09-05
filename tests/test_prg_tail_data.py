from pathlib import Path
import unittest

from scripts import prg_tail_data


ROOT = Path(__file__).resolve().parent.parent


class PrgTailDataTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.prg = prg_tail_data.extract_prg(
            (ROOT / "Castle Excellent (J).nes").read_bytes()
        )

    def test_tile_tables_cover_exact_room_cell_domain(self) -> None:
        self.assertEqual(prg_tail_data.tile_pair(self.prg, 0), (2, 2))
        self.assertEqual(prg_tail_data.tile_pair(self.prg, 99), (0x18, 0x18))
        with self.assertRaises(prg_tail_data.PrgTailDataError):
            prg_tail_data.tile_pair(self.prg, 100)

    def test_mutable_restored_cells_share_tiles(self) -> None:
        self.assertEqual(prg_tail_data.tile_pair(self.prg, 0x62), (0x18, 0x18))
        self.assertEqual(prg_tail_data.tile_pair(self.prg, 0x63), (0x18, 0x18))

    def test_vectors_target_named_platform_entries(self) -> None:
        self.assertEqual(prg_tail_data.read_vectors(self.prg), prg_tail_data.EXPECTED_VECTORS)

    def test_reference_contract_counts_every_unrolled_table_read(self) -> None:
        report = prg_tail_data.validate_contract(
            self.prg, (ROOT / "build/ghidra/instructions.tsv").read_text(encoding="utf-8")
        )
        self.assertEqual(report["bytes"], 280)
        self.assertEqual(report["table_entries"], 100)
        self.assertEqual(report["table_reads"], {"left": 400, "right": 400})


if __name__ == "__main__":
    unittest.main()

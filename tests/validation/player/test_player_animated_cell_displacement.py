from pathlib import Path
import unittest

from scripts.validation.player import player_animated_cell_displacement


ROOT = Path(__file__).resolve().parents[3]


class PlayerAnimatedCellDisplacementTests(unittest.TestCase):
    def test_incrementing_cell_moves_player_left_and_samples_new_edge(self) -> None:
        result = player_animated_cell_displacement.move_player_left(
            0x0100, 0x40, 0, (False, False, False)
        )
        self.assertTrue(result.moved)
        self.assertEqual(result.player_x, 0x00FE)
        self.assertEqual(result.movement_latch, 0xFF)
        self.assertEqual(result.probes, ((0x00FE, 0x40), (0x00FE, 0x47), (0x00FE, 0x4F)))

    def test_decrementing_cell_moves_player_right_and_samples_right_edge(self) -> None:
        result = player_animated_cell_displacement.move_player_right(
            0x0100, 0xF8, 0, (False, False, False)
        )
        self.assertTrue(result.moved)
        self.assertEqual(result.player_x, 0x0102)
        self.assertEqual(result.probes, ((0x0111, 0xF8), (0x0111, 0xFF), (0x0111, 0x07)))

    def test_first_collision_stops_probes_and_preserves_state(self) -> None:
        result = player_animated_cell_displacement.move_player_left(
            0x0040, 0x20, 0x55, (False, True, True)
        )
        self.assertFalse(result.moved)
        self.assertEqual(result.player_x, 0x0040)
        self.assertEqual(result.movement_latch, 0x55)
        self.assertEqual(result.probes, ((0x003E, 0x20), (0x003E, 0x27)))

    def test_machine_exact_horizontal_boundaries_are_preserved(self) -> None:
        self.assertTrue(
            player_animated_cell_displacement.move_player_left(
                2, 0, 0, (False, False, False)
            ).moved
        )
        self.assertFalse(
            player_animated_cell_displacement.move_player_left(
                1, 0, 0, (False, False, False)
            ).moved
        )
        self.assertTrue(
            player_animated_cell_displacement.move_player_right(
                0x013E, 0, 0, (False, False, False)
            ).moved
        )
        self.assertFalse(
            player_animated_cell_displacement.move_player_right(
                0x013F, 0, 0, (False, False, False)
            ).moved
        )

    def test_invalid_machine_values_and_collision_shape_are_rejected(self) -> None:
        with self.assertRaises(
            player_animated_cell_displacement.AnimatedCellDisplacementError
        ):
            player_animated_cell_displacement.move_player_left(
                0x10000, 0, 0, (False, False, False)
            )
        with self.assertRaises(
            player_animated_cell_displacement.AnimatedCellDisplacementError
        ):
            player_animated_cell_displacement.move_player_right(0, 0, 0, (False,))

    def test_reference_rom_and_exhaustive_contracts(self) -> None:
        prg = player_animated_cell_displacement.extract_prg(
            (ROOT / "Castle Excellent (J).nes").read_bytes()
        )
        report = player_animated_cell_displacement.validate_rom_contract(prg)
        self.assertEqual(report["routine_bytes"], 149)
        self.assertEqual(report["handler_entries"], 24)
        self.assertEqual(
            player_animated_cell_displacement.validate_exhaustive_contract(),
            {"x_cases": 131_072, "y_cases": 512, "collision_patterns": 16},
        )


if __name__ == "__main__":
    unittest.main()

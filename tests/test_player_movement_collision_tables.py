from pathlib import Path
import unittest

from scripts.validation.player import player_movement_collision_tables


ROOT = Path(__file__).resolve().parent.parent


class PlayerMovementCollisionTableTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.prg = player_movement_collision_tables.extract_prg(
            (ROOT / "Castle Excellent (J).nes").read_bytes()
        )

    def test_physical_tables_cover_exact_834_byte_range(self) -> None:
        report = player_movement_collision_tables.validate_rom_contract(self.prg)
        self.assertEqual(report["bytes"], 834)
        self.assertEqual(len(report["tables"]), 6)

    def test_downward_room_cells_select_animated_displacement(self) -> None:
        select = player_movement_collision_tables.select_handler
        self.assertEqual(select("down", 0x35), 0x87CB)
        self.assertEqual(select("down", 0x40), 0x87CB)
        self.assertEqual(select("down", 0x56), 0x8785)
        self.assertEqual(select("down", 0x61), 0x8785)
        self.assertEqual(select("down", 0x34), 0x926B)

    def test_upward_room_cells_are_all_no_op(self) -> None:
        self.assertEqual(
            {player_movement_collision_tables.select_handler("up", cell) for cell in range(100)},
            {0x926B},
        )

    def test_horizontal_room_cells_select_six_action_pairs(self) -> None:
        select = player_movement_collision_tables.select_handler
        self.assertEqual(select("horizontal", 0x19), 0xA5DD)
        self.assertEqual(select("horizontal", 0x2A), 0xA60F)
        self.assertEqual(select("horizontal", 0x1B), 0x926B)

    def test_runtime_direction_differences_are_explicit(self) -> None:
        select = player_movement_collision_tables.select_handler
        self.assertEqual(select("down", 0x8F), 0x8DB0)
        self.assertEqual(select("up", 0x8F), 0x926B)
        self.assertEqual(select("horizontal", 0x8F), 0x881A)
        self.assertEqual(select("horizontal", 0x8E), 0x89E1)

    def test_horizontal_type_a7_is_rejected_at_physical_boundary(self) -> None:
        select = player_movement_collision_tables.select_handler
        self.assertEqual(select("down", 0xA7), 0x926B)
        self.assertEqual(select("up", 0xA7), 0x926B)
        with self.assertRaises(
            player_movement_collision_tables.UnsafeHorizontalRuntimeTypeError
        ):
            select("horizontal", 0xA7)

    def test_consumer_and_synthetic_call_contracts(self) -> None:
        report = player_movement_collision_tables.validate_rom_contract(self.prg)
        self.assertEqual(report["consumer_loads"], 12)
        self.assertEqual(len(report["synthetic_calls"]), 3)

    def test_exhaustive_logical_selection_contract(self) -> None:
        self.assertEqual(
            player_movement_collision_tables.validate_exhaustive_contract(),
            {"selection_cases": 420, "physical_entries": 417, "logical_entries": 420},
        )


if __name__ == "__main__":
    unittest.main()

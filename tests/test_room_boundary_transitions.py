from pathlib import Path
import unittest

from scripts.validation.rooms import room_boundary_transitions as transitions


ROOT = Path(__file__).resolve().parent.parent


class RoomBoundaryTransitionTests(unittest.TestCase):
    def test_vertical_entries_align_x_and_save_new_coordinates(self) -> None:
        above = transitions.apply_room_boundary("above", 55, 0x0127, 0)
        below = transitions.apply_room_boundary("below", 55, 0x0127, 0xA0)
        self.assertEqual((above.room_number, above.player_x, above.player_y), (45, 0x0120, 0x98))
        self.assertEqual(above.saved_player, (0x20, 0x01, 0x98))
        self.assertEqual((below.room_number, below.player_x, below.player_y), (65, 0x0120, 0x10))

    def test_vertical_helpers_still_reload_at_top_and_bottom_rows(self) -> None:
        above = transitions.apply_room_boundary("above", 1, 7, 0)
        below = transitions.apply_room_boundary("below", 100, 7, 0xA0)
        self.assertEqual(above.room_number, 1)
        self.assertEqual(below.room_number, 100)
        self.assertIn("LoadRoom", above.calls)
        self.assertIn("LoadRoom", below.calls)

    def test_horizontal_castle_edges_only_clamp_and_update_scroll(self) -> None:
        left = transitions.apply_room_boundary("left", 51, 0xFFFF, 0x48)
        right = transitions.apply_room_boundary("right", 60, 0, 0x48)
        self.assertEqual((left.room_number, left.player_x), (51, 0))
        self.assertEqual((right.room_number, right.player_x), (60, 0x0130))
        self.assertIsNone(left.saved_player)
        self.assertIsNone(right.mutable_probe)
        self.assertEqual(left.calls[-1], "UpdateHorizontalScroll")

    def test_horizontal_transition_probes_mutable_cell_at_new_entrance(self) -> None:
        left = transitions.apply_room_boundary(
            "left", 55, 0x0140, 0x08, mutable_found=True
        )
        right = transitions.apply_room_boundary(
            "right", 55, 0, 0x08, mutable_found=False
        )
        self.assertEqual((left.room_number, left.player_x), (54, 0x0130))
        self.assertEqual(left.mutable_probe, (0x0130, 0xF8))
        self.assertIn("RestoreMutableCellByOrdinal", left.calls)
        self.assertEqual((right.room_number, right.player_x), (56, 0))
        self.assertEqual(right.mutable_probe, (0, 0xF8))
        self.assertNotIn("RestoreMutableCellByOrdinal", right.calls)

    def test_rejects_invalid_direction_and_machine_values(self) -> None:
        with self.assertRaises(transitions.RoomBoundaryTransitionError):
            transitions.apply_room_boundary("inside", 1, 0, 0)
        with self.assertRaises(transitions.RoomBoundaryTransitionError):
            transitions.apply_room_boundary("left", 1, 0x10000, 0)

    def test_reference_rom_and_exhaustive_contract(self) -> None:
        prg = transitions.extract_prg((ROOT / "Castle Excellent (J).nes").read_bytes())
        self.assertEqual(transitions.validate_rom_contract(prg)["bytes"], 222)
        report = transitions.validate_exhaustive_contract()
        self.assertEqual(report["vertical_x_cases"], 131_072)
        self.assertEqual(report["vertical_room_cases"], 200)
        self.assertEqual(report["horizontal_cases"], 102_400)


if __name__ == "__main__":
    unittest.main()

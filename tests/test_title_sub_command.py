from pathlib import Path
import unittest

from scripts import title_sub_command


ROOT = Path(__file__).resolve().parent.parent


class TitleSubCommandTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.prg, cls.chr_banks = title_sub_command.extract_regions(
            (ROOT / "Castle Excellent (J).nes").read_bytes()
        )

    def test_reference_rom_contract(self) -> None:
        report = title_sub_command.validate_rom_contract(self.prg, self.chr_banks)
        self.assertEqual(report["bytes"], 770)
        self.assertEqual(report["range_hashes"], 6)
        self.assertEqual(len(report["strings"]), 8)

    def test_all_menu_strings_decode(self) -> None:
        decoded = []
        for address, _expected in title_sub_command.EXPECTED_STRINGS:
            offset = address - title_sub_command.PRG_BASE
            end = self.prg.index(0, offset, title_sub_command.SUB_COMMAND_TEXT_END - title_sub_command.PRG_BASE) + 1
            decoded.append(title_sub_command.decode_tile_string(self.prg[offset:end]))
        self.assertEqual(decoded, [text for _address, text in title_sub_command.EXPECTED_STRINGS])

    def test_title_times_out_after_exactly_768_frames(self) -> None:
        counter = 0
        previous = 0xFF
        for _frame in range(title_sub_command.TITLE_TIMEOUT_FRAMES - 1):
            result = title_sub_command.title_frame(counter, 0, previous)
            self.assertFalse(result.exited)
            counter = result.counter
            previous = result.previous_buttons_inverted
        result = title_sub_command.title_frame(counter, 0, previous)
        self.assertTrue(result.exited)
        self.assertEqual(result.reason, "timeout")
        self.assertEqual(result.demo_active, 0xFF)

    def test_title_start_requires_a_fresh_edge(self) -> None:
        held_previous = title_sub_command.initialize_title_buttons(title_sub_command.CONTROLLER_START)
        held = title_sub_command.title_frame(0, title_sub_command.CONTROLLER_START, held_previous)
        self.assertFalse(held.exited)
        fresh = title_sub_command.title_frame(held.counter, 0, held.previous_buttons_inverted)
        fresh = title_sub_command.title_frame(fresh.counter, title_sub_command.CONTROLLER_START, fresh.previous_buttons_inverted)
        self.assertTrue(fresh.exited)
        self.assertEqual(fresh.reason, "start")
        self.assertEqual(fresh.demo_active, 0)

    def test_four_page_copy_plan_for_all_callers(self) -> None:
        for _source, page in title_sub_command.COPY_CALL_SITES:
            with self.subTest(source_page=page):
                plan = title_sub_command.nametable_copy_plan(page)
                copied = title_sub_command.copy_four_chr_pages(self.chr_banks[3], page)
                self.assertEqual(len(plan), 0x400)
                self.assertEqual(plan[0], (page << 8, 0x2000))
                self.assertEqual(plan[-1], ((page << 8) + 0x3FF, 0x23FF))
                self.assertEqual(copied, self.chr_banks[3][page << 8:(page << 8) + 0x400])

    def test_sub_command_entry_is_gated_and_edge_triggered(self) -> None:
        button = title_sub_command.CONTROLLER_A
        self.assertTrue(title_sub_command.sub_command_entry(0, 0, button, 0).opened)
        self.assertFalse(title_sub_command.sub_command_entry(0, 0, button, button).opened)
        self.assertFalse(title_sub_command.sub_command_entry(1, 0, button, 0).opened)
        self.assertFalse(title_sub_command.sub_command_entry(0, 1, button, 0).opened)

    def test_sub_command_entry_preserves_history_when_it_opens_or_is_gated(self) -> None:
        opened = title_sub_command.sub_command_entry(0, 0, title_sub_command.CONTROLLER_B, 0)
        gated = title_sub_command.sub_command_entry(1, 0, 0xFF, 0x34)
        idle = title_sub_command.sub_command_entry(0, 0, title_sub_command.CONTROLLER_UP, 0)
        self.assertEqual(opened.previous_controller2_buttons, 0)
        self.assertEqual(gated.previous_controller2_buttons, 0x34)
        self.assertEqual(idle.previous_controller2_buttons, title_sub_command.CONTROLLER_UP)

    def test_menu_navigation_wraps(self) -> None:
        down = title_sub_command.menu_frame(4, title_sub_command.CONTROLLER_DOWN, 0xFF)
        up = title_sub_command.menu_frame(0, title_sub_command.CONTROLLER_UP, 0xFF)
        self.assertEqual(down.selection, 0)
        self.assertEqual(up.selection, 4)
        self.assertEqual(title_sub_command.cursor_address(0), 0x218B)
        self.assertEqual(title_sub_command.cursor_address(4), 0x228B)

    def test_menu_confirmation_selects_transport_and_dispatch(self) -> None:
        start = title_sub_command.menu_frame(2, title_sub_command.CONTROLLER_START, 0xFF)
        pulse = title_sub_command.menu_frame(3, title_sub_command.CONTROLLER_A, 0xFF)
        self.assertEqual((start.command, start.target, start.transport_mode), ("load", 0xFD06, 0x00))
        self.assertEqual((pulse.command, pulse.target, pulse.transport_mode), ("save", 0xFBFE, 0xFF))

    def test_menu_input_priority_matches_code_order(self) -> None:
        all_buttons = (
            title_sub_command.CONTROLLER_DOWN
            | title_sub_command.CONTROLLER_START
            | title_sub_command.CONTROLLER_A
            | title_sub_command.CONTROLLER_UP
        )
        result = title_sub_command.menu_frame(1, all_buttons, 0xFF)
        self.assertEqual(result.selection, 2)
        self.assertIsNone(result.command)
        start_over_a = title_sub_command.menu_frame(
            1, title_sub_command.CONTROLLER_START | title_sub_command.CONTROLLER_A, 0xFF
        )
        self.assertEqual(start_over_a.transport_mode, 0x00)

    def test_dispatch_map_has_all_five_commands(self) -> None:
        actual = []
        for selection in range(title_sub_command.SUB_COMMAND_COUNT):
            result = title_sub_command.menu_frame(selection, title_sub_command.CONTROLLER_A, 0xFF)
            actual.append((result.command, result.target))
        self.assertEqual(tuple(actual), title_sub_command.SUB_COMMAND_TARGETS)

    def test_exhaustive_input_contracts(self) -> None:
        report = title_sub_command.validate_behavior_contract()
        self.assertEqual(report["menu_cases"], 5 * 256 * 256)
        self.assertEqual(report["entry_cases"], 4 * 256 * 256)

    def test_reset_current_room_copies_runtime_and_costs_a_life(self) -> None:
        runtime = bytes(range(14))
        result = title_sub_command.reset_current_room(3, 0x47, runtime)
        self.assertTrue(result.allowed)
        self.assertEqual(result.lives, 2)
        self.assertEqual(result.room_number, 0x47)
        self.assertEqual(result.runtime_state, runtime)
        self.assertEqual((result.player_x_lo, result.player_x_hi, result.player_y), (11, 12, 13))
        self.assertTrue(result.persistent_state_loaded)
        self.assertEqual(result.target, 0xFD96)
        self.assertFalse(title_sub_command.reset_current_room(0, 0x47, runtime).allowed)

    def test_back_restores_snapshot_clears_markers_and_costs_a_life(self) -> None:
        runtime = bytes(range(0x20, 0x20 + 14))
        result = title_sub_command.back_to_previous_room(4, 0x46, 0x47, runtime)
        self.assertTrue(result.allowed)
        self.assertEqual(result.lives, 3)
        self.assertEqual(result.room_number, 0x46)
        self.assertEqual(result.runtime_state, runtime)
        self.assertEqual((result.snapshot_a_room, result.snapshot_b_room), (0, 0))
        self.assertEqual((result.player_x_lo, result.player_x_hi, result.player_y), (0x2B, 0x2C, 0x2D))
        self.assertFalse(title_sub_command.back_to_previous_room(4, 0, 0x47, runtime).allowed)
        self.assertFalse(title_sub_command.back_to_previous_room(0, 0x46, 0x47, runtime).allowed)


if __name__ == "__main__":
    unittest.main()

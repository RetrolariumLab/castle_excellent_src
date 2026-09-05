from collections import Counter
from pathlib import Path
import unittest

from scripts import demo_playback


ROOT = Path(__file__).resolve().parent.parent


class DemoPlaybackTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.prg = demo_playback.extract_prg((ROOT / "Castle Excellent (J).nes").read_bytes())
        cls.script = demo_playback.script_bytes(cls.prg)

    def test_reference_rom_contract(self) -> None:
        report = demo_playback.validate_rom_contract(self.prg)
        self.assertEqual(report["bytes"], 120)
        self.assertEqual(report["callers"], 2)
        self.assertEqual(report["commands"], 72)

    def test_initial_state_points_to_script(self) -> None:
        self.assertEqual(demo_playback.initial_state(), demo_playback.DemoState(0xB82C, 0))

    def test_mask_clears_select_and_start_for_every_byte(self) -> None:
        for value in range(256):
            with self.subTest(value=value):
                result = demo_playback.mask_demo_buttons(value)
                self.assertEqual(result, value & 0xF3)
                self.assertEqual(result & 0x0C, 0)

    def test_pointer_increment_carries_and_wraps(self) -> None:
        self.assertEqual(demo_playback.advance_pointer(0xB8FF), 0xB900)
        self.assertEqual(demo_playback.advance_pointer(0xFFFF), 0x0000)

    def test_reader_uses_16_bit_pointer_carry(self) -> None:
        prg = bytearray(0x8000)
        prg[0xB8FF - 0x8000] = 0x01
        prg[0xB900 - 0x8000] = 0x80
        result = demo_playback.read_demo_input(
            bytes(prg), demo_playback.DemoState(0xB8FF, 11)
        )
        self.assertEqual(result.state, demo_playback.DemoState(0xB900, 0))
        self.assertEqual(result.controller_buttons, 0x80)

    def test_script_has_exact_distribution_and_terminal_marker(self) -> None:
        self.assertEqual(self.script[-1], 0xFF)
        self.assertNotIn(0xFF, self.script[:-1])
        self.assertEqual(
            dict(Counter(self.script[:-1])), demo_playback.EXPECTED_COMMAND_DISTRIBUTION
        )

    def test_first_command_is_returned_eleven_times(self) -> None:
        state = demo_playback.initial_state()
        values = []
        for _read in range(11):
            result = demo_playback.read_demo_input(self.prg, state)
            values.append(result.controller_buttons)
            state = result.state
        self.assertEqual(values, [self.script[0]] * 11)
        twelfth = demo_playback.read_demo_input(self.prg, state)
        self.assertEqual(twelfth.controller_buttons, self.script[1])
        self.assertEqual(twelfth.state, demo_playback.DemoState(0xB82D, 0))

    def test_every_later_command_is_returned_twelve_times(self) -> None:
        expanded, _reset_read = demo_playback.expand_demo(self.prg)
        offset = 11
        for command in self.script[1:-1]:
            with self.subTest(offset=offset, command=command):
                expected = bytes((demo_playback.mask_demo_buttons(command),)) * 12
                self.assertEqual(expanded[offset:offset + 12], expected)
                offset += 12
        self.assertEqual(offset, len(expanded))

    def test_full_script_returns_863_samples_then_resets_on_864(self) -> None:
        expanded, reset_read = demo_playback.expand_demo(self.prg)
        self.assertEqual(len(expanded), 863)
        self.assertEqual(reset_read, 864)

    def test_terminal_marker_resets_without_returning_buttons(self) -> None:
        result = demo_playback.read_demo_input(
            self.prg, demo_playback.DemoState(0xB873, 11)
        )
        self.assertTrue(result.reset)
        self.assertIsNone(result.controller_buttons)
        self.assertEqual(result.state.pointer, 0xB874)

    def test_nmi_keeps_demo_and_physical_inputs_separate(self) -> None:
        result = demo_playback.read_demo_input(self.prg, demo_playback.initial_state())
        state = demo_playback.apply_demo_nmi_input(result, 0x08)
        self.assertEqual(state.controller1_buttons, 0x80)
        self.assertEqual(state.controller2_buttons, 0)
        self.assertEqual(state.physical_controller1_buttons, 0x08)


if __name__ == "__main__":
    unittest.main()

from __future__ import annotations

import unittest



from scripts.validation.gameplay import controller_input
class ControllerInputTests(unittest.TestCase):
    def test_decodes_standard_button_order_from_d0(self) -> None:
        buttons = 0x01 | 0x08 | 0x40
        reads = controller_input.encode_serial_reads(buttons, data_line=0)
        self.assertEqual(controller_input.decode_serial_reads(reads), buttons)
        self.assertEqual(
            controller_input.pressed_button_names(buttons), ["A", "Start", "Left"]
        )

    def test_falls_back_to_d1_when_d0_is_clear(self) -> None:
        buttons = 0xA6
        reads = controller_input.encode_serial_reads(buttons, data_line=1)
        self.assertEqual(controller_input.decode_serial_reads(reads), buttons)

    def test_d0_set_produces_pressed_bit_without_consulting_d1(self) -> None:
        reads = [0x03] + [0x00] * 7
        self.assertEqual(controller_input.decode_serial_reads(reads), 0x01)

    def test_requires_exactly_eight_samples(self) -> None:
        with self.assertRaisesRegex(controller_input.ControllerInputError, "expected 8"):
            controller_input.decode_serial_reads([0] * 7)

    def test_exhaustive_validation(self) -> None:
        controller_input.validate_all_button_masks()


if __name__ == "__main__":
    unittest.main()

from __future__ import annotations

import unittest

from scripts.validation.gameplay import famicom_data_io


class FamicomDataIoTests(unittest.TestCase):
    def test_bits_are_msb_first(self) -> None:
        self.assertEqual(
            famicom_data_io.byte_bits_msb_first(0xA5),
            (1, 0, 1, 0, 0, 1, 0, 1),
        )

    def test_expansion_output_keeps_data_stable_while_clock_falls(self) -> None:
        pairs = famicom_data_io.expansion_write_pairs(0x80)
        self.assertEqual(pairs[0], (0x07, 0x03))
        self.assertEqual(pairs[1:], ((0x06, 0x02),) * 7)

    def test_expansion_input_reads_port_bit_two(self) -> None:
        samples = tuple(bit << 2 for bit in (1, 0, 1, 0, 0, 1, 0, 1))
        self.assertEqual(famicom_data_io.decode_expansion_samples(samples), 0xA5)

    def test_receiver_ignores_first_preamble_byte(self) -> None:
        self.assertTrue(famicom_data_io.expansion_preamble_matches((0xFF, 0xAA, 0x55)))
        self.assertFalse(famicom_data_io.expansion_preamble_matches((0x00, 0xAB, 0x55)))

    def test_pulse_transport_maps_zero_and_one_to_distinct_cycles(self) -> None:
        zero = famicom_data_io.pulse_byte_cycles(0x00)
        one = famicom_data_io.pulse_byte_cycles(0xFF)
        self.assertEqual(zero, ("long",) * 9 + ("short",) * 4)
        self.assertEqual(one, ("long",) + ("short",) * 20)

    def test_exhaustive_contract(self) -> None:
        report = famicom_data_io.validate_data_io_contract()
        self.assertEqual(report["validated_bytes"], 256)
        self.assertEqual(report["pulse_preamble_cycles"], 8448)


if __name__ == "__main__":
    unittest.main()

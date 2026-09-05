from __future__ import annotations

import unittest

from scripts import player_collision_dispatch as dispatch


class PlayerCollisionDispatchTests(unittest.TestCase):
    def setUp(self) -> None:
        self.room_handlers = tuple(0x8000 + index for index in range(100))
        self.runtime_handlers = tuple(0x9000 + index for index in range(41))

    def test_room_cell_uses_unmasked_identity(self) -> None:
        result = dispatch.select_collision_handler(
            0x53, self.room_handlers, self.runtime_handlers
        )
        self.assertEqual(result.domain, "room-cell")
        self.assertEqual(result.type_index, 0x53)
        self.assertEqual(result.doubled_index, 0xA6)
        self.assertEqual(result.handler, 0x8053)

    def test_runtime_type_uses_low_seven_bits(self) -> None:
        result = dispatch.select_collision_handler(
            0x90, self.room_handlers, self.runtime_handlers
        )
        self.assertEqual(result.domain, "runtime-object")
        self.assertEqual(result.type_index, 0x10)
        self.assertEqual(result.doubled_index, 0x20)
        self.assertEqual(result.handler, 0x9010)

    def test_highest_consumed_runtime_type_is_a7(self) -> None:
        result = dispatch.select_collision_handler(
            0xA7, self.room_handlers, self.runtime_handlers
        )
        self.assertEqual(result.type_index, 39)
        self.assertEqual(result.handler, 0x9027)

    def test_synthetic_jsr_pushes_return_minus_one(self) -> None:
        result = dispatch.select_collision_handler(
            0, self.room_handlers, self.runtime_handlers
        )
        self.assertEqual(result.synthetic_return, 0x949B)
        self.assertEqual(result.pushed_return, 0x949A)

    def test_rejects_sample_outside_selected_table(self) -> None:
        with self.assertRaises(dispatch.PlayerCollisionDispatchError):
            dispatch.select_collision_handler(
                100, self.room_handlers, self.runtime_handlers
            )
        with self.assertRaises(dispatch.PlayerCollisionDispatchError):
            dispatch.select_collision_handler(
                0xA9, self.room_handlers, self.runtime_handlers
            )

    def test_pointer_decoder_is_little_endian(self) -> None:
        self.assertEqual(
            dispatch.decode_pointer_table(bytes.fromhex("34 12 CD AB")),
            (0x1234, 0xABCD),
        )
        with self.assertRaises(dispatch.PlayerCollisionDispatchError):
            dispatch.decode_pointer_table(b"\x00")


if __name__ == "__main__":
    unittest.main()

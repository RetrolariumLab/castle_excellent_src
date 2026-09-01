from __future__ import annotations

import unittest

from scripts import save_data


def patterned_state() -> save_data.SaveState:
    return save_data.SaveState(
        room_number=37,
        player_lives=0xA5,
        runtime_state=bytes(range(save_data.RUNTIME_STATE_SIZE)),
        mutable_region=bytes(range(save_data.MUTABLE_REGION_SIZE)),
        object_region=bytes(value & 0xFF for value in range(save_data.OBJECT_REGION_SIZE)),
        visited_flags=bytes(range(save_data.VISITED_FLAGS_SIZE)),
    )


class SaveDataTests(unittest.TestCase):
    def test_field_offsets_cover_exact_payload(self) -> None:
        self.assertEqual(save_data.RUNTIME_OFFSET, 2)
        self.assertEqual(save_data.MUTABLE_OFFSET, 16)
        self.assertEqual(save_data.OBJECT_OFFSET, 136)
        self.assertEqual(save_data.VISITED_OFFSET, 286)
        self.assertEqual(save_data.SIGNATURE_OFFSET, 386)
        self.assertEqual(save_data.SIGNATURE_OFFSET + save_data.SIGNATURE_SIZE, 394)

    def test_encode_uses_descending_memory_order(self) -> None:
        state = patterned_state()
        payload = save_data.encode_payload(state)
        self.assertEqual(
            payload[save_data.MUTABLE_OFFSET : save_data.OBJECT_OFFSET],
            state.mutable_region[::-1],
        )
        self.assertEqual(
            payload[save_data.OBJECT_OFFSET : save_data.VISITED_OFFSET],
            state.object_region[::-1],
        )
        self.assertEqual(
            payload[save_data.VISITED_OFFSET : save_data.SIGNATURE_OFFSET],
            state.visited_flags[::-1],
        )

    def test_round_trip_preserves_every_field(self) -> None:
        state = patterned_state()
        self.assertEqual(save_data.decode_payload(save_data.encode_payload(state)), state)

    def test_wire_signature_is_eight_byte_reverse_traversal(self) -> None:
        self.assertEqual(save_data.BACKWARD_SIGNATURE_TEXT, b"GNUTUEDEB")
        self.assertEqual(save_data.BACKWARD_SIGNATURE_TEXT[1:][::-1], b"BEDEUTUN")

    def test_rejects_bad_payload_size_and_signature(self) -> None:
        with self.assertRaises(save_data.SaveDataError):
            save_data.decode_payload(bytes(save_data.PAYLOAD_SIZE - 1))
        payload = bytearray(save_data.encode_payload(patterned_state()))
        payload[-1] ^= 1
        with self.assertRaises(save_data.SaveDataError):
            save_data.decode_payload(bytes(payload))

    def test_rejects_wrong_region_size(self) -> None:
        state = patterned_state()
        bad = save_data.SaveState(
            room_number=state.room_number,
            player_lives=state.player_lives,
            runtime_state=state.runtime_state,
            mutable_region=state.mutable_region[:-1],
            object_region=state.object_region,
            visited_flags=state.visited_flags,
        )
        with self.assertRaises(save_data.SaveDataError):
            save_data.encode_payload(bad)


if __name__ == "__main__":
    unittest.main()

from pathlib import Path
import unittest

from scripts import room_object_state_save


ROOT = Path(__file__).resolve().parent.parent


class RoomObjectStateSaveTests(unittest.TestCase):
    def test_empty_runtime_pool_saves_all_removed_bits(self) -> None:
        result = room_object_state_save.save_current_room_object_state(
            bytes(room_object_state_save.RECORD_BYTES), 1
        )
        self.assertEqual(result.room, 1)
        self.assertEqual(result.bitmap, b"\xFF\xFF\xFF")

    def test_persistent_type_bounds_clear_their_bits(self) -> None:
        records = bytearray(room_object_state_save.RECORD_BYTES)
        records[0] = room_object_state_save.PERSISTENT_TYPE_FIRST
        records[-room_object_state_save.RECORD_SIZE] = (
            room_object_state_save.PERSISTENT_TYPE_LAST
        )
        result = room_object_state_save.save_current_room_object_state(bytes(records), 100)
        self.assertEqual(int.from_bytes(result.bitmap, "little"), 0x7FFFFE)

    def test_removed_and_transient_types_set_their_bits(self) -> None:
        for object_type in (0x00, 0x7F, 0xA8, 0xFF):
            with self.subTest(object_type=object_type):
                self.assertTrue(
                    room_object_state_save.object_is_removed_or_transient(object_type)
                )

    def test_every_runtime_slot_maps_to_one_little_endian_bit(self) -> None:
        for slot in range(room_object_state_save.RECORD_COUNT):
            records = bytearray(room_object_state_save.RECORD_BYTES)
            records[slot * room_object_state_save.RECORD_SIZE] = (
                room_object_state_save.PERSISTENT_TYPE_FIRST
            )
            bitmap = int.from_bytes(
                room_object_state_save.save_current_room_object_state(
                    bytes(records), 1
                ).bitmap,
                "little",
            )
            self.assertEqual(bitmap, 0xFFFFFF ^ (1 << slot))

    def test_invalid_inputs_are_rejected(self) -> None:
        with self.assertRaises(room_object_state_save.RoomObjectStateSaveError):
            room_object_state_save.object_is_removed_or_transient(0x100)
        with self.assertRaises(room_object_state_save.RoomObjectStateSaveError):
            room_object_state_save.save_current_room_object_state(b"", 1)
        with self.assertRaises(room_object_state_save.RoomObjectStateSaveError):
            room_object_state_save.save_current_room_object_state(
                bytes(room_object_state_save.RECORD_BYTES), 0
            )

    def test_reference_rom_and_exhaustive_contracts(self) -> None:
        prg = room_object_state_save.extract_prg(
            (ROOT / "Castle Excellent (J).nes").read_bytes()
        )
        report = room_object_state_save.validate_rom_contract(prg)
        self.assertEqual(report["routine_bytes"], 45)
        self.assertEqual(tuple(report["call_sites"]), room_object_state_save.EXPECTED_CALL_SITES)
        self.assertEqual(
            room_object_state_save.validate_exhaustive_contract(),
            {"object_types": 256, "record_slots": 24},
        )


if __name__ == "__main__":
    unittest.main()

from __future__ import annotations

from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parent.parent

from scripts.authoring import room_data
def put_cpu(prg: bytearray, address: int, data: bytes) -> None:
    offset = room_data.cpu_offset(address)
    prg[offset:offset + len(data)] = data


class CodebookTests(unittest.TestCase):
    def test_parses_ascii_prefix_codebook(self) -> None:
        prg = bytearray(32_768)
        put_cpu(prg, room_data.CODEBOOK_CPU, b"\x11" b"0\0" b"\x22" b"10\0" b"\x33" b"11\0" b"\xff")
        self.assertEqual(
            room_data.parse_codebook(bytes(prg)),
            [(0x11, "0"), (0x22, "10"), (0x33, "11")],
        )

    def test_decodes_msb_first(self) -> None:
        entries = [(0x11, "0"), (0x22, "10"), (0x33, "11")]
        output, consumed = room_data.decode_prefix_stream(
            bytes([0b01011000]), entries, output_size=4
        )
        self.assertEqual(output, bytes((0x11, 0x22, 0x33, 0x11)))
        self.assertEqual(consumed, 6)

    def test_rejects_non_prefix_free_table(self) -> None:
        with self.assertRaisesRegex(room_data.RoomDataError, "prefix-free"):
            room_data.validate_codebook([(1, "0"), (2, "01")])

    def test_encoder_uses_one_bits_for_partial_byte_padding(self) -> None:
        encoded, padding = room_data.encode_prefix_stream(
            bytes((0x11, 0x22, 0x33, 0x11)),
            [(0x11, "0"), (0x22, "10"), (0x33, "11")],
        )
        self.assertEqual(encoded, bytes((0b01011011,)))
        self.assertEqual(padding, 2)


class RoomTests(unittest.TestCase):
    def test_room_bank_split(self) -> None:
        prg = bytearray(32_768)
        table = room_data.cpu_offset(room_data.ROOM_POINTERS_CPU)
        prg[table + 66 * 2:table + 66 * 2 + 2] = (0x123).to_bytes(2, "little")
        prg[table + 67 * 2:table + 67 * 2 + 2] = (0x456).to_bytes(2, "little")
        chr_data = bytes(4 * room_data.CHR_BANK_SIZE)
        _stream, bank, offset = room_data.room_stream(bytes(prg), chr_data, 66)
        self.assertEqual((bank, offset), (2, 0x123))
        _stream, bank, offset = room_data.room_stream(bytes(prg), chr_data, 67)
        self.assertEqual((bank, offset), (3, 0x456))

    def test_stream_layout_requires_gapless_bank_local_intervals(self) -> None:
        prg = bytearray(32_768)
        put_cpu(prg, room_data.CODEBOOK_CPU, b"\x11" b"0\0" b"\xff")
        table = room_data.cpu_offset(room_data.ROOM_POINTERS_CPU)
        chr_data = bytearray(b"\xff" * (4 * room_data.CHR_BANK_SIZE))
        offsets = {2: 0, 3: 0}
        for room_index in range(room_data.ROOM_COUNT):
            bank = 2 if room_index < room_data.ROOM_BANK_SPLIT else 3
            offset = offsets[bank]
            prg[table + room_index * 2:table + room_index * 2 + 2] = (
                offset.to_bytes(2, "little")
            )
            start = bank * room_data.CHR_BANK_SIZE + offset
            chr_data[start:start + 50] = bytes(50)
            offsets[bank] += 50
        result = room_data.validate_room_stream_layout(bytes(prg), bytes(chr_data))
        self.assertEqual(result["banks"][0]["used_bytes"], 67 * 50)
        self.assertEqual(result["banks"][1]["used_bytes"], 33 * 50)

        prg[table + 2:table + 4] = (51).to_bytes(2, "little")
        with self.assertRaisesRegex(room_data.RoomDataError, "expected"):
            room_data.validate_room_stream_layout(bytes(prg), bytes(chr_data))

    def test_decodes_raw_object_record(self) -> None:
        prg = bytearray(32_768)
        put_cpu(prg, room_data.OBJECT_STREAM_CPU, bytes((0x01, 3, 4, 0xFF)))
        put_cpu(prg, room_data.RUNTIME_OBJECT_TYPES_CPU + 1, bytes((0x81,)))
        put_cpu(prg, room_data.OBJECT_HANDLER_TABLE_CPU + 2, bytes((0x34, 0x12)))
        result = room_data.decode_objects(bytes(prg), 0)
        self.assertEqual(result["objects"][0]["runtime_type"], 0x81)
        self.assertEqual(result["objects"][0]["handler"], 0x1234)
        self.assertEqual(result["objects"][0]["pixel_x"], 48)
        self.assertEqual(result["objects"][0]["pixel_y"], 32)

    def test_runtime_type_view_overlaps_the_physical_state_table(self) -> None:
        prg = bytearray(32_768)
        put_cpu(prg, room_data.OBJECT_STREAM_CPU, bytes((0x31, 1, 2, 0xFF)))
        self.assertEqual(
            room_data.RUNTIME_OBJECT_TYPES_CPU + 0x31,
            room_data.RUNTIME_OBJECT_STATES_CPU,
        )
        put_cpu(prg, room_data.RUNTIME_OBJECT_STATES_CPU, bytes((0x82,)))
        put_cpu(prg, room_data.OBJECT_HANDLER_TABLE_CPU + 4, bytes((0x78, 0x56)))
        result = room_data.decode_objects(bytes(prg), 0)
        self.assertEqual(result["objects"][0]["runtime_type"], 0x82)
        self.assertEqual(result["objects"][0]["handler"], 0x5678)

    def test_decodes_initial_state_for_the_table_driven_type_range(self) -> None:
        prg = bytearray(32_768)
        put_cpu(prg, room_data.OBJECT_STREAM_CPU, bytes((0x12, 0, 0, 0xFF)))
        put_cpu(prg, room_data.RUNTIME_OBJECT_TYPES_CPU + 0x12, bytes((0x84,)))
        put_cpu(prg, room_data.RUNTIME_OBJECT_STATES_CPU + 0x12, bytes((0xA5,)))
        result = room_data.decode_objects(bytes(prg), 0)
        self.assertEqual(result["objects"][0]["initial_state"], 0xA5)

    def test_rejects_a_room_that_overflows_the_runtime_pool(self) -> None:
        prg = bytearray(32_768)
        records = bytes((0x01, 0, 0)) * (room_data.RUNTIME_OBJECT_RECORD_COUNT + 1)
        put_cpu(prg, room_data.OBJECT_STREAM_CPU, records + bytes((0xFF,)))
        with self.assertRaisesRegex(room_data.RoomDataError, "exceeds 24"):
            room_data.decode_objects(bytes(prg), 0)

    def test_rejects_an_encoded_type_outside_the_proven_table(self) -> None:
        prg = bytearray(32_768)
        put_cpu(prg, room_data.OBJECT_STREAM_CPU, bytes((0x3D, 0, 0, 0xFF)))
        with self.assertRaisesRegex(room_data.RoomDataError, "offset.*invalid"):
            room_data.decode_objects(bytes(prg), 0)

    def test_object_stream_encoder_round_trips_terminated_triples(self) -> None:
        rooms = [{"objects": []} for _ in range(room_data.ROOM_COUNT)]
        rooms[0]["objects"] = [{"encoded_type": 0x12, "x": 3, "y": 4}]
        encoded = room_data.encode_object_stream(rooms)
        self.assertEqual(encoded[:5], bytes((0x12, 3, 4, 0xFF, 0xFF)))
        self.assertEqual(encoded.count(0xFF), room_data.ROOM_COUNT)

    def test_object_state_offsets_match_one_bit_per_static_object(self) -> None:
        prg = bytearray(32_768)
        rooms = [{"objects": []} for _ in range(room_data.ROOM_COUNT)]
        rooms[0]["objects"] = [{}] * 8
        rooms[1]["objects"] = [{}] * 9
        offsets = [0, 1, 3] + [3] * (room_data.ROOM_COUNT - 2)
        put_cpu(prg, room_data.ROOM_OBJECT_STATE_OFFSETS_CPU, bytes(offsets))
        self.assertEqual(
            room_data.parse_room_object_state_offsets(bytes(prg), rooms), offsets
        )

    def test_rejects_object_state_width_inconsistent_with_room_objects(self) -> None:
        prg = bytearray(32_768)
        rooms = [{"objects": []} for _ in range(room_data.ROOM_COUNT)]
        rooms[0]["objects"] = [{}] * 9
        offsets = [0, 1] + [1] * (room_data.ROOM_COUNT - 1)
        put_cpu(prg, room_data.ROOM_OBJECT_STATE_OFFSETS_CPU, bytes(offsets))
        with self.assertRaisesRegex(room_data.RoomDataError, "expected 2 for 9"):
            room_data.parse_room_object_state_offsets(bytes(prg), rooms)

    def test_mutable_cell_offsets_match_persistent_cell_count(self) -> None:
        prg = bytearray(32_768)
        empty_grid = [[0] * room_data.ROOM_WIDTH for _ in range(room_data.ROOM_HEIGHT)]
        rooms = [{"cells": [row[:] for row in empty_grid]} for _ in range(room_data.ROOM_COUNT)]
        for column, value in enumerate(sorted(room_data.PERSISTENT_MUTABLE_CELL_VALUES)):
            rooms[0]["cells"][0][column] = value
        offsets = [0, 1] + [1] * (room_data.ROOM_COUNT - 2) + [4]
        put_cpu(prg, room_data.ROOM_MUTABLE_CELL_STATE_OFFSETS_CPU, bytes(offsets))
        self.assertEqual(
            room_data.parse_room_mutable_cell_state_offsets(bytes(prg), rooms), offsets
        )

    def test_final_room_reserves_three_mutable_state_bytes(self) -> None:
        prg = bytearray(32_768)
        empty_grid = [[0] * room_data.ROOM_WIDTH for _ in range(room_data.ROOM_HEIGHT)]
        rooms = [{"cells": [row[:] for row in empty_grid]} for _ in range(room_data.ROOM_COUNT)]
        offsets = [0] * room_data.ROOM_COUNT + [3]
        put_cpu(prg, room_data.ROOM_MUTABLE_CELL_STATE_OFFSETS_CPU, bytes(offsets))
        self.assertEqual(
            room_data.parse_room_mutable_cell_state_offsets(bytes(prg), rooms)[-1], 3
        )

    def test_rejects_mutable_state_width_that_does_not_match_cells(self) -> None:
        prg = bytearray(32_768)
        empty_grid = [[0] * room_data.ROOM_WIDTH for _ in range(room_data.ROOM_HEIGHT)]
        rooms = [{"cells": [row[:] for row in empty_grid]} for _ in range(room_data.ROOM_COUNT)]
        rooms[0]["cells"][0][0] = 0x29
        offsets = [0] * room_data.ROOM_COUNT + [3]
        put_cpu(prg, room_data.ROOM_MUTABLE_CELL_STATE_OFFSETS_CPU, bytes(offsets))
        with self.assertRaisesRegex(room_data.RoomDataError, "expected 1 for 1"):
            room_data.parse_room_mutable_cell_state_offsets(bytes(prg), rooms)

    def test_room_object_count_and_stride_tables_match_runtime_layout(self) -> None:
        prg = bytearray(32_768)
        rooms = [{"objects": []} for _ in range(room_data.ROOM_COUNT)]
        rooms[0]["objects"] = [{}] * 3
        counts = bytes((3,)) + bytes(room_data.ROOM_COUNT - 1)
        put_cpu(prg, room_data.ROOM_OBJECT_COUNTS_CPU, counts)
        put_cpu(
            prg,
            room_data.RUNTIME_OBJECT_OFFSETS_CPU,
            bytes(count * 6 for count in range(room_data.RUNTIME_OBJECT_OFFSET_COUNT)),
        )
        self.assertEqual(room_data.parse_room_object_counts(bytes(prg), rooms)[0], 3)
        self.assertEqual(room_data.parse_runtime_object_offsets(bytes(prg))[-1], 144)

    def test_object_state_bits_remove_corresponding_static_records(self) -> None:
        objects = [{"encoded_type": index} for index in range(9)]
        active = room_data.apply_room_object_state(objects, bytes((0b00000010, 1)))
        self.assertEqual([item["encoded_type"] for item in active], [0, 2, 3, 4, 5, 6, 7])

    def test_mutable_cell_state_restores_both_visual_forms(self) -> None:
        cells = bytearray(room_data.ROOM_SIZE)
        cells[21] = 0x19
        cells[20] = 0x16
        restored = room_data.apply_room_mutable_cell_state(bytes(cells), bytes((1,)))
        self.assertEqual((restored[21], restored[41]), (0x62, 0x63))
        cells = bytearray(room_data.ROOM_SIZE)
        cells[40] = 0x54
        restored = room_data.apply_room_mutable_cell_state(bytes(cells), bytes((1,)))
        self.assertEqual((restored[40], restored[60]), (0x54, 0x55))

    def test_cell_markers_spawn_scaled_runtime_objects(self) -> None:
        cells = bytearray(room_data.ROOM_SIZE)
        cells[22] = 0x51
        converted, records = room_data.spawn_room_cell_objects(bytes(cells), 2)
        self.assertEqual(converted[22], 0x53)
        self.assertEqual(
            records,
            [{
                "runtime_offset": 12,
                "runtime_type": 0xA3,
                "pixel_x": 32,
                "pixel_y": 8,
                "initial_state": 0xFF,
            }],
        )


class RoomAttributeTests(unittest.TestCase):
    def attribute_prg(self, value: int = 0, initial: int = 0) -> bytearray:
        prg = bytearray(32_768)
        put_cpu(prg, room_data.INITIAL_ROOM_ATTRIBUTES_CPU, bytes([initial]) * 16)
        put_cpu(prg, room_data.ROOM_ATTRIBUTE_MASKS_CPU, bytes((0x03, 0x0C, 0x30, 0xC0)))
        values = bytearray(100)
        values[1] = value
        put_cpu(prg, room_data.ROOM_CELL_ATTRIBUTES_CPU, values)
        return prg

    def test_maps_cells_across_both_nametable_attribute_buffers(self) -> None:
        self.assertEqual(room_data.room_attribute_position(0, 0), (9, 2))
        self.assertEqual(room_data.room_attribute_position(14, 0), (72, 2))
        self.assertEqual(room_data.room_attribute_position(19, 19), (114, 3))

    def test_attribute_value_is_masked_into_its_quadrant(self) -> None:
        prg = self.attribute_prg(0xFF)
        cells = bytearray(room_data.ROOM_SIZE)
        cells[0] = 1
        attributes = room_data.build_room_attributes(bytes(prg), bytes(cells))
        self.assertEqual(attributes[9], 0x30)

    def test_preserving_cell_keeps_initial_attribute_byte(self) -> None:
        prg = self.attribute_prg(0, initial=0xFF)
        cells = bytearray(room_data.ROOM_SIZE)
        cells[0] = 0x53
        cells[1] = 0x53
        attributes = room_data.build_room_attributes(bytes(prg), bytes(cells))
        self.assertEqual(attributes[9], 0xFF)

    def test_rejects_cell_outside_attribute_value_table(self) -> None:
        prg = self.attribute_prg(0)
        cells = bytearray(room_data.ROOM_SIZE)
        cells[0] = 0xFE
        with self.assertRaisesRegex(room_data.RoomDataError, "exceeds attribute table"):
            room_data.build_room_attributes(bytes(prg), bytes(cells))


if __name__ == "__main__":
    unittest.main()

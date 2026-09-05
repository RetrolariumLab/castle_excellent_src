from __future__ import annotations

import unittest

from scripts import object_catalog


class ObjectCatalogTests(unittest.TestCase):
    def test_groups_static_objects_by_runtime_type_and_room(self) -> None:
        rooms = [
            {"objects": [
                {"runtime_type": 0x81, "encoded_type": 0x0E},
                {"runtime_type": 0x81, "encoded_type": 0x0F},
            ]},
            {"objects": [{"runtime_type": 0x82, "encoded_type": 0x10}]},
            {"objects": [{"runtime_type": 0x81, "encoded_type": 0x0E}]},
        ]
        counts, room_numbers, encoded_counts = object_catalog.group_static_objects(rooms)
        self.assertEqual(counts, {0x81: 3, 0x82: 1})
        self.assertEqual(room_numbers, {0x81: {1, 3}, 0x82: {2}})
        self.assertEqual(encoded_counts, {0x0E: 2, 0x0F: 1, 0x10: 1})

    def test_rejects_static_records_without_integer_types(self) -> None:
        with self.assertRaises(object_catalog.ObjectCatalogError):
            object_catalog.group_static_objects(
                [{"objects": [{"runtime_type": "81", "encoded_type": 0x0E}]}]
            )

    def test_catalog_runtime_domain_matches_both_handler_tables(self) -> None:
        self.assertEqual(object_catalog.RUNTIME_TYPE_COUNT, 42)
        self.assertEqual(
            len(object_catalog.runtime_object_dispatch.EXPECTED_HANDLER_POINTERS), 42
        )
        self.assertEqual(
            len(object_catalog.frame_sprites.EXPECTED_OBJECT_SPRITE_HANDLERS), 42
        )

    def test_five_cell_markers_create_runtime_types_a1_through_a5(self) -> None:
        self.assertEqual(
            object_catalog.EXPECTED_CELL_TYPE_COUNTS,
            {0xA1: 73, 0xA2: 47, 0xA3: 40, 0xA4: 8, 0xA5: 8},
        )
        self.assertEqual(sum(object_catalog.EXPECTED_CELL_TYPE_COUNTS.values()), 176)

    def test_unsourced_runtime_domain_is_explicit(self) -> None:
        self.assertEqual(
            object_catalog.EXPECTED_UNSOURCED_RUNTIME_TYPES,
            (0x80, 0x9B, 0x9C, 0x9D, 0x9E, 0xA0, 0xA6, 0xA7, 0xA8, 0xA9),
        )


if __name__ == "__main__":
    unittest.main()

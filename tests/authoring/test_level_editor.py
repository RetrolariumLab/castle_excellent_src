from __future__ import annotations

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]

from scripts.authoring import level_editor
from scripts.authoring import room_data
def put_cpu(prg: bytearray, address: int, payload: bytes) -> None:
    offset = room_data.cpu_offset(address)
    prg[offset:offset + len(payload)] = payload


def minimal_prg() -> bytes:
    prg = bytearray(32_768)
    put_cpu(prg, room_data.CODEBOOK_CPU, b"\x00" b"0\0" b"\xff")
    return bytes(prg)


def empty_workspace(profile: str = "test-profile") -> dict[str, object]:
    grid = [[0] * room_data.ROOM_WIDTH for _ in range(room_data.ROOM_HEIGHT)]
    return {
        "schema_version": 1,
        "format": "castle-excellent-levels",
        "profile": profile,
        "width": room_data.ROOM_WIDTH,
        "height": room_data.ROOM_HEIGHT,
        "rooms": [
            {"number": index + 1, "cells": [row[:] for row in grid], "objects": []}
            for index in range(room_data.ROOM_COUNT)
        ],
    }


class LevelEditorTests(unittest.TestCase):
    def test_project_configuration_matches_reconstructed_capacities(self) -> None:
        config, profile = level_editor.load_authoring(
            ROOT / "config/authoring/levels.json",
            "castle-excellent-japan-hsp-05",
        )
        self.assertEqual(profile["status"], "supported")
        self.assertEqual(config["objects"]["stream_capacity"], 2449)
        self.assertEqual(config["room_streams"]["bank_split_index"], 67)

    def test_complete_workspace_validates_all_rooms(self) -> None:
        rooms = level_editor.validate_workspace(
            empty_workspace(),
            "test-profile",
            minimal_prg(),
        )
        self.assertEqual(len(rooms), room_data.ROOM_COUNT)
        self.assertEqual(len(rooms[0]["cells"]), room_data.ROOM_SIZE)

    def test_workspace_rejects_cells_without_a_compression_code(self) -> None:
        workspace = empty_workspace()
        workspace["rooms"][0]["cells"][0][0] = 1
        with self.assertRaisesRegex(level_editor.LevelEditorError, "compression code"):
            level_editor.validate_workspace(workspace, "test-profile", minimal_prg())

    def test_workspace_rejects_static_and_cell_object_pool_overflow(self) -> None:
        workspace = empty_workspace()
        workspace["rooms"][0]["objects"] = [
            {"encoded_type": 0, "x": 0, "y": 0}
            for _ in range(room_data.RUNTIME_OBJECT_RECORD_COUNT)
        ]
        workspace["rooms"][0]["cells"][0][0] = 0x4B
        prg = bytearray(minimal_prg())
        put_cpu(prg, room_data.CODEBOOK_CPU, b"\x00" b"0\0" b"\x4b" b"10\0" b"\xff")
        with self.assertRaisesRegex(room_data.RoomDataError, "runtime object pool"):
            level_editor.validate_workspace(workspace, "test-profile", bytes(prg))

    def test_persistent_state_capacity_is_enforced(self) -> None:
        rooms = [{"cells": bytes(room_data.ROOM_SIZE), "objects": [{}] * 9}] * 100
        with self.assertRaisesRegex(level_editor.LevelEditorError, "capacity is 141"):
            level_editor.cumulative_state_offsets(
                rooms,
                mutable=False,
                capacity=141,
            )


if __name__ == "__main__":
    unittest.main()

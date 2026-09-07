from pathlib import Path
import unittest

from scripts.validation.objects import inventory_collectible_handlers as inventory_collectibles


ROOT = Path(__file__).resolve().parents[3]


class InventoryCollectibleHandlerTests(unittest.TestCase):
    def test_each_runtime_type_selects_one_unique_counter(self) -> None:
        for runtime_type, index in inventory_collectibles.INVENTORY_INDEX_BY_TYPE.items():
            with self.subTest(runtime_type=runtime_type):
                result = inventory_collectibles.collect_inventory_object(
                    runtime_type, True, (0, 0, 0, 0, 0, 0)
                )
                self.assertEqual(result.inventory[index], 1)
                self.assertEqual(sum(result.inventory), 1)

    def test_far_player_preserves_inventory_and_object(self) -> None:
        inventory = (1, 2, 3, 4, 5, 6)
        result = inventory_collectibles.collect_inventory_object(0x90, False, inventory)
        self.assertEqual(result.inventory, inventory)
        self.assertFalse(result.collected)
        self.assertIsNone(result.runtime_type)

    def test_pickup_wraps_counter_and_transforms_object(self) -> None:
        result = inventory_collectibles.collect_inventory_object(
            0x94, True, (0, 0, 0, 0, 0, 0xFF)
        )
        self.assertEqual(result.inventory[5], 0)
        self.assertEqual(
            (result.score_award, result.runtime_type, result.runtime_state, result.lifetime),
            (10, 0xA9, 5, 20),
        )
        self.assertTrue(result.play_sound_effect)

    def test_invalid_type_and_inventory_are_rejected(self) -> None:
        with self.assertRaises(inventory_collectibles.InventoryCollectibleError):
            inventory_collectibles.collect_inventory_object(0x8F, True, (0,) * 6)
        with self.assertRaises(inventory_collectibles.InventoryCollectibleError):
            inventory_collectibles.collect_inventory_object(0x90, True, (0,) * 5)

    def test_reference_rom_and_exhaustive_contracts(self) -> None:
        prg = inventory_collectibles.extract_prg(
            (ROOT / "Castle Excellent (J).nes").read_bytes()
        )
        report = inventory_collectibles.validate_rom_contract(prg)
        self.assertEqual(report["bytes"], 105)
        self.assertEqual(len(report["handler_targets"]), 6)
        self.assertEqual(
            inventory_collectibles.validate_exhaustive_contract(),
            {"runtime_types": 6, "cases": 3_072},
        )


if __name__ == "__main__":
    unittest.main()

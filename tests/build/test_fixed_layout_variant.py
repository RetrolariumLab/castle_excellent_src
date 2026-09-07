from __future__ import annotations

import hashlib
import unittest



from scripts.build import fixed_layout_variant as fixed
class FixedLayoutVariantTests(unittest.TestCase):
    def variant(self, image: bytes) -> dict[str, object]:
        changed = bytearray(image)
        changed[16 + 3] = 2
        return {
            "id": "sample",
            "base_sha256": hashlib.sha256(image).hexdigest(),
            "output_sha1": hashlib.sha1(changed).hexdigest(),
            "output_sha256": hashlib.sha256(changed).hexdigest(),
            "changes": [{
                "region": "prg",
                "offset": "0x3",
                "cpu_address": "0x8003",
                "original_hex": "01",
                "replacement_hex": "02",
            }],
        }

    def test_applies_only_the_manifest_owned_byte(self) -> None:
        image = b"NES\x1a" + bytes((2, 4, 0, 0)) + bytes(8) + b"\x00\x00\x00\x01" + bytes(65_532)
        output = fixed.apply_variant(image, self.variant(image))
        self.assertEqual(output[19], 2)
        self.assertEqual(sum(left != right for left, right in zip(image, output)), 1)

    def test_rejects_an_unexpected_original_byte(self) -> None:
        image = b"NES\x1a" + bytes((2, 4, 0, 0)) + bytes(8) + bytes(65_536)
        with self.assertRaisesRegex(fixed.FixedLayoutError, "original bytes"):
            fixed.apply_variant(image, self.variant(image))


if __name__ == "__main__":
    unittest.main()

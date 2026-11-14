import struct
import unittest
from inspect_demo import inspect_map, inspect_art, inspect_sounds


class Formats(unittest.TestCase):
    def test_empty_v7_map(self):
        data = struct.pack('<4ihh3H', 7, 1, 2, 3, 0, -1, 0, 0, 0)
        result = inspect_map(data)
        self.assertEqual(result['trailing_bytes'], 0)
        self.assertEqual(result['start']['x'], 1)

    def test_truncated_map(self):
        data = struct.pack('<4ihhH', 7, 0, 0, 0, 0, 0, 1)
        with self.assertRaises(ValueError):
            inspect_map(data)

    def test_art_uses_range_not_legacy_total(self):
        data = struct.pack('<4iHHI', 1, 999, 255, 255, 2, 3, 0)+bytes(6)
        self.assertEqual(inspect_art(data)['trailing_bytes'], 0)
        self.assertEqual(inspect_art(data)['populated'], 1)

    def test_sound_bank(self):
        data = bytes(4096)+struct.pack('<III', 0, 100, 9)+bytes(4096-12)
        self.assertEqual(inspect_sounds(data)['entries'][0]['bytes'], 100)

    def test_out_of_bounds_sound(self):
        data = bytes(4096)+struct.pack('<III', 0, 4097, 9)+bytes(4096-12)
        with self.assertRaises(ValueError):
            inspect_sounds(data)

    def test_hidden_sound_directory_data(self):
        data = bytes(4096)+struct.pack('<III', 0, 100, 9)+bytes(12)+b'x'+bytes(4096-25)
        with self.assertRaises(ValueError):
            inspect_sounds(data)


if __name__ == '__main__':
    unittest.main()

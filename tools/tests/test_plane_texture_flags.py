"""Verify complete texture-flag coverage and independent transform properties."""
import unittest

from check_ceilscan_tail import CASES as CEILING_CASES, transformed
from check_florscan_tail import CASES as FLOOR_CASES


class PlaneTextureFlagSpecification(unittest.TestCase):
    def test_both_fixtures_cover_every_orientation_combination(self):
        expected = set(range(0, 64, 4))
        self.assertEqual({case.flags for case in CEILING_CASES}, expected)
        self.assertEqual({case.flags for case in FLOOR_CASES}, expected)

    def test_double_scale_increments_both_texture_shifts(self):
        for flags in range(0, 64, 16):
            normal, _ = transformed(flags)
            doubled, _ = transformed(flags | 8)
            self.assertEqual(doubled, tuple(value + 1 for value in normal))

    def test_transpose_does_not_change_texture_shift_counts(self):
        for flags in range(0, 64, 8):
            self.assertEqual(transformed(flags)[0], transformed(flags | 4)[0])


if __name__ == '__main__':
    unittest.main()

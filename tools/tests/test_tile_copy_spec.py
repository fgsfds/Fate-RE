"""Independent expected-state cases; no original executable or compiler required."""
from struct import pack
import unittest

from check_copytilepiece_candidate import (
    SOURCE_TILE, DESTINATION_TILE, SOURCE_POINTER, DESTINATION_POINTER,
    boundary_cases, check_reference, model,
)
from differential import Observation


def case(**changes):
    return dict(name='specification', sizes=(2, 2, 2, 2),
                pixels=(b'\x01\x02\x03\x04', b'\xaa' * 4),
                source=(0, 0), copy=(2, 2), destination=(0, 0)) | changes


class TileCopySpecification(unittest.TestCase):
    def test_column_major_addressing_and_transparency(self):
        result = model(case(sizes=(2, 2, 3, 3), pixels=(b'\x01\xff\x03\x04', b'\xaa' * 9),
                            destination=(1, 1)))
        self.assertEqual(result.memory['destination'], b'\xaa\xaa\xaa\xaa\x01\xaa\xaa\x03\x04')

    def test_wrap_and_negative_destination_clipping(self):
        result = model(case(sizes=(2, 2, 2, 3), pixels=(bytes((1, 2, 3, 4)), b'\xaa' * 6),
                            source=(1, 1), copy=(3, 3), destination=(-1, 0)))
        self.assertEqual(result.memory['destination'], bytes((2, 1, 2, 4, 3, 4)))

    def test_lazy_load_order_and_pointers_even_when_no_pixels_are_copied(self):
        result = model(case(copy=(0, 2), lazy=True))
        self.assertEqual(result.calls, (('loadtile', SOURCE_TILE), ('loadtile', DESTINATION_TILE)))
        self.assertEqual(result.memory['tile_pointers'], pack('<2I', SOURCE_POINTER, DESTINATION_POINTER))
        self.assertEqual(result.memory['destination'], b'\xaa' * 4)

    def test_invalid_dimensions_exit_before_loading_either_tile(self):
        for sizes in ((0, 2, 2, 2), (2, -1, 2, 2), (2, 2, 0, 2), (2, 2, 2, -1)):
            with self.subTest(sizes=sizes):
                result = model(case(sizes=sizes, lazy=True))
                self.assertEqual(result.calls, ())
                self.assertEqual(result.memory['tile_pointers'], bytes(8))
                self.assertEqual(result.memory['destination'], b'\xaa' * 4)

    def test_negative_copy_counts_do_not_skip_lazy_loading(self):
        for counts in ((-1, 2), (2, -1)):
            with self.subTest(counts=counts):
                result = model(case(copy=counts, unloaded_tiles=(DESTINATION_TILE,)))
                self.assertEqual(result.calls, (('loadtile', DESTINATION_TILE),))
                self.assertEqual(result.memory['destination'], b'\xaa' * 4)

    def test_forward_overlap_is_not_memmove(self):
        overlap = next(row for row in boundary_cases() if row['name'].startswith('forward overlap'))
        result = model(overlap)
        self.assertEqual(result.memory['destination'], b'\x01' * 4)
        self.assertNotEqual(result.memory['destination'], b'\x01\x09\x0a\x0b')

    def test_all_unsigned_pixel_values_copy_except_255(self):
        scenario = case(sizes=(16, 16, 16, 16),
                        pixels=(bytes(range(256)), b'\x55' * 256), copy=(16, 16))
        self.assertEqual(model(scenario).memory['destination'], bytes(range(255)) + b'\x55')

    def test_specification_rejects_equal_but_wrong_observations(self):
        # Even identical reference/candidate execution must satisfy the oracle.
        scenario = case()
        expected = model(scenario)
        wrong = Observation({}, {**expected.memory, 'destination': b'\xaa' * 4}, ())
        with self.assertRaisesRegex(AssertionError, 'tile-copy specification'):
            check_reference(scenario, wrong)


if __name__ == '__main__':
    unittest.main()

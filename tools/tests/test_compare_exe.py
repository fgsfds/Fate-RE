import unittest
from compare_exe import compare


class ExactComparison(unittest.TestCase):
    def test_identical(self):
        self.assertTrue(compare(b'abc', b'abc')['identical'])

    def test_changed_ranges(self):
        result = compare(b'abcdefg', b'aXYdeZg')
        self.assertFalse(result['identical'])
        self.assertEqual(result['differing_bytes'], 3)
        self.assertEqual(result['first_100_ranges_end_exclusive'], [[1, 3], [5, 6]])

    def test_truncation_and_appending(self):
        for a, b in [(b'abc', b'ab'), (b'ab', b'abc')]:
            result = compare(a, b)
            self.assertFalse(result['identical'])
            self.assertEqual(result['first_100_ranges_end_exclusive'], [[2, 3]])

    def test_empty(self):
        self.assertEqual(compare(b'', b'')['differing_bytes'], 0)

    def test_range_output_is_bounded(self):
        result = compare(b'aa'*150, b'ab'*150)
        self.assertEqual(result['differing_range_count'], 150)
        self.assertEqual(len(result['first_100_ranges_end_exclusive']), 100)

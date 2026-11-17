"""Specification cases for Fate's older nearest-square-root table."""
import unittest

from check_ksqrt import table_value


class SquareRootTableSpecification(unittest.TestCase):
    def test_perfect_squares_are_exact_at_ten_fractional_bits(self):
        for root in range(46):
            self.assertEqual(table_value(root * root), root * 1024)

    def test_non_square_entries_choose_closest_squared_value(self):
        self.assertEqual(table_value(2), 1448)
        self.assertEqual(table_value(3), 1774)

    def test_all_entries_are_unsigned_words_and_local_squared_error_minima(self):
        for index in range(2048):
            root = table_value(index)
            square = index << 20
            error = abs(root * root - square)
            self.assertTrue(0 <= root <= 65535)
            if root:
                self.assertLess(error, abs((root - 1) ** 2 - square))
            self.assertLess(error, abs((root + 1) ** 2 - square))


if __name__ == '__main__':
    unittest.main()

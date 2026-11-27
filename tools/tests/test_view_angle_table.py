"""Independent fixed-point interpolation examples, without compiler or executable."""
from struct import pack
import unittest
from unittest.mock import patch

from check_view_angle_table import CAPACITY, check_reference, model
from differential import Observation


def scenario(columns, reciprocal):
    return dict(name='specification', columns=columns, reciprocal=reciprocal, table_seed=1)


class ViewAngleSpecification(unittest.TestCase):
    def test_nonpositive_columns_leave_output_untouched(self):
        for columns in (-1, 0):
            self.assertEqual(model(scenario(columns, 65536)), b'\xa5' * (CAPACITY * 2))

    def test_zero_step_repeats_first_angle(self):
        with patch('check_view_angle_table.angle_table', return_value=[640] * CAPACITY):
            result = model(scenario(3, 0))
        self.assertEqual(result[:6], pack('<3h', 10, 10, 10))
        self.assertEqual(result[6:], b'\xa5' * (CAPACITY * 2 - 6))

    def test_fractional_interpolation_rounds_signed_products_down(self):
        for next_angle, expected in ((32767, 511), (-32768, -512)):
            with patch('check_view_angle_table.angle_table',
                       return_value=[0, next_angle] + [0] * (CAPACITY - 2)):
                result = model(scenario(2, 13421772))  # step 65535: just below one.
            self.assertEqual(result[:4], pack('<2h', 0, expected))

    def test_integer_step_advances_table_without_interpolation(self):
        with patch('check_view_angle_table.angle_table',
                   return_value=[0, 64, 128] + [0] * (CAPACITY - 3)):
            result = model(scenario(3, 13421773))  # step 65536: exactly one.
        self.assertEqual(result[:6], pack('<3h', 0, 1, 2))

    def test_oracle_rejects_equal_but_wrong_execution(self):
        with self.assertRaisesRegex(AssertionError, 'view-angle interpolation'):
            check_reference(scenario(1, 0), Observation({}, {'columns': b'\xa5' * (CAPACITY * 2)}, ()))


if __name__ == '__main__':
    unittest.main()

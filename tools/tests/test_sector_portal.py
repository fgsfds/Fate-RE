"""Independent portal-search oracle tests; no original executable required."""
import unittest

from check_sector_portal import FIRST, SECOND, check_reference, expected_result, scenario
from differential import Observation


class SectorPortalSpecification(unittest.TestCase):
    def test_scan_smaller_sector_even_when_only_larger_has_portal(self):
        self.assertEqual(expected_result(scenario('first smaller', [-1], [FIRST, -1])), 0)
        self.assertEqual(expected_result(scenario('second smaller', [SECOND, -1], [-1])), 0)

    def test_equal_counts_scan_second(self):
        self.assertEqual(expected_result(scenario('first only', [SECOND], [-1])), 0)
        self.assertEqual(expected_result(scenario('second only', [-1], [FIRST])), 1)

    def test_empty_or_negative_selected_count_does_not_scan(self):
        for count in (0, -1):
            self.assertEqual(expected_result(scenario('empty', [SECOND], [FIRST],
                                                     count_first=count)), 0)

    def test_each_end_of_smaller_sector_can_match(self):
        for walls in ([SECOND, -1], [-1, SECOND]):
            self.assertEqual(expected_result(scenario('first smaller', walls, [-1] * 3)), 1)
        for walls in ([FIRST, -1], [-1, FIRST]):
            self.assertEqual(expected_result(scenario('second smaller', [-1] * 3, walls)), 1)

    def test_oracle_rejects_equal_but_wrong_execution(self):
        case = scenario('portal', [-1], [FIRST])
        with self.assertRaisesRegex(AssertionError, 'portal search expected'):
            check_reference(case, Observation({'eax': 0}, {}, ()))


if __name__ == '__main__':
    unittest.main()

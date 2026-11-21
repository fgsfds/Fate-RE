"""Oracle tests for the historical wall-bunch overlap and scan selection rules."""
import unittest

from check_bunchfront import SCAN_STRIDE, SECOND_SCAN, check_reference, model, scenario
from differential import Observation


class BunchfrontSpecification(unittest.TestCase):
    def test_adjacent_nonoverlapping_bunches_do_not_call_classifier(self):
        for first, second in (([(0, 2)], [(3, 8)]), ([(3, 8)], [(0, 2)])):
            self.assertEqual(model(scenario('disjoint', first, second)), (0xffffffff, ()))

    def test_shared_endpoint_is_overlap(self):
        self.assertEqual(model(scenario('endpoint', [(0, 3)], [(3, 8)], 0)),
                         (0, (('wallfront', 0, SECOND_SCAN),)))

    def test_equal_starts_choose_first_bunch_as_first_argument(self):
        self.assertEqual(model(scenario('equal', [(2, 4)], [(2, 6)])),
                         (1, (('wallfront', 0, SECOND_SCAN),)))

    def test_advance_second_bunch_to_overlapping_scan(self):
        case = scenario('advance second', [(8, 10)],
                        [(0, 2), (3, 5), (6, 9), (10, 13)])
        self.assertEqual(model(case), (1, (('wallfront', 0, SECOND_SCAN + 2 * SCAN_STRIDE),)))

    def test_advance_first_bunch_and_forward_negative_classification(self):
        case = scenario('advance first', [(0, 2), (3, 5), (6, 9), (10, 13)],
                        [(8, 10)], -1)
        self.assertEqual(model(case), (0xffffffff, (('wallfront', 2 * SCAN_STRIDE, SECOND_SCAN),)))

    def test_equal_but_wrong_execution_still_fails_specification(self):
        case = scenario('overlap', [(0, 10)], [(2, 8)])
        with self.assertRaisesRegex(AssertionError, 'bunchfront specification'):
            check_reference(case, Observation({'eax': 1}, {}, ()))


if __name__ == '__main__':
    unittest.main()

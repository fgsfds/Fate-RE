import unittest

from check_mouse_button_menu import expected_bindings, named_cases, randomized_cases


class MouseButtonOwnership(unittest.TestCase):
    def test_button_priority_and_unbound_values(self):
        for mask, expected in ((0, (255, 25, 200)), (1, (24, 25, 200)),
                               (2, (255, 25, 24)), (4, (255, 24, 200)),
                               (3, (24, 25, 200)), (0x8000, (255, 24, 200))):
            with self.subTest(mask=mask):
                scenario = dict(bindings=(255, 25, 200),
                                events=[dict(selection=24, buttons=mask, idle=0)])
                self.assertEqual(expected_bindings(scenario), bytes(expected))

    def test_last_owner_wins_independent_of_row_order(self):
        scenario = list(named_cases())[-1]
        self.assertEqual(expected_bindings(scenario), bytes((1, 1, 2)))

    def test_duplicate_initial_bindings_remain_until_explicitly_reassigned(self):
        self.assertEqual(expected_bindings(dict(bindings=(4, 4, 4), events=[])), bytes((4, 4, 4)))

    def test_seeded_edits_are_repeatable(self):
        self.assertEqual(list(randomized_cases(8, 123)), list(randomized_cases(8, 123)))
        self.assertNotEqual(list(randomized_cases(8, 123)), list(randomized_cases(8, 124)))


if __name__ == '__main__':
    unittest.main()

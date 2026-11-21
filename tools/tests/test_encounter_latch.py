"""Structure-only guards for the encounter latch fixture."""
import unittest

import check_encounter_latch as fixture


class EncounterLatchFixtureTests(unittest.TestCase):
    def test_natural_role_permutation_only_swaps_index_and_zero(self):
        parts = (b'latch', b'index', b'zero', b'tag')
        self.assertEqual(fixture.linked_order(parts), b'latchindexzerotag')
        self.assertEqual(fixture.natural_order(parts), b'latchzeroindextag')
        self.assertEqual(len(fixture.linked_order(parts)), len(fixture.natural_order(parts)))
        with self.assertRaisesRegex(ValueError, 'four registered'):
            fixture.natural_order(parts[:3])

    def test_compiler_boundaries_are_decoded_from_the_public_entry(self):
        code = b'\x90\xb8'+bytes(4)+b'\xc3'
        fixture.validate_slice_boundaries(code, [(0,1), (1,6), (6,7)])
        with self.assertRaisesRegex(ValueError, 'slice boundary'):
            fixture.validate_slice_boundaries(code, [(2,6)])

    def test_raw_handoff_guard_rejects_changes(self):
        fixture.validate_handoff(bytes.fromhex('668b35f62701006685f6'))
        with self.assertRaisesRegex(ValueError, 'handoff'):
            fixture.validate_handoff(bytes.fromhex('668b35f62701006685f7'))

    def test_transfer_guard_accepts_expected_layout(self):
        fixture.validate_transfers(fixture.edge_fixture())

    def test_transfer_guard_rejects_wrong_exit_and_call(self):
        wrong_exit = bytearray(fixture.edge_fixture())
        wrong_exit[0x17] += 1
        with self.assertRaisesRegex(ValueError, 'branch target|exits|transfer target'):
            fixture.validate_transfers(wrong_exit)

        wrong_call = bytearray(fixture.edge_fixture())
        wrong_call[0x4b] += 1
        with self.assertRaisesRegex(ValueError, 'call|transfer target'):
            fixture.validate_transfers(wrong_call)

    def test_mutations_pin_real_instruction_operands(self):
        code = fixture.edge_fixture()
        changed_state = fixture.mutate(code, 'state')
        changed_sound = fixture.mutate(code, 'sound')
        self.assertEqual(changed_state[0x38], 4)
        self.assertEqual(changed_sound[0x68], 0x8f)
        with self.assertRaisesRegex(ValueError, 'unknown'):
            fixture.mutate(code, 'observation')


if __name__ == '__main__':
    unittest.main()

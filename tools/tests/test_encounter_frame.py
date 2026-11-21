"""Self-contained structural tests for the encounter frame fixture."""
import struct
import unittest

import check_encounter_frame as fixture


class EncounterFrameFixtureTests(unittest.TestCase):
    def test_prefix_and_return_glue_keep_exact_asm_slots(self):
        initializer = bytes(range(39))
        prefix = fixture.compose_prefix(b'\x53\x51\x52\x56\x57', b'\x55', initializer)
        self.assertEqual(len(prefix), 45)
        self.assertEqual(prefix[:6], b'\x53\x51\x52\x56\x57\x55')
        self.assertEqual(prefix[6:], initializer)
        ret = fixture.compose_return(b'\x81\xc4\xb8\x00\x00\x00', b'\x5d', b'\x5f\x5e\x5a\x59\x5b\xc3')
        self.assertEqual(len(ret), 13)
        self.assertEqual(ret[6], 0x5d)
        with self.assertRaisesRegex(ValueError, 'entry prefix'):
            fixture.compose_prefix(b'\x53', b'\x55', initializer)
        with self.assertRaisesRegex(ValueError, 'return components'):
            fixture.compose_return(b'\x90', b'\x5d', b'\x90' * 6)

    def test_saved_slots_start_as_distinct_poison(self):
        saved = (1, 2, 3, 4, 5, 6)
        frame_base, scratch, expected, poison, frame = fixture.frame_inputs(0xa5, saved)
        self.assertEqual(expected, saved)
        self.assertEqual(len(set(poison)), fixture.SAVED_COUNT)
        self.assertTrue(set(poison).isdisjoint(saved))
        self.assertEqual(struct.unpack_from('<6I', frame, fixture.FRAME_BYTES), poison)
        self.assertEqual(len(scratch), fixture.FRAME_BYTES)
        self.assertEqual(frame_base, fixture.CALLER_SP - 208)

    def test_typed_code_fields_use_code_segment_base_only(self):
        init = bytes(39)
        loaded = fixture.materialize_code_fields(init, fixture.CODE_FIELDS)
        self.assertEqual(int.from_bytes(loaded[14:18], 'little'), 0x1de8e)
        self.assertEqual(int.from_bytes(loaded[33:37], 'little'), 0x1df0e)
        mutant = fixture.mutate_first_code_pointer(loaded, fixture.CODE_FIELDS)
        self.assertEqual(int.from_bytes(mutant[14:18], 'little'), 0x1de8f)
        self.assertEqual(int.from_bytes(mutant[33:37], 'little'), 0x1df0e)
        with self.assertRaisesRegex(ValueError, 'relocation metadata'):
            fixture.materialize_code_fields(init, {14: 0xde8e})

    def test_retained_ebp_guards_and_pop_mutation(self):
        blob = bytearray(0x43a17)
        blob[0x43533] = 0x55
        blob[0x43a16] = 0x5d
        fixture.validate_asm_guards(blob)
        blob[0x43a16] = 0x5f
        with self.assertRaisesRegex(ValueError, 'PUSH/POP EBP'):
            fixture.validate_asm_guards(blob)
        ret = b'\x81\xc4\xb8\x00\x00\x00\x5d\x5f\x5e\x5a\x59\x5b\xc3'
        mutant = fixture.mutate_pop_edi(ret)
        self.assertEqual(mutant[7], 0x5e)
        with self.assertRaisesRegex(ValueError, 'mutation anchor'):
            fixture.mutate_pop_edi(ret[:7] + b'\x5e' + ret[8:])

    def test_public_slice_boundaries_must_be_instruction_boundaries(self):
        public = b'\x90' * fixture.PUBLIC_SIZE
        fixture.validate_boundaries(public, [(0, 5), (5, 44), (1213, 1219), (1219, 1225)])
        with self.assertRaisesRegex(ValueError, 'splits a source instruction'):
            fixture.validate_boundaries(b'\xb8\x00\x00\x00\x00\x90', [(1, 5)])


if __name__ == '__main__':
    unittest.main()

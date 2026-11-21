import unittest
from unittest.mock import patch

from verify_c_leaf import LEAF_SECTION_BRANCHES, bind_section_branches


class SectionBranches(unittest.TestCase):
    def bind(self, code, branches, *, extent=None, start=0, end=None, fields=None, address=0x1000):
        value = bytearray(code)
        metadata = (len(code) if extent is None else extent, 64, branches)
        with patch.dict(LEAF_SECTION_BRANCHES, {'public': metadata}):
            bind_section_branches(value, 'public', address, {'public': 0x1000},
                                  set() if fields is None else fields, start,
                                  len(code) if end is None else end)
        return bytes(value)

    def test_rebinds_short_jump_and_conditional_operands_only(self):
        code = bytes.fromhex('eb 02 75 00 c3')
        result = self.bind(code, {0: (b'\xeb', 4, 7), 2: (b'\x75', 4, 9)})
        self.assertEqual(result, bytes.fromhex('eb 05 75 05 c3'))

    def test_rebinds_near_jump_and_conditional_operands_only(self):
        code = b'\xe9' + (6).to_bytes(4, 'little') + b'\x0f\x84' + bytes(4) + b'\xc3'
        result = self.bind(code, {0: (b'\xe9', 11, 20), 5: (b'\x0f\x84', 11, 30)})
        self.assertEqual(result[0], 0xe9)
        self.assertEqual(result[5:7], b'\x0f\x84')
        self.assertEqual(int.from_bytes(result[1:5], 'little', signed=True), 15)
        self.assertEqual(int.from_bytes(result[7:11], 'little', signed=True), 19)

    def test_only_places_selected_sections_but_checks_all_source_targets(self):
        code = bytes.fromhex('eb 02 75 00 c3')
        specs = {0: (b'\xeb', 4, 7), 2: (b'\x75', 4, 9)}
        self.assertEqual(self.bind(code, specs, start=2, address=0xffe),
                         bytes.fromhex('eb 02 75 07 c3'))
        with self.assertRaisesRegex(ValueError, 'compiler target'):
            self.bind(code, {0: (b'\xeb', 3, 7)}, start=2)

    def test_rejects_opcode_changes_fixup_overlap_and_split_boundaries(self):
        for kwargs in ({'fields': {1}}, {'start': 1}, {'end': 1}):
            with self.subTest(kwargs=kwargs), self.assertRaises(ValueError):
                self.bind(bytes.fromhex('eb 00 c3'), {0: (b'\xeb', 2, 3)}, **kwargs)
        with self.assertRaisesRegex(ValueError, 'opcode'):
            self.bind(bytes.fromhex('75 00 c3'), {0: (b'\xeb', 2, 3)})
        with self.assertRaisesRegex(ValueError, 'Unsupported'):
            self.bind(bytes.fromhex('e8 00 00 00 00 c3'), {0: (b'\xe8', 5, 5)})

    def test_rejects_extent_target_bounds_and_operand_overflow(self):
        code = bytes.fromhex('eb 00 c3')
        for specs, kwargs in (({0: (b'\xeb', 2, 3)}, {'extent': 4}),
                              ({0: (b'\xeb', 3, 3)}, {}),
                              ({0: (b'\xeb', 2, 64)}, {}),
                              ({0: (b'\xeb', 2, 3)}, {'address': 0x2000})):
            with self.subTest(specs=specs, kwargs=kwargs), self.assertRaises(ValueError):
                self.bind(code, specs, **kwargs)


class SectionBindingIntegration(unittest.TestCase):
    def test_places_call_and_local_branch_in_selected_suffix(self):
        from test_verify_c_leaf import fixture
        from verify_c_leaf import LEAF_CODE_SLICES, bind_leaf_details
        raw = bytes.fromhex('90 90 e8 00 00 00 00 eb 00 c3')
        obj = fixture(bytes.fromhex('a4 03 16 01 01'), code=raw)
        with patch.dict(LEAF_CODE_SLICES, {'section': ('leaf', 2, 10, 10)}), \
                patch.dict(LEAF_SECTION_BRANCHES, {'leaf': (10, 32, {7: (b'\xeb', 9, 16)})}):
            code, refs = bind_leaf_details(obj, 'section', {}, address=0x1010,
                                          functions={'global': 0x2000, 'leaf': 0x1000})
        self.assertEqual(refs, {})
        self.assertEqual(code[0], 0xe8)
        self.assertEqual(0x1015 + int.from_bytes(code[1:5], 'little', signed=True), 0x2000)
        self.assertEqual(code[5:], bytes.fromhex('eb f9 c3'))


class UnlinkedContextSuffix(unittest.TestCase):
    def test_omitted_return_is_checked_even_when_selected_bytes_match(self):
        from test_verify_c_leaf import fixture
        from verify_c_leaf import LEAF_CODE_SLICES, LEAF_CONTEXT_SUFFIXES, bind_leaf_details
        with patch.dict(LEAF_CODE_SLICES, {'view': ('leaf', 0, 1, 2)}), \
                patch.dict(LEAF_CONTEXT_SUFFIXES, {'leaf': b'\xc3'}):
            self.assertEqual(bind_leaf_details(fixture(fixup=b'', code=b'\x90\xc3'),
                             'view', {}), (b'\x90', {}))
            with self.assertRaisesRegex(ValueError, 'context suffix'):
                bind_leaf_details(fixture(fixup=b'', code=b'\x90\x90'), 'view', {})

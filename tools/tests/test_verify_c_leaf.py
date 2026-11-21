import unittest
from unittest.mock import patch
from test_match_objects import record
from verify_c_leaf import (
    INTERNAL_EPILOGUE_ALIASES, INTERNAL_LEAF_JUMPS, INTERNAL_SHORT_RETURNS, LEAVES, LEAF_ENTRY_PREFIXES, LEAF_ENTRY_PREFIX_FIXUPS,
    bind_leaf, bind_leaf_details, bind_short_returns, verify_leaf_relocations,
)


def fixture(fixup=bytes.fromhex('e4 00 14 01 01'), code=b'\x04\x00\x00\x00',
            *, name=b'leaf', external=b'global'):
    blob = record(0x96, b'\x05_TEXT\x04CODE\x04FLAT')
    blob += record(0x99, b'\x69' + len(code).to_bytes(4, 'little') + b'\x01\x02\x00')
    blob += record(0x9a, b'\x03')
    blob += record(0x8c, bytes((len(external),)) + external + b'\x00')
    blob += record(0xa1, b'\x01' + bytes(4) + code)
    blob += record(0x91, b'\x00\x01' + bytes((len(name),)) + name + bytes(5))
    # Use an explicit external target, not a segment target.
    blob += record(0x9d, fixup)
    return blob


class CompiledLeaf(unittest.TestCase):
    def test_float_edge_helpers_are_covered_at_original_spans(self):
        self.assertEqual(LEAVES['float_positive_zero_'], (0x995da, 3))
        self.assertEqual(LEAVES['float_largest_finite_'], (0x995dd, 11))

    def test_retained_entry_prefix_keeps_relative_call_address(self):
        with patch.dict(LEAF_ENTRY_PREFIXES, {'leaf': 2}):
            obj = fixture(bytes.fromhex('a4 03 16 01 01'), b'\x90\x90\xe8' + bytes(4))
            code, refs = bind_leaf_details(obj, 'leaf', {}, address=0x100, functions={'global': 0x200})
            self.assertEqual(code, b'\xe8' + (0xfb).to_bytes(4, 'little'))
            self.assertEqual(refs, {})

    def test_retained_entry_prefix_rejects_fixups(self):
        with patch.dict(LEAF_ENTRY_PREFIXES, {'leaf': 2}):
            obj = fixture(code=bytes(5))
            with self.assertRaisesRegex(ValueError, 'Relocation in retained assembly prefix'):
                bind_leaf_details(obj, 'leaf', {'global': 0x200})

    def test_allowlisted_prefix_data_fixup_is_bound_then_excluded(self):
        with patch.dict(LEAF_ENTRY_PREFIXES, {'leaf': 4}), patch.dict(
                LEAF_ENTRY_PREFIX_FIXUPS, {'leaf': {0: ('global', False)}}):
            obj = fixture(bytes.fromhex('e4 00 16 01 01'), code=bytes(4) + b'\xc3')
            code, refs = bind_leaf_details(obj, 'leaf', {'global': 0x200})
            self.assertEqual((code, refs), (b'\xc3', {}))
            with self.assertRaisesRegex(ValueError, 'Unbound leaf symbol'):
                bind_leaf_details(obj, 'leaf', {})

    def test_allowlisted_prefix_relative_call_is_excluded(self):
        with patch.dict(LEAF_ENTRY_PREFIXES, {'leaf': 5}), patch.dict(
                LEAF_ENTRY_PREFIX_FIXUPS, {'leaf': {1: ('global', True)}}):
            obj = fixture(bytes.fromhex('a4 01 16 01 01'), b'\xe8' + bytes(4) + b'\xc3')
            code, refs = bind_leaf_details(obj, 'leaf', {}, address=0x100,
                                           functions={'global': 0x200})
            self.assertEqual((code, refs), (b'\xc3', {}))

    def test_prefix_fixup_cannot_cross_kept_body_boundary(self):
        with patch.dict(LEAF_ENTRY_PREFIXES, {'leaf': 2}), patch.dict(
                LEAF_ENTRY_PREFIX_FIXUPS, {'leaf': {0: ('global', False)}}):
            with self.assertRaisesRegex(ValueError, 'crosses retained assembly prefix'):
                bind_leaf_details(fixture(bytes.fromhex('e4 00 16 01 01'), code=bytes(5)), 'leaf', {'global': 0x200})

    def test_prefix_fixup_identity_and_completeness_are_checked(self):
        for expected in ({0: ('other', False)}, {0: ('global', True)}):
            with self.subTest(expected=expected), patch.dict(LEAF_ENTRY_PREFIXES, {'leaf': 4}), patch.dict(
                    LEAF_ENTRY_PREFIX_FIXUPS, {'leaf': expected}):
                with self.assertRaisesRegex(ValueError, 'Unexpected retained assembly prefix'):
                    bind_leaf_details(fixture(bytes.fromhex('e4 00 16 01 01'), code=bytes(4) + b'\xc3'), 'leaf', {'global': 0x200})
        with patch.dict(LEAF_ENTRY_PREFIXES, {'leaf': 4}), patch.dict(
                LEAF_ENTRY_PREFIX_FIXUPS, {'leaf': {0: ('global', False)}}):
            with self.assertRaisesRegex(ValueError, 'Missing retained assembly prefix'):
                bind_leaf_details(fixture(b'', bytes(4) + b'\xc3'), 'leaf', {'global': 0x200})

    def test_prefix_code_pointer_metadata_has_no_negative_sites(self):
        with patch.dict(LEAF_ENTRY_PREFIXES, {'leaf': 4}), patch.dict(
                LEAF_ENTRY_PREFIX_FIXUPS, {'leaf': {0: ('global', False)}}):
            metadata = {}
            code, refs = bind_leaf_details(fixture(bytes.fromhex('e4 00 16 01 01'), code=bytes(4) + b'\xc3'), 'leaf', {},
                                           absolute_code={'global': 0x200}, code_bindings=metadata)
            self.assertEqual((code, refs, metadata), (b'\xc3', {}, {}))

    def test_internal_jump_between_discontiguous_leaves(self):
        for relative, error in ((-6, None), (-7, 'Unexpected internal leaf jump target')):
            body = b'\x90\xc3\xe9' + relative.to_bytes(4, 'little', signed=True)
            blob = record(0x96, b'\x05_TEXT\x04CODE')
            blob += record(0x99, b'\x69' + len(body).to_bytes(4, 'little') + b'\x01\x02\x00')
            blob += record(0xa1, b'\x01' + bytes(4) + body)
            blob += record(0x91, b'\x00\x01\x06parent' + bytes(5)
                           + b'\x06caller\x02' + bytes(4))
            with self.subTest(relative=relative), patch.dict(INTERNAL_LEAF_JUMPS, {
                    'caller': {0: ('parent', 1)}}):
                options = dict(address=0x1200, functions={'parent': 0x1000})
                if error is not None:
                    with self.assertRaisesRegex(ValueError, error):
                        bind_leaf_details(blob, 'caller', {}, **options)
                    continue
                code, bindings = bind_leaf_details(blob, 'caller', {}, **options)
                self.assertEqual(code, b'\xe9' + (-0x204).to_bytes(4, 'little', signed=True))
                self.assertEqual(bindings, {})

    def test_shared_epilogue_alias_checks_local_instructions(self):
        epilogue = bytes.fromhex('5f5e5a595bc3')
        for tail in (epilogue, b'\x90' + epilogue[1:]):
            jump = b'\xe9' + (-len(tail) - 5).to_bytes(4, 'little', signed=True)
            body = tail + jump
            blob = record(0x96, b'\x05_TEXT\x04CODE')
            blob += record(0x99, b'\x69' + len(body).to_bytes(4, 'little') + b'\x01\x02\x00')
            blob += record(0xa1, b'\x01' + bytes(4) + body)
            blob += record(0x91, b'\x00\x01\x05local' + bytes(5)
                           + b'\x06caller' + len(tail).to_bytes(4, 'little') + b'\x00')
            with self.subTest(tail=tail), patch.dict(INTERNAL_LEAF_JUMPS, {
                    'caller': {0: ('local', 0)}}), patch.dict(INTERNAL_EPILOGUE_ALIASES, {
                    ('local', 0): ('shared', epilogue)}):
                options = dict(address=0x1200, functions={'shared': 0x1500})
                if tail != epilogue:
                    with self.assertRaisesRegex(ValueError, 'Compiler-local epilogue'):
                        bind_leaf_details(blob, 'caller', {}, **options)
                else:
                    code, bindings = bind_leaf_details(blob, 'caller', {}, **options)
                    self.assertEqual(code, b'\xe9' + (0x2fb).to_bytes(4, 'little', signed=True))
                    self.assertEqual(bindings, {})

    def test_short_return_rebases_only_the_declared_local_branch(self):
        with patch.dict(INTERNAL_SHORT_RETURNS, {'test': ('shared', 3, ((0, 0x7c),))}):
            code = bytearray.fromhex('7c0190c3')
            bind_short_returns(code, 'test', 0x100, {'shared': 0xff}, set())
            self.assertEqual(code, bytes.fromhex('7cfd90c3'))
            for invalid, target, fields, message in (
                    ('7e0190c3', 0xff, set(), 'Invalid short return branch'),
                    ('7c0190c3', 0xff, {1}, 'Invalid short return branch'),
                    ('7c0090c3', 0xff, set(), 'Unexpected local short return target'),
                    ('7c019090', 0xff, set(), 'Expected compiler-local near return'),
                    ('7c0190c3', 0x182, set(), 'outside short branch range')):
                with self.subTest(invalid=invalid, target=target, fields=fields):
                    with self.assertRaisesRegex(ValueError, message):
                        bind_short_returns(bytearray.fromhex(invalid), 'test', 0x100,
                                           {'shared': target}, fields)

    def test_absolute_code_binding_and_le_target(self):
        metadata = {}
        code, bindings = bind_leaf_details(fixture(bytes.fromhex('e4 00 16 01 01')),
            'leaf', {}, absolute_code={'global': 0x3215b}, code_bindings=metadata)
        self.assertEqual(bindings, {0: 0x3215f})  # Preserve the encoded addend 4.
        self.assertEqual(metadata, bindings)
        self.assertEqual(code, (0x3215f).to_bytes(4, 'little'))
        verify_leaf_relocations(code, bindings, {0x40000: 0x4215f}, 0x40000,
                                code_bindings=metadata)

    def test_code_metadata_required(self):
        with self.assertRaisesRegex(ValueError, 'requires code_bindings'):
            bind_leaf(fixture(bytes.fromhex('e4 00 16 01 01')), 'leaf', {},
                      absolute_code={'global': 100})

    def test_reject_ambiguous_absolute_symbol(self):
        with self.assertRaisesRegex(ValueError, 'Ambiguous'):
            bind_leaf_details(fixture(bytes.fromhex('e4 00 16 01 01')), 'leaf',
                              {'global': 100}, absolute_code={'global': 100}, code_bindings={})

    def test_reject_stale_output_metadata(self):
        with self.assertRaisesRegex(ValueError, 'stale metadata'):
            bind_leaf_details(fixture(bytes.fromhex('e4 00 16 01 01')), 'leaf', {},
                              absolute_code={'global': 100}, code_bindings={0: 104})

    def test_reject_stale_verification_metadata(self):
        code = (104).to_bytes(4, 'little')
        for metadata in ({0: 105}, {1: 104}, {4: 104}):
            with self.subTest(metadata=metadata), self.assertRaisesRegex(ValueError, 'Stale'):
                verify_leaf_relocations(code, {0: 104}, {0x40000: 0x10068}, 0x40000,
                                        code_bindings=metadata)
        with self.assertRaisesRegex(ValueError, 'Stale'):
            verify_leaf_relocations(bytes(4), {0: 104}, {0x40000: 0x10068}, 0x40000,
                                    code_bindings={0: 104})

    def test_code_target_cannot_silently_use_data_base(self):
        code = (104).to_bytes(4, 'little')
        with self.assertRaisesRegex(ValueError, 'relocation'):
            verify_leaf_relocations(code, {0: 104}, {0x40000: 0x80068}, 0x40000,
                                    code_bindings={0: 104})
        with self.assertRaisesRegex(ValueError, 'relocation'):
            verify_leaf_relocations(code, {0: 104}, {0x40000: 0x10068}, 0x40000)

    def test_mixed_data_and_code_metadata(self):
        code = (104).to_bytes(4, 'little') + (200).to_bytes(4, 'little')
        verify_leaf_relocations(code, {0: 104, 4: 200},
                                {0x40000: 0x10068, 0x40004: 0x800c8}, 0x40000,
                                code_bindings={0: 104})

    def test_relative_and_absolute_code_namespaces_are_distinct(self):
        blob = fixture(bytes.fromhex('e4 00 16 01 01 a4 04 16 01 01'))
        blob = blob.replace(record(0x99, b'\x69\x04\x00\x00\x00\x01\x02\x00'),
                            record(0x99, b'\x69\x08\x00\x00\x00\x01\x02\x00'))
        blob = blob.replace(record(0xa1, b'\x01' + bytes(4) + b'\x04\x00\x00\x00'),
                            record(0xa1, b'\x01' + bytes(4) + b'\x04\x00\x00\x00' + bytes(4)))
        metadata = {}
        code, bindings = bind_leaf_details(blob, 'leaf', {}, address=0x40000,
            functions={'global': 0x4215b}, absolute_code={'global': 0x3215b}, code_bindings=metadata)
        self.assertEqual(bindings, {0: 0x3215f})
        self.assertEqual(metadata, bindings)
        self.assertEqual(int.from_bytes(code[4:], 'little'), 0x4215b - 0x40008)
        verify_leaf_relocations(code, bindings, {0x40000: 0x4215f}, 0x40000,
                                code_bindings=metadata)

    def test_absolute_does_not_fall_back_to_loaded_function_address(self):
        with self.assertRaisesRegex(ValueError, 'Unbound'):
            bind_leaf_details(fixture(bytes.fromhex('e4 00 16 01 01')), 'leaf', {},
                              functions={'global': 0x4215b}, code_bindings={})

    def test_external_binding(self):
        code, count = bind_leaf(fixture(bytes.fromhex('e4 00 16 01 01')), 'leaf', {'global': 100})
        self.assertEqual((code, count), ((104).to_bytes(4, 'little'), 1))

    def test_unbound_symbol(self):
        with self.assertRaisesRegex(ValueError, 'Unbound'):
            bind_leaf(fixture(bytes.fromhex('e4 00 16 01 01')), 'leaf', {})

    def test_reject_segment_target(self):
        with self.assertRaisesRegex(ValueError, 'Unsupported'):
            bind_leaf(fixture(), 'leaf', {})

    def test_reject_duplicate_fixup(self):
        with self.assertRaisesRegex(ValueError, 'overlapping'):
            bind_leaf(fixture(bytes.fromhex('e4 00 16 01 01')*2), 'leaf', {'global': 1})

    def test_missing_symbol(self):
        with self.assertRaisesRegex(ValueError, 'exactly one'):
            bind_leaf(fixture(), 'other', {})

    def test_original_pointer_targets(self):
        verify_leaf_relocations(bytes(8), {2: 100},
                                {0x10002: 0x80064, 0x20000: 1}, 0x10000)

    def test_missing_original_pointer(self):
        with self.assertRaisesRegex(ValueError, 'relocation'):
            verify_leaf_relocations(bytes(8), {2: 100}, {}, 0x10000)

    def test_unexpected_original_pointer(self):
        with self.assertRaisesRegex(ValueError, 'relocation'):
            verify_leaf_relocations(bytes(8), {}, {0x10002: 0x80064}, 0x10000)

    def test_wrong_original_target(self):
        with self.assertRaisesRegex(ValueError, 'relocation'):
            verify_leaf_relocations(bytes(8), {2: 100}, {0x10002: 0x80068}, 0x10000)

    def test_relative_external_binding(self):
        code, count = bind_leaf(fixture(bytes.fromhex('a4 00 16 01 01')), 'leaf', {},
                                address=0x10000, functions={'global': 0x12000})
        self.assertEqual((code, count), ((0x2000).to_bytes(4, 'little'), 0))

    def test_relative_backward_binding(self):
        code, count = bind_leaf(fixture(bytes.fromhex('a4 00 16 01 01')), 'leaf', {},
                                address=0x12000, functions={'global': 0x10000})
        self.assertEqual((code, count), ((0xffffe000).to_bytes(4, 'little'), 0))

    def test_relative_small_model_call(self):
        blob = fixture(bytes.fromhex('a4 01 56 01'), b'\xe8' + bytes(4))
        blob = blob.replace(record(0x9a, b'\x03'), b'')
        code, count = bind_leaf(blob, 'leaf', {}, address=0x10000,
                                functions={'global': 0x12000})
        self.assertEqual((code, count), (b'\xe8' + (0x1ffb).to_bytes(4, 'little'), 0))

    def test_reject_frame_by_target_for_other_relative_operands(self):
        for code in (b'\xe9' + bytes(4), b'\xe8\x01' + bytes(3)):
            with self.subTest(code=code), self.assertRaisesRegex(ValueError, 'frame'):
                blob = fixture(bytes.fromhex('a4 01 56 01'), code)
                bind_leaf(blob, 'leaf', {}, address=0x10000, functions={'global': 0x12000})

    def test_small_model_absolute_data_binding(self):
        code = bytes(7) + b'\xbe' + bytes(4)
        blob = fixture(bytes.fromhex('e4 08 56 01'), code,
                       name=b'get_fill_pattern_', external=b'_fill_pattern')
        bound, sites = bind_leaf_details(blob, 'get_fill_pattern_', {'_fill_pattern': 0x16c84})
        self.assertEqual(bound, code[:8] + (0x16c84).to_bytes(4, 'little'))
        self.assertEqual(sites, {8: 0x16c84})
        verify_leaf_relocations(bound, sites, {0x719a9: 0x96c84}, 0x719a1)

    def test_reject_other_small_model_absolute_data_operands(self):
        for name, external, opcode, value in (
                (b'leaf', b'_fill_pattern', 0xbe, 0),
                (b'get_fill_pattern_', b'global', 0xbe, 0),
                (b'get_fill_pattern_', b'_fill_pattern', 0xbf, 0),
                (b'get_fill_pattern_', b'_fill_pattern', 0xbe, 1)):
            with self.subTest(name=name, external=external, opcode=opcode, value=value):
                code = bytes(7) + bytes((opcode,)) + value.to_bytes(4, 'little')
                blob = fixture(bytes.fromhex('e4 08 56 01'), code, name=name, external=external)
                with self.assertRaisesRegex(ValueError, 'frame'):
                    bind_leaf(blob, name.decode(), {external.decode(): 0x16c84})

    def test_relative_requires_address(self):
        with self.assertRaisesRegex(ValueError, 'requires loaded'):
            bind_leaf(fixture(bytes.fromhex('a4 00 16 01 01')), 'leaf', {},
                      functions={'global': 0x10000})

    def test_relative_cannot_use_data_symbol(self):
        with self.assertRaisesRegex(ValueError, 'Unbound'):
            bind_leaf(fixture(bytes.fromhex('a4 00 16 01 01')), 'leaf',
                      {'global': 0x10000}, address=0x12000)

    def test_reject_unsupported_frames(self):
        for frame in ('e4 00 56 01', 'e4 00 06 01 01', 'e4 00 26 01 01',
                      'e4 00 46 01', 'e4 00 16 02 01'):
            with self.subTest(frame=frame), self.assertRaisesRegex(ValueError, 'frame'):
                bind_leaf(fixture(bytes.fromhex(frame)), 'leaf', {'global': 100})

    def test_reject_nonflat_group(self):
        blob = fixture(bytes.fromhex('e4 00 16 01 01'))
        # Rebuild LNAMES to preserve the record checksum.
        old = record(0x96, b'\x05_TEXT\x04CODE\x04FLAT')
        blob = blob.replace(old, record(0x96, b'\x05_TEXT\x04CODE\x04DATA'))
        with self.assertRaisesRegex(ValueError, 'frame'):
            bind_leaf(blob, 'leaf', {'global': 100})

    def test_reject_nonempty_flat_group(self):
        blob = fixture(bytes.fromhex('e4 00 16 01 01'))
        blob = blob.replace(record(0x9a, b'\x03'), record(0x9a, b'\x03\xff\x01'))
        with self.assertRaisesRegex(ValueError, 'frame'):
            bind_leaf(blob, 'leaf', {'global': 100})

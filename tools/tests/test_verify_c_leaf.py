import unittest
from test_match_objects import record
from verify_c_leaf import bind_leaf, bind_leaf_details, verify_leaf_relocations


def fixture(fixup=bytes.fromhex('e4 00 14 01 01')):
    blob = record(0x96, b'\x05_TEXT\x04CODE\x04FLAT')
    blob += record(0x99, b'\x69\x04\x00\x00\x00\x01\x02\x00')
    blob += record(0x9a, b'\x03')
    blob += record(0x8c, b'\x06global\x00')
    blob += record(0xa1, b'\x01'+bytes(4)+b'\x04\x00\x00\x00')
    blob += record(0x91, b'\x00\x01\x04leaf'+bytes(5))
    # Use an explicit external target, not a segment target.
    blob += record(0x9d, fixup)
    return blob


class CompiledLeaf(unittest.TestCase):
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

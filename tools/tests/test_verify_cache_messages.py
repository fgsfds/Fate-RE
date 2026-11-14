"""Synthetic diagnostic verifier fixtures; no game or compiler binaries required."""
import hashlib
import struct
import unittest
from unittest.mock import patch

import verify_cache_messages as verifier


class CacheMessages(unittest.TestCase):
    def setUp(self):
        # Exercise the real hash check and LE page translation with invented data.
        self.exe = bytearray(0x3000)
        header = 0x80
        struct.pack_into('<I', self.exe, 60, header)
        for offset, value in ((0x28, 4096), (0x40, 0x100),
                              (0x48, 0x140), (0x80, 0x1000)):
            struct.pack_into('<I', self.exe, header + offset, value)
        struct.pack_into('<6I', self.exe, header + 0x100 + 24,
                         0x2000, 0x80000, 0, 1, 2, 0)
        self.exe[header + 0x140:header + 0x148] = b'\0\0\1\0\0\0\2\0'
        payload = bytearray()
        self.publics = []
        for index, (name, size) in enumerate(verifier.MESSAGES.items()):
            self.publics.append((2, len(payload), name))
            # Model the two equal but separately located allocation messages.
            fill = 77 if 'allocation_error' in name else 65 + index
            message = bytes([fill]) * (size - 1) + b'\0'
            payload.extend(message)
            raw = 0x1000 + verifier.DATA_OFFSETS[name]
            self.exe[raw:raw + size] = message
        self.segments = [None, dict(name='_TEXT', cls='CODE', data=bytearray()),
                         dict(name='_DATA', cls='DATA', data=payload)]
        self.offsets = dict(verifier.DATA_OFFSETS)
        self.fixups = []

    def verify(self):
        # Mock only OMF decoding; the separate OMF parser has its own fixture suite.
        with patch.object(verifier, 'read_object', return_value=(self.segments, self.publics)), \
                patch.object(verifier, 'read_fixups', return_value=self.fixups), \
                patch.object(verifier, 'DATA_OFFSETS', self.offsets), \
                patch.object(verifier, 'TARGET_SHA256', hashlib.sha256(self.exe).hexdigest()):
            return verifier.verify(bytes(self.exe), b'synthetic object identity')

    def test_valid_distinct_arrays(self):
        result = self.verify()
        self.assertEqual(result['matching_initialized_data_bytes'], 387)
        self.assertEqual(len(result['arrays']), 15)
        self.assertFalse(result['final_linked_placement_verified'])
        allocation = [row for row in result['arrays'] if 'allocation_error' in row['symbol']]
        self.assertEqual(allocation[0]['sha256'], allocation[1]['sha256'])
        self.assertNotEqual(allocation[0]['raw_offset'], allocation[1]['raw_offset'])
        self.assertEqual(result['arrays'][0]['raw_offset'], '0x2748')

    def test_reject_aliased_equal_arrays(self):
        segment, offset, _ = self.publics[12]
        self.publics[13] = segment, offset, self.publics[13][2]
        with self.assertRaisesRegex(ValueError, 'distinct, contiguous and ordered'):
            self.verify()

    def test_reject_extra_public(self):
        self.publics.append((2, 0, '_unexpected'))
        with self.assertRaisesRegex(ValueError, 'public inventory'):
            self.verify()

    def test_reject_trailing_data(self):
        self.segments[2]['data'].append(0)
        with self.assertRaisesRegex(ValueError, 'outside diagnostic arrays'):
            self.verify()

    def test_reject_extra_code_payload(self):
        self.segments[1]['data'].append(0x90)
        with self.assertRaisesRegex(ValueError, 'one populated DATA segment'):
            self.verify()

    def test_reject_changed_string(self):
        self.segments[2]['data'][254] ^= 1
        with self.assertRaisesRegex(ValueError, 'Diagnostic array differs'):
            self.verify()

    def test_reject_missing_terminator(self):
        self.segments[2]['data'][-1] = 1
        # Match the non-NUL byte in the synthetic executable: termination must
        # still fail even though generated and original payloads are identical.
        self.exe[0x1000 + self.offsets['_group_too_many_files'] + 44] = 1
        with self.assertRaisesRegex(ValueError, 'Diagnostic array differs'):
            self.verify()

    def test_reject_overlapping_original_ranges(self):
        self.offsets['_group_offsets_allocation_error'] = self.offsets['_group_list_allocation_error']
        with self.assertRaisesRegex(ValueError, 'Original diagnostic ranges overlap'):
            self.verify()

    def test_reject_unexpected_relocations(self):
        self.fixups.append(object())
        with self.assertRaisesRegex(ValueError, 'Unexpected relocation'):
            self.verify()

    def test_reject_unknown_executable(self):
        with self.assertRaisesRegex(ValueError, 'Unknown FATE.EXE'):
            verifier.verify(bytes(self.exe), b'synthetic object identity')


if __name__ == '__main__':
    unittest.main()

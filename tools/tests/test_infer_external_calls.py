import unittest
from unittest.mock import patch
from infer_external_calls import infer
from test_match_objects import record


class ExternalCalls(unittest.TestCase):
    def test_relative_target_with_addend_and_displacement(self):
        blob = record(0x96, b'\x05_TEXT\x04CODE')
        blob += record(0x99, b'\x69\x04\x00\x00\x00\x01\x02\x00')
        blob += record(0x8c, b'\x06callee\x00')
        blob += record(0xa1, b'\x01'+bytes(4)+(7).to_bytes(4, 'little'))
        blob += record(0x91, b'\x00\x01\x06caller'+bytes(5))
        blob += record(0x9d, bytes.fromhex('a4 00 52 01 03000000'))
        exe = bytearray(0x35604)
        exe[0x35600:] = (-100).to_bytes(4, 'little', signed=True)
        comparison = dict(object_sha256='fixture', spans=[dict(
            symbol='caller', object_offset='0x0', candidate_address='0x10000',
            public_span=4, differing_bytes=0)])
        with patch('infer_external_calls.compare', return_value=comparison):
            result = infer(blob, bytes(exe))
        self.assertEqual(list(result['candidates']['callee']), [hex(0x10000+4-100-7-3)])

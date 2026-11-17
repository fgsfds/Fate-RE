import unittest

from bind_melee_group import bind_switch_groups
from test_match_objects import record


BASE = 0x39758
TABLES = ((0, 4, 12, 'first'), (12, 4, 30, 'second'))


def fixture(*, opcode=0xe8, call_addend=0, first_target=4):
    def offset(value):
        return value.to_bytes(4, 'little')

    dispatch = bytes.fromhex('2e ff 24 85')
    code = offset(first_target) + dispatch + offset(0)
    code += offset(16) + dispatch + offset(12)
    code += bytes([opcode]) + offset(call_addend) + b'\xc3'
    blob = record(0x96, b'\x05_TEXT\x04CODE\x04FLAT')
    blob += record(0x99, b'\x69' + offset(len(code)) + b'\x01\x02\x00')
    blob += record(0x9a, b'\x03')
    blob += record(0x8c, b'\x05first\x00')
    blob += record(0xa1, b'\x01' + offset(0) + code)
    blob += record(0x91, b'\x00\x01\x05first' + offset(4) + b'\x00'
                   + b'\x06second' + offset(16) + b'\x00')
    return blob + record(0x9d, bytes.fromhex(
        'e4 00 14 01 01 e4 08 14 01 01 e4 0c 14 01 01 e4 14 14 01 01 a4 19 16 01 01'))


class SwitchGroupBindings(unittest.TestCase):
    def bind(self, blob):
        return bind_switch_groups(blob, base=BASE, loaded=False, tables=TABLES,
                                  data_targets={}, call_targets={})

    def test_resolves_named_call_to_public_in_group(self):
        code, data, absolute, calls = self.bind(fixture())
        self.assertEqual(calls, {25: BASE + 4})
        self.assertEqual(int.from_bytes(code[25:29], 'little', signed=True), 4 - 29)
        self.assertEqual(data, {})
        self.assertEqual(absolute, {site: BASE - 0x10000 + target
                                    for site, target in [(0, 4), (8, 0), (12, 16), (20, 12)]})

    def test_rejects_local_call_addend_and_jump(self):
        for blob in (fixture(call_addend=1), fixture(opcode=0xe9)):
            with self.subTest(blob=blob), self.assertRaisesRegex(ValueError, 'same-segment'):
                self.bind(blob)

    def test_rejects_table_target_in_next_function(self):
        with self.assertRaisesRegex(ValueError, 'inside its function'):
            self.bind(fixture(first_target=16))

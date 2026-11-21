import unittest
from unittest.mock import patch

import bind_serial_init as serial


def compiled():
    code = bytearray(serial.CONTEXT_END + serial.SIZE)
    code[serial.EPILOGUE:serial.EPILOGUE + 6] = bytes.fromhex('5d5e5a595bc3')
    for site, width, opcode in ((serial.COMPILED_ENTRY + 26, 1, 0xeb),
                                 (serial.COMPILED_ENTRY + 643, 4, 0xe9)):
        code[site] = opcode
        end = site + 1 + width
        code[site + 1:end] = (serial.EPILOGUE - end).to_bytes(width, 'little', signed=True)
    return code


class SerialSharedReturn(unittest.TestCase):
    def bind(self, code, fixups=()):
        refs = ({8: 123, 975: 456}, {944: 789}, {20: 12, 1000: 34})
        with patch.object(serial, 'bind_switch_groups', return_value=(bytes(code), *refs)), \
                patch.object(serial, 'read_fixups', return_value=fixups):
            return serial.bind(b'fixture')

    def test_only_selects_serial_and_rebinds_both_exit_displacements(self):
        before = compiled()
        code, data, refs, calls = self.bind(before)
        self.assertEqual(len(code), 664)
        self.assertEqual((data, refs, calls), ({31: 456}, {0: 789}, {56: 34}))
        allowed = {43, *range(660, 664)}
        self.assertTrue(all(a == b or n in allowed
                            for n, (a, b) in enumerate(zip(before[944:], code))))
        for site, width in ((42, 1), (659, 4)):
            end = site + 1 + width
            displacement = int.from_bytes(code[site + 1:end], 'little', signed=True)
            self.assertEqual(serial.BASE + end + displacement, 0x41a3f)

    def test_rejects_changed_shared_epilogue_opcode_target_and_extent(self):
        for position in (serial.EPILOGUE, 986, 987, 1603, 1604):
            code = compiled()
            code[position] ^= 1
            with self.subTest(position=position), self.assertRaises(ValueError):
                self.bind(code)
        with self.assertRaisesRegex(ValueError, 'extent'):
            self.bind(compiled()[:-1])

    def test_rejects_fixup_overlapping_exit(self):
        from types import SimpleNamespace
        fixup = SimpleNamespace(segment=1, offset=987, width=4)
        with self.assertRaisesRegex(ValueError, 'fixup'):
            self.bind(compiled(), [fixup])

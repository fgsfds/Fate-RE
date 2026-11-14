"""Synthetic linkage controls; contains no original executable bytes."""
from contextlib import ExitStack
from types import SimpleNamespace
import unittest
from unittest.mock import patch
from compare_runtime_core import compare


class RuntimeCoreTests(unittest.TestCase):
    def run_case(self, pointers, operand=0x14484, code_change=False):
        address=0x10000
        code=b'\xa1'+bytes(4)+b'\xc3'
        original=bytearray(code); original[1:5]=operand.to_bytes(4,'little')
        if code_change: original[-1]=0x90
        exe=bytes(address+0x25600)+original
        fix=SimpleNamespace(segment=1,width=4,location=9,frame=(5,None),target=(2,1),
                            offset=1,displacement=0,relative=False)
        with ExitStack() as stack:
            for name,value in {
                'provenance':{},'read_object':([None,dict(data=code,cls='CODE')],[(1,0,'test')]),
                'layout':({1:set(range(6))},[]),'read_fixups':[fix],
                'read_externals':[None,'__ASTACKSIZ'],'read_le_fixups':dict(pointers=pointers)
            }.items(): stack.enter_context(patch('compare_runtime_core.'+name,return_value=value))
            return compare(exe,b'',b'','105',address,6,[('test',0)],True)

    def test_exact_bound_body(self):
        self.assertTrue(self.run_case({0x10001:0x94484})['exact_dependency_body'])

    def test_wrong_le_target(self):
        with self.assertRaises(ValueError):self.run_case({0x10001:0x94485})

    def test_extra_le_site(self):
        with self.assertRaises(ValueError):self.run_case({0x10001:0x94484,0x10002:0x94484})

    def test_raw_operand_difference_is_not_masked(self):
        self.assertFalse(self.run_case({0x10001:0x94484},operand=0x14485)['exact_dependency_body'])

    def test_instruction_difference_rejects_identity(self):
        self.assertFalse(self.run_case({0x10001:0x94484},code_change=True)['exact_dependency_body'])


if __name__=='__main__':unittest.main()

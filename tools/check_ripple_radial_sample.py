"""Check the frozen radial sample object without changing shared fixtures."""
import argparse
from hashlib import sha256
import json
from pathlib import Path
from struct import pack

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32
from unicorn.x86_const import *
from check_start_hook import DS, image
from le_fixups import read_le_fixups
import verify_c_leaf as verifier

ENTRY, END, STACK, STOP = 0x2EC1C, 0x2EC50, 0x3FF000, 0x3FFF00
TEXTURE = 0x380000
PUBLIC = 'ripple_radial_sample_'
SYMBOL = 'ripple_radial_sample_check_'
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--exe', type=Path, required=True)
parser.add_argument('--build', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
reference = args.exe.read_bytes()
assert sha256(reference).hexdigest() == verifier.TARGET_SHA256
obj = (args.build / 'riprad.obj').read_bytes()
source = Path(__file__).resolve().parents[1].joinpath('src/fate/ripple_radial.c').read_bytes()

verifier.LEAF_CODE_SLICES[SYMBOL] = (PUBLIC, 0, END-ENTRY, END-ENTRY+1)
verifier.LEAF_CONTEXT_SUFFIXES[PUBLIC] = b'\xc3'
verifier.FUNCTION_ADDRESSES[PUBLIC] = ENTRY
code, bindings = verifier.bind_leaf_details(obj, SYMBOL, verifier.DATA_OFFSETS, address=ENTRY)
assert code == reference[ENTRY+0x25600:END+0x25600]
verifier.verify_leaf_relocations(code, bindings, read_le_fixups(reference)['pointers'], ENTRY)
loaded, _ = verifier.bind_leaf_details(
    obj, SYMBOL, {k: DS+v for k, v in verifier.DATA_OFFSETS.items()}, address=ENTRY)

memory = image(reference)
cpu = Uc(UC_ARCH_X86, UC_MODE_32)
cpu.mem_map(0, len(memory))
cpu.mem_write(0, memory)
cpu.mem_write(ENTRY, loaded+b'\xc3')
patterns = (
    (0, 0, 0, 0, 0, 0),
    (127, 127, 1, 1, 1, 255),
    (0, 0, 0xffffffff, 0xfffffffe, 0xff, 0),
    (127, 0, 0xffffffff, 0x80000000, 0x8055017f, 213),
    (13, 127, 0xffffff80, 0xffffffff, 0xfffffff8, 5),
    (127, 127, 0x8000007f, 0xdeadbe80, 0xabcdef80, 0xfa),
)
count = 0
for radius in range(1, 11):
    for sample in range(128):
        offset = radius*512 + sample*4
        for origin_x, origin_y, raw_x, raw_y, amplitude, initial in patterns:
            stack_words = pack('<5I', STOP, 0xcafebabe, amplitude, origin_x, 0xdeadbeef)
            cpu.mem_write(STACK, stack_words)
            cpu.mem_write(0xdaedc+offset, pack('<I', raw_x))
            cpu.mem_write(0xdeedc+offset, pack('<I', raw_y))
            for reg, value in ((UC_X86_REG_EDI,radius), (UC_X86_REG_ESI,sample),
                    (UC_X86_REG_EDX,TEXTURE), (UC_X86_REG_EBP,origin_y),
                    (UC_X86_REG_ESP,STACK), (UC_X86_REG_EAX,0xabcdef01),
                    (UC_X86_REG_EBX,0x87654321), (UC_X86_REG_ECX,0xdeadbeef)):
                cpu.reg_write(reg, value)
            texture = bytearray(b'\xa7'*16384)
            x, y = (origin_x+raw_x)&127, (origin_y+raw_y)&127
            index = x*128+y
            texture[index] = initial
            cpu.mem_write(TEXTURE-1, b'\x5a'+texture+b'\x5a')
            cpu.emu_start(ENTRY, STOP, count=80)
            assert cpu.reg_read(UC_X86_REG_EIP) == STOP
            assert cpu.reg_read(UC_X86_REG_ECX) == TEXTURE+index
            assert cpu.reg_read(UC_X86_REG_EBX) == y
            assert cpu.reg_read(UC_X86_REG_EAX) == ((index&~255) | (amplitude&255))
            assert cpu.reg_read(UC_X86_REG_ESP) == STACK+4
            for reg, value in ((UC_X86_REG_EDI,radius), (UC_X86_REG_ESI,sample),
                    (UC_X86_REG_EDX,TEXTURE), (UC_X86_REG_EBP,origin_y)):
                assert cpu.reg_read(reg) == value
            assert cpu.mem_read(STACK,len(stack_words)) == stack_words
            texture[index] = (initial+amplitude)&255
            assert cpu.mem_read(TEXTURE-1,16386) == b'\x5a'+texture+b'\x5a'
            count += 1
report = {
    'status': 'PASS', 'cases': count, 'exact_code_bytes': len(code),
    'exact_data_relocations': len(bindings), 'guarded_private_suffix': 'c3',
    'object_sha256': sha256(obj).hexdigest(),
    'source_sha256': sha256(source).hexdigest(),
}
output = json.dumps(report, indent=2)
args.output.write_text(output+'\n')
print(output)

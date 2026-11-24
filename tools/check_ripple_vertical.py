"""Compare both compiled vertical border contexts and exercise each loop entry."""
import argparse
from hashlib import sha256
import json
from pathlib import Path

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32
from unicorn.x86_const import *
from check_start_hook import DS, image
from le_fixups import read_le_fixups
import verify_c_leaf as verifier

ENTRY, END, STACK, TEXTURE = 0x2ed1d, 0x2ed54, 0x3ff000, 0x380000
BORDER_OFFSET = 0x6331c
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--exe',type=Path,required=True)
parser.add_argument('--build',type=Path,required=True)
parser.add_argument('--output',type=Path,required=True)
args=parser.parse_args()
reference=args.exe.read_bytes()
assert sha256(reference).hexdigest()==verifier.TARGET_SHA256
obj=(args.build/'ripbord.obj').read_bytes()
source=Path(__file__).resolve().parents[1].joinpath('src/fate/ripple_border.c').read_bytes()
fixups = read_le_fixups(reference)['pointers']
spans = ((0x2ed1d, 11, 'ripple_vertical_head_'), (0x2ed29, 35, 'ripple_vertical_tail_'))
memory = image(reference)
cpu = Uc(UC_ARCH_X86, UC_MODE_32)
cpu.mem_map(0, len(memory))
cpu.mem_write(0, memory)
relocations = 0
for start, size, public in spans:
    symbol = f'{public}check_'
    verifier.LEAF_CODE_SLICES[symbol] = (public, 0, size, size+1)
    verifier.LEAF_CONTEXT_SUFFIXES[public] = b'\xc3'
    verifier.FUNCTION_ADDRESSES[public] = start
    code, bindings = verifier.bind_leaf_details(
        obj, symbol, verifier.DATA_OFFSETS, address=start)
    assert code == reference[start+0x25600:start+0x25600+size], (public, code.hex())
    verifier.verify_leaf_relocations(code, bindings, fixups, start)
    loaded, _ = verifier.bind_leaf_details(
        obj, symbol, {k: DS+v for k,v in verifier.DATA_OFFSETS.items()}, address=start)
    cpu.mem_write(start, loaded)
    relocations += len(bindings)

count = 0
for seed in range(4):
    texture = bytes((i*(seed*2+3) + (i//128)*(seed+13) + seed*17)&255 for i in range(16384))
    seed_plane = bytes((i*7+seed*13)&255 for i in range(17160))
    seed_stack = bytes((i*11+seed*19)&255 for i in range(36))
    cpu.mem_write(TEXTURE-1,b'\xda'+texture+b'\xdb')
    for first in range(-1,128):
        cpu.mem_write(DS+BORDER_OFFSET-1,b'\xd1'+seed_plane+b'\xd2')
        cpu.mem_write(STACK-8,seed_stack)
        start = ENTRY if first >= 0 else 0x2ed19
        for reg,value in ((UC_X86_REG_ESP,STACK),(UC_X86_REG_EDX,TEXTURE),
                (UC_X86_REG_EBP,first if first >= 0 else 0xdeadbeef),
                (UC_X86_REG_EAX,0x18a956ce),(UC_X86_REG_EBX,0x8071937c),
                (UC_X86_REG_ECX,0x68d9b10c),(UC_X86_REG_ESI,0x12345678),
                (UC_X86_REG_EDI,0xabcdef89)):
            cpu.reg_write(reg,value)
        cpu.emu_start(start,END,count=5000)
        left = texture[-1]&31
        right = texture[-128]&31
        for reg,value in ((UC_X86_REG_EIP,END),(UC_X86_REG_ESP,STACK),
                (UC_X86_REG_EDX,TEXTURE),(UC_X86_REG_EBP,128),
                (UC_X86_REG_EAX,128*33),(UC_X86_REG_EBX,0x3f00|right),
                (UC_X86_REG_ECX,0x68d9b100|left),(UC_X86_REG_ESI,0x12345678),
                (UC_X86_REG_EDI,0xabcdef89)):
            assert cpu.reg_read(reg) == value
        want_frame = bytearray(seed_stack)
        want_frame[8+16] = left
        assert cpu.mem_read(STACK-8,len(seed_stack)) == want_frame
        want_plane = bytearray(seed_plane)
        for row in range(max(0,first),128):
            base=(row+1)*132
            want_plane[base] = texture[row*128+127]&31
            want_plane[base+129] = texture[row*128]&31
        assert cpu.mem_read(DS+BORDER_OFFSET-1,17162) == b'\xd1'+want_plane+b'\xd2'
        assert cpu.mem_read(TEXTURE-1,16386) == b'\xda'+texture+b'\xdb'
        count += 1

report = {
    'status': 'PASS', 'cases': count, 'exact_code_bytes': sum(s[1] for s in spans),
    'exact_data_relocations': relocations, 'guarded_private_suffixes': ['c3','c3'],
    'object_sha256': sha256(obj).hexdigest(), 'source_sha256': sha256(source).hexdigest(),
}
output = json.dumps(report,indent=2)
args.output.write_text(output+'\n')
print(output)

"""Check the frozen radial setup object without changing shared fixtures."""
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

ENTRY, END, STACK, STOP = 0x2EBDC, 0x2EC13, 0x3FF000, 0x3FFF00
PUBLIC = 'ripple_radial_setup_'
SYMBOL = 'ripple_radial_setup_check_'
RADIUS, SPEED, SAMPLES, ORIGIN_X = 0x62fcc, 0x630fc, 0x5ae5c, 0x677bc
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
values = dict(verifier.DATA_OFFSETS, _ripple_radius=RADIUS, _ripple_origin_x=ORIGIN_X)
code, bindings = verifier.bind_leaf_details(obj, SYMBOL, values, address=ENTRY)
assert code == reference[ENTRY+0x25600:END+0x25600]
verifier.verify_leaf_relocations(code, bindings, read_le_fixups(reference)['pointers'], ENTRY)
rebased, _ = verifier.bind_leaf_details(
    obj, SYMBOL, {k:DS+v for k,v in values.items()}, address=ENTRY)

memory = image(reference)
cpu = Uc(UC_ARCH_X86, UC_MODE_32)
cpu.mem_map(0, len(memory))
cpu.mem_write(0, memory)
cpu.mem_write(ENTRY, rebased+b'\xc3')
count = 0
for slot in range(32):
    sign = 1 if slot&1 else -1
    for radius in range(1,11):
        for sample_count in (0,1,2,63,127,128):
            for wave in (0, 1, 0xfffffffe, 0x7fffffff, 0x80000000):
                origin = (slot*37 + radius*3 + sample_count)&127
                cpu.mem_write(DS+RADIUS+slot*4, pack('<I', radius))
                cpu.mem_write(DS+SPEED+radius*4, pack('<I', wave))
                cpu.mem_write(DS+SAMPLES+radius*4, pack('<I', sample_count))
                cpu.mem_write(DS+ORIGIN_X+slot*4, pack('<I', origin))
                cpu.mem_write(STACK, pack('<5I', STOP,0xcafebabe,0xa5a5a5a5,0xb6b6b6b6,0xdeadbeef))
                for reg, value in ((UC_X86_REG_EAX,slot),(UC_X86_REG_EBP,slot),
                        (UC_X86_REG_ESP,STACK),(UC_X86_REG_EDX,0x380000),
                        (UC_X86_REG_ECX,0x12345678),(UC_X86_REG_EBX,0x87654321),
                        (UC_X86_REG_ESI,0x92345678),(UC_X86_REG_EDI,0xabcdef01)):
                    cpu.reg_write(reg, value)
                cpu.emu_start(ENTRY, STOP, count=80)
                for reg, value in ((UC_X86_REG_EIP,STOP),(UC_X86_REG_EAX,origin),
                        (UC_X86_REG_EBX,sign&0xffffffff),(UC_X86_REG_ESI,(sample_count-1)&0xffffffff),
                        (UC_X86_REG_EDI,radius),(UC_X86_REG_EBP,slot),
                        (UC_X86_REG_EDX,0x380000),(UC_X86_REG_ECX,0x12345678),
                        (UC_X86_REG_ESP,STACK+4)):
                    assert cpu.reg_read(reg) == value
                assert cpu.mem_read(STACK,20) == pack(
                    '<5I', STOP,0xcafebabe,(wave*sign)&0xffffffff,origin,0xdeadbeef)
                count += 1

report = {
    'status': 'PASS', 'cases': count, 'exact_code_bytes': len(code),
    'exact_data_relocations': len(bindings), 'guarded_private_suffix': 'c3',
    'object_sha256': sha256(obj).hexdigest(), 'source_sha256': sha256(source).hexdigest(),
}
output = json.dumps(report, indent=2)
args.output.write_text(output+'\n')
print(output)

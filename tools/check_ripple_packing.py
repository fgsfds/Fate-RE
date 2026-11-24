"""Check bounded signed ripple lane packing and its register ABI."""
import argparse,json
from pathlib import Path
from unicorn import Uc,UC_ARCH_X86,UC_MODE_32
from unicorn.x86_const import *
from check_start_hook import image
from le_fixups import read_le_fixups
from verify_c_leaf import *
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--exe',type=Path,required=True)
p.add_argument('--build',type=Path,required=True)
p.add_argument('--output',type=Path,required=True)
a=p.parse_args()
exe=a.exe.read_bytes(); image(exe)
obj=(a.build/'rippack.obj').read_bytes()
for symbol in ('ripple_pack_two_bits_','ripple_pack_two_add_','ripple_pack_third_bits_','ripple_pack_third_add_','ripple_pack_fourth_phase_'):
 raw,size=LEAVES[symbol]
 code,refs=bind_leaf_details(obj,symbol,DATA_OFFSETS,address=raw-0x25600)
 assert code==exe[raw:raw+size] and not refs
 verify_leaf_relocations(code,refs,read_le_fixups(exe)["pointers"],raw-0x25600)
cases=0
for public,size,partials in (
 ('ripple_pack_two_',20,(0,1,248,255,0xffffffff,0x80000001)),
 ('ripple_pack_third_',11,(0,1,31,0x1f00,0x1f1f,0x1234)),
 ('ripple_pack_fourth_',16,(0,1,31,0x1f00,0x1f1f1f,0x123456))):
 alias='packing_fixture_'
 LEAF_CODE_SLICES[alias]=(public,0,size,size)
 code,refs=bind_leaf_details(obj,alias,DATA_OFFSETS,address=0x1000)
 assert not refs
 cpu=Uc(UC_ARCH_X86,UC_MODE_32);cpu.mem_map(0,0x10000);cpu.mem_write(0x1000,code)
 for first in partials:
  for value in range(256):
   for upper in (0,0xffffff00,0x80000000,0x12345600):
    second=upper|value
    cpu.mem_write(0x8000,(0x9000).to_bytes(4,'little')+b'\xa5'*16)
    cpu.reg_write(UC_X86_REG_ESP,0x8000)
    cpu.reg_write(UC_X86_REG_EAX,second);cpu.reg_write(UC_X86_REG_EDI,first)
    regs=(UC_X86_REG_EBX,UC_X86_REG_ECX,UC_X86_REG_EDX,UC_X86_REG_ESI,UC_X86_REG_EBP)
    for i,r in enumerate(regs):cpu.reg_write(r,0xabc00000+i)
    cpu.emu_start(0x1000,0x9000,count=30)
    assert cpu.reg_read(UC_X86_REG_EIP)==0x9000 and cpu.reg_read(UC_X86_REG_ESP)==0x8004
    assert cpu.mem_read(0x8004,16)==b'\xa5'*16
    if public=='ripple_pack_two_': eax=(value&248)<<5;edi=((first&248)>>3)+eax
    elif public=='ripple_pack_third_':eax=(value&248)<<13;edi=first+eax
    else:eax=(first+((value&248)<<21)-0x3d3d3d3e)&0xffffffff;edi=first
    assert cpu.reg_read(UC_X86_REG_EAX)==eax and cpu.reg_read(UC_X86_REG_EDI)==edi
    assert all(cpu.reg_read(r)==0xabc00000+i for i,r in enumerate(regs))
    cases+=1
result=dict(status='PASS',cases=cases,native_bytes=44,private_returns=3)
a.output.write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result))

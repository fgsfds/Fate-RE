"""Check ripple output row/frame and packed-word pointer handoffs."""
import argparse,json,struct
from pathlib import Path
from unicorn import Uc,UC_ARCH_X86,UC_MODE_32
from unicorn.x86_const import *
from check_start_hook import DS,image
from le_fixups import read_le_fixups
from verify_c_leaf import *
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--exe',type=Path,required=True);p.add_argument('--build',type=Path,required=True)
p.add_argument('--output',type=Path,required=True);a=p.parse_args()
exe=a.exe.read_bytes();image(exe);obj=(a.build/'ripout.obj').read_bytes();codes={}
for symbol,kind in (('ripple_output_row_phase_','row'),('ripple_store_output_phase_','store')):
 raw,size=LEAVES[symbol]
 code,refs=bind_leaf_details(obj,symbol,DATA_OFFSETS,address=raw-0x25600)
 assert code==exe[raw:raw+size]
 verify_leaf_relocations(code,refs,read_le_fixups(exe)['pointers'],raw-0x25600)
 codes[kind],_=bind_leaf_details(obj,symbol,{k:DS+v for k,v in DATA_OFFSETS.items()},address=raw-0x25600)
STACK,STOP=0x3ff000,0x3fff00
def exercise(code,kind,row=0,index=0,alignment=0,word=0):
 entry=0x2ed8a if kind=='row' else 0x2ee7f
 cpu=Uc(UC_ARCH_X86,UC_MODE_32);cpu.mem_map(0,0x400000);cpu.mem_write(entry,code+b'\xc3')
 frame=struct.pack('<6I',STOP,0x12345678,0x23456789,0x3456789a,0x456789ab,0x56789abc)
 cpu.mem_write(STACK,frame);cpu.reg_write(UC_X86_REG_ESP,STACK)
 regs=(UC_X86_REG_EAX,UC_X86_REG_EBX,UC_X86_REG_ECX,UC_X86_REG_EDX,UC_X86_REG_ESI,UC_X86_REG_EDI,UC_X86_REG_EBP)
 expected={r:0xabc00000+i for i,r in enumerate(regs)}
 for r,v in expected.items():cpu.reg_write(r,v)
 plane=DS+0x6331c;cpu.mem_write(plane-1,b'\x5a'*17162)
 if kind=='row':
  cpu.reg_write(UC_X86_REG_EBP,row);expected[UC_X86_REG_EBP]=row
  start=plane+(row+1)*132+1
  expected.update({UC_X86_REG_EAX:start,UC_X86_REG_ECX:start,UC_X86_REG_EDX:start+128})
  want_frame=bytearray(frame);struct.pack_into('<I',want_frame,4,start+128)
 else:
  tile=0x300000+alignment;out=tile+index*4
  cursor=plane+(index//32+1)*132+1+(index%32)*4
  cpu.mem_write(tile-16,b'\xa7'*16416)
  for r,v in ((UC_X86_REG_EAX,word),(UC_X86_REG_ESI,out),(UC_X86_REG_ECX,cursor)):cpu.reg_write(r,v)
  expected.update({UC_X86_REG_EAX:word,UC_X86_REG_ESI:out+4,UC_X86_REG_ECX:cursor+4})
  want_frame=frame
 cpu.emu_start(entry,STOP,count=80)
 assert cpu.reg_read(UC_X86_REG_EIP)==STOP and cpu.reg_read(UC_X86_REG_ESP)==STACK+4
 assert all(cpu.reg_read(r)==v for r,v in expected.items())
 assert cpu.mem_read(STACK,len(frame))==want_frame
 assert cpu.mem_read(plane-1,17162)==b'\x5a'*17162
 if kind=='store':
  want=bytearray(b'\xa7'*16416);struct.pack_into('<I',want,16+index*4,word)
  assert cpu.mem_read(tile-16,16416)==want
for row in range(128):exercise(codes['row'],'row',row=row)
count=0
for index in (0,31,32,4095):
 for alignment in range(4):
  for word in (0,0xffffffff,0x12345678,0x8055aa00):
   exercise(codes['store'],'store',index=index,alignment=alignment,word=word);count+=1
for kind,offset in (('row',28),('store',2)):
 changed=bytearray(codes[kind]);assert changed[offset]==4;changed[offset]=8
 try:exercise(bytes(changed),kind)
 except AssertionError:pass
 else:raise AssertionError('Output handoff mutation escaped')
result=dict(status='PASS',row_cases=128,store_cases=count,mutation_controls=2,native_bytes=39,le_sites=1)
a.output.write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result))

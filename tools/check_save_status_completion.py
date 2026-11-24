"""Check status length truncation, expiration wraparound and final return ABI."""
import argparse,json,struct
from pathlib import Path
from unicorn import Uc,UC_ARCH_X86,UC_MODE_32,UC_PROT_READ,UC_PROT_WRITE,UC_PROT_EXEC
from unicorn.x86_const import *
import verify_c_leaf as v
from check_start_hook import image,DS
from check_ripple_stack import mutate_public_byte
from check_ripple_control import rename_external
from le_fixups import read_le_fixups

LENGTH,CLOCK,EXPIRATION=DS+0x7f874,DS+0x287e88,DS+0x7709c
STACK,STOP,PRIVATE=0x4ff100,0x4fe000,0x400000
REGS=(UC_X86_REG_EAX,UC_X86_REG_EBX,UC_X86_REG_ECX,UC_X86_REG_EDX,
      UC_X86_REG_ESI,UC_X86_REG_EDI,UC_X86_REG_EBP)
CLOCKS=(0,1,0xffffffff,0xfffffe97,0xfffffe98,0xfffff000,0x7fffffff,0x80000000)
HIGH_BITS=(0,0x100,0x80000000,0xffffff00)
PAGES=tuple(sorted({address&~4095 for address in (LENGTH,CLOCK,EXPIRATION)}))

def exercise(entry,code,private):
 cpu=Uc(UC_ARCH_X86,UC_MODE_32)
 cpu.mem_map(entry&~4095,4096,UC_PROT_READ|UC_PROT_EXEC);cpu.mem_write(entry,code)
 cpu.mem_map(STOP,4096,UC_PROT_READ|UC_PROT_EXEC)
 cpu.mem_map(STACK&~4095,4096,UC_PROT_READ|UC_PROT_WRITE)
 for page in PAGES:cpu.mem_map(page,4096,UC_PROT_READ|UC_PROT_WRITE)
 frame=bytearray(b'\xcc'*4096);struct.pack_into('<I',frame,STACK&4095,STOP)
 cases=0
 for high in HIGH_BITS:
  for low in range(256):
   length=high|low
   for clock in CLOCKS:
    before={page:bytearray(b'\x5a'*4096) for page in PAGES}
    struct.pack_into('<I',before[CLOCK&~4095],CLOCK&4095,clock)
    for page,data in before.items():cpu.mem_write(page,bytes(data))
    cpu.mem_write(STACK&~4095,bytes(frame));cpu.reg_write(UC_X86_REG_ESP,STACK)
    want={reg:0xabc00000+i for i,reg in enumerate(REGS)};want[UC_X86_REG_EAX]=length
    for reg,value in want.items():cpu.reg_write(reg,value)
    flags=(0xcd7 if clock&1 else 0x8d7)|(0x200 if high&0x100 else 0)
    cpu.reg_write(UC_X86_REG_EFLAGS,flags)
    cpu.emu_start(entry,STOP if private else entry+len(code),count=20)
    expected=(clock+360+16*(length&255))&0xffffffff
    before[LENGTH&~4095][LENGTH&4095]=low
    struct.pack_into('<I',before[EXPIRATION&~4095],EXPIRATION&4095,expected)
    for page,data in before.items():assert cpu.mem_read(page,4096)==data
    assert cpu.mem_read(STACK&~4095,4096)==frame
    want.update({UC_X86_REG_EAX:0,UC_X86_REG_EDX:expected})
    assert all(cpu.reg_read(reg)==value for reg,value in want.items())
    assert cpu.reg_read(UC_X86_REG_ESP)==STACK+(4 if private else 0)
    assert cpu.reg_read(UC_X86_REG_EIP)==(STOP if private else entry+len(code))
    # XOR EAX,EAX defines these arithmetic flags; AF is architecturally undefined.
    assert cpu.reg_read(UC_X86_REG_EFLAGS)&0x8c5==0x44
    assert cpu.reg_read(UC_X86_REG_EFLAGS)&0x600==flags&0x600
    cases+=1
 return cases

def main():
 p=argparse.ArgumentParser(description=__doc__)
 p.add_argument('--exe',type=Path,required=True);p.add_argument('--build',type=Path,required=True)
 p.add_argument('--output',type=Path,required=True);a=p.parse_args()
 exe=a.exe.read_bytes();image(exe);pointers=read_le_fixups(exe)['pointers']
 blob=(a.build/'svstat.obj').read_bytes()
 phases=[row for row in v.SAVE_DYNAMIC_LAYOUT['phases'] if row['object']=='svstat']
 assert [(row['address'],row['end']-row['begin']) for row in phases]==[(0x30977,35),(0x31e98,35)]
 loaded=dict(v.DATA_OFFSETS,_save_status_length=LENGTH,_save_status_clock=CLOCK,_save_status_expiration=EXPIRATION)
 body_cases=0
 for phase in phases:
  address=phase['address']
  code,refs=v.bind_leaf_details(blob,phase['phase'],v.DATA_OFFSETS,address=address,functions=v.FUNCTION_ADDRESSES)
  assert code==exe[address+0x25600:address+0x25600+35]
  assert refs=={1:0x7f874,15:0x287e88,29:0x7709c}
  v.verify_leaf_relocations(code,refs,pointers,address)
  code,_=v.bind_leaf_details(blob,phase['phase'],loaded,address=address,functions=v.FUNCTION_ADDRESSES)
  body_cases+=exercise(address,code,False)
 public='save_status_completion_';alias=public+'private_check'
 v.LEAF_CODE_SLICES[alias]=(public,0,36,36)
 try:private,_=v.bind_leaf_details(blob,alias,loaded,address=PRIVATE,functions=v.FUNCTION_ADDRESSES)
 finally:del v.LEAF_CODE_SLICES[alias]
 private_cases=exercise(PRIVATE,private,True)
 controls=0;phase=phases[0]
 def rejected(bad,message):
  nonlocal controls
  try:v.bind_leaf_details(bad,phase['phase'],v.DATA_OFFSETS,address=phase['address'],functions=v.FUNCTION_ADDRESSES)
  except ValueError as exc:
   assert message in str(exc).lower(),str(exc);controls+=1
  else:raise AssertionError('Status context mutation escaped')
 rejected(mutate_public_byte(blob,public,35),'context')
 rejected(rename_external(blob,b'_save_status_clock',b'_save_status_clocm'),'fixup')
 digest=v.LEAF_CONTEXT_SHA256.pop(public)
 try:rejected(mutate_public_byte(blob,public,1),'addend')
 finally:v.LEAF_CONTEXT_SHA256[public]=digest
 result=dict(status='PASS',placed_cases=body_cases,private_cases=private_cases,
             length_byte_values=256,upper_bit_patterns=4,clock_values=len(CLOCKS),
             private_context_controls=controls,all_mapped_data_and_stack_pages_guarded=True)
 a.output.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(json.dumps(result))

if __name__=='__main__':main()

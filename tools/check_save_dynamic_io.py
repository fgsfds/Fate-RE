"""Check sized save transfers, zero counts, private saves and table-read ABI."""
import argparse,json,struct
from pathlib import Path
from unicorn import Uc,UC_ARCH_X86,UC_MODE_32,UC_HOOK_CODE
from unicorn.x86_const import *
import verify_c_leaf as v
from check_start_hook import image,DS
from check_save_field_io import BASES,EXTENT,REGS,STREAM,STACK,STOP,SCRATCH,exercise,oracle
from check_ripple_stack import mutate_public_byte
from check_ripple_control import rename_external
from le_fixups import read_le_fixups

def data_bindings():
 return dict(v.DATA_OFFSETS,_save_data_image=DS,_numsectors=DS+0x289154,
             _numwalls=DS+0x289152,_save_restore_words=DS+0x1a234)

def full_context(blob,context,address):
 public=context['public'];alias=public+'dynamic_private_check'
 v.LEAF_CODE_SLICES[alias]=(public,0,context['size'],context['size'])
 try:return v.bind_leaf_details(blob,alias,data_bindings(),address=address,functions=v.FUNCTION_ADDRESSES)[0]
 finally:del v.LEAF_CODE_SLICES[alias]

def table_case(code,private,seed,limit):
 run=dict(records=[dict(size=2048,data_offset=0x1a234)])
 base=BASES[seed];payload,want_data,_,want_trace,last=oracle(run,base,True,seed,limit)
 entry=SCRATCH if private else 0x2fea3
 cpu=Uc(UC_ARCH_X86,UC_MODE_32);cpu.mem_map(0,0x500000);cpu.mem_write(entry,code)
 cpu.mem_write(DS-16,b'\x5a'*16+base+b'\xa5'*16)
 frame=struct.pack('<I',STOP if private else 0x12345678)+b'\xcc'*60
 cpu.mem_write(STACK,frame);cpu.reg_write(UC_X86_REG_ESP,STACK)
 want={reg:0xabc00000+i for i,reg in enumerate(REGS)};want[UC_X86_REG_ESI]=STREAM
 for reg,value in want.items():cpu.reg_write(reg,value)
 calls=0
 def transfer(machine,address,size,user):
  nonlocal calls
  assert calls==0
  args=tuple(machine.reg_read(reg) for reg in (UC_X86_REG_EAX,UC_X86_REG_EDX,UC_X86_REG_EBX,UC_X86_REG_ECX))
  assert args==(DS+0x1a234,2048,1,STREAM)
  assert machine.reg_read(UC_X86_REG_EDI)==511
  esp=machine.reg_read(UC_X86_REG_ESP);assert esp==STACK-4
  ret,=struct.unpack('<I',machine.mem_read(esp,4));assert ret==entry+27
  amount=want_trace[0][-1]
  if amount:machine.mem_write(DS+0x1a234,payload[:amount])
  for reg,value in ((UC_X86_REG_EAX,last),(UC_X86_REG_EBX,0xb0000000),
                    (UC_X86_REG_ECX,0xc0000000),(UC_X86_REG_EDX,0xd0000000)):
   machine.reg_write(reg,value)
  machine.reg_write(UC_X86_REG_EFLAGS,0x247)
  machine.reg_write(UC_X86_REG_ESP,esp+4);machine.reg_write(UC_X86_REG_EIP,ret);calls+=1
 cpu.hook_add(UC_HOOK_CODE,transfer,begin=0x60638,end=0x60638)
 cpu.emu_start(entry,STOP if private else entry+len(code),count=30)
 assert calls==1 and cpu.mem_read(DS-16,EXTENT+32)==b'\x5a'*16+want_data+b'\xa5'*16
 assert cpu.mem_read(STACK,len(frame))==frame
 want.update({UC_X86_REG_EAX:511 if private else last,UC_X86_REG_EBX:0xb0000000,
              UC_X86_REG_ECX:0xc0000000,UC_X86_REG_EDX:0xd0000000,UC_X86_REG_EDI:511})
 assert all(cpu.reg_read(reg)==value for reg,value in want.items())
 assert cpu.reg_read(UC_X86_REG_ESP)==STACK+(4 if private else 0)
 assert cpu.reg_read(UC_X86_REG_EIP)==(STOP if private else entry+len(code))
 assert cpu.reg_read(UC_X86_REG_EFLAGS)==0x247

def main():
 p=argparse.ArgumentParser(description=__doc__)
 p.add_argument('--exe',type=Path,required=True);p.add_argument('--build',type=Path,required=True)
 p.add_argument('--output',type=Path,required=True);a=p.parse_args()
 exe=a.exe.read_bytes();image(exe);pointers=read_le_fixups(exe)['pointers']
 phases=v.SAVE_DYNAMIC_LAYOUT['phases'];objects=v.SAVE_DYNAMIC_LAYOUT['objects']
 cases=private_cases=0
 for phase in phases:
  if phase['object'] not in ('svsect','svwall'):continue
  obj=next(row for row in objects if row['object']==phase['object'])
  context=next(row for row in obj['contexts'] if row['public']==phase['public'])
  blob=(a.build/(phase['object']+'.obj')).read_bytes()
  code,refs=v.bind_leaf_details(blob,phase['phase'],v.DATA_OFFSETS,address=phase['address'],functions=v.FUNCTION_ADDRESSES)
  assert code==exe[phase['address']+0x25600:phase['address']+0x25600+len(code)]
  v.verify_leaf_relocations(code,refs,pointers,phase['address']);assert len(refs)==2
  loaded,_=v.bind_leaf_details(blob,phase['phase'],data_bindings(),address=phase['address'],functions=v.FUNCTION_ADDRESSES)
  private=bytearray(obj['size'])
  for row in obj['contexts']:
   private[row['start']:row['start']+row['size']]=full_context(blob,row,SCRATCH+row['start'])
  reading='read_' in phase['public'];sectors=phase['object']=='svsect'
  count_offset,buffer,stride,maximum=(0x289154,0x27c3a0,40,1024) if sectors else (0x289152,0x2310a0,32,8192)
  for count in (0,1,maximum-1,maximum):
   size=count*stride
   for seed in (0,1):
    base=bytearray(BASES[seed]);struct.pack_into('<h',base,count_offset,count)
    run=dict(start_address=phase['address'],body_start=phase['begin'],public_start=context['start'],
             private_prefix='',private_pushes=int(phase['begin']!=0),private_result='count',
             stream_register='esi' if reading else 'edi',call_target=0x60638 if reading else 0x60944,
             record_bytes=phase['end']-phase['begin'],records=[dict(size=size,data_offset=buffer)],base_data=bytes(base))
    for limit in sorted({0,1,size//2,max(0,size-1),size}):
     exercise(run,loaded,reading,seed,limit);cases+=1
     exercise(run,loaded,reading,seed,limit,private=bytes(private));private_cases+=1
 # The reader seeds EDI before the table call; its private return exposes 511.
 phase=next(row for row in phases if row['phase']=='save_read_restore_words_phase_')
 obj=next(row for row in objects if row['object']=='svstep')
 context=next(row for row in obj['contexts'] if row['public']==phase['public'])
 blob=(a.build/'svstep.obj').read_bytes()
 loaded,_=v.bind_leaf_details(blob,phase['phase'],data_bindings(),address=phase['address'],functions=v.FUNCTION_ADDRESSES)
 private=full_context(blob,context,SCRATCH)
 for seed in (0,1):
  for limit in (0,1,1024,2047,2048):
   table_case(loaded,False,seed,limit);table_case(private,True,seed,limit)
 controls=0
 def rejected(bad,phase,message='context'):
  nonlocal controls
  try:v.bind_leaf_details(bad,phase['phase'],v.DATA_OFFSETS,address=phase['address'],functions=v.FUNCTION_ADDRESSES)
  except ValueError as exc:
   assert message in str(exc).lower(),str(exc)
   controls+=1
  else:raise AssertionError('Private dynamic context mutation escaped')
 rejected(mutate_public_byte(blob,context['public'],27),phase)
 rejected(rename_external(blob,b'_save_restore_words',b'_save_restore_wordt'),phase,message='fixup')
 for phase in phases:
  if phase['object'] not in ('svsect','svwall') or phase['begin']==0:continue
  blob=(a.build/(phase['object']+'.obj')).read_bytes()
  rejected(mutate_public_byte(blob,phase['public'],0),phase)
  obj=next(row for row in objects if row['object']==phase['object'])
  context=next(row for row in obj['contexts'] if row['public']==phase['public'])
  rejected(mutate_public_byte(blob,phase['public'],context['size']-1),phase)
 result=dict(status='PASS',dynamic_body_cases=cases,dynamic_private_cases=private_cases,
             table_read_cases=20,private_context_controls=controls,zero_and_maximum_counts=True)
 a.output.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(json.dumps(result))

if __name__=='__main__':main()

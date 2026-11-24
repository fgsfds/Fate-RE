"""Check fixed message copies, actual strlen, shared tails and saved pointers."""
import argparse,json,struct
from pathlib import Path
from unicorn import Uc,UC_ARCH_X86,UC_MODE_32,UC_HOOK_CODE
from unicorn.x86_const import *
import verify_c_leaf as v
from check_start_hook import image,DS
from check_ripple_stack import mutate_public_byte
from check_ripple_control import rename_external
from le_fixups import read_le_fixups

EXTENT,DESTINATION=0x28a300,0x7aa70
PRIVATE,STREAM,STACK,STOP=0x400000,0x4f8000,0x4ff000,0x4fff00
REGS=(UC_X86_REG_EAX,UC_X86_REG_EBX,UC_X86_REG_ECX,UC_X86_REG_EDX,
      UC_X86_REG_ESI,UC_X86_REG_EDI,UC_X86_REG_EBP)

def bindings():
 return dict(v.DATA_OFFSETS,_save_loaded_status=DS+DESTINATION,_save_saved_status=DS+DESTINATION,
             _save_loaded_message=DS+0x5ef,_save_saved_message=DS+0x60f)

def private_image(blob,obj):
 segments,pubs,*_=v.parsed_leaf_object(blob);result=bytearray(segments[pubs[0][0]]['data'])
 for context in obj['contexts']:
  alias=context['public']+'message_private_check'
  v.LEAF_CODE_SLICES[alias]=(context['public'],0,context['size'],context['size'])
  try:code,_=v.bind_leaf_details(blob,alias,bindings(),address=PRIVATE+context['start'],functions=v.FUNCTION_ADDRESSES)
  finally:del v.LEAF_CODE_SLICES[alias]
  result[context['start']:context['start']+context['size']]=code
 return bytes(result)

def exercise(memory,placed,private,context,reading,payload,seed,full_private):
 size=len(payload);source=0x5ef if reading else 0x60f;length=payload.index(0)
 cpu=Uc(UC_ARCH_X86,UC_MODE_32);cpu.mem_map(0,0x500000);cpu.mem_write(0,memory)
 # Native strlen loads ES from DS; use the target's flat protected-mode ABI.
 cpu.mem_write(0x1000,struct.pack('<QQQ',0,0x00cf9a000000ffff,0x00cf92000000ffff))
 cpu.reg_write(UC_X86_REG_GDTR,(0,0x1000,23,0))
 for reg in (UC_X86_REG_DS,UC_X86_REG_ES,UC_X86_REG_SS):cpu.reg_write(reg,0x10)
 for address,code in placed.items():cpu.mem_write(address,code)
 if full_private:cpu.mem_write(PRIVATE,private)
 entry=PRIVATE+context['start'] if full_private else 0x3095f if reading else 0x31e73
 end=STOP if full_private else 0x30977 if reading else 0x31e98
 pattern=bytes((i*73+seed*31)&255 for i in range(256))
 base=bytearray((pattern*((EXTENT+255)//256))[:EXTENT]);base[source:source+size]=payload
 expected=bytearray(base);expected[DESTINATION:DESTINATION+size]=payload
 cpu.mem_write(DS-16,b'\x5a'*16+bytes(base)+b'\xa5'*16)
 frame=struct.pack('<I',STOP)+b'\xcc'*60;cpu.mem_write(STACK,frame)
 cpu.mem_write(STACK-128,b'\x6c'*128);cpu.reg_write(UC_X86_REG_ESP,STACK)
 want={reg:0xabc00000+i for i,reg in enumerate(REGS)}
 if not reading and not full_private:want[UC_X86_REG_ESI]=STREAM
 for reg,value in want.items():cpu.reg_write(reg,value)
 cpu.reg_write(UC_X86_REG_EFLAGS,0x8d7) # Flat string ABI: equal DS/ES, DF clear.
 trace=[]
 def hook(machine,address,instruction_size,user):
  esp=machine.reg_read(UC_X86_REG_ESP)
  ret,=struct.unpack('<I',machine.mem_read(esp,4))
  if address==0x60944:
   assert not reading and not full_private
   args=tuple(machine.reg_read(reg) for reg in (UC_X86_REG_EAX,UC_X86_REG_EDX,UC_X86_REG_EBX,UC_X86_REG_ECX))
   assert args==(DS+0x174640,0x64c8,1,STREAM)
   assert esp==STACK-20 and ret==0x4034b
   assert machine.reg_read(UC_X86_REG_EDI)==DS+DESTINATION
   assert machine.reg_read(UC_X86_REG_ESI)==STREAM
   trace.append('crusher_write')
   for reg,value in ((UC_X86_REG_EAX,seed&1),(UC_X86_REG_EBX,0xb0000000),
                     (UC_X86_REG_ECX,0xc0000000),(UC_X86_REG_EDX,0xd0000000)):
    machine.reg_write(reg,value)
  elif address==0x60802:
   assert not reading and not full_private
   assert machine.reg_read(UC_X86_REG_EAX)==STREAM
   assert machine.reg_read(UC_X86_REG_ESI)==DS+source
   assert machine.reg_read(UC_X86_REG_EDI)==DS+DESTINATION
   assert esp==STACK-4 and ret==0x31e8b
   trace.append('close');machine.reg_write(UC_X86_REG_EAX,0xffffffff if seed&1 else 0)
  else:
   assert address==0x60381 and machine.reg_read(UC_X86_REG_EAX)==DS+DESTINATION
   assert machine.mem_read(DS+DESTINATION,size)==payload
   assert machine.reg_read(UC_X86_REG_ESI)==DS+source+size
   assert machine.reg_read(UC_X86_REG_EDI)==DS+DESTINATION+size
   assert esp==STACK-4 and ret==(PRIVATE+24 if full_private else end)
   trace.append('length')
   return # Execute the pinned native strlen implementation.
  machine.reg_write(UC_X86_REG_ESP,esp+4);machine.reg_write(UC_X86_REG_EIP,ret)
 for address in (0x60944,0x60802,0x60381):cpu.hook_add(UC_HOOK_CODE,hook,begin=address,end=address)
 cpu.emu_start(entry,end,count=200)
 assert trace==(['crusher_write','close','length'] if not reading and not full_private else ['length'])
 assert cpu.mem_read(DS-16,EXTENT+32)==b'\x5a'*16+bytes(expected)+b'\xa5'*16
 assert cpu.mem_read(STACK,len(frame))==frame and cpu.mem_read(STACK-128,96)==b'\x6c'*96
 want.update({UC_X86_REG_EAX:length,UC_X86_REG_ESI:DS+source+size,UC_X86_REG_EDI:DS+DESTINATION+size})
 if full_private:want[UC_X86_REG_EBX]=length
 assert cpu.reg_read(UC_X86_REG_EIP)==end,(hex(cpu.reg_read(UC_X86_REG_EIP)),hex(cpu.reg_read(UC_X86_REG_ESP)))
 assert all(cpu.reg_read(reg)==value for reg,value in want.items()),(reading,full_private,
   {reg:(cpu.reg_read(reg),value) for reg,value in want.items() if cpu.reg_read(reg)!=value})
 assert cpu.reg_read(UC_X86_REG_ESP)==STACK+(4 if full_private else 0)
 assert cpu.reg_read(UC_X86_REG_EIP)==end and not cpu.reg_read(UC_X86_REG_EFLAGS)&0x400
 assert all(cpu.reg_read(reg)==0x10 for reg in (UC_X86_REG_DS,UC_X86_REG_ES,UC_X86_REG_SS))

def main():
 p=argparse.ArgumentParser(description=__doc__)
 p.add_argument('--exe',type=Path,required=True);p.add_argument('--build',type=Path,required=True)
 p.add_argument('--output',type=Path,required=True);a=p.parse_args()
 exe=a.exe.read_bytes();memory=image(exe);pointers=read_le_fixups(exe)['pointers']
 blob=(a.build/'svmsg.obj').read_bytes()
 obj=next(row for row in v.SAVE_DYNAMIC_LAYOUT['objects'] if row['object']=='svmsg')
 phases=[row for row in v.SAVE_DYNAMIC_LAYOUT['phases'] if row['object']=='svmsg'];placed={}
 for phase in phases:
  address=phase['address'];size=phase['end']-phase['begin']
  code,refs=v.bind_leaf_details(blob,phase['phase'],v.DATA_OFFSETS,address=address,functions=v.FUNCTION_ADDRESSES)
  assert code==exe[address+0x25600:address+0x25600+size]
  v.verify_leaf_relocations(code,refs,pointers,address)
  placed[address]=v.bind_leaf_details(blob,phase['phase'],bindings(),address=address,functions=v.FUNCTION_ADDRESSES)[0]
 private=private_image(blob,obj);cases={'placed_read':0,'placed_write':0,'private_read':0,'private_write':0}
 for reading,size,source in ((True,13,0x5ef),(False,12,0x60f)):
  context=next(row for row in obj['contexts'] if row['public']==('save_copy_loaded_message_' if reading else 'save_copy_saved_message_'))
  original=memory[DS+source:DS+source+size];assert original[-1]==0
  payloads=[(original,0)]
  for seed in range(3):
   for stop in range(size):
    payload=bytearray(((i*37+seed*71+1)&255) or 0x7f for i in range(size));payload[stop]=0
    payloads.append((bytes(payload),seed))
  for payload,seed in payloads:
   for full_private in (False,True):
    exercise(memory,placed,private,context,reading,payload,seed,full_private)
    cases[('private_' if full_private else 'placed_')+('read' if reading else 'write')]+=1
 controls=0
 def rejected(bad,phase,message='context'):
  nonlocal controls
  try:v.bind_leaf_details(bad,phase['phase'],v.DATA_OFFSETS,address=phase['address'],functions=v.FUNCTION_ADDRESSES)
  except ValueError as exc:
   assert message in str(exc).lower(),str(exc);controls+=1
  else:raise AssertionError('Message private context mutation escaped')
 read=next(row for row in phases if row['public']=='save_copy_loaded_message_')
 saved=next(row for row in phases if row['public']=='save_copy_saved_message_')
 rejected(mutate_public_byte(blob,read['public'],24),read)
 rejected(mutate_public_byte(blob,saved['public'],18),saved)
 rejected(rename_external(blob,b'_save_saved_message',b'_save_saved_messagf'),saved,'fixup')
 rejected(rename_external(blob,b'strlen_',b'strlem_'),read,'fixup')
 digest=v.LEAF_CONTEXT_SHA256.pop(read['public'])
 try:rejected(mutate_public_byte(blob,read['public'],11),read,'addend')
 finally:v.LEAF_CONTEXT_SHA256[read['public']]=digest
 result=dict(status='PASS',**cases,native_strlen_cases=sum(cases.values()),
             real_crusher_wrapper_cases=cases['placed_write'],close_and_fwrite_abi_stubs=True,
             private_context_controls=controls,fixed_extent_and_post_nul_bytes_checked=True)
 a.output.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(json.dumps(result))

if __name__=='__main__':main()

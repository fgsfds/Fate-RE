"""Check filename frames, native forward append, open failure and header I/O."""
import argparse,json,struct
from pathlib import Path
from unicorn import Uc,UC_ARCH_X86,UC_MODE_32,UC_HOOK_CODE
from unicorn.x86_const import *
import verify_c_leaf as v
from check_start_hook import image,DS
from check_ripple_stack import mutate_public_byte
from check_ripple_control import rename_external
from le_fixups import read_le_fixups

EXTENT=0x28a300
PRIVATE,STREAM,STACK,STOP=0x400000,0x4f8000,0x4ff000,0x4fff00
REGS=(UC_X86_REG_EAX,UC_X86_REG_EBX,UC_X86_REG_ECX,UC_X86_REG_EDX,
      UC_X86_REG_ESI,UC_X86_REG_EDI,UC_X86_REG_EBP)
NAMES=('load_slot_format','save_slot_format','load_basename','save_basename',
       'load_mode','save_mode','player_count','local_player')

def bindings():
 return dict(v.DATA_OFFSETS,**{'_'+name:DS+v.DATA_OFFSETS['_'+name] for name in NAMES})

def private_image(blob,obj):
 segments,pubs,*_=v.parsed_leaf_object(blob);result=bytearray(segments[pubs[0][0]]['data'])
 for context in obj['contexts']:
  alias=context['public']+'opening_private_check'
  v.LEAF_CODE_SLICES[alias]=(context['public'],0,context['size'],context['size'])
  try:code,_=v.bind_leaf_details(blob,alias,bindings(),address=PRIVATE+context['start'],functions=v.FUNCTION_ADDRESSES)
  finally:del v.LEAF_CODE_SLICES[alias]
  result[context['start']:context['start']+context['size']]=code
 return bytes(result)

def cleanup_case(entry,code,result):
 cpu=Uc(UC_ARCH_X86,UC_MODE_32);cpu.mem_map(0,0x500000);cpu.mem_write(entry,code)
 cpu.mem_write(0x1000,struct.pack('<QQQ',0,0x00cf9a000000ffff,0x00cf92000000ffff))
 cpu.reg_write(UC_X86_REG_GDTR,(0,0x1000,23,0))
 for reg in (UC_X86_REG_DS,UC_X86_REG_ES,UC_X86_REG_SS):cpu.reg_write(reg,0x10)
 want={reg:0xabc00000+i for i,reg in enumerate(REGS)};want[UC_X86_REG_EAX]=result
 for reg in REGS:cpu.reg_write(reg,0xdead0000+reg)
 cpu.reg_write(UC_X86_REG_EAX,result);cpu.reg_write(UC_X86_REG_EBP,want[UC_X86_REG_EBP])
 frame=bytearray(b'\xa5'*192)
 struct.pack_into('<5I',frame,108,*(want[reg] for reg in (UC_X86_REG_EDI,UC_X86_REG_ESI,UC_X86_REG_EDX,UC_X86_REG_ECX,UC_X86_REG_EBX)))
 struct.pack_into('<I',frame,128,STOP)
 cpu.mem_write(STACK-128,bytes(frame));cpu.reg_write(UC_X86_REG_ESP,STACK-40)
 cpu.emu_start(entry,STOP,count=20)
 assert cpu.mem_read(STACK-128,len(frame))==frame
 assert all(cpu.reg_read(reg)==value for reg,value in want.items())
 assert cpu.reg_read(UC_X86_REG_ESP)==STACK+4 and cpu.reg_read(UC_X86_REG_EIP)==STOP

def exercise(memory,placed,private,obj,context,reading,slot,opened,limit,seed,full_private):
 cpu=Uc(UC_ARCH_X86,UC_MODE_32);cpu.mem_map(0,0x500000);cpu.mem_write(0,memory)
 cpu.mem_write(0x1000,struct.pack('<QQQ',0,0x00cf9a000000ffff,0x00cf92000000ffff))
 cpu.reg_write(UC_X86_REG_GDTR,(0,0x1000,23,0))
 for reg in (UC_X86_REG_DS,UC_X86_REG_ES,UC_X86_REG_SS):cpu.reg_write(reg,0x10)
 for address,code in placed.items():cpu.mem_write(address,code)
 if full_private:cpu.mem_write(PRIVATE,private)
 original=0x2f46b if reading else 0x309a3
 entry=PRIVATE+context['start'] if full_private else original
 end=STOP if full_private or not opened else original+102
 local=STACK-40;suffix=b'.G'+f'{slot:02d}'.encode()+b'\0';filename=b'GAMEDATA'+suffix
 expected_local=bytearray(b'\xa5'*20);expected_local[12:17]=suffix
 expected_local[:13]=filename
 base=bytearray(memory[DS:DS+EXTENT])
 struct.pack_into('<HH',base,0x13ce0,0x93b1+seed,0x1e70+seed)
 expected=bytearray(base);cpu.mem_write(DS-16,b'\x5a'*16+bytes(base)+b'\xa5'*16)
 cpu.mem_write(STACK-256,b'\xa5'*512)
 frame=struct.pack('<I',STOP)+b'\xcc'*60;cpu.mem_write(STACK,frame)
 cpu.reg_write(UC_X86_REG_ESP,STACK)
 want={reg:0xabc00000+i for i,reg in enumerate(REGS)};want[UC_X86_REG_EAX]=slot
 for reg,value in want.items():cpu.reg_write(reg,value)
 cpu.reg_write(UC_X86_REG_EFLAGS,0x8d7)
 direction='load' if reading else 'save'
 format_address=DS+v.DATA_OFFSETS['_'+direction+'_slot_format']
 mode_address=DS+v.DATA_OFFSETS['_'+direction+'_mode']
 basename_address=DS+v.DATA_OFFSETS['_'+direction+'_basename']
 close_context,close_site=next((row,int(site)) for row in obj['contexts'] for site,spec in row['fixups'].items() if spec[0]=='fclose_')
 close_return=PRIVATE+close_context['start']+close_site+4
 io_target=0x60638 if reading else 0x60944
 io_count=cursor=0;trace=[];output=bytearray();last=0
 payload=bytes((0x31+i*71+seed)&255 for i in range(4))
 def complete_call(machine,esp,ret):
  machine.reg_write(UC_X86_REG_ESP,esp+4);machine.reg_write(UC_X86_REG_EIP,ret)
 def hook(machine,address,instruction_size,user):
  nonlocal io_count,cursor,last
  esp=machine.reg_read(UC_X86_REG_ESP)
  if address==entry+68:
   assert machine.reg_read(UC_X86_REG_EAX)==(STREAM if opened else 0)
   assert machine.reg_read(UC_X86_REG_EDI)==(STREAM if opened else 0)
   assert machine.reg_read(UC_X86_REG_ESI)==(STREAM if opened else 0)
   assert esp==local and machine.mem_read(local,20)==expected_local
   saved=struct.pack('<5I',*(want[reg] for reg in (UC_X86_REG_EDI,UC_X86_REG_ESI,UC_X86_REG_EDX,UC_X86_REG_ECX,UC_X86_REG_EBX)))
   assert machine.mem_read(STACK-20,20)==saved
   assert machine.reg_read(UC_X86_REG_EFLAGS)&0x8c5==(4 if opened else 0x44)
   trace.append('test');return
  ret,=struct.unpack('<I',machine.mem_read(esp,4))
  if address==0x601f3:
   destination,pattern,index=struct.unpack('<3I',machine.mem_read(esp+4,12))
   assert (destination,pattern,index)==(local+12,format_address,slot)
   assert machine.mem_read(pattern,7)==b'.G%.2i\0'
   assert machine.reg_read(UC_X86_REG_EAX)==local+12 and machine.reg_read(UC_X86_REG_EDX)==local+12
   assert machine.reg_read(UC_X86_REG_EDI)==local and machine.reg_read(UC_X86_REG_ESI)==basename_address
   assert esp==STACK-56 and ret==entry+37
   machine.mem_write(destination,suffix);machine.reg_write(UC_X86_REG_EAX,4)
   trace.append('format');complete_call(machine,esp,ret)
  elif address==0x60223:
   assert machine.reg_read(UC_X86_REG_EAX)==local and machine.reg_read(UC_X86_REG_EDX)==local+12
   assert machine.reg_read(UC_X86_REG_EDI)==local+9 and machine.reg_read(UC_X86_REG_ESI)==basename_address+9
   assert machine.mem_read(local,9)==b'GAMEDATA\0' and machine.mem_read(local+12,5)==suffix
   assert esp==local-4 and ret==entry+50
   trace.append('append');return # Execute the pinned forward-pair-copy runtime.
  elif address==0x605a2:
   assert machine.reg_read(UC_X86_REG_EAX)==local and machine.reg_read(UC_X86_REG_EDX)==mode_address
   assert machine.mem_read(local,len(filename))==filename and machine.mem_read(local,20)==expected_local
   assert machine.mem_read(mode_address,3)==(b'rb\0' if reading else b'wb\0')
   assert esp==local-4 and ret==entry+62
   machine.reg_write(UC_X86_REG_EAX,STREAM if opened else 0)
   machine.reg_write(UC_X86_REG_EDX,0xd0abcdef)
   machine.reg_write(UC_X86_REG_EFLAGS,0x8d7)
   trace.append('open');complete_call(machine,esp,ret)
  elif address==io_target:
   assert opened and io_count<(2 if full_private else 1)
   offset=0x13ce0+2*io_count
   args=tuple(machine.reg_read(reg) for reg in (UC_X86_REG_EAX,UC_X86_REG_EDX,UC_X86_REG_EBX,UC_X86_REG_ECX))
   assert args==(DS+offset,2,1,STREAM)
   assert machine.reg_read(UC_X86_REG_ESI)==STREAM and machine.reg_read(UC_X86_REG_EDI)==STREAM
   assert esp==local-4 and ret==(entry+(99 if io_count==0 else 121) if full_private else original+102)
   amount=min(2,max(0,limit-cursor));last=int(amount==2)
   if reading:
    if amount:machine.mem_write(DS+offset,payload[cursor:cursor+amount])
    expected[offset:offset+amount]=payload[cursor:cursor+amount]
   else:output.extend(base[offset:offset+amount])
   cursor+=amount
   for reg,value in ((UC_X86_REG_EAX,last),(UC_X86_REG_EBX,0xb0000000+io_count),
                     (UC_X86_REG_ECX,0xc0000000+io_count),(UC_X86_REG_EDX,0xd0000000+io_count)):
    machine.reg_write(reg,value)
   trace.append('transfer');io_count+=1;complete_call(machine,esp,ret)
  else:
   assert address==0x60802 and full_private and opened and io_count==2
   assert machine.reg_read(UC_X86_REG_EAX)==STREAM and machine.reg_read(UC_X86_REG_ESI)==STREAM
   assert esp==local-4 and ret==close_return
   machine.reg_write(UC_X86_REG_EAX,0xffffffff if seed else 0)
   trace.append('close');complete_call(machine,esp,ret)
 for address in (0x601f3,0x60223,0x605a2,io_target,0x60802,entry+68):
  cpu.hook_add(UC_HOOK_CODE,hook,begin=address,end=address)
 cpu.emu_start(entry,end,count=1000)
 expected_trace=['format','append','open','test']
 if opened:expected_trace+=['transfer']*(2 if full_private else 1)
 if opened and full_private:expected_trace+=['close']
 assert trace==expected_trace
 assert cpu.mem_read(DS-16,EXTENT+32)==b'\x5a'*16+bytes(expected)+b'\xa5'*16
 if not reading:assert output==base[0x13ce0:0x13ce0+min(limit,4 if full_private else 2)]
 assert cpu.mem_read(STACK,64)==frame and cpu.mem_read(STACK-256,160)==b'\xa5'*160
 assert cpu.mem_read(local,20)==expected_local
 if full_private or not opened:
  want[UC_X86_REG_EAX]=(0xffffffff if not opened or seed else 0)
  assert cpu.reg_read(UC_X86_REG_ESP)==STACK+4
 else:
  want.update({UC_X86_REG_EAX:last,UC_X86_REG_EBX:0xb0000000,UC_X86_REG_ECX:0xc0000000,
               UC_X86_REG_EDX:0xd0000000,UC_X86_REG_ESI:STREAM,UC_X86_REG_EDI:STREAM})
  assert cpu.reg_read(UC_X86_REG_ESP)==local
 assert all(cpu.reg_read(reg)==value for reg,value in want.items())
 assert cpu.reg_read(UC_X86_REG_EIP)==end and not cpu.reg_read(UC_X86_REG_EFLAGS)&0x400
 assert all(cpu.reg_read(reg)==0x10 for reg in (UC_X86_REG_DS,UC_X86_REG_ES,UC_X86_REG_SS))

def main():
 p=argparse.ArgumentParser(description=__doc__)
 p.add_argument('--exe',type=Path,required=True);p.add_argument('--build',type=Path,required=True)
 p.add_argument('--output',type=Path,required=True);a=p.parse_args()
 exe=a.exe.read_bytes();memory=image(exe);pointers=read_le_fixups(exe)['pointers']
 blob=(a.build/'svopen.obj').read_bytes()
 obj=next(row for row in v.SAVE_DYNAMIC_LAYOUT['objects'] if row['object']=='svopen')
 phases=[row for row in v.SAVE_DYNAMIC_LAYOUT['phases'] if row['object']=='svopen'];placed={}
 for phase in phases:
  address=phase['address'];size=phase['end']-phase['begin']
  code,refs=v.bind_leaf_details(blob,phase['phase'],v.DATA_OFFSETS,address=address,functions=v.FUNCTION_ADDRESSES)
  assert code==exe[address+0x25600:address+0x25600+size]
  v.verify_leaf_relocations(code,refs,pointers,address)
  placed[address]=v.bind_leaf_details(blob,phase['phase'],bindings(),address=address,functions=v.FUNCTION_ADDRESSES)[0]
 private=private_image(blob,obj);counts={'placed_success':0,'placed_failure':0,'private_success':0,'private_failure':0}
 cleanup_cases=0
 for address in (0x3099a,0x31ebb):
  for result in (0,1,0xffffffff):cleanup_case(address,placed[address],result);cleanup_cases+=1
 for reading in (True,False):
  context=next(row for row in obj['contexts'] if row['public']==('save_open_read_slot_' if reading else 'save_open_write_slot_'))
  for slot in range(10):
   for seed in (0,1):
    for full_private in (False,True):
     for opened in (False,True):
      for limit in (range(5 if full_private else 3) if opened else (0,)):
       exercise(memory,placed,private,obj,context,reading,slot,opened,limit,seed,full_private)
       counts[('private_' if full_private else 'placed_')+('success' if opened else 'failure')]+=1
 controls=0;phase=next(row for row in phases if row['phase']=='save_read_path_phase_')
 def rejected(bad,message='context'):
  nonlocal controls
  try:v.bind_leaf_details(bad,phase['phase'],v.DATA_OFFSETS,address=phase['address'],functions=v.FUNCTION_ADDRESSES)
  except ValueError as exc:
   assert message in str(exc).lower(),str(exc);controls+=1
  else:raise AssertionError('Slot opening context mutation escaped')
 rejected(mutate_public_byte(blob,phase['public'],68))
 rejected(mutate_public_byte(blob,phase['public'],136))
 rejected(rename_external(blob,b'strcat_',b'strcam_'),'fixup')
 digest=v.LEAF_CONTEXT_SHA256.pop(phase['public'])
 try:rejected(mutate_public_byte(blob,phase['public'],110),'addend')
 finally:v.LEAF_CONTEXT_SHA256[phase['public']]=digest
 result=dict(status='PASS',**counts,slots=10,native_overlapping_append_cases=sum(counts.values()),
             cleanup_cases=cleanup_cases,full_context_controls=controls,format_open_header_close_abi_stubs=True,
             retained_failure_branch_and_c_cleanup_placed=True,complete_data_and_frame_guards=True)
 a.output.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(json.dumps(result))

if __name__=='__main__':main()

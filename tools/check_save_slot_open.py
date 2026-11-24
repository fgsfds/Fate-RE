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
       'load_mode','save_mode','player_count','local_player','first_player',
       'next_player','player_x','player_y')

def bindings():
 return dict(v.DATA_OFFSETS,**{'_'+name:DS+v.DATA_OFFSETS['_'+name] for name in NAMES})

def private_limits(reading):
 records=[(0x13ce0,2),(0x13ce2,2),(0x19028a,2),(0x18fd78,32),(0x5ad9c,64)]
 if not reading:records.append((0x5ad5c,64))
 total=sum(size for _,size in records);values={0,1,total,total-1};cursor=0
 for _,size in records:
  cursor+=size
  values.update(max(0,min(total,cursor+d)) for d in (-1,0,1))
 return tuple(sorted(values))

def private_image(blob,obj):
 segments,pubs,*_=v.parsed_leaf_object(blob);result=bytearray(segments[pubs[0][0]]['data'])
 for context in obj['contexts']:
  alias=context['public']+'opening_private_check'
  v.LEAF_CODE_SLICES[alias]=(context['public'],0,context['size'],context['size'])
  branch=v.LEAF_SECTION_BRANCHES.pop(context['public'],None)
  try:code,_=v.bind_leaf_details(blob,alias,bindings(),address=PRIVATE+context['start'],functions=v.FUNCTION_ADDRESSES)
  finally:
   del v.LEAF_CODE_SLICES[alias]
   if branch is not None:v.LEAF_SECTION_BRANCHES[context['public']]=branch
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
 records=[(0x13ce0,2),(0x13ce2,2),(0x19028a,2),(0x18fd78,32),(0x5ad9c,64)]
 if not reading:records.append((0x5ad5c,64))
 total=sum(size for _,size in records)
 initial=0 if seed==0 else 15;incoming=15 if seed==0 else 0
 struct.pack_into('<HH',base,0x13ce0,1,initial)
 struct.pack_into('<h',base,0x19028a,initial)
 struct.pack_into('<16h',base,0x18fd78,*([-1]*16))
 header=bytearray(total);struct.pack_into('<HHh',header,0,2,incoming,incoming)
 header[6:]=bytes((0x31+i*71+seed)&255 for i in range(total-6))
 struct.pack_into('<16h',header,6,*([-1]*16))
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
 io_target=0x60638 if reading else 0x60944
 io_count=cursor=0;trace=[];output=bytearray();last=0
 payload=bytes(header)
 io_returns=sorted(PRIVATE+context['start']+int(site)+4 for site,spec in context['fixups'].items() if spec[0]==('fread_' if reading else 'fwrite_'))
 close_site=next(int(site) for site,spec in context['fixups'].items() if spec[0]=='fclose_')
 close_return=PRIVATE+context['start']+close_site+4
 init_return=next((PRIVATE+context['start']+int(site)+4 for site,spec in context['fixups'].items() if spec[0]=='initialize_board_entry_'),None)
 # Independently model the serialized records and partial input before execution.
 remaining=limit;payload_cursor=0;expected_output=bytearray()
 for offset,size in (records if full_private else records[:1]):
  amount=min(size,max(0,remaining));remaining-=amount
  if reading:expected[offset:offset+amount]=payload[payload_cursor:payload_cursor+amount]
  else:expected_output.extend(base[offset:offset+amount])
  payload_cursor+=amount
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
   assert opened and io_count<(len(records) if full_private else 1)
   record_index=io_count if full_private else 0
   offset,size=records[record_index]
   args=tuple(machine.reg_read(reg) for reg in (UC_X86_REG_EAX,UC_X86_REG_EDX,UC_X86_REG_EBX,UC_X86_REG_ECX))
   assert args==(DS+offset,size,1,STREAM)
   assert machine.reg_read(UC_X86_REG_ESI)==STREAM
   assert machine.reg_read(UC_X86_REG_EDI)==(0xffffffff if reading and io_count==4 else STREAM)
   assert esp==local-4 and ret==(io_returns[io_count] if full_private else original+102)
   amount=min(size,max(0,limit-cursor));last=int(amount==size)
   if reading:
    if amount:machine.mem_write(DS+offset,payload[cursor:cursor+amount])
   else:output.extend(base[offset:offset+amount])
   cursor+=amount
   for reg,value in ((UC_X86_REG_EAX,last),(UC_X86_REG_EBX,0xb0000000+io_count),
                     (UC_X86_REG_ECX,0xc0000000+io_count),(UC_X86_REG_EDX,0xd0000000+io_count)):
    machine.reg_write(reg,value)
   trace.append('transfer');io_count+=1;complete_call(machine,esp,ret)
  elif address==0x2e14f:
   player=struct.unpack_from('<h',expected,0x19028a)[0]
   assert full_private and reading and io_count==4 and machine.reg_read(UC_X86_REG_EAX)==player
   assert machine.reg_read(UC_X86_REG_EDI)==player and machine.reg_read(UC_X86_REG_ESI)==STREAM
   assert esp==local-4 and ret==init_return
   trace.append('initialize');machine.reg_write(UC_X86_REG_EAX,0xa0000000+player);complete_call(machine,esp,ret)
  else:
   assert address==0x60802 and full_private and opened and io_count==len(records)
   assert machine.reg_read(UC_X86_REG_EAX)==STREAM and machine.reg_read(UC_X86_REG_ESI)==STREAM
   assert esp==local-4 and ret==close_return
   machine.reg_write(UC_X86_REG_EAX,0xffffffff if seed else 0)
   trace.append('close');complete_call(machine,esp,ret)
 for address in (0x601f3,0x60223,0x605a2,io_target,0x2e14f,0x60802,entry+68):
  cpu.hook_add(UC_HOOK_CODE,hook,begin=address,end=address)
 cpu.emu_start(entry,end,count=1000)
 expected_trace=['format','append','open','test']
 if opened:
  expected_trace+=(['transfer']*4+['initialize','transfer'] if full_private and reading else ['transfer']*(len(records) if full_private else 1))
 if opened and full_private:expected_trace+=['close']
 assert trace==expected_trace
 assert cpu.mem_read(DS-16,EXTENT+32)==b'\x5a'*16+bytes(expected)+b'\xa5'*16
 if not reading:assert output==expected_output
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
 phases=[row for row in v.SAVE_DYNAMIC_LAYOUT['phases'] if row['object'] in ('svoread','svowrite')]
 placed={};objects={}
 for name in ('svoread','svowrite'):
  blob=(a.build/f'{name}.obj').read_bytes()
  obj=next(row for row in v.SAVE_DYNAMIC_LAYOUT['objects'] if row['object']==name);objects[name]=obj
  assert len(obj['contexts'])==1 and obj['contexts'][0]['start']==0
  priv=private_image(blob,obj)
  for phase in (row for row in phases if row['object']==name):
   address=phase['address'];size=phase['end']-phase['begin']
   code,refs=v.bind_leaf_details(blob,phase['phase'],v.DATA_OFFSETS,address=address,functions=v.FUNCTION_ADDRESSES)
   assert code==exe[address+0x25600:address+0x25600+size]
   v.verify_leaf_relocations(code,refs,pointers,address)
   placed[address]=v.bind_leaf_details(blob,phase['phase'],bindings(),address=address,functions=v.FUNCTION_ADDRESSES)[0]
  objects[name]=dict(obj,private_image=priv,blob=blob)
 private_by_name={name:row['private_image'] for name,row in objects.items()}
 for start,cleanup in ((0x2f46b,0x3099a),(0x309a3,0x31ebb)):
  spans=sorted((address,address+len(code)) for address,code in placed.items() if start<=address<start+102)
  cursor=start
  for begin,end in spans:
   assert begin==cursor;cursor=end
  assert cursor==start+102 and len(placed[cleanup])==9
 counts={'placed_success':0,'placed_failure':0,'private_success':0,'private_failure':0}
 cleanup_cases=0
 for address in (0x3099a,0x31ebb):
  for result in (0,1,0xffffffff):cleanup_case(address,placed[address],result);cleanup_cases+=1
 for reading in (True,False):
  obj=objects['svoread' if reading else 'svowrite'];private=private_by_name['svoread' if reading else 'svowrite']
  context=next(row for row in obj['contexts'] if row['public']==('save_open_read_slot_' if reading else 'save_open_write_slot_'))
  for slot in range(10):
   for seed in (0,1):
    for full_private in (False,True):
     for opened in (False,True):
      limits=private_limits(reading) if full_private and opened else ((0,1,2) if opened else (0,))
      for limit in limits:
       exercise(memory,placed,private,obj,context,reading,slot,opened,limit,seed,full_private)
       counts[('private_' if full_private else 'placed_')+('success' if opened else 'failure')]+=1
 controls=0;phase=next(row for row in phases if row['phase']=='save_read_path_phase_')
 obj=objects['svoread'];blob=obj['blob'];context=obj['contexts'][0]
 def rejected(bad,message='context'):
  nonlocal controls
  try:v.bind_leaf_details(bad,phase['phase'],v.DATA_OFFSETS,address=phase['address'],functions=v.FUNCTION_ADDRESSES)
  except ValueError as exc:
   assert message in str(exc).lower(),str(exc);controls+=1
  else:raise AssertionError('Slot opening context mutation escaped')
 rejected(mutate_public_byte(blob,phase['public'],102))
 rejected(mutate_public_byte(blob,phase['public'],context['size']-1))
 rejected(rename_external(blob,b'strcat_',b'strcam_'),'fixup')
 digest=v.LEAF_CONTEXT_SHA256.pop(phase['public'])
 site=next(int(site) for site,spec in context['fixups'].items() if int(site)>=102 and not spec[1])
 try:rejected(mutate_public_byte(blob,phase['public'],site),'addend')
 finally:v.LEAF_CONTEXT_SHA256[phase['public']]=digest
 result=dict(status='PASS',**counts,slots=10,native_overlapping_append_cases=sum(counts.values()),
             cleanup_cases=cleanup_cases,full_context_controls=controls,format_open_header_close_abi_stubs=True,
             fully_c_failure_and_cleanup_placed=True,complete_data_and_frame_guards=True)
 a.output.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(json.dumps(result))

if __name__=='__main__':main()

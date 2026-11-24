"""Check serialized field order, partial transfers, call ABI and private cursors."""
import argparse,json,struct
from pathlib import Path
from unicorn import Uc,UC_ARCH_X86,UC_MODE_32,UC_HOOK_CODE
from unicorn.x86_const import *
from check_start_hook import image,DS
from check_ripple_stack import mutate_public_byte
from check_ripple_control import rename_external
from le_fixups import read_le_fixups
import verify_c_leaf as v

EXTENT=0x28a300
SCRATCH,STREAM,STACK,STOP=0x400000,0x4f8000,0x4ff000,0x4fff00
REGS=(UC_X86_REG_EAX,UC_X86_REG_EBX,UC_X86_REG_ECX,UC_X86_REG_EDX,
      UC_X86_REG_ESI,UC_X86_REG_EDI,UC_X86_REG_EBP)
BASES={seed:(bytes((i*73+seed*31)&255 for i in range(256))*((EXTENT+255)//256))[:EXTENT]
       for seed in (0,1)}

def oracle(run,base,reading,seed,limit):
 total=sum(row['size'] for row in run['records'])
 payload=(bytes((255-i*37+seed*17)&255 for i in range(256))*((total+255)//256))[:total]
 position=0;expected=bytearray(base);output=bytearray();trace=[];last_complete=0
 for row in run['records']:
  size,offset=row['size'],row['data_offset'];amount=min(size,max(0,limit-position))
  trace.append((DS+offset,size,1,STREAM,position,amount))
  if reading:expected[offset:offset+amount]=payload[position:position+amount]
  else:output.extend(base[offset:offset+amount])
  position+=amount;last_complete=int(amount==size)
 return payload,bytes(expected),bytes(output),trace,last_complete

def exercise(run,code,reading,seed,limit,private=None):
 base=BASES[seed];payload,want_data,want_output,want_trace,last=oracle(run,base,reading,seed,limit)
 cpu=Uc(UC_ARCH_X86,UC_MODE_32);cpu.mem_map(0,0x500000)
 entry=run['start_address'] if private is None else SCRATCH+run['public_start']
 cpu.mem_write(entry,code) if private is None else cpu.mem_write(SCRATCH,private)
 cpu.mem_write(DS-16,b'\x5a'*16+base+b'\xa5'*16)
 frame=struct.pack('<I',0x12345678 if private is None else STOP)+b'\xcc'*60
 cpu.mem_write(STACK,frame);cpu.reg_write(UC_X86_REG_ESP,STACK)
 want={reg:0xabc00000+i for i,reg in enumerate(REGS)}
 file_reg=UC_X86_REG_ESI if run['stream_register']=='esi' else UC_X86_REG_EDI
 want[file_reg]=STREAM
 for reg,value in want.items():cpu.reg_write(reg,value)
 cpu.reg_write(UC_X86_REG_EFLAGS,0x202)
 cursor=0;actual_trace=[];output=bytearray();calls=0
 def transfer(machine,address,size,user):
  nonlocal cursor,calls
  assert calls<len(run['records'])
  ptr,n,count,stream=(machine.reg_read(reg) for reg in (UC_X86_REG_EAX,UC_X86_REG_EDX,UC_X86_REG_EBX,UC_X86_REG_ECX))
  assert count==1 and stream==STREAM
  assert DS<=ptr<ptr+n<=DS+EXTENT
  amount=min(n,max(0,limit-cursor));actual_trace.append((ptr,n,count,stream,cursor,amount))
  assert actual_trace[-1]==want_trace[calls]
  esp=machine.reg_read(UC_X86_REG_ESP)
  pushes=0 if private is None else len(bytes.fromhex(run['private_prefix']))
  assert esp==STACK-4-4*pushes,'Transfer must be CALL with only the guarded private saves'
  ret,=struct.unpack('<I',machine.mem_read(esp,4))
  assert ret==entry+(0 if private is None else run['body_start'])+run.get('record_bytes',22)*(calls+1)
  if reading:
   if amount:machine.mem_write(ptr,payload[cursor:cursor+amount])
  else:output.extend(machine.mem_read(ptr,amount))
  cursor+=amount
  for reg,value in ((UC_X86_REG_EAX,int(amount==n)),(UC_X86_REG_EBX,0xb0000000+calls),
                    (UC_X86_REG_ECX,0xc0000000+calls),(UC_X86_REG_EDX,0xd0000000+calls)):
   machine.reg_write(reg,value)
  machine.reg_write(UC_X86_REG_EFLAGS,0x202|(calls&1))
  machine.reg_write(UC_X86_REG_ESP,esp+4);machine.reg_write(UC_X86_REG_EIP,ret);calls+=1
 handle=cpu.hook_add(UC_HOOK_CODE,transfer,begin=run['call_target'],end=run['call_target'])
 try:cpu.emu_start(entry,entry+len(code) if private is None else STOP,count=len(run['records'])*12+200)
 finally:cpu.hook_del(handle)
 assert calls==len(run['records']) and actual_trace==want_trace
 assert cpu.mem_read(DS-16,EXTENT+32)==b'\x5a'*16+want_data+b'\xa5'*16
 assert bytes(output)==want_output
 assert cpu.mem_read(STACK,len(frame))==frame
 for reg in (UC_X86_REG_ESI,UC_X86_REG_EDI,UC_X86_REG_EBP):assert cpu.reg_read(reg)==want[reg]
 if private is None:
  assert cpu.reg_read(UC_X86_REG_EIP)==entry+len(code) and cpu.reg_read(UC_X86_REG_ESP)==STACK
  for reg,value in ((UC_X86_REG_EAX,last),(UC_X86_REG_EBX,0xb0000000+calls-1),
                    (UC_X86_REG_ECX,0xc0000000+calls-1),(UC_X86_REG_EDX,0xd0000000+calls-1)):
   assert cpu.reg_read(reg)==value
  assert cpu.reg_read(UC_X86_REG_EFLAGS)==0x202|((calls-1)&1)
 else:
  final=run['records'][-1]
  assert cpu.reg_read(UC_X86_REG_EBX)==DS+final['data_offset']+last*final['size']
  assert cpu.reg_read(UC_X86_REG_EIP)==STOP and cpu.reg_read(UC_X86_REG_ESP)==STACK+4

def private_image(blob,routine):
 segments,pubs,*_=v.parsed_leaf_object(blob);result=bytearray(segments[pubs[0][0]]['data'])
 for run in routine['runs']:
  alias=run['public']+'private_check';v.LEAF_CODE_SLICES[alias]=(run['public'],0,run['public_size'],run['public_size'])
  try:
   code,_=v.bind_leaf_details(blob,alias,dict(v.DATA_OFFSETS,_save_data_image=DS),
                              address=SCRATCH+run['public_start'],functions=v.FUNCTION_ADDRESSES)
  finally:del v.LEAF_CODE_SLICES[alias]
  result[run['public_start']:run['public_start']+run['public_size']]=code
 return bytes(result)

def main():
 p=argparse.ArgumentParser(description=__doc__)
 p.add_argument('--exe',type=Path,required=True);p.add_argument('--build',type=Path,required=True)
 p.add_argument('--output',type=Path,required=True);a=p.parse_args()
 exe=a.exe.read_bytes();image(exe);pointers=read_le_fixups(exe)['pointers'];layout=dict(routines=v.SAVE_IO_ROUTINES)
 h=struct.unpack_from('<I',exe,60)[0];objects=struct.unpack_from('<I',exe,h+0x40)[0]
 assert struct.unpack_from('<II',exe,h+objects+24)==(EXTENT,DS)
 body_cases=private_cases=fields=native=0
 for routine in layout['routines']:
  blob=(a.build/(routine['object']+'.obj')).read_bytes()
  context_runs=[run for owner in layout['routines'] if owner['object']==routine['object'] for run in owner['runs']]
  private=private_image(blob,dict(runs=context_runs))
  reading=routine['symbol']=='read_game_data'
  for run in routine['runs']:
   address=run['start_address'];raw=run['start_file_offset'];size=run['body_size']
   stride=run.get('record_bytes',22)
   assert size==len(run['records'])*stride
   code,refs=v.bind_leaf_details(blob,run['phase'],v.DATA_OFFSETS,address=address,functions=v.FUNCTION_ADDRESSES)
   assert code==exe[raw:raw+size]
   v.verify_leaf_relocations(code,refs,pointers,address);assert len(refs)==len(run['records'])
   for i,row in enumerate(run['records']):
    assert row['address']==address+stride*i
    observed=exe[raw+stride*i:raw+stride*(i+1)]
    if stride==19:
     assert row['size']==1 and observed[:6]==b'\xbb\x01\0\0\0\xb8'
     assert observed[12:15]==b'\x89\xda\xe8'
     buffer_site,stream_site,call_site=6,10,15
    else:
     assert observed[:6]==b'\xbb\x01\0\0\0\xba' and observed[10]==0xb8 and observed[17]==0xe8
     assert int.from_bytes(observed[6:10],'little')==row['size']
     buffer_site,stream_site,call_site=11,15,18
    assert int.from_bytes(observed[buffer_site:buffer_site+4],'little')==row['data_offset']
    assert observed[stream_site:stream_site+2]==(b'\x89\xf1' if run['stream_register']=='esi' else b'\x89\xf9')
    assert address+stride*(i+1)+int.from_bytes(observed[call_site:call_site+4],'little',signed=True)==run['call_target']
   loaded,_=v.bind_leaf_details(blob,run['phase'],dict(v.DATA_OFFSETS,_save_data_image=DS),address=address,functions=v.FUNCTION_ADDRESSES)
   total=sum(row['size'] for row in run['records'])
   for seed in (0,1):
    for limit in (total,0,1,total//2,total-1):
     exercise(run,loaded,reading,seed,limit);body_cases+=1
    for limit in (total,total//2):
     exercise(run,loaded,reading,seed,limit,private=private);private_cases+=1
   fields+=len(run['records']);native+=size
 # Alter private code while leaving every selected field instruction intact.
 routine=layout['routines'][0];blob=(a.build/(routine['object']+'.obj')).read_bytes();run=routine['runs'][7]
 def rejected(bad,row=run,message='context'):
  try:v.bind_leaf_details(bad,row['phase'],v.DATA_OFFSETS,address=row['start_address'],functions=v.FUNCTION_ADDRESSES)
  except ValueError as exc:assert message in str(exc).lower(),str(exc)
  else:raise AssertionError('Private save-field mutation escaped')
 rejected(mutate_public_byte(blob,run['public'],0))
 rejected(mutate_public_byte(blob,run['public'],run['public_size']-1))
 rejected(rename_external(blob,b'_save_data_image',b'_save_data_imagf'),message='fixup')
 digest=v.LEAF_CONTEXT_SHA256.pop(run['public'])
 suffix=v.LEAF_CONTEXT_SUFFIXES.pop(run['public'])
 try:
  site=int(next(iter(run['private_fixups'])))
  rejected(mutate_public_byte(blob,run['public'],site),message='addend')
 finally:
  v.LEAF_CONTEXT_SHA256[run['public']]=digest
  v.LEAF_CONTEXT_SUFFIXES[run['public']]=suffix
 # The byte contexts share compiler-generated cursor tails across directions.
 byte_read,byte_write=v.SAVE_BYTE_LAYOUT['routines']
 blob=(a.build/'svbytes.obj').read_bytes();run=byte_read['runs'][0]
 rejected(mutate_public_byte(blob,run['public'],run['body_size']),row=run)
 shared=byte_write['runs'][-1]
 rejected(mutate_public_byte(blob,shared['public'],shared['public_size']-1),row=shared)
 rejected(rename_external(blob,b'_save_data_image',b'_save_data_imagf'),row=run,message='fixup')
 digest=v.LEAF_CONTEXT_SHA256.pop(run['public'])
 suffix=v.LEAF_CONTEXT_SUFFIXES.pop(run['public'])
 try:
  site=int(next(iter(run['private_fixups'])))
  rejected(mutate_public_byte(blob,run['public'],site),row=run,message='addend')
 finally:
  v.LEAF_CONTEXT_SHA256[run['public']]=digest
  v.LEAF_CONTEXT_SUFFIXES[run['public']]=suffix
 assert (fields,native)==(465,10164)
 result=dict(status='PASS',runs=26,fields=fields,native_bytes=native,le_sites=fields,
             body_cases=body_cases,private_cursor_cases=private_cases,
             partial_and_empty_transfers=True,private_context_controls=8)
 a.output.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(json.dumps(result))

if __name__=='__main__':main()

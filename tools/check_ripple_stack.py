"""Check ripple frame composition, loop flags, continuations and RNG call ABI."""
import argparse,json,struct
from pathlib import Path
from unicorn import Uc,UC_ARCH_X86,UC_MODE_32,UC_HOOK_CODE
from unicorn.x86_const import *
from check_start_hook import DS,image
from le_fixups import read_le_fixups
from match_objects import index as omf_index
from verify_c_leaf import (LEAVES,DATA_OFFSETS,FUNCTION_ADDRESSES,bind_leaf_details,
                           parsed_leaf_object,verify_leaf_relocations)

STACK,STOP=0x3ff000,0x3fff00
REGS=(UC_X86_REG_EAX,UC_X86_REG_EBX,UC_X86_REG_ECX,UC_X86_REG_EDX,
      UC_X86_REG_ESI,UC_X86_REG_EDI,UC_X86_REG_EBP)
# symbol stem, object, independent operation
PHASES=(
 ('frame_allocate','ripidx','allocate'),('index_seed','ripidx','write_eax'),
 ('index_commit','ripidx','write_ebp'),('index_spawn_read','ripidx','read_ecx'),
 ('index_radial_seed','ripidx','write_eax'),('index_floor_read','ripidx','read_eax'),
 ('index_step','ripidx','step_index'),('index_radial_read','ripidx','read_eax'),
 ('frame_release','ripidx','release'),('frame_return','ripidx','return'),
 ('particle_guard','riptest','particle_guard'),('sample_step','riptest','step_sample'),
 ('sample_test','riptest','test_sample'),('spawn_test','riptest','test_spawn'),
 ('last_slot','riptest','last_slot'),('random_x_call','riptest','draw'),
 ('random_y_call','riptest','draw'),('mask_guard_compare','riploop','compare_row'),
 ('vertical_guard_compare','riploop','compare_row'))

def mutate_public_byte(blob,public,relative):
 _,publics,*_=parsed_leaf_object(blob)
 segment,start,_=next(row for row in publics if row[2]==public)
 target=start+relative;changed=bytearray(blob);cursor=0
 while cursor<len(blob):
  kind=blob[cursor];length=int.from_bytes(blob[cursor+1:cursor+3],'little');end=cursor+3+length
  if kind in (0xa0,0xa1):
   data=blob[cursor+3:end-1];seg,pos=omf_index(data,0);width=4 if kind==0xa1 else 2
   origin=int.from_bytes(data[pos:pos+width],'little');payload=pos+width
   if seg==segment and origin<=target<origin+len(data)-payload:
    changed[cursor+3+payload+target-origin]^=1;changed[end-1]=0
    changed[end-1]=(-sum(changed[cursor:end]))&255
    return bytes(changed)
  cursor=end
 raise AssertionError('Missing private context byte')

def exercise(entry,code,mode,value):
 cpu=Uc(UC_ARCH_X86,UC_MODE_32);cpu.mem_map(0,0x400000);cpu.mem_write(entry,code)
 before=bytearray(b'\xa7'*96);index=7
 if mode in ('step_index','read_ecx','read_eax'):index=value
 if mode=='return':index=STOP
 struct.pack_into('<I',before,32,index&0xffffffff)
 cpu.mem_write(STACK-32,bytes(before));cpu.reg_write(UC_X86_REG_ESP,STACK)
 want={reg:0xabc00000+i for i,reg in enumerate(REGS)}
 if mode=='write_eax':want[UC_X86_REG_EAX]=value&0xffffffff
 if mode=='write_ebp':want[UC_X86_REG_EBP]=value&0xffffffff
 if mode in ('step_sample','test_sample'):want[UC_X86_REG_ESI]=value&0xffffffff
 if mode=='test_spawn':want[UC_X86_REG_ECX]=value&0xffffffff
 if mode=='particle_guard':want[UC_X86_REG_EAX]=value&0xffffffff
 if mode=='compare_row':want[UC_X86_REG_EBP]=value
 for reg,bits in want.items():cpu.reg_write(reg,bits)
 counter=DS+DATA_OFFSETS['_ripple_count'];count=value if mode=='last_slot' else 17
 counter_bytes=struct.pack('<3I',0x13572468,count,0x87654321)
 cpu.mem_write(counter-4,counter_bytes)
 if mode=='draw':
  cpu.mem_write(FUNCTION_ADDRESSES['random_value_'],b'\xb8'+struct.pack('<I',value)+b'\xc3')
 targets={entry+len(code),STOP,0x2ebda}
 def stop(machine,address,size,user):
  if address in targets:machine.emu_stop()
 cpu.hook_add(UC_HOOK_CODE,stop)
 cpu.reg_write(UC_X86_REG_EFLAGS,0x8d7)
 try:cpu.emu_start(entry,STOP,count=30)
 except Exception as exc:
  raise AssertionError((mode,value,hex(cpu.reg_read(UC_X86_REG_EIP)),
                        hex(cpu.reg_read(UC_X86_REG_ESP)))) from exc
 expected_ip=STOP if mode=='return' else (0x2ebda if mode=='particle_guard' and value>=0 else entry+len(code))
 assert cpu.reg_read(UC_X86_REG_EIP)==expected_ip,(mode,value)
 delta=-20 if mode=='allocate' else 20 if mode=='release' else 4 if mode=='return' else 0
 assert cpu.reg_read(UC_X86_REG_ESP)==STACK+delta
 if mode in ('write_eax','write_ebp'):struct.pack_into('<I',before,32,value&0xffffffff)
 if mode=='read_eax':want[UC_X86_REG_EAX]=value&0xffffffff
 if mode=='read_ecx':want[UC_X86_REG_ECX]=value&0xffffffff
 if mode=='step_index':struct.pack_into('<I',before,32,(value-1)&0xffffffff)
 if mode=='step_sample':want[UC_X86_REG_ESI]=(value-1)&0xffffffff
 if mode=='last_slot':want[UC_X86_REG_EAX]=(value-1)&0xffffffff
 if mode=='draw':
  want[UC_X86_REG_EAX]=value
  struct.pack_into('<I',before,28,entry+5)
 assert all(cpu.reg_read(reg)==bits for reg,bits in want.items()),(mode,value)
 assert cpu.mem_read(STACK-32,len(before))==bytes(before),(mode,value)
 assert cpu.mem_read(counter-4,len(counter_bytes))==counter_bytes
 flags=cpu.reg_read(UC_X86_REG_EFLAGS)
 if mode in ('test_spawn','test_sample','particle_guard'):
  bits=value&0xffffffff
  expected=(0x40 if bits==0 else 0)|(0x80 if bits&0x80000000 else 0)|(4 if (bits&255).bit_count()%2==0 else 0)
  assert flags&0x8c5==expected,(mode,value,hex(flags))
 if mode=='compare_row':
  assert (bool(flags&0x80)!=bool(flags&0x800))==(value<128)
  assert bool(flags&0x40)==(value==128)

def main():
 p=argparse.ArgumentParser(description=__doc__)
 p.add_argument('--exe',type=Path,required=True);p.add_argument('--build',type=Path,required=True)
 p.add_argument('--output',type=Path,required=True);a=p.parse_args()
 exe=a.exe.read_bytes();image(exe);fixups=read_le_fixups(exe)['pointers'];objects={}
 cases=0;byte_count=0;le_count=0
 for stem,obj,mode in PHASES:
  symbol='ripple_'+stem+'_phase_';raw,size=LEAVES[symbol];entry=raw-0x25600
  blob=objects.setdefault(obj,(a.build/(obj+'.obj')).read_bytes())
  code,refs=bind_leaf_details(blob,symbol,DATA_OFFSETS,address=entry,functions=FUNCTION_ADDRESSES)
  assert code==exe[raw:raw+size]
  verify_leaf_relocations(code,refs,fixups,entry);byte_count+=size;le_count+=len(refs)
  code,_=bind_leaf_details(blob,symbol,{k:DS+v for k,v in DATA_OFFSETS.items()},address=entry,functions=FUNCTION_ADDRESSES)
  values=range(32) if mode=='step_index' else range(128) if mode=='step_sample' else range(33) if mode=='last_slot' else (0,1,127,128) if mode=='compare_row' else (0,0xffffffff,0x80000000,0x12345678) if mode=='draw' else (-1,0,1,31) if mode not in ('allocate','release','return') else (0,)
  for value in values:exercise(entry,code,mode,value);cases+=1
 controls=(
  ('ripidx','ripple_seed_and_read_ecx_',2,'ripple_index_seed_phase_'),
  ('ripidx','ripple_commit_and_read_eax_',12,'ripple_index_commit_phase_'),
  ('ripidx','ripple_step_and_read_eax_',3,'ripple_index_step_phase_'),
  ('ripidx','ripple_step_and_read_eax_',10,'ripple_index_step_phase_'),
  ('riptest','ripple_sample_guard_',4,'ripple_sample_test_phase_'),
  ('riptest','ripple_random_draw_',6,'ripple_random_x_call_phase_'))
 for obj,public,offset,symbol in controls:
  bad=mutate_public_byte(objects[obj],public,offset);raw,_=LEAVES[symbol]
  try:bind_leaf_details(bad,symbol,DATA_OFFSETS,address=raw-0x25600,functions=FUNCTION_ADDRESSES)
  except ValueError as exc:
   assert 'context' in str(exc).lower(),str(exc)
  else:raise AssertionError('Private context mutation escaped')
 result=dict(status='PASS',cases=cases,spans=len(PHASES),native_bytes=byte_count,
             le_sites=le_count,private_context_controls=len(controls))
 a.output.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(json.dumps(result))

if __name__=='__main__':main()

"""Check complete ripple C coverage, placed control edges and private C model."""
import argparse,json,struct
from pathlib import Path
from unicorn import Uc,UC_ARCH_X86,UC_MODE_32,UC_HOOK_CODE
from unicorn.x86_const import *
from check_start_hook import image,DS
from check_ripple_texture import exercise
from check_ripple_stack import mutate_public_byte
import verify_c_leaf as v
from le_fixups import read_le_fixups

BASE,RAW,SIZE,STACK,STOP=0x2eb57,0x54157,855,0x3ff000,0x3fff00
PUBLIC='ripple_flow_context_'
REGS=(UC_X86_REG_EAX,UC_X86_REG_EBX,UC_X86_REG_ECX,UC_X86_REG_EDX,
      UC_X86_REG_ESI,UC_X86_REG_EDI,UC_X86_REG_EBP)
# Address, operation, expected target. Predicates come from the algorithm,
# independently of the compiler target offsets in the placement registry.
EDGES=((0x2eb80,'jump',0x2ebc5),(0x2ebca,'spawn',0x2eb82),
       (0x2ebd5,'jump',0x2ecb2),(0x2ec1a,'jump',0x2ec5f),
       (0x2ec61,'sample',0x2ec1c),(0x2ecc6,'jump',0x2ece9),
       (0x2ecef,'row',0x2ecc8),(0x2ed1b,'jump',0x2ed4c),
       (0x2ed52,'row',0x2ed1d),(0x2ed85,'jump',0x2ee92),
       (0x2eda9,'jump',0x2ee87))

def edge_case(exe,address,branch,kind,target,value):
 prefix_size=5 if kind=='spawn' else 2 if kind=='sample' else 6 if kind=='row' else 0
 entry=address-prefix_size;raw=entry+0x25600;prefix=exe[raw:raw+prefix_size]
 cpu=Uc(UC_ARCH_X86,UC_MODE_32);cpu.mem_map(0,0x400000)
 cpu.mem_write(entry,prefix+branch)
 frame=struct.pack('<6I',value&0xffffffff,0x12345678,0x23456789,0x3456789a,0x456789ab,0x56789abc)
 cpu.mem_write(STACK,frame);cpu.reg_write(UC_X86_REG_ESP,STACK)
 want={reg:0xabc00000+i for i,reg in enumerate(REGS)}
 if kind=='sample':want[UC_X86_REG_ESI]=value&0xffffffff
 if kind=='row':want[UC_X86_REG_EBP]=value
 for reg,bits in want.items():cpu.reg_write(reg,bits)
 end=address+len(branch)
 def stop(machine,pc,size,user):
  if pc in (target,end):machine.emu_stop()
 cpu.hook_add(UC_HOOK_CODE,stop);cpu.reg_write(UC_X86_REG_EFLAGS,0x8d7)
 cpu.emu_start(entry,STOP,count=20)
 taken=kind=='jump' or (value>=0 if kind in ('sample','spawn') else value<128)
 assert cpu.reg_read(UC_X86_REG_EIP)==(target if taken else end),(kind,value)
 assert cpu.reg_read(UC_X86_REG_ESP)==STACK
 if kind=='spawn':want[UC_X86_REG_ECX]=value&0xffffffff
 assert all(cpu.reg_read(reg)==bits for reg,bits in want.items())
 assert cpu.mem_read(STACK,len(frame))==frame
 if kind!='jump':
  flags=cpu.reg_read(UC_X86_REG_EFLAGS)
  assert (bool(flags&0x80)!=bool(flags&0x800))==(value<(128 if kind=='row' else 0))

def saved_case(entry,code,restore):
 cpu=Uc(UC_ARCH_X86,UC_MODE_32);cpu.mem_map(0,0x400000);cpu.mem_write(entry,code)
 want={reg:0xabc00000+i for i,reg in enumerate(REGS)}
 for reg,bits in want.items():cpu.reg_write(reg,bits)
 saved=(UC_X86_REG_EBP,UC_X86_REG_EDI,UC_X86_REG_ESI,UC_X86_REG_EDX,UC_X86_REG_ECX,UC_X86_REG_EBX)
 before=bytearray(b'\xa7'*64)
 if restore:
  for i,reg in enumerate(saved):want[reg]=0x12340000+i
  struct.pack_into('<6I',before,32,*(want[reg] for reg in saved))
 cpu.mem_write(STACK-32,bytes(before));cpu.reg_write(UC_X86_REG_ESP,STACK)
 cpu.reg_write(UC_X86_REG_EFLAGS,0x8d7)
 if not restore:struct.pack_into('<6I',before,8,*(want[reg] for reg in saved))
 cpu.emu_start(entry,entry+len(code),count=10)
 assert cpu.reg_read(UC_X86_REG_ESP)==STACK+(24 if restore else -24)
 assert all(cpu.reg_read(reg)==bits for reg,bits in want.items())
 assert cpu.mem_read(STACK-32,len(before))==bytes(before)
 assert cpu.reg_read(UC_X86_REG_EFLAGS)==0x8d7

def rename_external(blob,old,new):
 assert len(old)==len(new);out=bytearray(blob);cursor=0
 while cursor<len(blob):
  length=int.from_bytes(blob[cursor+1:cursor+3],'little');end=cursor+3+length
  if blob[cursor]==0x8c:
   pos=blob.find(old,cursor+3,end-1)
   if pos!=-1:
    out[pos:pos+len(old)]=new;out[end-1]=0;out[end-1]=(-sum(out[cursor:end]))&255
    return bytes(out)
  cursor=end
 raise AssertionError('Missing private external symbol')

def main():
 p=argparse.ArgumentParser(description=__doc__)
 p.add_argument('--exe',type=Path,required=True);p.add_argument('--build',type=Path,required=True)
 p.add_argument('--output',type=Path,required=True);a=p.parse_args()
 exe=a.exe.read_bytes();memory=image(exe);obj=(a.build/'ripflow.obj').read_bytes()
 pointers=read_le_fixups(exe)['pointers'];placed={};spans=0
 for symbol,(public,start,end,extent) in v.LEAF_CODE_SLICES.items():
  if public!=PUBLIC:continue
  raw,size=v.LEAVES[symbol];assert end-start==size and extent==865
  code,refs=v.bind_leaf_details(obj,symbol,v.DATA_OFFSETS,address=raw-0x25600,functions=v.FUNCTION_ADDRESSES)
  assert code==exe[raw:raw+size] and not refs
  v.verify_leaf_relocations(code,refs,pointers,raw-0x25600)
  placed[raw-0x25600]=code;spans+=1
 assert spans==13 and sum(map(len,placed.values()))==43
 inventory=json.loads((Path(__file__).resolve().parent/'data/matching-routines.json').read_text())
 covered=[0]*SIZE
 for row in inventory['spans']:
  lo=int(row['raw_offset'],16);hi=lo+row['bytes']
  for address in range(max(RAW,lo),min(RAW+SIZE,hi)):covered[address-RAW]+=1
 assert covered==[1]*SIZE,'Ripple C inventory has a gap or overlap'
 edge_cases=0
 for address,kind,target in EDGES:
  values=range(-1,4) if kind=='spawn' else range(-1,128) if kind=='sample' else range(129) if kind=='row' else (0,)
  for value in values:edge_case(exe,address,placed[address],kind,target,value);edge_cases+=1
 saved_case(BASE,placed[BASE],False);saved_case(0x2eea7,placed[0x2eea7],True)
 # Execute the unplaced compiler context with its own original internal
 # targets, then the complete production image, against the same torus oracle.
 alias='ripple_private_model_check_';metadata=v.LEAF_SECTION_BRANCHES.pop(PUBLIC)
 v.LEAF_CODE_SLICES[alias]=(PUBLIC,0,865,865)
 try:
  model,_=v.bind_leaf_details(obj,alias,{k:DS+val for k,val in v.DATA_OFFSETS.items()},
                             address=BASE,functions=v.FUNCTION_ADDRESSES)
 finally:
  del v.LEAF_CODE_SLICES[alias];v.LEAF_SECTION_BRANCHES[PUBLIC]=metadata
 for count in (0,1,4,28,29,30,31,32):
  for seed in range(4):exercise(memory,count,seed,body=model);exercise(memory,count,seed)
 first='ripple_control_saved_registers_phase_'
 def rejected(blob,symbol=first,message='context'):
  raw,_=v.LEAVES[symbol]
  try:v.bind_leaf_details(blob,symbol,v.DATA_OFFSETS,address=raw-0x25600,functions=v.FUNCTION_ADDRESSES)
  except ValueError as exc:assert message in str(exc).lower(),str(exc)
  else:raise AssertionError('Invalid private context or branch metadata escaped')
 rejected(mutate_public_byte(obj,PUBLIC,11))
 rejected(mutate_public_byte(obj,PUBLIC,864))
 rejected(rename_external(obj,b'_ripple_count',b'_ripple_frame'),message='fixup')
 digest=v.LEAF_CONTEXT_SHA256.pop(PUBLIC)
 try:rejected(mutate_public_byte(obj,PUBLIC,355),message='addend')
 finally:v.LEAF_CONTEXT_SHA256[PUBLIC]=digest
 size,placed_size,branches=metadata;wrong=dict(branches);op,compiled,target=wrong[47]
 wrong[47]=(op,compiled+1,target);v.LEAF_SECTION_BRANCHES[PUBLIC]=(size,placed_size,wrong)
 try:rejected(obj,'ripple_control_branch_2eb80_phase_',message='compiler target')
 finally:v.LEAF_SECTION_BRANCHES[PUBLIC]=metadata
 wrong=dict(branches);wrong[47]=(op,compiled,target+1);v.LEAF_SECTION_BRANCHES[PUBLIC]=(size,placed_size,wrong)
 try:
  code,_=v.bind_leaf_details(obj,'ripple_control_branch_2eb80_phase_',v.DATA_OFFSETS,
                            address=0x2eb80,functions=v.FUNCTION_ADDRESSES)
  assert code!=placed[0x2eb80],'Wrong destination mutation escaped'
 finally:v.LEAF_SECTION_BRANCHES[PUBLIC]=metadata
 result=dict(status='PASS',selected_spans=spans,native_control_bytes=43,whole_routine_c_bytes=855,
             edge_cases=edge_cases,saved_register_cases=2,private_model_cases=32,
             production_cases=32,mutation_controls=6,selected_le_sites=0)
 a.output.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(json.dumps(result))

if __name__=='__main__':main()

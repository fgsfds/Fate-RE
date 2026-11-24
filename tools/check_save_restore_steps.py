"""Check pointer conversion words, live index/flags, and composed 512-item loops."""
import argparse,json,struct
from pathlib import Path
from unicorn import Uc,UC_ARCH_X86,UC_MODE_32
from unicorn.x86_const import *
import verify_c_leaf as v
from check_start_hook import image,DS
from check_save_dynamic_io import full_context,data_bindings,placed_range
from check_ripple_stack import mutate_public_byte
from check_ripple_control import rename_external
from le_fixups import read_le_fixups

TABLE=DS+0x1a234
SHIFT=((DS+0x27c3a0)<<2)&0xffffffff
STACK,STOP,PRIVATE=0x4ff000,0x4fff00,0x400000
REGS=(UC_X86_REG_EAX,UC_X86_REG_EBX,UC_X86_REG_ECX,UC_X86_REG_EDX,
      UC_X86_REG_ESI,UC_X86_REG_EDI,UC_X86_REG_EBP)
WORDS=(0,1,0x7fffffff,0x80000000,0xffffffff,SHIFT,(-SHIFT)&0xffffffff)
MODES=(('read',0x2fec0),('offset',0x313c5),('address',0x313ff))

def arithmetic(word,subtract):
 result=(word-SHIFT if subtract else word+SHIFT)&0xffffffff
 carry=word<SHIFT if subtract else word+SHIFT>0xffffffff
 overflow=((word^SHIFT)&(word^result) if subtract else ~(word^SHIFT)&(word^result))&0x80000000
 flags=int(carry)|(int((result&255).bit_count()%2==0)<<2)|((word^SHIFT^result)&0x10)
 flags|=(int(result==0)<<6)|(int(bool(result&0x80000000))<<7)|(int(bool(overflow))<<11)
 return result,flags

def step(cpu,mode,entry,code,index,word):
 cpu.mem_write(entry,code)
 cpu.ctl_remove_cache(entry,entry+len(code))
 data=bytearray(b'\x5a'*16+b'\x6d'*2048+b'\xa5'*16)
 struct.pack_into('<I',data,16+index*4,word);cpu.mem_write(TABLE-16,bytes(data))
 want={reg:0xabc00000+i for i,reg in enumerate(REGS)}
 counter=UC_X86_REG_EDI if mode=='read' else UC_X86_REG_EAX;want[counter]=index
 for reg,value in want.items():cpu.reg_write(reg,value)
 frame=struct.pack('<I',STOP)+b'\xcc'*60
 cpu.mem_write(STACK,frame);cpu.reg_write(UC_X86_REG_ESP,STACK);cpu.reg_write(UC_X86_REG_EFLAGS,0x602)
 cpu.emu_start(entry,entry+len(code),count=40)
 result,flags=arithmetic(word,mode=='offset')
 struct.pack_into('<I',data,16+index*4,result)
 assert cpu.mem_read(TABLE-16,len(data))==data
 assert cpu.mem_read(STACK,len(frame))==frame
 want[counter]=(index-1)&0xffffffff
 if mode=='read':want.update({UC_X86_REG_EBX:SHIFT,UC_X86_REG_EDX:result})
 elif mode=='offset':want.update({UC_X86_REG_EDX:SHIFT,UC_X86_REG_EBX:result})
 else:want.update({UC_X86_REG_EDX:result,UC_X86_REG_EBX:word})
 assert all(cpu.reg_read(reg)==value for reg,value in want.items()),(mode,index,word)
 assert cpu.reg_read(UC_X86_REG_EFLAGS)&0x8d5==flags,(mode,index,word,'flags')
 assert cpu.reg_read(UC_X86_REG_ESP)==STACK
 assert cpu.reg_read(UC_X86_REG_EIP)==entry+len(code)

def init_case(cpu,entry,code):
 cpu.mem_write(entry,code);want={reg:0xabc00000+i for i,reg in enumerate(REGS)}
 cpu.ctl_remove_cache(entry,entry+len(code))
 for reg,value in want.items():cpu.reg_write(reg,value)
 frame=struct.pack('<I',STOP)+b'\xcc'*60;cpu.mem_write(STACK,frame)
 cpu.reg_write(UC_X86_REG_ESP,STACK);cpu.reg_write(UC_X86_REG_EFLAGS,0x8d7)
 cpu.emu_start(entry,entry+len(code),count=10)
 want[UC_X86_REG_EAX]=511
 assert all(cpu.reg_read(reg)==value for reg,value in want.items())
 assert cpu.mem_read(STACK,len(frame))==frame and cpu.reg_read(UC_X86_REG_EFLAGS)==0x8d7
 assert cpu.reg_read(UC_X86_REG_ESP)==STACK
 assert cpu.reg_read(UC_X86_REG_EIP)==entry+len(code)

def loop_case(cpu,mode,entry,code,values,private=False):
 cpu.mem_write(entry,code)
 cpu.ctl_remove_cache(entry,entry+len(code))
 before=b'\x5a'*16+struct.pack('<512I',*values)+b'\xa5'*16
 cpu.mem_write(TABLE-16,before)
 want={reg:0xabc00000+i for i,reg in enumerate(REGS)}
 if mode=='read':want[UC_X86_REG_EDI]=511
 for reg,value in want.items():cpu.reg_write(reg,value)
 frame=struct.pack('<I',STOP)+b'\xcc'*60;cpu.mem_write(STACK,frame);cpu.reg_write(UC_X86_REG_ESP,STACK)
 cpu.reg_write(UC_X86_REG_EFLAGS,0x202);cpu.emu_start(entry,STOP if private else entry+len(code),count=6000)
 expected=[(word-SHIFT if mode=='offset' else word+SHIFT)&0xffffffff for word in values]
 assert cpu.mem_read(TABLE-16,len(before))==b'\x5a'*16+struct.pack('<512I',*expected)+b'\xa5'*16
 assert cpu.mem_read(STACK,len(frame))==frame and cpu.reg_read(UC_X86_REG_ESP)==STACK+(4 if private else 0)
 assert cpu.reg_read(UC_X86_REG_EIP)==(STOP if private else entry+len(code))
 counter=UC_X86_REG_EDI if mode=='read' else UC_X86_REG_EAX;want[counter]=0xffffffff
 if mode=='read':want.update({UC_X86_REG_EBX:SHIFT,UC_X86_REG_EDX:expected[0]})
 elif mode=='offset':want.update({UC_X86_REG_EDX:SHIFT,UC_X86_REG_EBX:expected[0]})
 else:want.update({UC_X86_REG_EDX:expected[0],UC_X86_REG_EBX:values[0]})
 assert all(cpu.reg_read(reg)==value for reg,value in want.items())
 # Compiler-generated TEST/JGE uses the decremented index, ending at signed -1.
 assert cpu.reg_read(UC_X86_REG_EFLAGS)&0x8c1==0x80
 return expected

def main():
 p=argparse.ArgumentParser(description=__doc__)
 p.add_argument('--exe',type=Path,required=True);p.add_argument('--build',type=Path,required=True)
 p.add_argument('--output',type=Path,required=True);a=p.parse_args()
 exe=a.exe.read_bytes();image(exe);pointers=read_le_fixups(exe)['pointers']
 blob=(a.build/'svstep.obj').read_bytes()
 obj=next(row for row in v.SAVE_DYNAMIC_LAYOUT['objects'] if row['object']=='svstep')
 phases=[row for row in v.SAVE_DYNAMIC_LAYOUT['phases'] if row['object']=='svstep']
 placed={}
 for phase in phases:
  address=phase['address']
  code,refs=v.bind_leaf_details(blob,phase['phase'],v.DATA_OFFSETS,address=address,functions=v.FUNCTION_ADDRESSES)
  assert code==exe[address+0x25600:address+0x25600+len(code)]
  v.verify_leaf_relocations(code,refs,pointers,address)
  placed[address]=v.bind_leaf_details(blob,phase['phase'],data_bindings(),address=address,functions=v.FUNCTION_ADDRESSES)[0]
 cpu=Uc(UC_ARCH_X86,UC_MODE_32);cpu.mem_map(0,0x500000)
 body_cases=private_cases=init_cases=loop_cases=0
 for mode,address in MODES:
  code=placed_range(placed,address,25)
  for index in range(512):
   for word in WORDS:step(cpu,mode,address,code,index,word);body_cases+=1
 for address in (0x313be,0x313f8):init_case(cpu,address,placed_range(placed,address,5));init_cases+=1
 loops={}
 for mode,entry,size in (('read',0x2febe,31),('offset',0x313be,36),('address',0x313f8,36)):
  loops[mode]=(entry,placed_range(placed,entry,size))
 for seed in range(4):
  values=[((i*0x9e3779b9)^(seed*0x7f4a7c15))&0xffffffff for i in range(512)]
  for mode in ('read','offset','address'):
   loop_case(cpu,mode,*loops[mode],values);loop_cases+=1
  offsets=loop_case(cpu,'offset',*loops['offset'],values)
  restored=loop_case(cpu,'address',*loops['address'],offsets);loop_cases+=2
  assert restored==values
  for mode in ('offset','address'):
   context=next(row for row in obj['contexts'] if row['public']=='save_restore_'+mode+'_loop_')
   loop_case(cpu,mode,PRIVATE,full_context(blob,context,PRIVATE),values,True);private_cases+=1
 controls=0
 phase=next(row for row in phases if row['phase']=='save_restore_offset_suffix_phase_')
 def rejected(bad,message='context'):
  nonlocal controls
  try:v.bind_leaf_details(bad,phase['phase'],v.DATA_OFFSETS,address=phase['address'],functions=v.FUNCTION_ADDRESSES)
  except ValueError as exc:
   assert message in str(exc).lower(),str(exc)
   controls+=1
  else:raise AssertionError('Private conversion context mutation escaped')
 rejected(mutate_public_byte(blob,'save_restore_offset_loop_',12))
 rejected(mutate_public_byte(blob,'save_restore_offset_loop_',40))
 rejected(rename_external(blob,b'_save_restore_words',b'_save_restore_wordt'),message='fixup')
 public='save_restore_offset_loop_';original=v.LEAF_SECTION_BRANCHES[public]
 phase=next(row for row in phases if row['phase']=='save_restore_offset_prefix_phase_')
 try:
  branches=dict(original[2]);branches[5]=(b'\xeb',35,32)
  v.LEAF_SECTION_BRANCHES[public]=(41,36,branches)
  rejected(blob,message='compiler target')
  branches[5]=(b'\xeb',36,36)
  v.LEAF_SECTION_BRANCHES[public]=(41,36,branches)
  rejected(blob,message='target outside')
 finally:v.LEAF_SECTION_BRANCHES[public]=original
 result=dict(status='PASS',placed_step_cases=body_cases,private_loop_cases=private_cases,
             initializer_cases=init_cases,whole_loop_cases=loop_cases,round_trips=4,
             private_context_controls=controls,all_512_indices=True)
 a.output.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(json.dumps(result))

if __name__=='__main__':main()

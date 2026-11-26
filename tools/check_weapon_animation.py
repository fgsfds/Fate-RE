"""Independent weapon state-machine model; projectile behavior is stubbed."""
from pathlib import Path
import sys,struct,json,hashlib,itertools
ROOT=Path(__file__).resolve().parents[1]
from unicorn import Uc,UC_ARCH_X86,UC_MODE_32,UC_HOOK_CODE,UC_HOOK_MEM_WRITE
from unicorn.x86_const import *
from check_start_hook import image,DS
from compare_exe import TARGET_SHA256
from le_fixups import read_le_fixups
ENTRY,SIZE,FIRE=0x29cd4,1307,0x124a1
CALLER_SP,STOP,DATA_SIZE=0x3fef00,0x3fff00,0x28a300
# The stub's dedicated test word stays inside the actual LE DATA object.
FRAMES,DEFS,MARKER=0x12868,0x12b68,DATA_SIZE-16
A=dict(last=0x2034,action=0x2bdc,state=0x2bde,selected=0x2be0,displayed=0x2be2,tile=0x2be4,input=0x5ac8f,x=0x7dee8,y=0x7deea,projectile=0x8523c,fire_tile=0x8523e,direction=0x85240,limit=0x85242,requested=0x85246,clock=0x287e88)
REGS=(UC_X86_REG_EAX,UC_X86_REG_EBX,UC_X86_REG_ECX,UC_X86_REG_EDX,UC_X86_REG_ESI,UC_X86_REG_EDI,UC_X86_REG_EBP)
GP=(0xabc00123,0x3456789a,0xfedc1234,0xbad01234,0x66778899,0x778899aa,0x8899aabb)
u32=lambda n:n&0xffffffff
i16=lambda n:(n&0x7fff)-(n&0x8000)
i32=lambda n:(n&0x7fffffff)-(n&0x80000000)
def put(m,p,fmt,*values):struct.pack_into('<'+fmt,m,p,*values)
def get(m,p,fmt):return struct.unpack_from('<'+fmt,m,p)[0]
def write(m,key,value):put(m,DS+A[key],'I' if key in ('clock','last') else 'h',u32(value) if key in ('clock','last') else i16(value))
def read(m,key):return get(m,DS+A[key],'I' if key in ('clock','last') else 'h')
def defs(m,index):
 assert 0<=index<8
 return struct.unpack_from('<12h',m,DS+DEFS+24*index)
def flags_add(a,b):
 a,b=u32(a),u32(b);wide=a+b;out=u32(wide)
 return ((wide>>32)&1)|(4 if (out&255).bit_count()%2==0 else 0)|((a^b^out)&16)|(64 if out==0 else 0)|(128 if out&0x80000000 else 0)|(2048 if (~(a^b)&(a^out)&0x80000000) else 0)

def verify_data_extent(exe):
 header=get(exe,0x3c,'I');table=get(exe,header+0x40,'I')
 assert struct.unpack_from('<2I',exe,header+table+24)==(DATA_SIZE,DS)
 assert 0<=MARKER and MARKER+4<=DATA_SIZE

def cases():
 rows=[]
 def add(name,**kw):
  row=dict(name=name,clock=0x10007,last=0x10000,action=0,state=0,selected=1,displayed=1,tile=1035,requested=1,direction=0,limit=1037,projectile=2,fire_tile=1040,input=1<<13,x=1234,y=-2345,patch={},defs_patch={},data_patch={})
  row.update(kw);rows.append(row)
 for selected,requested,action,delta in itertools.product(range(8),range(8),(-1,0,1,2,3),(6,7)):
  add(f'idle_{selected}_{requested}_{action}_{delta}',selected=selected,displayed=selected,tile=1053 if selected==0 else 1035,requested=7,input=requested<<13,action=action,clock=0x10000+delta)
 for state,direction,relation,delta,displayed in itertools.product((1,3,4),(0,-1,2),(-1,0,1),(6,7),(0,1,3)):
  origin=1053 if displayed==0 else (1033 if displayed==1 else 1067)
  limit=origin+4;tile=limit+relation
  add(f'active_{state}_{direction}_{relation}_{delta}_{displayed}',state=state,direction=direction,tile=tile,limit=limit,displayed=displayed,clock=0x10000+delta,requested=2,fire_tile=tile+(1 if direction==0 else -1))
 for requested,delta in itertools.product(range(8),(6,7)):
  add(f'raise_{requested}_{delta}',state=2,requested=requested,clock=0x10000+delta)
 for state,delta in itertools.product((-32768,-1,5,32767),(6,7)):
  add(f'unknown_{state}_{delta}',state=state,clock=0x10000+delta)
 for clock,last in [(0,0),(6,0),(7,0),(0,0xffffffff),(3,0xfffffff0),(0x80000003,0x7ffffff0),(0x7fffffff,0x80000000),(0x80000000,0),(0x7fffffff,0),(0xffffffff,0)]:
  add(f'clock_{clock}_{last}',state=1,tile=1034,limit=1038,clock=clock,last=last)
 for width in (-32768,-32767,32760,32767):
  add(f'word_tile_{width}',state=1,tile=width,limit=width,direction=-1,displayed=1,defs_patch={1:{0:width}})
 for state,patch in itertools.product((0,4),({},dict(displayed=0,tile=1055,clock=0xfffffff0),dict(displayed=3,tile=1068,selected=2,requested=0,state=-1,x=-999,y=999))):
  add(f'callback_{state}_{len(rows)}',state=state,action=1 if state==0 else 0,selected=0 if state==0 else 1,displayed=0 if state==0 else 1,input=0 if state==0 else 1<<13,tile=1039 if state==4 else 1053,limit=1042,fire_tile=1040,patch=patch)
 for projectile in (-32768,-1,0,32767):
  add(f'projectile_word_{projectile}',action=1,selected=0,displayed=0,input=0,defs_patch={0:{7:projectile}})
 # Distinguish another in-object negative frame from the slot-zero tile-0
 # transitions above, whose frame is always -1053. Seed both pairs explicitly.
 add('slot_zero_negative_frame',state=-1,displayed=0,tile=1052,
     data_patch={FRAMES-4:(-1234,2345),FRAMES-1053*4:(3141,-2718)})
 return rows

def seed(original,case):
 m=bytearray(original)
 for key in A:write(m,key,case[key])
 for index,fields in case['defs_patch'].items():
  for field,value in fields.items():put(m,DS+DEFS+24*index+2*field,'h',i16(value))
 for offset,pair in case['data_patch'].items():
  assert 0<=offset and offset+4<=DATA_SIZE
  put(m,DS+offset,'hh',*pair)
 put(m,DS+MARKER,'I',0x76543210)
 m[CALLER_SP-96:CALLER_SP+68]=bytes([0xa7])*164;put(m,CALLER_SP,'I',STOP)
 return m

def expected(initial,case):
 m=bytearray(initial);calls=[]
 def setv(key,value):write(m,key,value)
 def val(key):return read(m,key)
 def fire():
  calls.append(u32(val('projectile')))
  put(m,DS+MARKER,'I',u32(calls[-1]^len(calls)))
  for key,value in case['patch'].items():setv(key,value)
 stepped=i32(val('clock')-val('last'))>6
 if stepped:setv('last',val('clock'))
 state=val('state')
 if state==0:
  requested=(val('input')&65535)>>13
  setv('requested',requested)
  if requested!=val('selected'):
   selected=val('selected');row=defs(m,selected)
   setv('tile',row[2]);setv('displayed',selected);setv('limit',row[3]);setv('state',1)
   setv('direction',-1 if val('tile')>val('limit') else 0)
  else:
   row=defs(m,requested);action=val('action')
   phase=4 if action==1 else 8 if action==2 and row[8]!=0 else None
   if phase is not None:
    setv('displayed',requested);setv('tile',row[phase]);setv('limit',row[phase+1]);setv('fire_tile',row[phase+2]);setv('projectile',row[phase+3]);setv('state',4)
    setv('direction',-1 if val('tile')>val('limit') else 0)
    if val('tile')==val('fire_tile'):fire()
 elif state==2:
  row=defs(m,val('requested'))
  setv('state',3);setv('displayed',val('requested'));setv('tile',row[0]);setv('limit',row[1]);setv('direction',-1 if row[0]>row[1] else 0)
 elif state in (1,3,4):
  direction=1 if val('direction')==0 else -1
  before_limit=val('tile')<val('limit') if direction==1 else val('tile')>val('limit')
  if state!=4 or stepped:
   if before_limit:
    if stepped:
     setv('tile',val('tile')+direction)
     if state==4 and val('tile')==val('fire_tile'):fire()
   elif state==1:setv('state',2)
   elif state==3:setv('selected',val('requested'));setv('state',0)
   else:
    requested=val('requested');setv('state',0);setv('displayed',requested);setv('tile',defs(m,requested)[1])
 displayed=val('displayed');origin=1053 if displayed==0 else defs(m,displayed)[0]
 frame=i16(val('tile')-origin);offset=frame*4+displayed*96
 address=DS+FRAMES+offset
 assert DS<=address and address+4<=DS+DATA_SIZE,(case['name'],hex(address))
 x,y=struct.unpack_from('<hh',m,address);setv('x',x);setv('y',y)
 return bytes(m[DS:DS+DATA_SIZE]),tuple(calls),(u32(offset)&0xffff0000)|(y&65535),flags_add(frame*4,displayed*96)

def exercise(original,body,case,entry=ENTRY,*,native=False):
 initial=seed(original,case);model=expected(initial,case)
 cpu=Uc(UC_ARCH_X86,UC_MODE_32);cpu.mem_map(0,0x400000);cpu.mem_write(0,bytes(initial));cpu.mem_write(entry,body);cpu.mem_write(FIRE,b'\xc3')
 for reg,value in zip(REGS,GP):cpu.reg_write(reg,value)
 cpu.reg_write(UC_X86_REG_ESP,CALLER_SP);cpu.reg_write(UC_X86_REG_EFLAGS,0x202)
 calls=[];lowest=CALLER_SP
 def hook(_cpu,address,size,_user):
  if address==STOP:cpu.emu_stop();return
  if entry<=address<entry+len(body):return
  assert address==FIRE,f'escaped {address:x}'
  argument=cpu.reg_read(UC_X86_REG_EAX);calls.append(argument)
  cpu.mem_write(DS+MARKER,struct.pack('<I',u32(argument^len(calls))))
  for key,value in case['patch'].items():
   fmt='I' if key in ('clock','last') else 'h'
   cpu.mem_write(DS+A[key],struct.pack('<'+fmt,u32(value) if fmt=='I' else i16(value)))
  cpu.reg_write(UC_X86_REG_EAX,0xfedc1234);cpu.reg_write(UC_X86_REG_EFLAGS,0x8d7)
 def writes(_cpu,_kind,address,size,_value,_user):
  nonlocal lowest
  if DS<=address and address+size<=DS+DATA_SIZE:return
  assert CALLER_SP-(128 if native else 24)<=address and address+size<=CALLER_SP,f'write {address:x}'
  lowest=min(lowest,address)
 cpu.hook_add(UC_HOOK_CODE,hook);cpu.hook_add(UC_HOOK_MEM_WRITE,writes)
 cpu.emu_start(entry,STOP,count=5000)
 assert cpu.reg_read(UC_X86_REG_EIP)==STOP and cpu.reg_read(UC_X86_REG_ESP)==CALLER_SP+4,case['name']
 assert tuple(cpu.reg_read(reg) for reg in REGS[1:])==GP[1:],case['name']
 assert bytes(cpu.mem_read(CALLER_SP+4,64))==bytes([0xa7])*64
 if not native:assert bytes(cpu.mem_read(CALLER_SP-96,72))==bytes([0xa7])*72
 observed=(bytes(cpu.mem_read(DS,DATA_SIZE)),tuple(calls))
 assert observed==model[:2],case['name']
 regs=tuple(cpu.reg_read(reg) for reg in REGS);flags=cpu.reg_read(UC_X86_REG_EFLAGS)&0x8d5
 if not native:assert (regs[0],flags)==model[2:],case['name']
 return observed,regs,flags,CALLER_SP-lowest

def bind_production(exe,build):
 import verify_c_leaf as v
 from verify_c_suite import OBJECT_NAMES
 from verify_assembly_suite import ROUTINES,GROUP_SLICES,DATA_POINTER_SITES,verify_pointer_operands
 from capstone import Cs,CS_ARCH_X86,CS_MODE_32
 layout=v.WEAPON_ANIMATION_LAYOUT;contexts={c['public']:c for c in layout['contexts']};blobs={};boundaries={}
 for public,context in contexts.items():
  blob=(build/(context['object']+'.obj')).read_bytes();blobs[public]=blob
  parsed=v.parsed_leaf_object(blob);raw_context=bytes(parsed[0][1]['data'])
  assert parsed[1]==((1,0,public),) and len(raw_context)==context['size']
  instructions=tuple(Cs(CS_ARCH_X86,CS_MODE_32).disasm(raw_context,0))
  boundaries[public]={i.address for i in instructions}|{len(raw_context)}
  assert sum(i.size for i in instructions)==len(raw_context)
 pointers=read_le_fixups(exe)['pointers'];covered=set();exact_body=bytearray(SIZE);run_body=bytearray(SIZE);reports=[]
 def install(address,exact,loaded):
  region=set(range(address,address+len(exact)))
  assert region<=set(range(ENTRY,ENTRY+SIZE)) and not covered.intersection(region)
  covered.update(region);exact_body[address-ENTRY:address-ENTRY+len(exact)]=exact;run_body[address-ENTRY:address-ENTRY+len(loaded)]=loaded
 for phase in layout['phases']:
  name=phase['symbol'];address=phase['address'];size=phase['end']-phase['begin']
  context=contexts[phase['public']];blob=blobs[context['public']]
  assert OBJECT_NAMES[name]==context['object'] and v.LEAVES[name]==(address+0x25600,size)
  assert v.LEAF_CODE_SLICES[name]==(context['public'],phase['begin'],phase['end'],context['size'])
  assert phase['begin'] in boundaries[context['public']] and phase['end'] in boundaries[context['public']]
  fields={}
  exact,bindings=v.bind_leaf_details(blob,name,v.DATA_OFFSETS,address=address,functions=v.FUNCTION_ADDRESSES,absolute_code=v.CODE_OFFSETS,code_bindings=fields)
  assert not fields and exact==exe[address+0x25600:address+0x25600+size]
  v.verify_leaf_relocations(exact,bindings,pointers,address,code_bindings=fields)
  loaded_fields={}
  loaded,loaded_bindings=v.bind_leaf_details(blob,name,{k:DS+n for k,n in v.DATA_OFFSETS.items()},address=address,functions=v.FUNCTION_ADDRESSES,absolute_code=v.CODE_OFFSETS,code_bindings=loaded_fields)
  assert not loaded_fields and loaded_bindings=={k:DS+n for k,n in bindings.items()}
  install(address,exact,loaded);reports.append(dict(symbol=name,bytes=size,DATA_sites=len(bindings)))
 binary=(build/'asm/weapon_animation.bin').read_bytes();assert len(binary)==layout['assembly_size']
 for row in layout['retained']:
  name=row['symbol'];address=row['address'];size=row['size'];offset,total=GROUP_SLICES[name]
  fields={int(k):n for k,n in row['fixups'].items()}
  assert next(r for r in ROUTINES if r[0]==name)[3:]==(address,size,fields)
  assert offset==row['binary_offset'] and total==len(binary)
  exact=binary[offset:offset+size];assert exact==exe[address+0x25600:address+0x25600+size]
  assert dict(pointers.between(address,address+size))=={address+k:n for k,n in fields.items()}
  assert set(DATA_POINTER_SITES[name])==set(fields)
  verify_pointer_operands(exact,fields,DATA_POINTER_SITES[name]);loaded=bytearray(exact)
  for site,target in fields.items():loaded[site:site+4]=target.to_bytes(4,'little')
  install(address,exact,loaded)
 assert covered==set(range(ENTRY,ENTRY+SIZE)) and exact_body==exe[ENTRY+0x25600:ENTRY+0x25600+SIZE]
 assert sum(r['bytes'] for r in reports)==393 and sum(r['DATA_sites'] for r in reports)==25
 return blobs,bytes(run_body),reports

def bind_natural(blob,context):
 import verify_c_leaf as v
 public=context['public'];base=0x40000
 # Natural replay keeps compiler branch destinations; production binding
 # separately checks their original encodings and places selected edges.
 branches=v.LEAF_SECTION_BRANCHES.pop(public)
 try:
  fields={}
  code,bindings=v.bind_leaf_details(blob,public,{k:DS+n for k,n in v.DATA_OFFSETS.items()},address=base,functions=v.FUNCTION_ADDRESSES,absolute_code=v.CODE_OFFSETS,code_bindings=fields)
  assert not fields and len(code)==context['size'] and len(bindings)==106
 finally:v.LEAF_SECTION_BRANCHES[public]=branches
 return code,base

def context_controls(blob,context):
 import verify_c_leaf as v
 from dataclasses import replace
 from check_encounter_actor import rewrite_fixup
 from check_encounter_spawn import move_zero_public
 from check_ripple_stack import mutate_public_byte
 from check_ripple_control import rename_external
 layout=v.WEAPON_ANIMATION_LAYOUT;public=context['public'];phase=next(p for p in layout['phases'] if p['public']==public);controls=[]
 def bind(b):return v.bind_leaf_details(b,phase['symbol'],v.DATA_OFFSETS,address=phase['address'],functions=v.FUNCTION_ADDRESSES,absolute_code=v.CODE_OFFSETS,code_bindings={})
 def reject(b,message):
  try:bind(b)
  except ValueError as error:assert message in str(error),str(error)
  else:raise AssertionError('Context mutation escaped: '+message)
 baseline=bind(blob);roundtrip,changed=rewrite_fixup(blob,lambda f:False,lambda f:f)
 assert not changed and bind(roundtrip)==baseline
 reject(mutate_public_byte(blob,public,context['size']-1),'context digest');controls.append('private_return')
 reject(rename_external(blob,b'_weapon_frame_words',b'_weapon_frame_wordx'),'fixup records');controls.append('excluded_frame_external')
 _,_,externals,_,fixups=v.parsed_leaf_object(blob)
 clock=externals.index('_game_clock');last=externals.index('_last_frame_tick');fire=externals.index('fire_player_projectile_')
 for name,predicate,change in [
  ('valid_DATA_target',lambda f:f.target==(2,clock),lambda f:replace(f,target=(2,last))),
  ('DATA_to_call_symbol',lambda f:f.target==(2,clock),lambda f:replace(f,target=(2,fire))),
  ('call_to_DATA_symbol',lambda f:f.relative,lambda f:replace(f,target=(2,clock))),
  ('frame',lambda f:True,lambda f:replace(f,frame=(1,1))),
  ('displacement',lambda f:True,lambda f:replace(f,displacement=1)),
  ('external_index',lambda f:True,lambda f:replace(f,target=(2,127)))]:
  bad,changed=rewrite_fixup(blob,predicate,change);assert changed
  if name=='external_index':
   try:bind(bad)
   except ValueError as error:assert 'external index' in str(error) or 'fixup records' in str(error),str(error)
   else:raise AssertionError('Invalid external index escaped')
  else:reject(bad,'fixup records')
  controls.append(name)
 saved_digest=v.LEAF_CONTEXT_SHA256.pop(public)
 try:
  excluded=next(f for f in fixups if externals[f.target[1]]=='_weapon_frame_words')
  reject(mutate_public_byte(blob,public,excluded.offset),'target/form/addend');controls.append('excluded_addend_without_digest')
  site=int(next(iter(context['branches'])));opcode=bytes.fromhex(context['branches'][str(site)][0])
  reject(mutate_public_byte(blob,public,site+len(opcode)),'compiler target');controls.append('branch_target_without_digest')
  reject(mutate_public_byte(blob,public,site),'opcode/fixup');controls.append('branch_opcode_without_digest')
 finally:v.LEAF_CONTEXT_SHA256[public]=saved_digest
 saved_fixups=v.LEAF_CONTEXT_FIXUPS.pop(public)
 try:reject(move_zero_public(blob,public,shift=context['size']),'literal prefix')
 finally:v.LEAF_CONTEXT_FIXUPS[public]=saved_fixups
 controls.append('moved_public_with_fixup_inventory_suspended')
 return controls

def code_controls(original,body,rows):
 controls=[]
 for name,site,old,new,case_name in [
  ('clock_threshold',ENTRY+18,6,7,'clock_7_0'),
  ('clock_branch',ENTRY+19,0x7e,0x7f,'clock_7_0'),
  ('state_dispatch',0x29d07,0x85,0x84,'active_1_0_-1_7_1'),
  ('active_state_kind',0x29f56,1,2,'active_1_0_-1_7_1'),
  ('signed_direction',0x29e41,0x9e,0x9f,'idle_0_0_1_6'),
  ('projectile_sign_extension',0x29e61,0xbf,0xb7,'projectile_word_-1'),
  ('record_stride',0x29dbf,2,1,'idle_1_1_1_7'),
  ('lowering_transition',0x29f90,2,3,'active_1_0_0_6_1')]:
  case=next(c for c in rows if c['name']==case_name);bad=bytearray(body);assert bad[site-ENTRY]==old,(name,hex(site),bad[site-ENTRY])
  bad[site-ENTRY]=new
  try:exercise(original,bytes(bad),case)
  except AssertionError as error:assert str(error)==case_name,str(error)
  else:raise AssertionError('Code mutation escaped: '+name)
  controls.append(name)
 return controls

def natural_code_controls(original,body,base,rows):
 # After binding the guarded private context, redirect frame -1 to -1053.
 # The distinct seeded pairs make the final-DATA oracle detect the wrong read.
 # Register allocation differs between the two guarded compiler contexts.
 instructions=[bytes.fromhex(s) for s in ('81ea1d040000','81e81d040000')]
 assert sum(body.count(i) for i in instructions)==1
 instruction=next(i for i in instructions if i in body)
 site=body.index(instruction);bad=bytearray(body)
 bad[site+2:site+6]=(2105).to_bytes(4,'little')
 case=next(c for c in rows if c['name']=='slot_zero_negative_frame')
 try:exercise(original,bytes(bad),case,base,native=True)
 except AssertionError as error:assert str(error)==case['name'],str(error)
 else:raise AssertionError('Native negative-frame alias escaped')
 return ['slot_zero_negative_frame_alias']

def main():
 import argparse
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--exe',type=Path,required=True);parser.add_argument('--build',type=Path,required=True);parser.add_argument('--output',type=Path,required=True);a=parser.parse_args()
 exe=a.exe.read_bytes();assert hashlib.sha256(exe).hexdigest()==TARGET_SHA256;verify_data_extent(exe)
 original=image(exe);reference=bytes(original[ENTRY:ENTRY+SIZE]);blobs,body,spans=bind_production(exe,a.build)
 import verify_c_leaf as v
 contexts=v.WEAPON_ANIMATION_LAYOUT['contexts'];rows=cases();calls=0
 natural_contexts=[]
 for context in contexts:
  code,base=bind_natural(blobs[context['public']],context)
  natural_contexts.append(dict(context=context,code=code,base=base,register_differences=0,flag_differences=0))
 for case in rows:
  observed=exercise(original,reference,case);placed=exercise(original,body,case);assert placed==observed,case['name']
  calls+=len(observed[0][1])
  for row in natural_contexts:
   native=exercise(original,row['code'],case,row['base'],native=True);assert native[0]==observed[0],case['name']
   row['register_differences']+=native[1]!=observed[1];row['flag_differences']+=native[2]!=observed[2]
 private=[]
 for row in natural_contexts:
  context=row['context']
  private.append(dict(public=context['public'],cases=len(rows),register_difference_cases=row['register_differences'],flag_difference_cases=row['flag_differences'],context_controls=context_controls(blobs[context['public']],context),code_controls=natural_code_controls(original,row['code'],row['base'],rows)))
 report=dict(status='PASS',cases=len(rows),projectile_calls=calls,private_contexts=private,placed_c_bytes=sum(s['bytes'] for s in spans),DATA_sites=sum(s['DATA_sites'] for s in spans),spans=spans,code_controls=code_controls(original,body,rows),scope='Original and placed full routine vs independent final-DATA/ordered-callback model, saved registers/stack/raw EAX/arithmetic flags. Complete private C contexts separately check modeled effects and saved ABI, not raw EAX/flags equivalence. Valid definition slots0..7 and actual LE DATA lookup bounds, including slot-zero negative frames. Projectile is stubbed; no volatile access trace, clock-ISR interleavings or projectile gameplay validation.')
 a.output.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');print(json.dumps(report))
if __name__=='__main__':main()

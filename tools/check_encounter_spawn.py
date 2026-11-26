"""Independent bounded spawn-prefix model; helper calls are stubbed."""
from pathlib import Path
import sys,struct,json,hashlib
ROOT=Path(__file__).resolve().parents[1]
from unicorn import Uc,UC_ARCH_X86,UC_MODE_32,UC_HOOK_CODE,UC_HOOK_MEM_WRITE
from unicorn.x86_const import *
from check_start_hook import image,DS
from compare_exe import TARGET_SHA256
from le_fixups import read_le_fixups

ENTRY,END,RAW,SIZE=0x1df5b,0x1e1b0,0x4355b,597
CALLER_SP=0x3fef00
SP=CALLER_SP-208
DATA_SIZE=0x360000
A=dict(clock=0x12814,advance=0x229b,ticks=0x7a994,count=0x3be6,triggers=0x77124,
       sprite=0x2040a0,sectors=0x27c3a0,numsectors=0x289154,rotating=0x7dec0,width=0x1f2020)
F=dict(rand=0x602d0,sound=0x34f79,sector=0x542c4,spawn=0x11073,listed=0x134c2)
REGS=(UC_X86_REG_EAX,UC_X86_REG_EBX,UC_X86_REG_ECX,UC_X86_REG_EDX,UC_X86_REG_ESI,UC_X86_REG_EDI,UC_X86_REG_EBP)
POSITIONS=((-10240,-6400),(-9728,-5632),(-8960,-5376),(-7936,-5888),(-7424,-5376),
 (-9984,-7168),(-8704,-6656),(-7936,-7424),(-7424,-7168),(-10752,-9216),(-10240,-8192),
 (-6912,-8448),(-9984,-9728),(-7680,-9728),(-8704,-10240),(-9216,-10752))
REPEATS=bytes([60]*2+[30]*4+[15]*16+[7]*10)
TABLE=struct.pack('<32i',*(v for p in POSITIONS for v in p))+REPEATS
u32=lambda n:n&0xffffffff
i16=lambda n:(n&0x7fff)-(n&0x8000)
def put(m,p,fmt,*v):struct.pack_into('<'+fmt,m,p,*v)
def get(m,p,fmt):return struct.unpack_from('<'+fmt,m,p)[0]
def trigger(x=-9000,y=-7000,tag=0x203,slot=2):return(slot,tag,x,y)
def cases():
 rows=[]
 def add(name,**kw):
  c=dict(name=name,clock=1,advance=0,ticks=1,triggers=[],tags=[14,1,14,-1],widths=[64,127],
         hint=-1,slots=[13,17,21,25,28,31],seed=3,draw=None)
  c.update(kw);rows.append(c)
 for clock in (-1,0,1,9,10,11,32767):
  for advance in (0,1):
   for ticks in (0,1,3):add(f'clock_{clock}_{advance}_{ticks}',clock=clock,advance=advance,ticks=ticks)
 for field,bounds in [('x',(-12290,-5123)),('y',(-11531,-4614))]:
  for n in (bounds[0]-1,bounds[0],bounds[0]+1,bounds[1]-1,bounds[1],bounds[1]+1,-2147483648,2147483647):
   add(f'{field}_{n}',clock=0,triggers=[trigger(**{field:n})])
 add('wrong_hitag',clock=0,triggers=[trigger(tag=-1)])
 add('multiple_triggers',clock=0,triggers=[trigger(slot=2),trigger(x=0,slot=3),trigger(slot=4)],ticks=3)
 add('no_sectors',clock=0,triggers=[trigger()],tags=[],ticks=0)
 add('no_tag14',clock=0,triggers=[trigger()],tags=[0,-1,13,15])
 add('all_tag14',clock=0,triggers=[trigger()],tags=[14]*4)
 add('same_sprite',slots=[13],ticks=3)
 for hint in (0,32767,-32768):add('hint_'+str(hint),hint=hint)
 for widths in ([0,0],[-32768,32767],[-1,1]):add('widths_'+str(widths),widths=widths,ticks=3)
 for draw in (0,32767):add('draw_'+str(draw),draw=draw,ticks=3)
 for ticks in (0,1):
  add('poisoned_ecx_'+str(ticks),clock=0,advance=1,ticks=ticks,
      triggers=[trigger(slot=2),trigger(y=-0x30000,slot=3)])
 for ticks in (-1,-2147483648,-2147483647,1073741824):add('ticks_wrap_'+str(ticks),ticks=ticks)
 return rows
def draw(c,n):
 if c['draw'] is not None:return c['draw']
 i,j=divmod(n,5)
 return (((i*7+c['seed'])&15)|0x3100,0x7ffe|((i+c['seed'])&1),
         ((i*3+c['seed'])&15)|0x7f00,0x1234+i,0x455a+i)[j]&0x7fff
def seed(original,c):
 m=bytearray(original)
 for name,fmt,value in [('clock','h',c['clock']),('advance','h',c['advance']),('ticks','i',c['ticks']),
                        ('count','h',len(c['triggers'])),('numsectors','h',len(c['tags'])),('rotating','h',-123)]:
  put(m,DS+A[name],fmt,value)
 for i in range(64):m[DS+A['sprite']+44*i:DS+A['sprite']+44*(i+1)]=bytes([0x91+i%31])*44
 for index,(slot,tag,x,y) in enumerate(c['triggers'],1):
  put(m,DS+A['triggers']+4*index,'hh',slot,-99)
  p=DS+A['sprite']+44*slot;put(m,p,'ii',x,y);put(m,p+40,'h',tag)
 for i,tag in enumerate(c['tags']):put(m,DS+A['sectors']+40*i+34,'h',tag)
 for tile,width in zip((0x350,0x351),c['widths']):put(m,DS+A['width']+2*tile,'h',width)
 m[SP-64:CALLER_SP+68]=bytes([0xa7])*(CALLER_SP+68-(SP-64))
 m[SP:SP+160]=TABLE;put(m,SP+0xac,'h',c['hint'])
 put(m,SP+184,'7I',0x55667788,0x66778899,0x778899aa,0x12345678,0x89abcdef,0x3456789a,0x3fff00)
 return m
def expected(initial,c):
 m=bytearray(initial);calls=[];clock=c['clock'];rng=0
 if clock!=10:
  if clock==0:
   for slot,tag,x,y in c['triggers']:
    if tag==0x203 and -12290<x<-5123 and -11531<y<-4614:
     clock=1;put(m,DS+A['clock'],'h',clock)
     calls.extend([('sound',136,0,0,0),('sound',135,0,0,0)])
     put(m,DS+A['rotating'],'h',0)
     for i,tag in enumerate(c['tags']):
      if tag==14:put(m,DS+A['sectors']+40*i+34,'h',0)
  if clock>0:
   if c['advance']:clock=i16(clock+1);put(m,DS+A['clock'],'h',clock)
   put(m,SP+0xb4,'I',1)
   for i in range(max(0,(u32(2*c['ticks']) ^ 0x80000000)-0x80000000)):
    vals=[draw(c,rng+j) for j in range(5)];rng+=5
    calls.append(('rand',vals[0]));x,y=POSITIONS[vals[0]&15]
    put(m,SP+0xa0,'iii',x,y,-50170)
    hint=get(m,SP+0xac,'h');sector=(i+c['seed'])%len(c['tags'])
    calls.append(('sector',u32(x),u32(y),SP+0xac,hint));put(m,SP+0xac,'h',sector)
    slot=c['slots'][i%len(c['slots'])];p=DS+A['sprite']+44*slot
    calls.append(('spawn',43,SP+0xa0,sector,(x,y,-50170),slot))
    put(m,p,'iii',x,y,-50170)
    calls.append(('rand',vals[1]));tile=0x350+(vals[1]&1);put(m,p+14,'h',tile)
    calls.extend(('rand',n) for n in vals[2:])
    rx,ry=REPEATS[(vals[2]&15)*2:(vals[2]&15)*2+2]
    rx>>=vals[3]&1;ry>>=vals[4]&1
    put(m,SP+0xb0,'I',vals[4]&1);put(m,p+20,'BB',rx,ry)
    width=c['widths'][tile-0x350];put(m,p+18,'B',((width*rx)>>7)&255)
    calls.append(('listed',slot,i+2));put(m,SP+0xb4,'I',i+2)
 return bytes(m[DS:DS+DATA_SIZE]),bytes(m[SP:SP+184]),tuple(calls)
def exercise(original,body,c):
 initial=seed(original,c);cpu=Uc(UC_ARCH_X86,UC_MODE_32);cpu.mem_map(0,0x400000);cpu.mem_write(0,bytes(initial));cpu.mem_write(ENTRY,body)
 for target in F.values():cpu.mem_write(target,b'\xc3')
 for reg,value in zip(REGS,(0xbad00000,0x3456789a,0,0x12345678,0x1df2e,SP+160,0x55667788)):cpu.reg_write(reg,value)
 cpu.reg_write(UC_X86_REG_ESP,SP);cpu.reg_write(UC_X86_REG_EFLAGS,0x202)
 calls=[];state=dict(rng=0,spawn=0)
 def r(reg):return cpu.reg_read(reg)
 def w(reg,n):cpu.reg_write(reg,u32(n))
 def hook(_cpu,address,size,_user):
  if address==END:cpu.emu_stop();return
  if ENTRY<=address<END:return
  assert address in F.values(),f'escaped phase {address:x}'
  if address==F['rand']:
   n=draw(c,state['rng']);state['rng']+=1;calls.append(('rand',n));w(UC_X86_REG_EAX,n)
  elif address==F['sound']:
   calls.append(('sound',r(UC_X86_REG_EAX),r(UC_X86_REG_EDX),r(UC_X86_REG_EBX),r(UC_X86_REG_ECX)))
   w(UC_X86_REG_EAX,-1);w(UC_X86_REG_EBX,0xbad01001);w(UC_X86_REG_EDX,0xbad01002)
  elif address==F['sector']:
   p=r(UC_X86_REG_EBX);hint=struct.unpack('<h',cpu.mem_read(p,2))[0]
   calls.append(('sector',r(UC_X86_REG_EAX),r(UC_X86_REG_EDX),p,hint));assert p==SP+0xac
   sector=(state['spawn']+c['seed'])%len(c['tags']);cpu.mem_write(p,struct.pack('<h',sector))
   for reg,n in ((UC_X86_REG_EAX,0xbad02000),(UC_X86_REG_EBX,0xbad02001),(UC_X86_REG_EDX,0xbad02002)):w(reg,n)
  elif address==F['spawn']:
   p=r(UC_X86_REG_EDX);position=struct.unpack('<iii',cpu.mem_read(p,12));i=state['spawn'];slot=c['slots'][i%len(c['slots'])]
   calls.append(('spawn',r(UC_X86_REG_EAX),p,r(UC_X86_REG_EBX),position,slot));assert p==SP+0xa0
   cpu.mem_write(DS+A['sprite']+44*slot,struct.pack('<iii',*position));state['spawn']+=1
   for reg,n in ((UC_X86_REG_EAX,0xabcd0000|slot),(UC_X86_REG_EBX,0xbad03001),(UC_X86_REG_EDX,0xbad03002)):w(reg,n)
  else:
   calls.append(('listed',r(UC_X86_REG_EAX),r(UC_X86_REG_EDX)));w(UC_X86_REG_EAX,0xbad04000)
 def writes(_cpu,_kind,address,size,_value,_user):
  assert DS<=address and address+size<=DS+DATA_SIZE or SP-32<=address and address+size<=SP+184, f'write {address:x}'
 cpu.hook_add(UC_HOOK_CODE,hook);cpu.hook_add(UC_HOOK_MEM_WRITE,writes)
 cpu.emu_start(ENTRY,END,count=50000)
 assert r(UC_X86_REG_EIP)==END and r(UC_X86_REG_ESP)==SP
 assert bytes(cpu.mem_read(SP+184,92))==bytes(initial[SP+184:SP+276])
 assert bytes(cpu.mem_read(SP-64,32))==bytes(initial[SP-64:SP-32])
 result=(bytes(cpu.mem_read(DS,DATA_SIZE)),bytes(cpu.mem_read(SP,184)),tuple(calls))
 assert result==expected(initial,c),c['name']
 return result,tuple(r(reg) for reg in REGS),r(UC_X86_REG_EFLAGS)&0x8c5
def bind_prefix(exe,build):
 import verify_c_leaf as v
 from verify_c_suite import OBJECT_NAMES
 from verify_assembly_suite import ROUTINES,GROUP_SLICES,DATA_POINTER_SITES,verify_pointer_operands
 layout=v.ENCOUNTER_SPAWN_LAYOUT
 pointers=read_le_fixups(exe)['pointers'];raw=bytearray(SIZE);loaded=bytearray(SIZE);covered=set()
 reports=[]
 def install(address,exact,runtime):
  region=set(range(address,address+len(exact)))
  assert not covered.intersection(region) and region <= set(range(ENTRY,END))
  covered.update(region);raw[address-ENTRY:address-ENTRY+len(exact)]=exact;loaded[address-ENTRY:address-ENTRY+len(runtime)]=runtime
 for phase in layout['phases']:
  name=phase['symbol'];address=phase['address']
  assert OBJECT_NAMES[name]==phase['object']
  blob=(build/(phase['object']+'.obj')).read_bytes();code_fields={}
  exact,bindings=v.bind_leaf_details(blob,name,v.DATA_OFFSETS,address=address,functions=v.FUNCTION_ADDRESSES,absolute_code=v.CODE_OFFSETS,code_bindings=code_fields)
  assert not code_fields
  v.verify_leaf_relocations(exact,bindings,pointers,address,code_bindings=code_fields)
  offset,size=v.LEAVES[name];assert exact==exe[offset:offset+size]
  if not ENTRY<=address<END:continue
  loaded_fields={}
  runtime,runtime_bindings=v.bind_leaf_details(blob,name,{k:DS+n for k,n in v.DATA_OFFSETS.items()},address=address,functions=v.FUNCTION_ADDRESSES,absolute_code=v.CODE_OFFSETS,code_bindings=loaded_fields)
  assert not loaded_fields and runtime_bindings=={k:DS+n for k,n in bindings.items()}
  install(address,exact,runtime);reports.append(dict(symbol=name,bytes=size,DATA_sites=len(bindings)))
 binary=(build/'asm/level_encounter.bin').read_bytes();assert len(binary)==layout['assembly_size']
 for row in layout['retained']:
  name=row['symbol'];address=row['address'];size=row['size'];offset,total=GROUP_SLICES[name]
  registration=next(r for r in ROUTINES if r[0]==name)
  expected={int(k):n for k,n in row['fixups'].items()}
  assert registration[3:]==(address,size,expected) and total==len(binary) and offset==row['binary_offset']
  exact=binary[offset:offset+size];assert exact==exe[address+0x25600:address+0x25600+size]
  assert dict(pointers.between(address,address+size))=={address+k:n for k,n in expected.items()}
  verify_pointer_operands(exact,expected,DATA_POINTER_SITES[name])
  runtime=bytearray(exact)
  for site,target in expected.items():runtime[site:site+4]=target.to_bytes(4,'little')
  install(address,exact,runtime)
 assert covered==set(range(ENTRY,END)) and raw==exe[RAW:RAW+SIZE]
 return bytes(loaded),reports

def move_zero_public(blob,public,shift=40):
    import verify_c_leaf as v
    from match_objects import index
    segments,publics,_,_,fixups=v.parsed_leaf_object(blob)
    assert publics==((1,0,public),)
    raw=bytes(segments[1]['data'])
    assert max((f.offset+f.width for f in fixups),default=0)<=shift
    def record(kind,data):
        row=bytearray([kind])+bytearray((len(data)+1).to_bytes(2,'little'))+data
        row.append((-sum(row))&255)
        return row
    out=bytearray();cursor=0;segment=0;inserted=False;modified=False
    while cursor<len(blob):
        kind=blob[cursor];length=int.from_bytes(blob[cursor+1:cursor+3],'little');end=cursor+3+length;data=bytearray(blob[cursor+3:end-1])
        if kind in (0x98,0x99):
            segment+=1
            if segment==1:
                pos=4 if data[0]>>5==0 else 1;width=4 if kind&1 else 2
                assert int.from_bytes(data[pos:pos+width],'little')==len(raw)
                data[pos:pos+width]=(len(raw)+shift).to_bytes(width,'little')
        if kind in (0x90,0x91):
            _,pos=index(data,0);seg,pos=index(data,pos);assert seg==1
            size=data[pos];name=bytes(data[pos+1:pos+1+size]).decode('ascii');assert name==public
            pos+=size+1;width=4 if kind&1 else 2;assert int.from_bytes(data[pos:pos+width],'little')==0
            data[pos:pos+width]=shift.to_bytes(width,'little');modified=True
        if kind in (0x8a,0x8b):
            assert not inserted
            out.extend(record(0xa1,bytearray(b'\x01')+bytearray(shift.to_bytes(4,'little'))+raw));inserted=True
        out.extend(record(kind,data));cursor=end
    assert inserted and modified
    parsed=v.parsed_leaf_object(bytes(out));assert parsed[1]==((1,shift,public),)
    assert bytes(parsed[0][1]['data'][shift:])==raw and parsed[-1]==fixups
    return bytes(out)


def context_controls(build):
 import verify_c_leaf as v
 from dataclasses import replace
 from check_encounter_actor import rewrite_fixup
 from check_ripple_stack import mutate_public_byte
 controls=[]
 for context in v.ENCOUNTER_SPAWN_LAYOUT['contexts']:
  public=context['public'];blob=(build/(context['object']+'.obj')).read_bytes()
  phase=next(p for p in v.ENCOUNTER_SPAWN_LAYOUT['phases'] if p['public']==public)
  def bind(b):
   return v.bind_leaf_details(b,phase['symbol'],v.DATA_OFFSETS,address=phase['address'],functions=v.FUNCTION_ADDRESSES,absolute_code=v.CODE_OFFSETS,code_bindings={})
  def reject(b,message):
   try:bind(b)
   except ValueError as error:assert message in str(error),str(error)
   else:raise AssertionError('Context mutation escaped: '+message)
  original=bind(blob)
  unchanged,changed=rewrite_fixup(blob,lambda f:False,lambda f:f)
  assert not changed and bind(unchanged)==original
  reject(mutate_public_byte(blob,public,context['size']-1),'context digest');controls.append(public+'private_ret')
  prefix=context.get('prefix',160)
  if prefix:
   reject(mutate_public_byte(blob,public,-prefix),'literal prefix');controls.append(public+'literal')
  else:
   reject(move_zero_public(blob,public),'literal prefix');controls.append(public+'moved_public')
  operands=[f[1]-prefix for f in context['records']['fixups'] if f[-1] is not None]
  if operands:
   reject(mutate_public_byte(blob,public,operands[0]),'context digest');controls.append(public+'raw_addend')
  _,_,externals,_,_=v.parsed_leaf_object(blob)
  mutations=[
   ('target',lambda f:f.target[0]==2,lambda f:replace(f,target=(2,127))),
   ('internal_target',lambda f:f.target[0]==0,lambda f:replace(f,target=(0,3))),
   ('frame',lambda f:f.target[0]==2,lambda f:replace(f,frame=(1,1))),
   ('displacement',lambda f:f.target[0]==2,lambda f:replace(f,displacement=1))]
  if '_encounter_clock' in externals and '_advance_clock' in externals:
   clock_index=externals.index('_encounter_clock');advance_index=externals.index('_advance_clock')
   mutations.append(('valid_external_target',lambda f:f.target==(2,clock_index),lambda f:replace(f,target=(2,advance_index))))
  for name,predicate,change in mutations:
   bad,changed=rewrite_fixup(blob,predicate,change)
   if not changed:
    assert not any(predicate(f) for f in v.parsed_leaf_object(blob)[-1])
    continue
   assert changed
   try:bind(bad)
   except ValueError as error:assert 'fixup records' in str(error) or name=='target' and 'external index' in str(error),str(error)
   else:raise AssertionError('OMF mutation escaped')
   controls.append(public+name)
  if context['branches']:
   site=int(next(iter(context['branches'])))
   bad=mutate_public_byte(blob,public,site+len(bytes.fromhex(context['branches'][str(site)][0])))
   digest=v.LEAF_CONTEXT_SHA256.pop(public)
   try:reject(bad,'compiler target')
   finally:v.LEAF_CONTEXT_SHA256[public]=digest
   controls.append(public+'branch_without_digest')
 return controls

def byte_witness_cases(original,build):
 """Run the complete private conversion witness against its integer contract."""
 import itertools
 import verify_c_leaf as v
 context=next(c for c in v.ENCOUNTER_SPAWN_LAYOUT['contexts'] if c['object']=='encbyte')
 blob=(build/'encbyte.obj').read_bytes();base=0x40000;stop=0x3fff00
 fields={}
 code,bindings=v.bind_leaf_details(blob,context['public'],v.DATA_OFFSETS,address=base,functions=v.FUNCTION_ADDRESSES,absolute_code=v.CODE_OFFSETS,code_bindings=fields)
 assert len(code)==context['size'] and not fields and not bindings
 rows=list(itertools.product((0,1,32767),repeat=3))
 rows.extend(tuple((i*k+offset)&32767 for k,offset in ((293,0x100),(797,0x7f00),(983,0x1234))) for i in range(64))
 for draws in rows:
  cpu=Uc(UC_ARCH_X86,UC_MODE_32);cpu.mem_map(0,0x400000);cpu.mem_write(0,bytes(original));cpu.mem_write(base,code);cpu.mem_write(F['rand'],b'\xc3')
  cpu.mem_write(CALLER_SP-64,bytes([0xa7])*132);cpu.mem_write(CALLER_SP,struct.pack('<I',stop));cpu.reg_write(UC_X86_REG_ESP,CALLER_SP)
  values=(0xbad00000,0x3456789a,0xfeed1234,0x12345678,0x55667788,0x66778899,0x778899aa)
  for reg,value in zip(REGS,values):cpu.reg_write(reg,value)
  calls=[]
  def hook(_cpu,address,size,_user):
   if address==stop:cpu.emu_stop();return
   if base<=address<base+len(code):return
   assert address==F['rand'] and len(calls)<3
   cpu.reg_write(UC_X86_REG_EAX,draws[len(calls)]);calls.append(address)
  cpu.hook_add(UC_HOOK_CODE,hook);cpu.emu_start(base,stop,count=500)
  assert len(calls)==3 and cpu.reg_read(UC_X86_REG_EIP)==stop
  assert cpu.reg_read(UC_X86_REG_EAX)==(draws[0]%16)+16*(draws[1]%2)+32*(draws[2]%2),draws
  assert tuple(cpu.reg_read(reg) for reg in REGS[1:])==values[1:]
  assert cpu.reg_read(UC_X86_REG_ESP)==CALLER_SP+4
  assert bytes(cpu.mem_read(CALLER_SP-64,40))==bytes([0xa7])*40
  assert bytes(cpu.mem_read(CALLER_SP+4,64))==bytes([0xa7])*64
  assert bytes(cpu.mem_read(DS,DATA_SIZE))==bytes(original[DS:DS+DATA_SIZE])
 return len(rows)

def width_witness_cases(original,build):
 """Check low-word signed promotion and the custom EBX result ABI."""
 import verify_c_leaf as v
 context=next(c for c in v.ENCOUNTER_SPAWN_LAYOUT['contexts'] if c['object']=='encwidth')
 fields={};base=0x41000;stop=0x3fff00
 code,bindings=v.bind_leaf_details((build/'encwidth.obj').read_bytes(),context['public'],v.DATA_OFFSETS,address=base,functions=v.FUNCTION_ADDRESSES,code_bindings=fields)
 assert code==bytes.fromhex('0fbfd8c3') and not bindings and not fields
 cases=0
 for width in (-32768,-32767,-256,-1,0,1,255,256,32767):
  for high in (0,0x1234,0xffff):
   cpu=Uc(UC_ARCH_X86,UC_MODE_32);cpu.mem_map(0,0x400000);cpu.mem_write(0,bytes(original));cpu.mem_write(base,code);cpu.mem_write(CALLER_SP-64,bytes([0xa7])*132);cpu.mem_write(CALLER_SP,struct.pack('<I',stop));cpu.reg_write(UC_X86_REG_ESP,CALLER_SP)
   values=((high<<16)|(width&65535),0x3456789a,0xfeed1234,0x12345678,0x55667788,0x66778899,0x778899aa)
   for reg,value in zip(REGS,values):cpu.reg_write(reg,value)
   cpu.reg_write(UC_X86_REG_EFLAGS,0x8d7);cpu.emu_start(base,stop,count=10)
   expected_regs=list(values);expected_regs[1]=u32(width)
   assert tuple(cpu.reg_read(reg) for reg in REGS)==tuple(expected_regs)
   assert cpu.reg_read(UC_X86_REG_ESP)==CALLER_SP+4 and cpu.reg_read(UC_X86_REG_EIP)==stop
   assert cpu.reg_read(UC_X86_REG_EFLAGS)&0x8d5==0x8d5
   assert bytes(cpu.mem_read(CALLER_SP-64,64))==bytes([0xa7])*64 and bytes(cpu.mem_read(CALLER_SP+4,64))==bytes([0xa7])*64
   assert bytes(cpu.mem_read(DS,DATA_SIZE))==bytes(original[DS:DS+DATA_SIZE])
   cases+=1
 return cases

def natural_operand_cases(original,build,rows):
 """Check the private prefix's modeled effects without claiming boundary ABI."""
 import verify_c_leaf as v
 context=next(c for c in v.ENCOUNTER_SPAWN_LAYOUT['contexts'] if c['object']=='encoper')
 prefix=context['prefix'];blob=(build/'encoper.obj').read_bytes()
 end=min(f[1]-prefix-3 for f in context['records']['fixups'] if f[-1]=='_first_trigger_sprite')
 raw=v.parsed_leaf_object(blob)[0][1]['data'][prefix:]
 assert raw[end:end+3]==bytes.fromhex('0fbf05') and raw[:12]==bytes.fromhex('53515256575581ecb8000000')
 alias='encounter_operand_fixture_prefix_';assert alias not in v.LEAF_CODE_SLICES
 v.LEAF_CODE_SLICES[alias]=(context['public'],ENTRY-0x1df2e,end,context['size'])
 try:
  fields={}
  code,bindings=v.bind_leaf_details(blob,alias,{k:DS+n for k,n in v.DATA_OFFSETS.items()},address=ENTRY,functions=v.FUNCTION_ADDRESSES,absolute_code=v.CODE_OFFSETS,code_bindings=fields)
  assert not fields and len(bindings)==23
 finally:del v.LEAF_CODE_SLICES[alias]
 global END
 saved_end=END;reference=bytes(original[ENTRY:saved_end]);regs_differ=flags_differ=0
 for case in rows:
  baseline=exercise(original,reference,case)
  END=ENTRY+len(code)
  try:observed=exercise(original,code,case)
  finally:END=saved_end
  assert observed[0]==baseline[0],case['name']
  regs_differ+=observed[1]!=baseline[1];flags_differ+=observed[2]!=baseline[2]
 return dict(cases=len(rows),register_difference_cases=regs_differ,flag_difference_cases=flags_differ,scope='Private prefix memory/frame/call effects only; scratch-register/flag differences do not qualify as a shared-boundary replacement.')

def main():
 import argparse
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--exe',type=Path,required=True);parser.add_argument('--build',type=Path,required=True);parser.add_argument('--output',type=Path,required=True);a=parser.parse_args()
 exe=a.exe.read_bytes();assert hashlib.sha256(exe).hexdigest()==TARGET_SHA256
 assert exe[0x4348e:0x4352e]==TABLE
 original=image(exe);reference=bytes(original[ENTRY:END]);body,spans=bind_prefix(exe,a.build)
 rows=cases()
 for c in rows:
  observed=exercise(original,body,c)
  assert observed==exercise(original,reference,c),c['name']
  if c['name']=='poisoned_ecx_0':assert observed[1][2]==0xfffd0001 and observed[1][5]==0xfffd0002
 case=next(c for c in rows if c['name']=='clock_1_0_1')
 controls=[]
 for name,site,old,new in [('height',0x1e076,6,7),('counter',0x1e071,1,2),('position_destination',0x1e0bd,0xa8,0xa4),('y_shift_destination',0x1e124,0xb0,0xa0),('rng_position_mask',0x1e091,15,7),('rng_bx_lane',0x1e111,0xe7,0xe3)]:
  mutation_case=next(c for c in rows if c['name']=='draw_32767') if name.startswith('rng_') else case
  bad=bytearray(body);assert bad[site-ENTRY]==old;bad[site-ENTRY]=new
  try:exercise(original,bytes(bad),mutation_case)
  except AssertionError as error:assert str(error)==mutation_case['name'],str(error)
  else:raise AssertionError('Semantic mutation escaped: '+name)
  controls.append(name)
 width_case=next(c for c in rows if c['widths']==[-1,1]);baseline=exercise(original,body,width_case)
 bad=bytearray(body);assert bad[0x1e171-ENTRY]==0xbf;bad[0x1e171-ENTRY]=0xb7
 changed=exercise(original,bytes(bad),width_case)
 assert changed[0]==baseline[0] and changed[2]==baseline[2]
 assert baseline[1][1]==0xffffffff and changed[1][1]==65535
 assert changed[1][:1]+changed[1][2:]==baseline[1][:1]+baseline[1][2:]
 controls.append('width_signed_promotion_register_result')
 report=dict(status='PASS',cases=len(rows),byte_witness_cases=byte_witness_cases(original,a.build),width_witness_cases=width_witness_cases(original,a.build),natural_operand=natural_operand_cases(original,a.build,rows),prefix_bytes=SIZE,native_bytes=sum(s['bytes'] for s in spans),DATA_sites=sum(s['DATA_sites'] for s in spans),spans=spans,context_controls=context_controls(a.build),code_controls=controls,scope='Placed production C plus retained assembly, independent DATA/frame/call model and original register/defined-flag comparison. Complete byte and width witnesses separately check results and preserved state; private operand prefix separately checks modeled effects. RNG/sound/sector/spawn/list helpers stubbed; bounded counts, RNG 0..32767, seeded incoming hint; no map/assets/live allocator validation.')
 a.output.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');print(json.dumps(report))
if __name__=='__main__':main()

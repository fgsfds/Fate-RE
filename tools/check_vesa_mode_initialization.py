"""Check reference, selected C phases and private VESA initializer context."""
import argparse, json
from hashlib import sha256
from dataclasses import dataclass, replace
from pathlib import Path
from struct import pack, pack_into, unpack
from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn import x86_const as x
from check_start_hook import image
from check_video_memory_mapping import pattern
import verify_c_leaf as v
from check_ripple_control import rename_external
from check_ripple_stack import mutate_public_byte
from le_fixups import read_le_fixups

DS,SIZE,S,STOP,ENTRY=0x80000,0x28a300,0x4ff000,0x4fff00,0x43d0c
F=S-308
REGS=[x.UC_X86_REG_EAX,x.UC_X86_REG_EBX,x.UC_X86_REG_ECX,x.UC_X86_REG_EDX,x.UC_X86_REG_ESI,x.UC_X86_REG_EDI,x.UC_X86_REG_EBP]
AX,BX,CX,DX,SI,DI,BP=REGS
TARGETS={0x43a50:'allocate',0x43b28:'query',0x4380a:'interrupt',0x438f9:'far',0x43b71:'map',0x40bb4:'printf',0x60353:'exit'}
G=dict(width=0x286b68,height=0x286b7c,pitch=0x286b64,count=0x286b78,linear=0x286b60,software=0x286b84,page=0x286b70,draw=0x286b74,skip=0x286b54,bank=0x286b5c,mapped=0x286b58)
@dataclass(frozen=True)
class Case:
    name:str='linear'
    attempted:int=1
    unsupported:int=0
    rejects:tuple=()
    accepted:bool=True
    linear:bool=True
    width:int=640
    height:int=480
    pitch:int=672
    pages:int=1
    gran:int=64
    pm:bool=True
    seed:int=0

def run(memory,c,code=None,private=False):
    cpu=Uc(UC_ARCH_X86,UC_MODE_32);cpu.mem_map(0,0x500000);cpu.mem_write(0,memory)
    if code is not None:cpu.mem_write(ENTRY,code)
    cpu.mem_write(0x1000,pack('<4Q',0,0x00cf9b000000ffff,0x00cf93000000ffff,0x00cf93000000ffff))
    cpu.reg_write(x.UC_X86_REG_GDTR,(0,0x1000,31,0));cpu.reg_write(x.UC_X86_REG_CS,8)
    for r in (x.UC_X86_REG_DS,x.UC_X86_REG_ES,x.UC_X86_REG_SS):cpu.reg_write(r,0x10)
    for r in (x.UC_X86_REG_FS,x.UC_X86_REG_GS):cpu.reg_write(r,0x18)
    cpu.reg_write(x.UC_X86_REG_EFLAGS,2)
    data=bytearray(pattern(SIZE,0x41+c.seed));expected=bytearray(data)
    def put(off,fmt,value):pack_into('<'+fmt,data,off,value);pack_into('<'+fmt,expected,off,value)
    def expect(off,fmt,value):pack_into('<'+fmt,expected,off,value)
    for off in (0x19e2,0x19e7,0x19ec,0x19fd):
        end=memory.index(b'\0',DS+off)+1
        data[off:end-DS]=memory[DS+off:end];expected[off:end-DS]=memory[DS+off:end]
    put(0x13ff4,'B',c.attempted);put(0x13ff0,'I',0x3a0000)
    for off in G.values():put(off,'I',0x12340000+off)
    put(0x13ff5,'I',0x351111);put(0x13ff9,'I',0x352222)
    put(0x288116,'I',0xabcdef01);put(0x28811a,'H',0x7abc)
    reasons=list(c.rejects)+(['valid'] if c.accepted else [])
    modes=list(range(0x101,0x101+len(reasons)))
    listbytes=pack('<'+'H'*(len(modes)+1),*modes,0xffff)
    cpu.mem_write(0x60020,listbytes);cpu.mem_write(0x62020,pack('<hh',-4,8))
    if c.attempted:data[0x1ec720:0x1ec720+len(listbytes)]=listbytes;expected[0x1ec720:0x1ec720+len(listbytes)]=listbytes
    controller=bytearray(pattern(512,0x73));controller[:4]=b'BAD!' if c.unsupported==2 else bytes(data[0x19e7:0x19eb])
    pack_into('<I',controller,14,0x60000020)
    cpu.mem_write(DS-16,b'\x5a'*16+data+b'\xa6'*16)
    if not c.attempted:
        expect(0x13ff4,'B',1);expected[0x1ec2a0:0x1ec2a0+512]=controller
        if not c.unsupported:expected[0x1ec720:0x1ec720+len(listbytes)]=listbytes
    unsupported=not c.attempted and c.unsupported
    success=not unsupported and c.accepted
    if not unsupported:
        expect(G['width'],'I',c.width);expect(G['height'],'I',c.height)
    n=min(c.pages+1,64);page=c.pitch*c.height;linearbase=0xe1234567;selector=0xfabc
    if success:
        expect(G['pitch'],'I',c.pitch)
        if c.pm:expect(0x13ff5,'I',0x6201c);expect(0x13ff9,'I',0x62028)
        if c.linear:
            expect(G['mapped'],'I',linearbase);expect(0x288116,'I',0);expect(0x28811a,'H',selector)
            software=int(n<=1);draw=linearbase
            for i in range(n):expect(0x1ec5a0+i*4,'I',(linearbase+i*page)&0xffffffff)
        else:
            shifts={64:0,32:1,16:2,8:3,4:4,2:5,1:6}
            if c.gran in shifts:expect(G['bank'],'I',shifts[c.gran])
            special=c.width==320 and c.height==200 and n>=2
            software=int(not special);page=0x10000 if special else page;draw=0xa0000 if special else 0x3a0000;n=1
        for key,val in [('count',n),('linear',int(c.linear)),('software',software),('skip',software),('page',page),('draw',draw)]:expect(G[key],'I',val)
        for i in range(n):
            q,r=divmod(i*page,c.pitch);expect(0x1ec49c+4*(i+1),'H',r&0xffff);expect(0x1ec49e+4*(i+1),'H',q&0xffff)
    cpu.mem_write(F-128,b'\xa5'*(S+64-(F-128)))
    caller=pack('<I',STOP)+pattern(60,0x92);cpu.mem_write(S,caller)
    incoming=dict(zip(REGS,(c.width,0xb1234567,0xc2345678,c.height,0x51234567,0x62345678,0x73456789)))
    for r,val in incoming.items():cpu.reg_write(r,val)
    cpu.reg_write(x.UC_X86_REG_ESP,S)
    trace=[];queries=[]
    want=(['allocate'] if not c.attempted else [])
    if unsupported:want+=['printf']
    else:
        want+=['query']*len(reasons)
        want+=['interrupt','far']+(['map'] if c.linear else []) if c.accepted else ['printf','exit']
    def reg(r):return cpu.reg_read(r)
    def u32(addr):return unpack('<I',cpu.mem_read(addr,4))[0]
    def visit(emu,pc,size,_):
        name=TARGETS.get(pc)
        if name is None:return
        assert len(trace)<len(want) and want[len(trace)]==name,(c.name,trace,name,want)
        trace.append(name);sp=reg(x.UC_X86_REG_ESP)
        assert reg(x.UC_X86_REG_ES)==0x10 and not reg(x.UC_X86_REG_EFLAGS)&0x400
        if name=='allocate':
            assert (reg(AX),reg(DX),reg(BX))==(F+0x100,DS+0x1ec2a0,512)
            assert unpack('<H',emu.mem_read(F+0x100,2))[0]==0x4f00
            if private:assert unpack('<7H',emu.mem_read(F+0x100,14))[1:6]==(0,0,0,0,0)
            assert emu.mem_read(DS+0x1ec2a0,4)==bytes(data[0x19e2:0x19e6])
            emu.mem_write(DS+0x1ec2a0,bytes(controller));emu.mem_write(F+0x100,pack('<7H',0 if c.unsupported==1 else 0x4f,0x1111,0x2222,0x3333,0x4444,0x5555,0))
        elif name=='query':
            index=len(queries);reason=reasons[index];assert reg(AX)==modes[index] and reg(DX)==F
            info=bytearray(pattern(256,0x24+index));pack_into('<HH',info,0,0x1201|int(c.linear)*0x80,0x81ce);pack_into('<H',info,4,c.gran)
            pack_into('<hhh',info,0x10,c.pitch,c.width,c.height)
            for off,val in [(0x18,1),(0x19,8),(0x1b,4),(0x1d,c.pages)]:info[off]=val
            pack_into('<I',info,0x28,0xe0000000)
            if reason in ('planes','bpp','model'):info[dict(planes=0x18,bpp=0x19,model=0x1b)[reason]]=3
            if reason in ('width','height'):pack_into('<h',info,0x12 if reason=='width' else 0x14,-1)
            emu.mem_write(F,bytes(info));emu.reg_write(AX,int(reason!='query'));emu.reg_write(DX,0xdedede01);queries.append(reason)
        elif name in ('interrupt','far'):
            assert (reg(AX),reg(DX),reg(BX))==(0x10,F+0x100,F+0x100)
            if name=='far' or not private:assert reg(CX)==F+0x110
            words=unpack('<7H',emu.mem_read(F+0x100,14))
            if name=='interrupt':assert words[0]==0x4f02 and words[1]==(modes[-1]|(0x4000 if c.linear else 0))
            else:assert words[:4]==(0x4f0a,0,0,0)
            if private:
                if name=='interrupt':assert words[2:6]==(0,0,0,0)
                else:
                    segments=unpack('<6H',emu.mem_read(F+0x110,12))
                    assert (segments[0],segments[3])==(0,0)
                    assert words[4:6]==(0x4444,0x20)
            emu.mem_write(F+0x100,pack('<7H',0x4f if name=='interrupt' or c.pm else 0,0x1111,0x2222,0x3333,0x4444,0x20,0))
            if name=='far':emu.mem_write(F+0x110,pack('<4H',0x6200,0x7777,0x8888,0x9999));emu.reg_write(CX,0xcafeab12)
        elif name=='map':
            assert reg(AX)==0xe0000000;emu.mem_write(DS+G['mapped'],pack('<I',linearbase));emu.reg_write(AX,0);emu.reg_write(DX,selector)
        elif name=='printf':
            assert u32(sp+4)==DS+(0x19ec if unsupported else 0x19fd)
            if not unsupported:assert (u32(sp+8),u32(sp+12))==(c.width,c.height)
            emu.reg_write(AX,0xa111)
        elif name=='exit':
            assert reg(AX)==0;emu.emu_stop();return
        if name in ('allocate','interrupt','far'):
            for r,val in ((AX,0xa1111111),(BX,0xb2222222),(DX,0xd3333333)):emu.reg_write(r,val)
        emu.reg_write(x.UC_X86_REG_EIP,u32(sp));emu.reg_write(x.UC_X86_REG_ESP,sp+4)
    cpu.hook_add(UC_HOOK_CODE,visit);cpu.emu_start(ENTRY,STOP,timeout=2_000_000,count=50000)
    assert trace==want,(c.name,trace,want)
    actual=bytes(cpu.mem_read(DS,SIZE))
    if actual!=expected:
        off=next(i for i,(a,b) in enumerate(zip(actual,expected)) if a!=b)
        raise AssertionError((c.name,'DATA',hex(off),actual[off:off+8].hex(),expected[off:off+8].hex()))
    assert cpu.mem_read(DS-16,16)==b'\x5a'*16 and cpu.mem_read(DS+SIZE,16)==b'\xa6'*16
    assert cpu.mem_read(S,64)==caller
    assert cpu.mem_read(F-128,48)==b'\xa5'*48
    fatal=not unsupported and not c.accepted
    if not fatal:
        assert reg(x.UC_X86_REG_EIP)==STOP and reg(x.UC_X86_REG_ESP)==S+4
        for r in (BX,CX,SI,DI,BP):assert reg(r)==incoming[r],(c.name,'preserved',r,hex(reg(r)))
    return dict(name=c.name,queries=len(queries),trace=trace,returned=not fatal)

def all_cases():
    cases=[Case(),Case(name='fresh',attempted=0),Case(name='ax-failure',attempted=0,unsupported=1),Case(name='signature-failure',attempted=0,unsupported=2),Case(name='empty-list',accepted=False)]
    for reason in ('query','model','bpp','planes','width','height'):
        cases.extend([Case(name='reject-'+reason,rejects=(reason,),accepted=False),Case(name='skip-'+reason,rejects=(reason,))])
    for gran in (64,32,16,8,4,2,1,3):cases.append(Case(name='bank-'+str(gran),linear=False,gran=gran))
    cases.extend([Case(name='bank320-one',linear=False,width=320,height=200,pitch=320,pages=0),Case(name='bank320-two',linear=False,width=320,height=200,pitch=320,pages=1),Case(name='linear-one',pages=0),Case(name='linear-64',pages=255),Case(name='no-pm',pm=False),Case(name='fresh-rejections',attempted=0,rejects=('query','model','bpp','planes','width','height'))])
    return [replace(c,seed=i) for i,c in enumerate(cases)]

PHASES=(
 ("vesa_init_probe_prelude_phase_",0x000,0x03d,0x000),
 ("vesa_init_controller_reply_phase_",0x08e,0x0bf,0x068),
 ("vesa_init_mode_query_phase_",0x0cc,0x113,0x0ab),
 ("vesa_init_mode_dimensions_phase_",0x12e,0x16e,0x119),
 ("vesa_init_framebuffer_phase_",0x25e,0x3c3,0x222),
 ("vesa_init_pages_and_scan_tail_phase_",0x3d8,0x467,0x39c),
)
PUBLIC,OBJECT,CONTEXT_SIZE="initialize_vesa_mode_","vbeinit",1133

def programs(executable,memory,build):
    blob=(build/(OBJECT+'.obj')).read_bytes()
    layout=v.CONTROLLER_PREFIX_LAYOUT
    [obj]=[r for r in layout['objects'] if r['object']==OBJECT]
    [context]=obj['contexts']
    assert (context['public'],context['size'],context['start'])==(PUBLIC,CONTEXT_SIZE,0)
    assert context['sha256']=='85ceaf5218b0e913fa06077c69c347cfcf6e75227f48d25771ef3d6fdbb8a54a'
    assert len(context['fixups'])==69 and len(context['branches']['sites'])==44
    metadata={r['phase']:r for r in layout['phases'] if r['routine']=='initialize_vesa_mode'}
    assert set(metadata)=={r[0] for r in PHASES}
    pointers=read_le_fixups(executable)['pointers']
    assert len(pointers.between(ENTRY,ENTRY+1072))==59
    loaded_data={k:DS+val for k,val in v.DATA_OFFSETS.items()}
    placed=bytearray(memory[ENTRY:ENTRY+1072]);used=set();le_count=0;call_count=0
    def bind(phase,candidate=blob,loaded=False):
        code_refs={}
        code,refs=v.bind_leaf_details(candidate,phase[0],loaded_data if loaded else v.DATA_OFFSETS,address=ENTRY+phase[3],functions=v.FUNCTION_ADDRESSES,absolute_code=v.CODE_OFFSETS,code_bindings=code_refs)
        assert not code_refs
        return code,refs
    for phase in PHASES:
        name,begin,end,offset=phase;r=metadata[name]
        assert (r['begin'],r['end'],r['address'],r['object'],r['public'])==(begin,end,ENTRY+offset,OBJECT,PUBLIC)
        assert not used.intersection(range(begin,end));used.update(range(begin,end))
        code,refs=bind(phase)
        assert code==executable[ENTRY+0x25600+offset:ENTRY+0x25600+offset+len(code)]
        v.verify_leaf_relocations(code,refs,pointers,ENTRY+offset)
        le_count+=len(refs)
        call_count+=sum(begin<=int(k)<end and spec[1] for k,spec in context['fixups'].items())
        loaded,_=bind(phase,loaded=True);placed[offset:offset+len(code)]=loaded
    assert (len(used),le_count,call_count)==(745,52,8)
    # Original direct calls remain outside every selected C phase.
    for site,target in ((0x43d62,0x43a50),(0x43ea3,0x4380a),(0x43ee2,0x438f9)):
        assert not any(ENTRY+r[3]<=site<ENTRY+r[3]+r[2]-r[1] for r in PHASES)
        assert memory[site]==0xe8 and site+5+int.from_bytes(memory[site+1:site+5],'little',signed=True)==target
    alias='vesa_init_fixture_private_'
    assert alias not in v.LEAF_CODE_SLICES
    branch_guard=v.LEAF_SECTION_BRANCHES.pop(PUBLIC)
    v.LEAF_CODE_SLICES[alias]=(PUBLIC,0,CONTEXT_SIZE,CONTEXT_SIZE)
    try:
        private,_=v.bind_leaf_details(blob,alias,loaded_data,address=ENTRY,functions=v.FUNCTION_ADDRESSES,absolute_code=v.CODE_OFFSETS)
    finally:
        del v.LEAF_CODE_SLICES[alias];v.LEAF_SECTION_BRANCHES[PUBLIC]=branch_guard
    first=PHASES[0]
    def rejected(candidate,reason):
        try:bind(first,candidate)
        except ValueError as exc:assert reason in str(exc).lower(),(reason,str(exc))
        else:raise AssertionError('Mutation escaped '+reason)
    rejected(mutate_public_byte(blob,PUBLIC,CONTEXT_SIZE-1),'context')
    rejected(rename_external(blob,b'strncpy_',b'strncpz_'),'fixup')
    data_site=next(int(k) for k,spec in context['fixups'].items() if not spec[1])
    digest=v.LEAF_CONTEXT_SHA256.pop(PUBLIC)
    try:rejected(mutate_public_byte(blob,PUBLIC,data_site),'addend')
    finally:v.LEAF_CONTEXT_SHA256[PUBLIC]=digest
    n,m,branches=branch_guard;site=min(branches);op,old,new=branches[site]
    try:
        v.LEAF_SECTION_BRANCHES[PUBLIC]=(n,m,branches|{site:(op,old-1,new)})
        rejected(blob,'compiler target')
        v.LEAF_SECTION_BRANCHES[PUBLIC]=(n,m,branches|{site:(op,old,new-1)})
        bad,_=bind(first)
        assert bad!=executable[ENTRY+0x25600:ENTRY+0x25600+len(bad)]
    finally:v.LEAF_SECTION_BRANCHES[PUBLIC]=branch_guard
    return [('reference',None,False),('placed',bytes(placed),False),('private',private,True)]

def main():
    p=argparse.ArgumentParser();p.add_argument('--exe',type=Path,required=True);p.add_argument('--build',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
    executable=a.exe.read_bytes();memory=image(executable)
    modes=programs(executable,memory,a.build)
    results=[dict(mode=mode,**run(memory,c,code,private)) for mode,code,private in modes for c in all_cases()]
    report=dict(status='PASS',cases=len(results),cases_per_mode=len(all_cases()),full_data_checks=len(results),selected_native_bytes=745,selected_le_sites=52,retained_assembly_bytes=327,guarded_branches=44,guarded_raw_fixups=69,mutation_controls=5,native_callees=['strncpy','strncmp','signed_division'],reference_and_placed_shared_epilogue=True,primitive_stubs=list(TARGETS.values()),fixture_sha256=sha256(Path(__file__).read_bytes()).hexdigest(),results=results)
    a.output.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');print(json.dumps({k:v for k,v in report.items() if k!='results'}))
if __name__=='__main__':main()

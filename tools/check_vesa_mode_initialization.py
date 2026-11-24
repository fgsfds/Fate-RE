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
    reject_value:int=3
    pm_segment:int=0x6200
    pm_offset:int=0x20
    pm_entries:tuple=(-4,8)

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
    cpu.mem_write(0x60020,listbytes)
    table=(c.pm_segment<<4)+c.pm_offset
    table_bytes=pack('<hh',*c.pm_entries)
    assert table%2==0 and not (0x60020<=table<0x60020+len(listbytes))
    if DS<=table and table+4<=DS+SIZE:
        data[table-DS:table-DS+4]=table_bytes;expected[table-DS:table-DS+4]=table_bytes
    if c.attempted:data[0x1ec720:0x1ec720+len(listbytes)]=listbytes;expected[0x1ec720:0x1ec720+len(listbytes)]=listbytes
    controller=bytearray(pattern(512,0x73));controller[:4]=b'BAD!' if c.unsupported==2 else bytes(data[0x19e7:0x19eb])
    pack_into('<I',controller,14,0x60000020)
    cpu.mem_write(DS-16,b'\x5a'*16+data+b'\xa6'*16)
    cpu.mem_write(table,table_bytes)
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
        if c.pm:
            expect(0x13ff5,'I',(table+c.pm_entries[0])&0xffffffff)
            expect(0x13ff9,'I',(table+c.pm_entries[1])&0xffffffff)
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
            if reason in ('planes','bpp','model'):info[dict(planes=0x18,bpp=0x19,model=0x1b)[reason]]=c.reject_value
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
                    assert words[4:6]==(0x4444,c.pm_offset)
            emu.mem_write(F+0x100,pack('<7H',0x4f if name=='interrupt' or c.pm else 0,0x1111,0x2222,0x3333,0x4444,c.pm_offset,0))
            if name=='far':emu.mem_write(F+0x110,pack('<4H',c.pm_segment,0x7777,0x8888,0x9999));emu.reg_write(CX,0xcafeab12)
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
    for reason in ('model','bpp','planes'):
        for value in (0,0x7f,0x80,0xff):
            cases.extend([Case(name=f'reject-{reason}-{value}',rejects=(reason,),accepted=False,reject_value=value),Case(name=f'skip-{reason}-{value}',rejects=(reason,),reject_value=value)])
    cases.extend([Case(name='pm-zero-segment',pm_segment=0,pm_offset=0x7000,pm_entries=(-4096,32767)),Case(name='pm-high-segment',pm_segment=0xfabc,pm_offset=0x122,pm_entries=(-32768,32767)),Case(name='pm-cross-64k',pm_segment=0x6000,pm_offset=0xfffe,pm_entries=(-128,255))])
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

SECONDARY_PHASES=(('vesa_init_secondary_at_03d_', 118, 123, 61), ('vesa_init_secondary_at_042_', 61, 68, 66), ('vesa_init_secondary_at_049_', 70, 78, 73), ('vesa_init_secondary_at_051_', 123, 128, 81), ('vesa_init_secondary_at_05b_', 133, 146, 91), ('vesa_init_secondary_at_0f2_', 279, 318, 242), ('vesa_init_secondary_at_159_', 382, 408, 345), ('vesa_init_secondary_at_173_', 410, 417, 371), ('vesa_init_secondary_at_17a_', 408, 410, 378), ('vesa_init_secondary_at_17c_', 466, 471, 380), ('vesa_init_secondary_at_181_', 417, 425, 385), ('vesa_init_secondary_at_189_', 427, 434, 393), ('vesa_init_secondary_at_190_', 471, 478, 400), ('vesa_init_secondary_at_19c_', 483, 505, 412), ('vesa_init_secondary_at_1b2_', 521, 529, 434), ('vesa_init_secondary_at_1ba_', 513, 521, 442), ('vesa_init_secondary_at_1c2_', 505, 513, 450), ('vesa_init_secondary_at_1ca_', 545, 557, 458), ('vesa_init_secondary_at_1db_', 562, 579, 475), ('vesa_init_secondary_at_1ec_', 587, 589, 492), ('vesa_init_secondary_at_1ee_', 579, 587, 494), ('vesa_init_secondary_at_1f6_', 589, 623, 502), ('vesa_init_secondary_at_38c_', 989, 999, 908))

def programs(executable,memory,build):
    specs=[(PUBLIC,OBJECT,CONTEXT_SIZE,'85ceaf5218b0e913fa06077c69c347cfcf6e75227f48d25771ef3d6fdbb8a54a',44,PHASES),('vesa_init_predicate_context_','vbeprdc',1154,'45c1a3471decfdf2aacded073df706841341eb0432a04b83507083e6b3b7693b',3,SECONDARY_PHASES)]
    layout=v.CONTROLLER_PREFIX_LAYOUT
    metadata={r['phase']:r for r in layout['phases'] if r['routine']=='initialize_vesa_mode'}
    assert set(metadata)=={r[0] for spec in specs for r in spec[5]}
    pointers=read_le_fixups(executable)['pointers']
    assert len(pointers.between(ENTRY,ENTRY+1072))==59
    loaded_data={k:DS+val for k,val in v.DATA_OFFSETS.items()}
    placed=bytearray(memory[ENTRY:ENTRY+1072]);destinations=set();le_count=0;call_count=0;private_modes=[]
    for public,objname,size,digest,branch_count,phases in specs:
        blob=(build/(objname+'.obj')).read_bytes()
        [obj]=[r for r in layout['objects'] if r['object']==objname]
        [context]=obj['contexts']
        assert (context['public'],context['size'],context['start'],context['sha256'])==(public,size,0,digest)
        assert len(context['fixups'])==69 and len(context['branches']['sites'])==branch_count
        if objname=='vbeprdc':assert v.LEAF_SECTION_BRANCHES[public][2]=={0x120:(b'\x0f\x85',0x451,0x400),0x12f:(b'\x0f\x85',0x451,0x400),0x23f:(b'\x75',0x26f,0x218)}
        used=set()
        def bind(phase,candidate=blob,loaded=False):
            code_refs={}
            code,refs=v.bind_leaf_details(candidate,phase[0],loaded_data if loaded else v.DATA_OFFSETS,address=ENTRY+phase[3],functions=v.FUNCTION_ADDRESSES,absolute_code=v.CODE_OFFSETS,code_bindings=code_refs)
            assert not code_refs
            return code,refs
        for phase in phases:
            name,begin,end,offset=phase;r=metadata[name]
            assert (r['begin'],r['end'],r['address'],r['object'],r['public'])==(begin,end,ENTRY+offset,objname,public)
            assert not used.intersection(range(begin,end));used.update(range(begin,end))
            assert not destinations.intersection(range(offset,offset+end-begin));destinations.update(range(offset,offset+end-begin))
            code,refs=bind(phase)
            assert code==executable[ENTRY+0x25600+offset:ENTRY+0x25600+offset+len(code)]
            v.verify_leaf_relocations(code,refs,pointers,ENTRY+offset)
            le_count+=len(refs);call_count+=sum(begin<=int(k)<end and spec[1] for k,spec in context['fixups'].items())
            loaded,_=bind(phase,loaded=True);placed[offset:offset+len(code)]=loaded
        assert len(used)==(745 if objname==OBJECT else 268)
        alias=public+'fixture_private_'
        assert alias not in v.LEAF_CODE_SLICES
        branch_guard=v.LEAF_SECTION_BRANCHES.pop(public)
        v.LEAF_CODE_SLICES[alias]=(public,0,size,size)
        try:
            private,_=v.bind_leaf_details(blob,alias,loaded_data,address=ENTRY,functions=v.FUNCTION_ADDRESSES,absolute_code=v.CODE_OFFSETS)
        finally:
            del v.LEAF_CODE_SLICES[alias];v.LEAF_SECTION_BRANCHES[public]=branch_guard
        private_modes.append(('private-'+objname,private,True))
        first=phases[0]
        def rejected(candidate,reason,phase=first):
            try:bind(phase,candidate)
            except ValueError as exc:assert reason in str(exc).lower(),(reason,str(exc))
            else:raise AssertionError('Mutation escaped '+reason)
        rejected(mutate_public_byte(blob,public,size-1),'context')
        rejected(rename_external(blob,b'strncpy_',b'strncpz_'),'fixup')
        data_site=next(int(k) for k,spec in context['fixups'].items() if not spec[1])
        context_digest=v.LEAF_CONTEXT_SHA256.pop(public)
        try:rejected(mutate_public_byte(blob,public,data_site),'addend')
        finally:v.LEAF_CONTEXT_SHA256[public]=context_digest
        n,m,branches=branch_guard;site=min(branches);op,old,new=branches[site]
        branch_phase=next(phase for phase in phases if phase[1]<=site<phase[2])
        try:
            v.LEAF_SECTION_BRANCHES[public]=(n,m,branches|{site:(op,old-1,new)})
            rejected(blob,'compiler target',branch_phase)
            v.LEAF_SECTION_BRANCHES[public]=(n,m,branches|{site:(op,old,new-1)})
            bad,_=bind(branch_phase)
            raw=ENTRY+0x25600+branch_phase[3]
            assert bad!=executable[raw:raw+len(bad)]
        finally:v.LEAF_SECTION_BRANCHES[public]=branch_guard
    assert (len(destinations),le_count,call_count)==(1013,57,8)
    # All direct calls with unproven BIOS inputs stay original assembly.
    for site,target in ((0x43d62,0x43a50),(0x43ea3,0x4380a),(0x43ee2,0x438f9)):
        assert not destinations.intersection(range(site-ENTRY,site-ENTRY+5))
        assert memory[site]==0xe8 and site+5+int.from_bytes(memory[site+1:site+5],'little',signed=True)==target
    return [('reference',None,False),('placed',bytes(placed),False)]+private_modes

def main():
    p=argparse.ArgumentParser();p.add_argument('--exe',type=Path,required=True);p.add_argument('--build',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
    executable=a.exe.read_bytes();memory=image(executable)
    modes=programs(executable,memory,a.build)
    results=[dict(mode=mode,**run(memory,c,code,private)) for mode,code,private in modes for c in all_cases()]
    report=dict(status='PASS',cases=len(results),cases_per_mode=len(all_cases()),full_data_checks=len(results),selected_native_bytes=1013,selected_le_sites=57,retained_assembly_bytes=59,guarded_branches=47,guarded_raw_fixups=138,mutation_controls=10,native_callees=['strncpy','strncmp','signed_division'],reference_and_placed_shared_epilogue=True,primitive_stubs=list(TARGETS.values()),fixture_sha256=sha256(Path(__file__).read_bytes()).hexdigest(),results=results)
    a.output.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');print(json.dumps({k:v for k,v in report.items() if k!='results'}))
if __name__=='__main__':main()

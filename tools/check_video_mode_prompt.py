"""Check the reference, placed suppliers and private video-mode prompt context."""
import argparse,json
from hashlib import sha256
from unittest.mock import patch
from pathlib import Path
from dataclasses import dataclass,replace
from struct import pack,pack_into,unpack
from unicorn import Uc,UC_ARCH_X86,UC_MODE_32,UC_HOOK_CODE
from unicorn import x86_const as x
from check_start_hook import image
from check_video_memory_mapping import pattern
from capstone import Cs,CS_ARCH_X86,CS_MODE_32
from le_fixups import read_le_fixups
from verify_c_leaf import verify_leaf_relocations
from check_ripple_stack import mutate_public_byte
from check_ripple_control import rename_external
import bind_video_prompt_sections as binder

D,DATA_SIZE,S,STOP,ENTRY=0x80000,0x28a300,0x4ff000,0x4fff00,0x36d0a
REGS=[x.UC_X86_REG_EAX,x.UC_X86_REG_EBX,x.UC_X86_REG_ECX,x.UC_X86_REG_EDX,x.UC_X86_REG_ESI,x.UC_X86_REG_EDI,x.UC_X86_REG_EBP]
AX,BX,CX,DX,SI,DI,BP=REGS
BG,GET,FG,PRINT=0x6f1bf,0x6f22c,0x6f25d,0x36b0e
TARGETS={BG:'bg',GET:'get',FG:'fg',PRINT:'print'}
FORMATS={0x9e3:4,0x9eb:3,0x9fd:5,0xa0d:3}
SELECTED,COUNT,MODE,WANTED_W,WANTED_H=0x173d54,0x173d56,0x12d70,0x12d74,0x12d78
CALL_STAGES={
 'heading-bg':(0x36e3c,'bg'),'heading-fg':(0x36e43,'fg'),'heading':(0x36e5e,'print'),
 'normal-bg':(0x36e6b,'bg'),'normal-fg':(0x36e82,'fg'),'placeholder':(0x36ea0,'print'),
 'selected-bg':(0x36ec7,'bg'),'selected-fg':(0x36ed1,'fg'),'dimensions':(0x36f0e,'print'),
 'get':(0x36f16,'get'),'restore-bg':(0x36f26,'bg'),'restore-fg':(0x36f3d,'fg'),'footer':(0x36f62,'print'),
}
@dataclass(frozen=True)
class Case:
    mode:int
    bright:int
    selected:int
    wanted:tuple
    variant:int=0
    seed:int=0

def tables(mode,variant=0):
    if mode==0:w,h=(320,360,400),(200,360,400)
    elif mode==1:w,h=(320,640),(200,480)
    else:return (320,),(200,),((0,0),)
    n=len(w);pairs=tuple((i,i) for i in range(n))
    if variant==1:
        w=tuple((-32768,1,32767)[:n]);h=tuple((32767,-1,0)[:n]);pairs=tuple((n-i-1,i) for i in range(n))
    elif variant==2:pairs=((0,0),)*n
    return w,h,pairs

def cases():
    result=[]
    for mode in range(6):
        for variant in (range(3) if mode<2 else range(1)):
            w,h,pairs=tables(mode,variant)
            wanted=sorted({(w[a],h[b]) for a,b in pairs}|{(-123,456)})
            for bright in (0,1):
                for selected in sorted({-1,0,len(pairs)-1,len(pairs)+4,32767}):
                    for wh in wanted:result.append(Case(mode,bright,selected,wh,variant,len(result)))
    return result

def run(memory,c,code=None,entry=ENTRY,prefix_size=0,private=False):
    cpu=Uc(UC_ARCH_X86,UC_MODE_32);cpu.mem_map(0,0x500000);cpu.mem_write(0,memory)
    if code is not None:cpu.mem_write(entry-prefix_size,code)
    cpu.mem_write(0x1000,pack('<4Q',0,0x00cf9b000000ffff,0x00cf93000000ffff,0x00cf93000000ffff))
    cpu.reg_write(x.UC_X86_REG_GDTR,(0,0x1000,31,0));cpu.reg_write(x.UC_X86_REG_CS,8)
    for r in (x.UC_X86_REG_DS,x.UC_X86_REG_ES,x.UC_X86_REG_SS):cpu.reg_write(r,0x10)
    for r in (x.UC_X86_REG_FS,x.UC_X86_REG_GS):cpu.reg_write(r,0x18)
    cpu.reg_write(x.UC_X86_REG_EFLAGS,2)
    data=bytearray(pattern(DATA_SIZE,0x31+c.seed))
    names=unpack('<6I',memory[D+0x12d30:D+0x12d48])
    data[0x12d30:0x12d48]=memory[D+0x12d30:D+0x12d48]
    for start in [D+off for off in FORMATS]+list(names):
        end=memory.index(b'\0',start)+1;data[start-D:end-D]=memory[start:end]
    for mode,base in ((0,0x12d48),(1,0x12d60)):
        w,h,pairs=tables(mode,c.variant if c.mode==mode else 0)
        flat=tuple(w)+tuple(h)+tuple(v for pair in pairs for v in pair)
        data[base:base+2*len(flat)]=pack('<'+'h'*len(flat),*flat)
    text_mode=c.seed%6
    for off,val in ((MODE,text_mode),(WANTED_W,c.wanted[0]),(WANTED_H,c.wanted[1])):pack_into('<i',data,off,val)
    pack_into('<h',data,SELECTED,c.selected);pack_into('<h',data,COUNT,-222)
    expected=bytearray(data);w,h,pairs=tables(c.mode,c.variant);n=len(pairs)
    selected=n-1 if c.selected>=n else c.selected
    for i,(wi,hi) in enumerate(pairs):
        if (w[wi],h[hi])==c.wanted:selected=i
    pack_into('<h',expected,COUNT,n);pack_into('<h',expected,SELECTED,selected)
    normal=11 if c.bright else 3
    want=[];return_addresses=[]
    def add(stage,value):
        pc,kind=CALL_STAGES[stage];want.append((kind,value));return_addresses.append(pc+5)
    add('heading-bg',normal);add('heading-fg',0);add('heading',(47,5,D+0x9e3,names[text_mode]));add('normal-bg',1);add('normal-fg',normal)
    foreground=normal
    for i in range(11):
        if i>=n:add('placeholder',(47,6+i,D+0x9eb));continue
        if i==selected:add('selected-bg',7 if c.bright else 1);add('selected-fg',15);foreground=15
        wi,hi=pairs[i];add('dimensions',(47,6+i,D+0x9fd,w[wi],h[hi]));add('get',foreground)
        if foreground==15:add('restore-bg',1);add('restore-fg',normal);foreground=normal
    add('footer',(47,17,D+0xa0d))
    cpu.mem_write(D-16,b'\x5a'*16+bytes(data)+b'\xa6'*16)
    cpu.mem_write(S-160,b'\xa5'*224);caller=pack('<I',STOP)+pattern(60,0x91+c.seed);cpu.mem_write(S,caller)
    incoming=dict(zip(REGS,(0xa5010000|c.mode,0xb2021234,0xc3032345,0xd4040000|c.bright,0x55003456,0x66004567,0x77005678)))
    for r,val in incoming.items():cpu.reg_write(r,val)
    cpu.reg_write(x.UC_X86_REG_ESP,S)
    trace=[];colors=dict(bg=-1,fg=-1)
    def reg(r):return cpu.reg_read(r)
    def hook(emu,pc,size,_):
        name=TARGETS.get(pc)
        if name is None:return
        sp=reg(x.UC_X86_REG_ESP)
        frame=S-44
        assert len(trace)<len(return_addresses)
        actual_return=unpack('<I',emu.mem_read(sp,4))[0]
        assert actual_return==return_addresses[len(trace)]+entry-ENTRY+(6 if private else 0),(c,'CALL return',hex(actual_return),hex(return_addresses[len(trace)]))
        saved=pack('<5I',*(incoming[r] for r in (BP,DI,SI,CX,BX)))
        assert emu.mem_read(S-20,20)==saved
        if not private:
            assert reg(CX)==incoming[DX]
            assert reg(BP)==(D+0x12d54 if c.mode==0 else D+0x12d68 if c.mode==1 else frame)
            assert reg(SI)==(D+0x12d4e if c.mode==0 else D+0x12d64 if c.mode==1 else frame+0x0c)
            expected_width=D+0x12d48 if c.mode==0 else D+0x12d60 if c.mode==1 else frame+0x10
            assert unpack('<I',emu.mem_read(frame+4,4))[0]==expected_width
            assert unpack('<I',emu.mem_read(frame,4))[0]==0
            assert unpack('<I',emu.mem_read(frame+0x10,4))[0]==320
            assert unpack('<I',emu.mem_read(frame+0x0c,4))[0]==200
            assert unpack('<I',emu.mem_read(frame+0x14,4))[0]==11
            assert reg(BX)==0
        assert reg(x.UC_X86_REG_ES)==0x10 and not reg(x.UC_X86_REG_EFLAGS)&0x400
        if name in ('bg','fg'):
            value=reg(AX)&(0xffff if name=='fg' else 0xffffffff);assert value<16,(c,name,hex(value));colors[name]=value;event=(name,value)
            emu.reg_write(AX,0xa1234000+c.seed)
        elif name=='get':
            event=('get',colors['fg']);emu.reg_write(AX,0xeaff0000|colors['fg'])
        else:
            head=unpack('<3I',emu.mem_read(sp+4,12));fmt=head[2]-D;assert fmt in FORMATS,(c,head)
            values=list(unpack('<'+'I'*FORMATS[fmt],emu.mem_read(sp+4,4*FORMATS[fmt])))
            for i in (0,1):
                values[i]&=0xffff
                if values[i]&0x8000:values[i]-=0x10000
            if fmt==0x9fd:
                for i in (3,4):values[i]=values[i]-(1<<32) if values[i]>>31 else values[i]
            event=('print',tuple(values));emu.reg_write(AX,0xa1234000+c.seed)
        arguments=FORMATS[event[1][2]-D] if name=='print' else 0
        assert sp==frame-4-4*arguments,(c,'stack at CALL',hex(sp),arguments)
        assert len(trace)<len(want) and event==want[len(trace)],(c,len(trace),event,want[len(trace):len(trace)+1])
        trace.append(event)
        ret=unpack('<I',emu.mem_read(sp,4))[0];emu.reg_write(x.UC_X86_REG_EIP,ret);emu.reg_write(x.UC_X86_REG_ESP,sp+4)
    cpu.hook_add(UC_HOOK_CODE,hook);cpu.emu_start(entry,STOP,timeout=2_000_000,count=20000)
    assert trace==want
    assert reg(x.UC_X86_REG_EIP)==STOP and reg(x.UC_X86_REG_ESP)==S+4
    for r in (BX,CX,SI,DI,BP):assert reg(r)==incoming[r],(c,'preserved',r)
    assert cpu.mem_read(S,64)==caller and cpu.mem_read(S-160,64)==b'\xa5'*64
    assert cpu.mem_read(D-16,16)==b'\x5a'*16 and cpu.mem_read(D+DATA_SIZE,16)==b'\xa6'*16
    actual=bytes(cpu.mem_read(D,DATA_SIZE))
    if actual!=expected:
        off=next(i for i,(a,b) in enumerate(zip(actual,expected)) if a!=b);raise AssertionError((c,'DATA',hex(off),actual[off:off+4].hex(),expected[off:off+4].hex()))
    return dict(calls=len(trace),selected=selected,count=n,prints=13)

def reject(blob, expectation, records=None, **kwargs):
    def invoke():
        symbol, _, _, address = binder.SECTIONS[0]
        options = {'address': address, 'code_bindings': {}} | kwargs
        return binder.bind_section(blob, symbol, **options)

    try:
        if records is None:
            invoke()
        else:
            with patch.object(binder, 'parsed_leaf_object', return_value=records):
                invoke()
    except ValueError as error:
        assert expectation in str(error), str(error)
    else:
        raise AssertionError(f'Guard accepted {expectation}')


def guard_checks(blob):
    segments, publics, externals, flat, fixups = binder.parsed_leaf_object(blob)
    segment = segments[1]
    raw = segment['data']
    guards = []
    for position, label in ((0, 'table-slot addend'), (0x054, 'omitted dispatch'),
                            (0x275, 'selected footer')):
        changed = raw[:position]+bytes((raw[position]^1,))+raw[position+1:]
        altered = (segments[0], dict(segment, data=changed), *segments[2:])
        reject(blob, 'CODE digest', (altered, publics, externals, flat, fixups))
        guards.append(label)

    target_index = next(i for i, f in enumerate(fixups) if f.offset == 0x025)
    for mutation, label in (({'target': (2, externals.index('_video_default_width'))}, 'CODE external identity'),
                            ({'frame': (1, 0)}, 'FLAT frame'),
                            ({'width': 2}, 'operand width')):
        modified = replace(fixups[target_index], **mutation)
        altered = (*fixups[:target_index], modified, *fixups[target_index+1:])
        reject(blob, 'fixup form/target/addend', (segments, publics, externals, flat, altered))
        guards.append(label)
    target_index = next(i for i, f in enumerate(fixups) if f.offset == 0x055)
    modified = replace(fixups[target_index], displacement=1)
    altered = (*fixups[:target_index], modified, *fixups[target_index+1:])
    reject(blob, 'fixup form/target/addend', (segments, publics, externals, flat, altered))
    guards.append('compiler dispatch displacement')
    reject(blob, 'fixup inventory', (segments, publics, externals, flat, fixups[:-1]))
    guards.append('missing fixup')
    reject(blob, 'placement differs', address=binder.ENTRY+1)
    guards.append('wrong slice placement')
    reject(blob, 'empty output metadata', code_bindings={0: 1})
    guards.append('stale offset metadata')
    return guards


def programs(executable,memory,build):
    blob=(build/'vprompt.obj').read_bytes();pointers=read_le_fixups(executable)['pointers']
    assert len(pointers.between(ENTRY,ENTRY+617))==29
    assert len(binder.SECTIONS)==7 and binder.PUBLIC=='prompt_video_mode_context_'
    assert binder.GROUP_SHA256=='4a90693dbb0828c518541509f16ee57b0259d5ca65bd0561efa8c998d565c3e2'
    original_calls={i.address:TARGETS[int(i.op_str,16)] for i in Cs(CS_ARCH_X86,CS_MODE_32).disasm(memory[ENTRY:ENTRY+617],ENTRY) if i.mnemonic=='call'}
    assert original_calls=={pc:kind for pc,kind in CALL_STAGES.values()}
    overlay=bytearray(memory[ENTRY:ENTRY+617]);destinations=set();sources=set();le_count=0;code_count=0;selected_calls={}
    for name,start,end,address in binder.SECTIONS:
        code_refs={};code,refs=binder.bind_section(blob,name,address,code_refs)
        raw=address+0x25600;assert code==executable[raw:raw+len(code)]
        verify_leaf_relocations(code,refs,pointers,address,code_bindings=code_refs)
        assert not destinations.intersection(range(address,address+len(code)));destinations.update(range(address,address+len(code)))
        assert not sources.intersection(range(start,end));sources.update(range(start,end))
        loaded_refs={};loaded,refs_loaded=binder.bind_section(blob,name,address,loaded_refs,loaded=True)
        assert loaded==memory[address:address+len(loaded)]
        assert refs_loaded=={site-address:target for site,target in pointers.between(address,address+len(loaded))}
        overlay[address-ENTRY:address-ENTRY+len(loaded)]=loaded
        le_count+=len(refs);code_count+=len(code_refs)
        for i in Cs(CS_ARCH_X86,CS_MODE_32).disasm(loaded,address):
            if i.mnemonic=='call':selected_calls[binder.PREFIX+start+i.address-address+1]=(i.address,int(i.op_str,16))
    assert bytes(overlay)==memory[ENTRY:ENTRY+617]
    assert (len(destinations),len(sources),le_count,code_count)==(353,353,18,2)
    assert selected_calls==binder.SELECTED_CALLS
    for source,(encoding,old,new) in binder.BRANCHES.items():
        if new is None:continue
        [phase]=[p for p in binder.SECTIONS if p[1]<=source<p[2]]
        pc=phase[3]+source-phase[1]
        [ins]=list(Cs(CS_ARCH_X86,CS_MODE_32).disasm(memory[pc:pc+len(bytes.fromhex(encoding))],pc))
        assert ins.bytes.hex()==encoding and int(ins.op_str,16)==new
    assert tuple(target for _,target in pointers.between(0x36cf2,0x36d0a))==(0x36d45,0x36d66,0x36d87,0x36d87,0x36d87,0x36d87)
    assert pointers[0x36d41]==0x36cf2
    private,*_=binder.bind_context(blob,loaded=True,base=0x400000-24)
    private_calls={i.address:TARGETS[int(i.op_str,16)] for i in Cs(CS_ARCH_X86,CS_MODE_32).disasm(private[24:],0x400000) if i.mnemonic=='call'}
    assert private_calls=={pc-ENTRY+6+0x400000:kind for pc,kind in CALL_STAGES.values()}
    controls=guard_checks(blob)
    reject(mutate_public_byte(blob,binder.PUBLIC,622),'CODE digest');controls.append('valid-checksum private RET')
    reject(mutate_public_byte(blob,binder.PUBLIC,-24),'CODE digest');controls.append('valid-checksum private table')
    reject(rename_external(blob,b'_requested_video_width',b'_requested_video_widtx'),'fixup form/target/addend');controls.append('valid-checksum external target')
    assert len(controls)==13
    return [('reference',None,ENTRY,0,False),('placed',bytes(overlay),ENTRY,0,False),('private',private,0x400000,24,True)],controls

def main():
    p=argparse.ArgumentParser();p.add_argument('--exe',type=Path,required=True);p.add_argument('--build',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args();executable=a.exe.read_bytes();memory=image(executable)
    assert memory[0x3694a:0x36952]==pack('<Ihh',0,320,200)
    modes,controls=programs(executable,memory,a.build)
    results=[run(memory,c,code=code,entry=entry,prefix_size=prefix,private=private) for _,code,entry,prefix,private in modes for c in cases()]
    report=dict(status='PASS',cases=len(results),cases_per_mode=len(cases()),full_data_checks=len(results),calls=sum(r['calls'] for r in results),prints=sum(r['prints'] for r in results),selected_native_bytes=353,selected_le_sites=18,selected_code_le_sites=2,selected_data_le_sites=16,retained_body_assembly_bytes=264,retained_dispatch_and_alignment_bytes=25,guarded_code_group_bytes=647,guarded_fixups=48,guarded_direct_branches=23,selected_direct_branches=16,selected_calls=10,mutation_controls=controls,primitive_stubs=list(TARGETS.values()),fixture_sha256=sha256(Path(__file__).read_bytes()).hexdigest())
    a.output.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');print(json.dumps({k:v for k,v in report.items() if k!='mutation_controls'}))
if __name__=='__main__':main()

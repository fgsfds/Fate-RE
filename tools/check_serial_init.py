"""Independent bounded UART initializer state and I/O oracle."""
import argparse
import hashlib
import json
from pathlib import Path
from struct import pack
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(ROOT/'tools'), str(ROOT/'work/cache/python/095240b6cf469e2f88b1')]
from differential import Machine, Contract, Region, Observation, first_difference, require_mutations_detected
from compare_exe import TARGET_SHA256
from le_fixups import read_le_fixups, pointer_range
from verify_c_leaf import verify_leaf_relocations

BASE, ENTRY, RAW, SIZE = 0x41a46, 0x41a56, 0x67046, 664
EPILOGUE = 0x41a3f
DS, DATA_SIZE, STACK, STOP = 0x80000, 0x360000, 0x3f0000, 0x3fff00
A = dict(option=0x13cdf, comnum=0x18fe10, vector=0x18fe04,
    count=0x18fe14, port=0x18fde8, baud=0x18fe28, fifo=0x18fdf8,
    volatile=0x18fdfc, state_18fe2c=0x18fe2c, state_18fe38=0x18fe38,
    ptr_rx=0x18fdbc, ptr_write=0x18fdd0, ptr_read=0x18fdd8,
    ptr_fdf0=0x18fdf0, ptr_fe00=0x18fe00, ptr_fe1c=0x18fe1c,
    ptr_fdf4=0x18fdf4)
P = dict(ptr_rx=0x220000, ptr_write=0x220002, ptr_read=0x220004,
         ptr_fdf0=0x220006, ptr_fe00=0x220008, ptr_fe1c=0x220009,
         ptr_fdf4=0x22000a, port=0x22000c, fifo=0x22000e)
FUNCTIONS = dict(install_serial_interrupts_=0x430cc,
    disable_interrupts_=0x603dc, enable_interrupts_=0x60409, inp_=0x6326a)
CONTRACT = Contract(ENTRY, STOP, STACK, 4, preserved=('ebx','ecx','edx','esi','edi','ebp'), results=('eax',), flags_mask=0x200,
                    instruction_limit=500000, wall_timeout_us=5000000)
INITIAL = bytes(range(256)) * (DATA_SIZE // 256)
sha = lambda b: hashlib.sha256(b).hexdigest()

def put(m, off, value, width=4):
    m[off:off+width] = (value & ((1 << (width*8))-1)).to_bytes(width,'little')
def get(m, off, width=4, signed=False):
    return int.from_bytes(m[off:off+width], 'little', signed=signed)

def cases():
    out=[]
    def add(name, **updates):
        c=dict(name=name,comnum=1,speed=9600,option=0,bda={1:0x3f8,2:0x2f8,3:0x3e8,4:0x2e8},
            probe=0x60,fifo_status=0xc0,drain=0,lsr_ready=True,pic=0xa5,
            reset=0x11223344,state2c=0x55667788,state38=0x99aabbcc)
        c.update(updates); out.append(c)
    for n in (0,5,0xffffffff): add('invalid_comnum_'+str(n),comnum=n)
    for speed in (0,-1,1,110,300,9600,38400,57600,115200,114688,114689,0x7fffffff):
        add('speed_'+str(speed),speed=speed)
    add('bda_zero_fallback_com1',bda={1:0,2:0,3:0,4:0})
    for n in (1,2,3,4): add('bda_zero_fallback_'+str(n),comnum=n,bda={1:0,2:0,3:0,4:0})
    add('probe_absent',probe=0,bda={1:0,2:0,3:0,4:0})
    add('fifo_present',fifo_status=0xc0)
    add('fifo_absent',fifo_status=0x00)
    for drain in (0,1,16): add('drain_'+str(drain),drain=drain)
    add('lsr_not_ready',lsr_ready=False,drain=16)
    add('pic_mask_vectors',pic=0xff,comnum=1)
    add('pic_mask_com2',pic=0x5a,comnum=2)
    add('volatile_reset',reset=0xffffffff,state2c=0xdeadbeef,state38=0xabcdef01)
    for option in (0,16,127,128,255): add('option_'+str(option),option=option)
    add('fifo_ready_beyond_budget',drain=20)
    add('nonfifo_ready_beyond_budget',drain=20,fifo_status=0)
    add('probe_not_used_with_bda',probe=0)
    assert len(out)>=30
    return out

def initial_memory(c):
    m=bytearray(INITIAL)
    put(m,A['option'],c['option'],1); put(m,A['comnum'],c['comnum'])
    for key,value in dict(vector=0xfeedface,count=0x12345678,baud=c['speed'],
            volatile=c['reset'],state_18fe2c=c['state2c'],state_18fe38=c['state38']).items():
        put(m,A[key],value)
    for key,off in P.items(): put(m,A[key],DS+off)
    return m


def expected_behavior(c):
    m=initial_memory(c); calls=[]
    def result(value):
        return Observation({'eax':value,'eflags':0x200},{'DS':bytes(m)},tuple(calls))
    com=c['comnum']
    if not 1<=com<=4: return result(0xffffffff)
    vector=((c['option']&255)>>4)+10
    put(m,A['vector'],vector)
    calls.append(('install_serial_interrupts',))
    put(m,P['ptr_fe00'],0,1); put(m,A['count'],0)
    for key in ('ptr_rx','ptr_fdf0','ptr_read','ptr_write'): put(m,P[key],0,2)
    port=c['bda'][com]
    if not port:
        port=(0x3f8,0x2f8,0x3e8,0x2e8)[com-1]
        calls.append(('inp',port+5))
        if c['probe']&0x60 != 0x60:
            put(m,P['port'],0,2)
            return result(0xffffffff)
    put(m,P['port'],port,2)
    baud=c['speed']
    if not 1<=baud<=115200: return result(0xffffffff)
    calls.append(('disable_interrupts',))
    divisor=115200//baud
    calls.extend([('out',port+3,1,128),('out',port,1,divisor&255),
                  ('out',port+1,1,(divisor>>8)&255),('out',port+3,1,3),
                  ('out',port+2,1,135),('in',port+2,1,c['fifo_status'])])
    fifo=16 if c['fifo_status']&248==192 else 1
    put(m,P['fifo'],fifo,1)
    if fifo==1: calls.append(('out',port+2,1,0))
    available=c['drain'] if c['lsr_ready'] else 0
    drained=min(available,fifo)
    for _ in range(drained): calls.extend([('in',port+5,1,1),('in',port,1,90)])
    # The status read precedes the remaining-budget test, even at zero budget.
    calls.append(('in',port+5,1,int(available>drained)))
    calls.extend([('out',port+4,1,11),('out',port+1,1,0),
        ('in',33,1,c['pic']),('out',33,1,c['pic']&(255^(1<<(vector&7)))),
        ('in',port+6,1,0),('in',port+5,1,0),('in',port,1,0),
        ('in',port+2,1,c['fifo_status']),('out',port+1,1,3),('out',32,1,32)])
    put(m,A['volatile'],0); put(m,A['state_18fe2c'],0)
    put(m,P['ptr_fe1c'],0,1); put(m,P['ptr_fdf4'],0,1)
    calls.append(('enable_interrupts',))
    put(m,A['state_18fe38'],0)
    return result(0)


def reference_body(exe):
    assert sha(exe)==TARGET_SHA256, 'pinned executable hash mismatch'
    body=bytearray(exe[RAW:RAW+SIZE]); assert len(body)==SIZE
    for off,target in pointer_range(read_le_fixups(exe)['pointers'],BASE,SIZE).items():
        assert off+4<=SIZE
        if target>=0x80000: target=DS+target-0x80000
        body[off:off+4]=pack('<I',target)
    return bytes(body)

def exercise(body,c):
    machine=Machine(CONTRACT,body,[Region('DS',DS,DATA_SIZE)],code_address=BASE)
    machine.add_code(EPILOGUE,bytes.fromhex('5d5e5a595bc3'))
    machine.write(DS,initial_memory(c))
    for i in range(4): machine.write(0x400+2*i,pack('<H',c['bda'][i+1]))
    com=c['comnum']
    port=c['bda'][com] or (0x3f8,0x2f8,0x3e8,0x2e8)[com-1] if 1<=com<=4 else 0
    uart=dict(reads=0,draining=True)
    def input_port(_cpu,p,size,_user):
        assert size==1
        if p==33: value=c['pic']
        elif p==port+2: value=c['fifo_status']
        elif p==port+5:
            value=int(uart['draining'] and c['lsr_ready'] and uart['reads']<c['drain'])
        elif p==port:
            value=90 if uart['draining'] else 0
            if uart['draining']: uart['reads']+=1
        elif p==port+6: value=0
        else: raise AssertionError('unexpected input port '+hex(p))
        machine.record('in',p,size,value)
        return value
    def output_port(_cpu,p,size,value,_user):
        assert size==1
        machine.record('out',p,size,value&255)
        if p==port+4: uart['draining']=False
    def stub(name):
        def f(m):
            m.record(name)
            return {'eax':0xfeedbeef}
        return f
    def inp(m):
        m.record('inp',m.register('eax'))
        return {'eax':0xaabbcc00 | c['probe']}
    for name in ('install_serial_interrupts','disable_interrupts','enable_interrupts'):
        machine.stub(FUNCTIONS[name+'_'],stub(name))
    machine.stub(FUNCTIONS['inp_'],inp)
    from unicorn import UC_HOOK_INSN
    from unicorn.x86_const import UC_X86_INS_IN, UC_X86_INS_OUT
    hooks=[machine.cpu.hook_add(UC_HOOK_INSN,input_port,None,1,0,UC_X86_INS_IN),
           machine.cpu.hook_add(UC_HOOK_INSN,output_port,None,1,0,UC_X86_INS_OUT)]
    try:
        return machine.run(dict(eax=0x11112222,ebx=0x89abcdef,ecx=0x87654321,
            edx=0x76543210,esi=0x23456789,edi=0x3456789a,ebp=0x456789ab,eflags=0x202))
    finally:
        for h in hooks: machine.cpu.hook_del(h)


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--build',type=Path,required=True); p.add_argument('--exe',type=Path,required=True)
    p.add_argument('--output',type=Path); a=p.parse_args()
    exe=a.exe.read_bytes(); obj=(a.build/'serialin.obj').read_bytes()
    assert sha(exe)==TARGET_SHA256,'pinned executable hash mismatch'
    from bind_serial_init import bind
    raw,data,code,calls=bind(obj)
    assert raw==exe[RAW:RAW+SIZE], 'candidate machine code differs'
    refs=dict(data); refs.update(code)
    verify_leaf_relocations(raw,refs,read_le_fixups(exe)['pointers'],BASE,code_bindings=code)
    candidate,data_refs,code_refs,reloc_calls=bind(obj,loaded=True)
    reference=reference_body(exe)
    assert len(candidate)==len(reference)==SIZE and candidate==reference
    assert len(data_refs)+len(code_refs)==46, 'expected 46 LE relocation sites'
    report=dict(fixture='initialize-serial-network',status='FAIL',inventory_eligible=False,
        exact_verified=True,reference_sha256=sha(exe),candidate_object_sha256=sha(obj),
        data_bytes_compared=DATA_SIZE,preserved_registers=list(CONTRACT.preserved),
        candidate_bytes=SIZE,data_fixups=len(data_refs),code_fixups=len(code_refs),cases=[])
    for c in cases():
        expected=expected_behavior(c)
        for name,body in [('original',reference),('candidate',candidate)]:
            observed=exercise(body,c); diff=first_difference(expected,observed)
            assert not diff,'%s %s: %s'%(name,c['name'],diff)
        report['cases'].append(dict(name=c['name'],status='PASS',ds_sha256=sha(observed.memory['DS']),trace_sha256=sha(repr(observed.calls).encode())))
    controls=[]
    for name,pattern,index,value,case in [
        ('wrong-speed-divisor',b'\xb8\x00\xc2\x01\x00',1,1,next(c for c in cases() if c['name']=='speed_1')),
        ('wrong-fifo-drain-limit',b'\xc6\x00\x10',2,0x0f,next(c for c in cases() if c['name']=='drain_16'))]:
        altered=bytearray(reference); at=altered.find(pattern)
        assert at>=0 and altered.count(pattern)==1, 'mutation must identify exactly one instruction'
        altered[at+index]=value; controls.append((name,bytes(altered),case))
    report['negative_controls_detected']=require_mutations_detected('initialize-serial-network',reference,controls,exercise)
    report['cases_passed']=len(report['cases'])
    report['status']='PASS'
    if a.output: a.output.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({k:v for k,v in report.items() if k!='cases'},indent=2))
if __name__=='__main__': main()

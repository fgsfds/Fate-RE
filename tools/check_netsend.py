"""Independent bounded netsend packet oracle; reads existing objects only.
Exact byte/LE qualification and behavioral assertions are separate gates.
"""
import argparse
import hashlib
import json
from pathlib import Path
from struct import pack, unpack
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(ROOT/'tools'), str(ROOT/'work/cache/python/095240b6cf469e2f88b1')]
from differential import (Machine, Contract, Region, Observation, bind_bodies,
                          first_difference, require_mutations_detected)
from le_fixups import read_le_fixups, pointer_range
from compare_exe import TARGET_SHA256
from unicorn import UC_HOOK_CODE

ENTRY, RAW, SIZE = 0x41d59, 0x67359, 629
DS, DATA_SIZE, STACK, STOP = 0x80000, 3538944, 0x3f0000, 0x3fff00
A = dict(socket=0x13e64, compaddr=0x186d88, messout=0x18fd98,
         ipxout=0x18fdac, rmoffset32=0x18fdc0, ecbput=0x18fde0,
         rmsegment16=0x18fdec)
F = dict(memcpy_=0x63245, simulate_network_interrupt_=0x42ffc)
CONTRACT = Contract(ENTRY, STOP, STACK, 4,
    preserved=('ebx','ecx','esi','edi','ebp'), instruction_limit=400000, wall_timeout_us=30000000)
INITIAL = bytes(range(256)) * (DATA_SIZE//256)
sha = lambda data: hashlib.sha256(data).hexdigest()


def put(m, off, value, width=4):
    m[off:off+width] = (value & ((1 << (8*width))-1)).to_bytes(width,'little')


def cases():
    result = []
    def add(name, **updates):
        c = dict(name=name, peer=0, length=546, socket=0x1234,
                 ipx=0x290157, ecb=0x2910ab, message=0x2923f1,
                 rmoffset=0x300123, segment=0x12345678, busy=0,
                 clear_after=None, high_peer=0x76540000, high_length=0x89ab0000)
        c.update(updates)
        result.append(c)
    for peer in range(16):
        add('peer_'+str(peer), peer=peer)
    for peer in (-1, -2, -32768, 65535, 0x8000):
        add('broadcast_'+str(peer), peer=peer)
    for length in (0,1,255,256,546,32767,32768,65535,-1,-32768):
        add('length_'+str(length), length=length, peer=15)
    for socket in (0,1,255,256,0x7fff,0x8000,0xffff,-1):
        add('socket_'+str(socket),socket=socket,peer=-1)
    for i, offset in enumerate((0,0x310057,0x310058,0x310100,0x321234,0xffffffff,0x80000001)):
        add('realmode_split_'+str(i), rmoffset=offset,
            segment=(0xffff8000+i*0x103)&0xffffffff)
    for n in (0,1,2,17,32766,32767,32768):
        add('busy_clear_after_'+str(n),busy=0x81,clear_after=n,peer=-1)
    add('busy_timeout',busy=0xff)
    add('alternate_buffers',ipx=0x2a00ff,ecb=0x2a3001,message=0x2b0000,
        rmoffset=0x320100,segment=0x8000,peer=7)
    assert len(result) == 55
    return result


def initial_memory(c):
    assert (c['peer'] & 0xffff) < 16 or c['peer'] & 0x8000
    m = bytearray(INITIAL)
    for name, value in [('socket',c['socket']),('ipxout',DS+c['ipx']),
                        ('ecbput',DS+c['ecb']),('messout',DS+c['message']),
                        ('rmoffset32',c['rmoffset']),('rmsegment16',c['segment'])]:
        put(m,A[name],value,2 if name=='socket' else 4)
    for peer in range(16):
        m[A['compaddr']+peer*12:A['compaddr']+(peer+1)*12] = bytes(
            (peer*29+j*17+3)&255 for j in range(12))
    m[c['ecb']+8] = c['busy']
    return m


def wait_visits(c):
    if not c['busy']:
        return 1
    n = c['clear_after']
    return 32768 if n is None else min(n+1,32768)


def expected_behavior(c):
    m = initial_memory(c)
    ipx, ecb, peer = c['ipx'], c['ecb'], c['peer'] & 0xffff
    header, control = bytearray(30), bytearray(48)
    header[5] = 4
    socket = (c['socket'] & 0xffff).to_bytes(2,'little')
    calls = [('busy_wait',wait_visits(c))]
    if peer & 0x8000:
        header[6:10] = m[A['compaddr']:A['compaddr']+4]
        header[10:16] = b'\xff'*6
        header[16:18] = socket
        control[28:34] = b'\xff'*6
        calls.append(('memcpy',DS+ipx+6,DS+A['compaddr'],4))
    else:
        address = A['compaddr']+peer*12
        header[6:18] = m[address:address+12]
        control[28:34] = m[address+4:address+10]
        calls.extend([('memcpy',DS+ipx+6,DS+address,12),
                      ('memcpy',DS+ecb+28,DS+address+4,6)])
    control[10:12] = socket
    control[34:36] = b'\x02\x00'
    control[36:38] = ((DS+ipx-c['rmoffset'])&65535).to_bytes(2,'little')
    control[38:40] = (c['segment']&65535).to_bytes(2,'little')
    control[40:42] = b'\x1e\x00'
    control[42:44] = ((DS+c['message']-c['rmoffset'])&65535).to_bytes(2,'little')
    control[44:46] = control[38:40]
    control[46:48] = (c['length']&65535).to_bytes(2,'little')
    m[ipx:ipx+30], m[ecb:ecb+48] = header,control
    calls.append(('simulate_network_interrupt',0x7a,0,3,0,0,DS+ecb,0,
                  bytes(header).hex(),bytes(control).hex()))
    return Observation({}, {'DS':bytes(m)},tuple(calls))


def exercise(body,c):
    machine = Machine(CONTRACT,body,[Region('DS',DS,DATA_SIZE)])
    machine.write(DS,initial_memory(c))
    visits = 0
    def busy_hook(cpu,address,size,user):
        nonlocal visits
        if address == 0x41d6f:
            visits += 1
            if c['busy'] and c['clear_after'] is not None and visits > c['clear_after']:
                machine.write(DS+c['ecb']+8,b'\x00')
        elif address == 0x41d7c:
            machine.record('busy_wait',visits)
    hook = machine.cpu.hook_add(UC_HOOK_CODE,busy_hook)
    def memcpy(m):
        dst,src,count = (m.register(r) for r in ('eax','edx','ebx'))
        assert count in (4,6,12), 'unbounded memcpy'
        assert DS+A['compaddr'] <= src and src+count <= DS+A['compaddr']+192
        assert (DS+c['ipx'] <= dst and dst+count <= DS+c['ipx']+30 or
                DS+c['ecb'] <= dst and dst+count <= DS+c['ecb']+48)
        m.record('memcpy',dst,src,count)
        m.write(dst,m.read(src,count))
        return {'eax':dst}
    def interrupt(m):
        regs = tuple(m.register(r) for r in ('eax','edx','ebx','ecx'))
        args = unpack('<3I',m.read(m.register('esp')+4,12))
        m.record('simulate_network_interrupt',*regs,*args,
                 m.read(DS+c['ipx'],30).hex(),m.read(DS+c['ecb'],48).hex())
        return dict(eax=0xaabbccdd,ebx=0x1234abcd,ecx=0xfedcba98,edx=0xdeadbeef)
    machine.stub(F['memcpy_'],memcpy)
    # Default Watcom ABI passes four registers then three callee-popped words.
    machine.add_code(F['simulate_network_interrupt_'],b'\xc2\x0c\x00')
    machine.stubs[F['simulate_network_interrupt_']] = interrupt
    try:
        return machine.run(dict(eax=c['high_peer']|(c['peer']&65535),
            edx=c['high_length']|(c['length']&65535),ebx=0x12345678,
            ecx=0x87654321,esi=0x23456789,edi=0x3456789a,
            ebp=0x456789ab,eflags=0x202))
    finally:
        machine.cpu.hook_del(hook)


def reference_body(exe):
    assert sha(exe)==TARGET_SHA256, 'pinned executable hash mismatch'
    body = bytearray(exe[RAW:RAW+SIZE])
    assert len(body)==SIZE
    refs = pointer_range(read_le_fixups(exe)['pointers'],ENTRY,SIZE)
    assert len(refs)==57, 'expected 57 LE sites'
    for off,target in refs.items():
        assert off+4 <= SIZE
        body[off:off+4] = pack('<I',target)
    return bytes(body)


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--exe', type=Path, required=True)
    p.add_argument('--object', type=Path, required=True)
    p.add_argument('--output',type=Path)
    a = p.parse_args()
    exe, obj = a.exe.read_bytes(), a.object.read_bytes()
    reference = reference_body(exe)
    report = dict(fixture='send-ipx-packet',status='FAIL',mode='exact-and-behavior',
        inventory_eligible=False,exact_verified=False,reference_sha256=sha(exe),
        candidate_object_sha256=sha(obj),reference_body_sha256=sha(reference),
        reference_le_fixups=57,data_bytes_compared=DATA_SIZE,cases=[],
        preserved_registers=list(CONTRACT.preserved),
        instruction_limit=CONTRACT.instruction_limit, wall_timeout_us=CONTRACT.wall_timeout_us,
        helper_contracts={'memcpy':'EAX/EDX/EBX arguments; modifies EAX only',
            'simulate_network_interrupt':'EAX/EDX/EBX/ECX and three stack words; RET 12; modifies EAX/EBX/ECX/EDX'},
        model_scope='Bounded peers 0..15 and negative short broadcasts; independent packet/ECB bytes and full DS comparison; deterministic driver stub; busy polling bounded to 32768 visits; no live IPX or DOS-driver verification')
    try:
        rebound,candidate,fixups = bind_bodies(exe,obj,'netsend_',ENTRY,SIZE,
            {'_'+k:v for k,v in A.items()},F,data_base=DS)
        assert rebound==reference
        assert fixups==57
        report.update(exact_verified=True,candidate_bytes=len(candidate),
            candidate_absolute_fixups=fixups,candidate_body_sha256=sha(candidate))
        for c in cases():
            expected = expected_behavior(c)
            original = exercise(reference,c)
            difference = first_difference(expected,original)
            assert not difference, f"original {c['name']}: {difference}"
            actual = exercise(candidate,c)
            difference = first_difference(expected,actual)
            assert not difference, f"candidate {c['name']}: {difference}"
            report['cases'].append(dict(name=c['name'],status='PASS',
                busy_loop_visits=wait_visits(c),reference_ds_sha256=sha(original.memory['DS']),
                candidate_ds_sha256=sha(actual.memory['DS']),trace_sha256=sha(repr(actual.calls).encode())))
        wrong_type = bytearray(reference)
        pos = wrong_type.index(b'\xc6\x40\x05\x04')
        wrong_type[pos+3] = 5
        wrong_wait = bytearray(reference)
        pos = wrong_wait.index(b'\xb8\xff\x7f\x00\x00')
        wrong_wait[pos+1:pos+5] = pack('<I',32766)
        timeout = next(c for c in cases() if c['name']=='busy_timeout')
        report['negative_controls_detected'] = require_mutations_detected('send-ipx-packet',reference,
            [('wrong_packet_type',bytes(wrong_type),cases()[0]),
             ('wrong_busy_timeout',bytes(wrong_wait),timeout)],exercise)
        report['status']='PASS'
    except Exception as error:
        report['failure']=str(error)
        raise
    finally:
        report['cases_passed']=len(report['cases'])
        if a.output:
            a.output.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({k:v for k,v in report.items() if k!='cases'},indent=2))


if __name__=='__main__':
    main()


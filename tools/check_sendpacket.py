"""Independent bounded sendpacket protocol/state oracle; never compiles sources.

Exact bytes and LE relocation provenance are separate from the Python packet
model. No ASM aliases are read, so retiring the original ASM cannot affect it.
"""
import argparse
import hashlib
import json
from pathlib import Path
from struct import pack
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(ROOT/'tools'), str(ROOT/'work/cache/python/095240b6cf469e2f88b1')]
from differential import (Machine, Contract, Region, Observation, bind_bodies,
                          first_difference, require_mutations_detected)
from compare_exe import TARGET_SHA256
from le_fixups import read_le_fixups, pointer_range
from unicorn import UC_HOOK_CODE

ENTRY, RAW, SIZE = 0x424ec, 0x67aec, 1177
DS, DATA_SIZE, STACK, STOP = 0x80000, 3538944, 0x3f0000, 0x3fff00
A = dict(multioption=0x13cde, comrateoption=0x13cdf, myconnectindex=0x13ce2,
    connecthead=0x19028a, connectpoint2=0x18fd78, outbufindex=0x18fb78,
    outcnt=0x18fe14, crctable=0x18f778, outbuf=0x18fe34,
    outbufend=0x18fdd0, ecbput=0x18fde0, messout=0x18fd98,
    netoutcnt=0x186e48, omessout=0x186e58, omessleng=0x18f6f8,
    omessconnectindex=0x186cb8, omessnum=0x18f6d8)
BINDINGS = {'_'+k:v for k,v in A.items()}
BINDINGS.update(dict(_netoutcnt_backing=0x186e47, _omessnum_backing=0x18f6d6,
    _omessout_backing=0x1865d0, _omessleng_backing=0x18f6f0,
    _omessconnectindex_backing=0x186cb0))
F = dict(comsend_=0x41fce, startcom_=0x4204f, getcrc_=0x42f73, netsend_=0x41d59)
CONTRACT = Contract(ENTRY, STOP, STACK, 4,
    preserved=('ecx','esi','edi','ebp'), instruction_limit=2000000)
INITIAL = bytes(range(256)) * (DATA_SIZE//256)
sha = lambda b: hashlib.sha256(b).hexdigest()


def put(m, off, value, width=4):
    m[off:off+width] = (value & ((1 << (width*8))-1)).to_bytes(width,'little')


def get(m, off, width=4, signed=False):
    return int.from_bytes(m[off:off+width], 'little', signed=signed)


def slot(name, peer, index):
    assert -1 <= peer < 16 and 0 <= index < 4, 'unbounded history index'
    return A[name] + (peer*4+index)*(546 if name=='omessout' else 2)


def crc_table():
    result = []
    for byte in range(256):
        value = byte << 8
        for _ in range(8):
            value = ((value << 1) ^ (0x1021 if value & 0x8000 else 0)) & 65535
        result.append(value)
    return result


TABLE = crc_table()


def crc(payload):
    value = 0
    for byte in reversed(payload):
        value = ((value << 8) & 65535) ^ TABLE[(value >> 8) ^ byte]
    return value


def cases():
    result = []
    def add(name, **updates):
        c = dict(name=name, mode=5, rate=0, peer=3, local=1,
            payload=bytes([7,0x83,0x8f,0xff,0x80]), length=None,
            outcnt=17, end=101, head=0, chain=(0,1,3,15), phase=0, net_seed=None,
            busy=0, clear_after=None, input=0x290003, ring=0x2a0000,
            endptr=0x2a5002, message=0x2b0001, ecb=0x2c0003)
        c.update(updates)
        if c['length'] is None:
            c['length'] = len(c['payload'])
        result.append(c)
    add('disabled',mode=0)
    for mode in range(1,5):
        for rate in (0,1,15,16,0x81,0xff):
            add('serial_%d_rate_%d'%(mode,rate),mode=mode,rate=rate)
        for marker in (253,254):
            add('serial_%d_reset_%d'%(mode,marker),mode=mode,rate=1,
                payload=bytes([marker,0x83,0x8f]),outcnt=127,end=16383)
    for length in (0,1,2,3,16,255,546):
        payload = bytes(([7,0x83,0x8f,0xff]*137)[:max(1,length)])
        add('serial_length_'+str(length),mode=4,rate=15,payload=payload,
            length=length,outcnt=127,end=16382)
    add('serial_negative_length',mode=2,rate=1,length=-1)
    for marker in (0,127):
        add('serial_counter_'+str(marker),mode=1,rate=1,outcnt=marker)
    # Every reserved first byte is checked, including the 200/255 boundaries.
    for marker in range(200,256):
        add('ipx_reserved_'+str(marker),payload=bytes([marker,0x83,0x8f]),
            peer=-1 if marker&1 else 15,mode=5+(marker%3))
    for peer in (0,1,3,15):
        for phase in range(4):
            add('ipx_unicast_%d_slot_%d'%(peer,phase),peer=peer,phase=phase)
    for phase in range(4):
        add('ipx_broadcast_guard_slot_'+str(phase),peer=-1,phase=phase)
    for length in (0,1,2,255,500):
        add('ipx_length_'+str(length),payload=bytes([199])+bytes(
            (i*17)&255 for i in range(max(0,length-1))),length=length)
    add('ipx_reserved_maximum',payload=bytes([255])+bytes(545))
    add('ipx_negative_length',length=-1)
    for count in (0,1,2,17,1024,262143,262144):
        add('busy_clear_after_'+str(count),busy=0x81,clear_after=count,
            payload=b'\xc8')
    add('busy_timeout',busy=0xff,payload=b'\xff')
    add('ipx_unicast_counter_wrap', net_seed=255)
    add('ipx_broadcast_counters_wrap', peer=-1, net_seed=255)
    add('ipx_broadcast_mutates_guard_selector', peer=-1, payload=bytes([7])+bytes(543)+b'\xfe\xff')
    add('ipx_empty_connection_list',peer=-1,chain=(),head=-1)
    add('alternate_backing_memory',mode=3,rate=1,ring=0x2d0001,
        endptr=0x2e0003,input=0x2e1007,message=0x2f0005,ecb=0x300007,
        end=16383,payload=b'\x83\x8f')
    assert len(result)==139
    return result


def initial_memory(c):
    assert c['peer'] in (-1,0,1,3,15)
    assert -1 <= c['length'] <= 546
    m = bytearray(INITIAL)
    # History guard row -1 intentionally backs the original broadcast quirk.
    # Payloads are initialized before the overlapping real metadata arrays.
    for peer in range(-1,16):
        for k in range(4):
            off = slot('omessout',peer,k)
            m[off:off+546] = bytes((peer*31+k*13+i*7)&255 for i in range(546))
    for peer in range(-1,16):
        put(m,A['omessnum']+peer*2,(peer+c['phase'])&3,2)
        for k in range(4):
            put(m,slot('omessleng',peer,k),(peer*3+k*5+7)%20,2)
            put(m,slot('omessconnectindex',peer,k),-1 if (peer+k)&1 else peer,2)
        put(m,A['netoutcnt']+peer,(250+peer*3)&255 if c['net_seed'] is None else c['net_seed'],1)
    for i,value in enumerate(TABLE):
        put(m,A['crctable']+i*4,value)
    for name,width in [('multioption',1),('comrateoption',1),('myconnectindex',2),('connecthead',2),('outcnt',4)]:
        key = dict(multioption='mode',comrateoption='rate',myconnectindex='local',connecthead='head').get(name,name)
        put(m,A[name],c[key],width)
    for name,key in [('outbuf','ring'),('outbufend','endptr'),('messout','message'),('ecbput','ecb')]:
        put(m,A[name],DS+c[key])
    put(m,c['endptr'],c['end'],2)
    for peer in range(16):
        put(m,A['connectpoint2']+peer*2,-1,2)
    assert len(set(c['chain']))==len(c['chain']) and len(c['chain'])<=16
    for i,peer in enumerate(c['chain']):
        put(m,A['connectpoint2']+peer*2,c['chain'][i+1] if i+1<len(c['chain']) else -1,2)
    m[c['input']:c['input']+len(c['payload'])] = c['payload']
    m[c['ecb']+8] = c['busy']
    return m


def wait_visits(c):
    # One final test of zero budget occurs after all 262144 busy decrements.
    return 1 if not c['busy'] else min(262145, (c['clear_after']+1) if c['clear_after'] is not None else 262145)


def expected_behavior(c):
    m = initial_memory(c)
    calls = []
    payload = c['payload'][:max(0,c['length'])]
    if not c['mode']:
        return Observation({}, {'DS':bytes(m)},tuple(calls))
    if c['mode'] < 5:
        count = 0 if c['payload'][0] in (253,254) else c['outcnt']
        put(m,A['outcnt'],count)
        put(m,A['outbufindex']+count*4,c['end'])
        header = ((c['length']&1)<<7)+count
        outgoing = [header,*payload]
        if c['rate']&15:
            value = crc(payload)
            calls_crc = ('getcrc',DS+c['input'],c['length'],payload.hex(),value)
            value = ((value << 8)&65535) ^ TABLE[(value>>8)^header]
            outgoing.extend([value&255,value>>8])
        pos = c['end']
        for i,byte in enumerate(outgoing):
            if c['rate']&15 and i==1+len(payload):
                calls.append(calls_crc)
            calls.append(('comsend',byte))
            # ESC1 escapes to 83 80; ESC2 escapes to 83 81.
            encoded = bytes([0x83,0x80 if byte==0x83 else 0x81]) if byte in (0x83,0x8f) else bytes([byte])
            for wire_byte in encoded:
                m[c['ring']+pos] = wire_byte
                pos = (pos+1)&16383
        m[c['ring']+pos] = 0x8f
        pos = (pos+1)&16383
        put(m,c['endptr'],pos,2)
        calls.append(('startcom',pos))
        put(m,A['outcnt'],(count+1)&127)
    else:
        calls.append(('busy_wait',wait_visits(c)))
        # The zero-budget test does not read the busy byte on its last visit.
        if c['busy'] and c['clear_after'] is not None and c['clear_after'] < 262144:
            m[c['ecb']+8] = 0
        packet = bytearray([c['local']&255])
        if c['payload'][0]>=200:
            m[A['netoutcnt']:A['netoutcnt']+16] = bytes(16)
            packet.extend([254,*payload])
        else:
            targets = [p for p in c['chain'] if p!=c['local']] if c['peer']<0 else [c['peer']]
            for peer in targets:
                index = get(m,A['omessnum']+peer*2,2,signed=True)
                put(m,slot('omessconnectindex',peer,index),c['peer'],2)
                put(m,slot('omessleng',peer,index),c['length'],2)
                off = slot('omessout',peer,index)
                m[off:off+len(payload)] = payload
            # Broadcast writes all participants but reads row -1 for assembly.
            peer = c['peer']
            for age in range(4):
                index = (get(m,A['omessnum']+peer*2,2,signed=True)-age)&3
                kind = get(m,slot('omessconnectindex',peer,index),2,signed=True)
                if kind<0:
                    packet.append(255)
                    packet.extend((m[A['netoutcnt']+p]-age)&255 for p in c['chain'] if p!=c['local'])
                else:
                    packet.extend([peer&255,(m[A['netoutcnt']+peer]-age)&255])
                length = get(m,slot('omessleng',peer,index),2,signed=True)
                assert -1<=length<=546
                packet.extend((length&65535).to_bytes(2,'little'))
                off = slot('omessout',peer,index)
                packet.extend(m[off:off+max(0,length)])
        m[c['message']:c['message']+len(packet)] = packet
        calls.append(('netsend',c['peer'],len(packet),packet.hex()))
        if c['payload'][0]<200:
            for peer in targets:
                put(m,A['netoutcnt']+peer,m[A['netoutcnt']+peer]+1,1)
                put(m,A['omessnum']+peer*2,(get(m,A['omessnum']+peer*2,2)+1)&3,2)
    return Observation({}, {'DS':bytes(m)},tuple(calls))


class LongerTimeout:
    """Keep Machine's ABI/write checks; permit the bounded busy-loop to finish."""
    def __init__(self,cpu):
        self.cpu = cpu
    def __getattr__(self,name):
        return getattr(self.cpu,name)
    def emu_start(self,*args,**kwargs):
        # Wall time only: Machine still supplies the two-million instruction cap.
        kwargs['timeout'] = 30000000
        return self.cpu.emu_start(*args,**kwargs)


def exercise(body,c):
    machine = Machine(CONTRACT,body,[Region('DS',DS,DATA_SIZE)])
    machine.cpu = LongerTimeout(machine.cpu)
    machine.write(DS,initial_memory(c))
    visits = 0
    def busy_hook(cpu,address,size,user):
        nonlocal visits
        if address==0x42624:
            visits += 1
            if c['busy'] and c['clear_after'] is not None and visits>c['clear_after'] and visits<=262144:
                machine.write(DS+c['ecb']+8,b'\0')
        elif address==0x42631:
            machine.record('busy_wait',visits)
    hook = machine.cpu.hook_add(UC_HOOK_CODE,busy_hook)
    def comsend(m):
        byte = m.register('eax')&255
        m.record('comsend',byte)
        pos = int.from_bytes(m.read(DS+c['endptr'],2),'little')
        assert pos<16384
        encoded = bytes([0x83,0x80 if byte==0x83 else 0x81]) if byte in (0x83,0x8f) else bytes([byte])
        for value in encoded:
            m.write(DS+c['ring']+pos,bytes([value]))
            pos = (pos+1)&16383
        m.write(DS+c['endptr'],pack('<H',pos))
        return dict(eax=0xcafe0000|byte)
    def getcrc(m):
        ptr = m.register('eax')
        length = m.register('edx')&65535
        length = length-65536 if length&32768 else length
        assert ptr==DS+c['input'] and -1<=length<=546
        payload = m.read(ptr,max(0,length))
        value = crc(payload)
        m.record('getcrc',ptr,length,payload.hex(),value)
        return dict(eax=value,edx=0xdeadbeef)
    def startcom(m):
        m.record('startcom',int.from_bytes(m.read(DS+c['endptr'],2),'little'))
        return dict(eax=0xaabbccdd)
    def netsend(m):
        peer = m.register('eax')&65535
        peer = peer-65536 if peer&32768 else peer
        length = m.register('edx')&65535
        assert peer==c['peer'] and 1<=length<=560, 'unbounded packet'
        m.record('netsend',peer,length,m.read(DS+c['message'],length).hex())
        return dict(eax=0x11223344,edx=0x55667788)
    for name,callback in [('comsend_',comsend),('getcrc_',getcrc),('startcom_',startcom),('netsend_',netsend)]:
        machine.stub(F[name],callback)
    try:
        return machine.run(dict(eax=0x76540000|(c['peer']&65535),
            edx=DS+c['input'],ebx=0x89ab0000|(c['length']&65535),
            ecx=0x87654321,esi=0x23456789,edi=0x3456789a,
            ebp=0x456789ab,eflags=0x202))
    finally:
        machine.cpu.hook_del(hook)


def reference_body(exe):
    assert sha(exe)==TARGET_SHA256, 'pinned executable hash mismatch'
    body = bytearray(exe[RAW:RAW+SIZE])
    assert len(body)==SIZE
    refs = pointer_range(read_le_fixups(exe)['pointers'],ENTRY,SIZE)
    assert len(refs)==62, 'expected 62 LE sites'
    for off,target in refs.items():
        assert off+4<=SIZE
        body[off:off+4] = pack('<I',target)
    return bytes(body)


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--exe', type=Path, required=True)
    p.add_argument('--object', type=Path, required=True)
    p.add_argument('--output',type=Path)
    p.add_argument('--original-only',action='store_true',help='Validate independent model against original only; never exact-qualifies candidate')
    a = p.parse_args()
    exe = a.exe.read_bytes()
    reference = reference_body(exe)
    report = dict(fixture='send-game-packet',status='FAIL',inventory_eligible=False,
        mode='original-model-only' if a.original_only else 'exact-and-behavior',
        exact_verified=False,reference_sha256=sha(exe),reference_body_sha256=sha(reference),
        reference_le_fixups=62,data_bytes_compared=DATA_SIZE,cases=[],
        preserved_registers=list(CONTRACT.preserved),instruction_limit=CONTRACT.instruction_limit,
        helper_contracts=dict(comsend='EAX byte; modifies EAX only; escaped ring writes',
            startcom='No arguments; modifies EAX only; deterministic no-drain transmitter',
            getcrc='EAX pointer/EDX signed short; modifies EAX/EDX',
            netsend='EAX signed peer/EDX short length; modifies EAX/EDX'),
        model_scope='Modes 0..7; serial ring/escaping/reverse CRC; IPX reserved reset and four-packet history; bounded broadcast guard row -1 preserves original quirk; full DS; bounded busy polling; deterministic helpers, no live serial/IPX driver')
    try:
        candidate = None
        if not a.original_only:
            obj = a.object.read_bytes()
            rebound,candidate,fixups = bind_bodies(exe,obj,'sendpacket_',ENTRY,SIZE,
                BINDINGS,F,data_base=DS)
            assert rebound==reference and fixups==62
            report.update(exact_verified=True,candidate_bytes=len(candidate),
                candidate_object_sha256=sha(obj),candidate_body_sha256=sha(candidate),
                candidate_absolute_fixups=fixups)
        for c in cases():
            expected = expected_behavior(c)
            original = exercise(reference,c)
            difference = first_difference(expected,original)
            assert not difference, 'original %s: %s'%(c['name'],difference)
            actual = exercise(candidate,c) if candidate is not None else None
            if actual is not None:
                difference = first_difference(expected,actual)
                assert not difference, 'candidate %s: %s'%(c['name'],difference)
            report['cases'].append(dict(name=c['name'],status='PASS',
                reference_ds_sha256=sha(original.memory['DS']),
                candidate_ds_sha256=sha(actual.memory['DS']) if actual else None,
                trace_sha256=sha(repr(original.calls).encode())))
        wrong_marker = bytearray(reference)
        pos = wrong_marker.index(b'\xc6\x04\x02\x8f')
        wrong_marker[pos+3] = 0x8e
        wrong_reset = bytearray(reference)
        pos = wrong_reset.index(b'\xc6\x04\x03\xfe')
        wrong_reset[pos+3] = 0xfd
        wrong_wait = bytearray(reference)
        pos = wrong_wait.index(b'\xbb\x00\x00\x04\x00')
        wrong_wait[pos+1:pos+5] = pack('<I',262143)
        selected = cases()
        report['negative_controls_detected'] = require_mutations_detected('send-game-packet',reference,
            [('wrong_serial_terminator',bytes(wrong_marker),next(c for c in selected if c['mode']==1)),
             ('wrong_ipx_sync_marker',bytes(wrong_reset),next(c for c in selected if c['name']=='ipx_reserved_200')),
             ('wrong_busy_timeout',bytes(wrong_wait),next(c for c in selected if c['name']=='busy_timeout'))],exercise)
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

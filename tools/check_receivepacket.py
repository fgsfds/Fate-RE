"""Independent bounded getpacket serial/IPX model; never invokes the compiler.

The model checks AX, helper calls, saved registers, and all 3,538,944 DS bytes.
Exact bytes/LE provenance remain a separate gate from behavioral equivalence.
"""
import argparse
import hashlib
import json
from pathlib import Path
from struct import pack
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(ROOT/'tools'), str(ROOT/'work/cache/python/095240b6cf469e2f88b1')]
from differential import (Machine, Contract, Region, Observation, bind_bodies, first_difference,
                          require_mutations_detected)
from compare_exe import TARGET_SHA256
from le_fixups import read_le_fixups, pointer_range

ENTRY, RAW, SIZE = 0x42985, 0x67f85, 1429
DS, DATA_SIZE, STACK, STOP = 0x80000, 3538944, 0x3f0000, 0x3fff00
RETURN, RETURN_BYTES = 0x42489, bytes.fromhex('5d5f5e595bc3')
A = dict(multioption=0x13cde, comrateoption=0x13cdf, syncstate=0x13cdc,
    myconnectindex=0x13ce2, connecthead=0x19028a, connectpoint2=0x18fd78,
    netincnt=0x186d38, comescape=0x18fdfc, comreset=0x18fe2c,
    syncbufleng=0x18fe38, syncbuf=0x190062, getmess=0x18fe40,
    myconnectnum=0x18fe30, otherconnectnum=0x18fe08,
    inbuf=0x18fe24, inbufplc=0x18fdbc, inbufend=0x18fdf0,
    outbufplc=0x18fdd8, comresend=0x18fdf4, comerror=0x18fe1c,
    incnt=0x18fe00, outcnt=0x18fe14, outbufindex=0x18fb78,
    crctable=0x18f778, netinbuf=0x18fdb4, netinbufplc=0x18fdb8,
    netinbufend=0x18fda8)
BINDINGS = {'_'+name: offset for name,offset in A.items()}
BINDINGS['_syncbuf_backing'] = A['syncbuf']-2
F = dict(startcom_=0x4204f, getcrc_=0x42f73, processreservedmessage_=0x432c1,
    netinitconnection_=0x42319)
CONTRACT = Contract(ENTRY, STOP, STACK, 4,
    preserved=('ebx','ecx','esi','edi','ebp'),results=('eax',),
    instruction_limit=300000)
INITIAL = bytes(range(256))*(DATA_SIZE//256)
sha = lambda value: hashlib.sha256(value).hexdigest()


def put(m, off, value, width=4):
    m[off:off+width] = (value & ((1 << (width*8))-1)).to_bytes(width,'little')


def get(m, off, width=4, signed=False):
    return int.from_bytes(m[off:off+width],'little',signed=signed)


def short(value):
    return (value+32768)%65536-32768


def crc_table():
    table=[]
    for byte in range(256):
        value=byte<<8
        for _ in range(8):
            value=((value<<1) ^ (0x1021 if value&0x8000 else 0))&65535
        table.append(value)
    return table


TABLE=crc_table()


def crc(payload):
    value=0
    for byte in reversed(payload):
        value=((value<<8)&65535)^TABLE[(value>>8)^byte]
    return value


def escape(payload):
    out=bytearray()
    for byte in payload:
        out.extend((0x83,0x80 if byte==0x83 else 0x81) if byte in (0x83,0x8f) else (byte,))
    return bytes(out)


def frame(payload, count=7, rate=0, bad_crc=False, bad_parity=False):
    header=(count&127)|((len(payload)&1)<<7)
    if bad_parity:
        header ^= 0x80
    body=bytes([header])+payload
    if rate&15:
        value=((crc(payload)<<8)&65535)^TABLE[(crc(payload)>>8)^header]
        if bad_crc:
            value ^= 1
        body += pack('<H',value)
    return escape(body)+b'\x8f'


def ipx_packet(sender=3, messages=()):
    data=bytearray([sender])
    for item in messages:
        target,seq,payload=item
        data.append(target)
        if target==0xfe:
            data.extend(payload)
        else:
            data.extend(bytes(seq) if target==0xff else bytes([seq]))
            data.extend(pack('<H',len(payload)))
            data.extend(payload)
    assert 2 <= len(data) <= 546
    return pack('<H',len(data))+data


def cases():
    result=[]
    def add(name, **updates):
        c=dict(name=name,mode=1,rate=0,local=1,sender=3,incnt=7,
            netcount=7,start=101,stream=b'',sync=b'',prefix=b'\x61\x42',
            comescape=0,comreset=0,comerror=0,comresend=0,outcnt=17,
            mynum=10,othernum=20,chain=(0,1,3,15),ring=0x290000,
            cursor=0x2a1002,endptr=0x2a1012,outptr=0x2a1022,
            resendptr=0x2a1031,errorptr=0x2a1033,countptr=0x2a1035,
            other=0x2b0003,output=0x2c0005)
        c.update(updates)
        result.append(c)
    add('disabled',mode=0,stream=frame(b'hello'))
    for mode in range(1,5):
        for rate in (0,1,15,16,0x81,255):
            add('serial_mode_%d_rate_%d'%(mode,rate),mode=mode,rate=rate,
                stream=frame(b'\x07\x83\x8f\xff',rate=rate))
    for length in (0,1,2,3,31,255,543):
        payload=bytes((i*19+3)&255 for i in range(length))
        add('serial_payload_'+str(length),stream=frame(payload),start=16382)
    # At least one helper CRC has bit 15 set, exercising defined unsigned shifts.
    high=next(bytes([x]) for x in range(256) if crc(bytes([x]))>=32768)
    add('serial_crc_high_bit',rate=1,stream=frame(high,rate=1))
    add('serial_escape_partial',stream=b'\x83')
    add('serial_escaped_controls',stream=frame(b'\x83\x8f'))
    add('serial_nested_escape',stream=b'\x83\x83\x80\x81')
    add('serial_escape_reset',stream=b'\x83\x8f',sync=b'old',
        comescape=2,comreset=3,comerror=2)
    add('serial_resend',stream=b'\x83\x23',start=8191)
    add('serial_resend_pending',stream=b'\x83\x23',comresend=2)
    add('serial_resend_close',stream=b'\x83\x14')
    add('serial_resend_distance_four',stream=b'\x83\x15')
    add('serial_resend_distance_five',stream=b'\x83\x16')
    add('serial_sync_capacity',sync=bytes([17])*546,stream=b'\x44\x83\x80')
    add('serial_sync_almost_capacity',sync=bytes([17])*545,stream=b'\x83\x81\x44')
    for rate in (0,1):
        for n in (0,1,2):
            add('serial_truncated_rate_%d_prefix_%d'%(rate,n),rate=rate,
                sync=bytes([7,10][:n]),stream=b'\x8f')
    add('serial_bad_parity',stream=frame(b'abc',bad_parity=True))
    add('serial_bad_crc',rate=1,stream=frame(b'abc',rate=1,bad_crc=True))
    add('serial_bad_counter',stream=frame(b'abc',count=19))
    add('serial_old_counter',stream=frame(b'abc',count=6))
    add('serial_bad_reset_cooldown',stream=frame(b'a',count=8),comreset=2)
    add('serial_bad_reset_pending',stream=frame(b'a',count=8),comerror=2)
    add('serial_bad_then_good',stream=frame(b'bad',count=8)+frame(b'good'))
    add('serial_counter_wrap',incnt=127,start=16383,stream=frame(b'a',count=127))
    add('serial_master_arbitration_lower',incnt=1,stream=frame(b'\xfe',count=2))
    add('serial_master_arbitration_higher',incnt=1,mynum=30,stream=frame(b'\xfe',count=2))
    for marker in (199,200,253,254,255):
        add('serial_reserved_'+str(marker),stream=frame(bytes([marker,3])))
    add('serial_empty_ring',sync=b'partial')
    for mode in (5,6,7,128,255):
        add('ipx_mode_'+str(mode),mode=mode,stream=ipx_packet(messages=((1,7,b'abc'),)))
    for sender in (0,1,3,15):
        add('ipx_sender_'+str(sender),mode=5,sender=sender,
            stream=ipx_packet(sender,((1,7,b'abc'),)))
    for marker in (0,199,200,252,253,254,255):
        add('ipx_reserved_'+str(marker),mode=5,
            stream=ipx_packet(messages=((1,7,bytes([marker,17])),)))
    for length in (0,1,2,255,500):
        add('ipx_payload_'+str(length),mode=5,start=16383,
            stream=ipx_packet(messages=((1,7,bytes([7])*length),)))
    for retry in range(1,4):
        items=[(1,8+i,b'old'+bytes([i])) for i in range(retry)]+[(1,7,b'recover')]
        add('ipx_history_retry_'+str(retry),mode=5,stream=ipx_packet(messages=items))
    add('ipx_history_all_bad',mode=5,stream=ipx_packet(messages=[(1,8+i,b'old') for i in range(4)]))
    add('ipx_history_reserved',mode=5,stream=ipx_packet(messages=((1,8,b'bad'),(1,7,b'\xfdok'))))
    add('ipx_broadcast',mode=5,stream=ipx_packet(messages=((255,(12,7,22),b'hello'),)))
    add('ipx_broadcast_history',mode=5,stream=ipx_packet(messages=((255,(12,8,22),b'old'),(255,(12,7,22),b'new'))))
    add('ipx_reset_reserved',mode=5,stream=ipx_packet(messages=((254,0,b'\xfe\x03'),)))
    add('ipx_reset_ordinary',mode=5,stream=ipx_packet(messages=((254,0,b'\x07\x03'),)))
    add('ipx_counter_wrap',mode=5,netcount=255,stream=ipx_packet(messages=((1,255,b'x'),)))
    add('ipx_empty_ring',mode=5)
    add('alternate_backing_memory',mode=5,ring=0x2d0011,cursor=0x2e1003,
        endptr=0x2e1015,output=0x2f0007,start=16380,
        stream=ipx_packet(messages=((1,7,b'wrapped'),)))
    add('serial_maximum_no_crc',stream=frame(bytes([7])*545))
    add('serial_maximum_crc',rate=1,stream=frame(bytes([7])*543,rate=1))
    add('serial_local_zero',local=0,stream=frame(b'hello'))
    add('serial_alternate_backing',ring=0x2d0011,cursor=0x2e1003,endptr=0x2e1015,
        outptr=0x2e1025,resendptr=0x2e1031,errorptr=0x2e1033,countptr=0x2e1035,
        other=0x2f0003,output=0x300005,start=16382,rate=1,stream=frame(b'\x83\x8f',rate=1))
    for marker in (200,253,255):
        add('ipx_self_reserved_'+str(marker),mode=5,sender=1,
            stream=ipx_packet(1,((1,7,bytes([marker,17])),)))
    add('ipx_self_history',mode=5,sender=1,
        stream=ipx_packet(1,((1,8,b'bad'),(1,7,b'retry'))))
    for before,after in ((253,254),(253,255),(255,253)):
        add('ipx_callback_%d_to_%d'%(before,after),mode=5,reserved_after=after,
            stream=ipx_packet(messages=((1,7,bytes([before,17])),)))
    assert len(result)==110
    return result


def initial_memory(c):
    m=bytearray(INITIAL)
    for name in ('multioption','comrateoption'):
        put(m,A[name],c['mode' if name=='multioption' else 'rate'],1)
    for name,value in [('myconnectindex',c['local']),('connecthead',c['chain'][0])]:
        put(m,A[name],value,2)
    for i in range(16):
        put(m,A['connectpoint2']+2*i,-1,2)
        put(m,A['netincnt']+i,c['netcount'],1)
    for left,right in zip(c['chain'],c['chain'][1:]):
        put(m,A['connectpoint2']+2*left,right,2)
    ptrs=dict(inbuf=c['ring'],netinbuf=c['ring'],inbufplc=c['cursor'],
        netinbufplc=c['cursor'],inbufend=c['endptr'],netinbufend=c['endptr'],
        outbufplc=c['outptr'],comresend=c['resendptr'],comerror=c['errorptr'],incnt=c['countptr'])
    for name,offset in ptrs.items():
        put(m,A[name],DS+offset)
    for name,key in [('comescape','comescape'),('comreset','comreset'),('outcnt','outcnt'),
                     ('myconnectnum','mynum'),('otherconnectnum','othernum')]:
        put(m,A[name],c[key])
    put(m,A['syncbufleng'],len(c['sync']))
    m[A['syncbuf']-2:A['syncbuf']]=c['prefix']
    m[A['syncbuf']:A['syncbuf']+len(c['sync'])]=c['sync']
    for key in ('comresend','comerror','incnt'):
        put(m,c[dict(comresend='resendptr',comerror='errorptr',incnt='countptr')[key]],c[key],1)
    put(m,c['cursor'],c['start'],2)
    put(m,c['endptr'],(c['start']+len(c['stream']))&16383,2)
    put(m,c['outptr'],0x1234,2)
    for i,byte in enumerate(c['stream']):
        m[c['ring']+((c['start']+i)&16383)]=byte
    for i,value in enumerate(TABLE):
        put(m,A['crctable']+4*i,value)
    for i in range(128):
        put(m,A['outbufindex']+4*i,0x10003+i*137)
    return m


def expected_behavior(c):
    m=initial_memory(c)
    calls=[]
    def r(name): return get(m,A[name])
    def w(name,value): put(m,A[name],value)
    def startcom():
        calls.append(('startcom',get(m,c['outptr'],2),m[c['resendptr']],m[c['errorptr']],r('comreset')))
    def reserved(length):
        calls.append(('processreservedmessage',length,DS+c['output'],m[c['output']:c['output']+length].hex()))
        if 'reserved_after' in c:
            m[c['output']]=c['reserved_after']
    result=0
    if c['mode'] and c['mode']<5:
        put(m,c['other'],c['local']^1,2)
        while get(m,c['cursor'],2)!=get(m,c['endptr'],2):
            index=get(m,c['cursor'],2)
            byte=m[c['ring']+index]
            put(m,c['cursor'],(index+1)&16383,2)
            if byte!=0x8f:
                if byte==0x83:
                    w('comescape',r('comescape')+1)
                    continue
                if r('comescape'):
                    w('comescape',r('comescape')-1)
                    if byte<128 and not m[c['resendptr']] and ((byte-r('outcnt'))&127)>4:
                        m[c['resendptr']]=2
                        put(m,c['outptr'],get(m,A['outbufindex']+byte*4,2),2)
                        startcom()
                        continue
                    if r('syncbufleng')<546 and byte in (128,129):
                        byte=0x83 if byte==128 else 0x8f
                if r('syncbufleng')<546:
                    m[A['syncbuf']+r('syncbufleng')]=byte
                    w('syncbufleng',r('syncbufleng')+1)
                continue
            if r('comescape'):
                for key in ('comescape','comreset','syncbufleng'): w(key,0)
                m[c['errorptr']]=0
                continue
            length=short(r('syncbufleng')-3+(2 if not c['rate']&15 else 0))
            header=m[A['syncbuf']]
            bad=int((header&127)!=m[c['countptr']])
            if bad and m[c['countptr']]==1 and m[A['syncbuf']+1]==254:
                put(m,A['myconnectindex'],int(c['mynum']<c['othernum']),2)
            if (header>>7)!=(length&1): bad|=2
            payload=bytes(m[A['syncbuf']+1:A['syncbuf']+1+max(0,length)])
            m[c['output']:c['output']+len(payload)]=payload
            if c['rate']&15:
                value=crc(payload)
                calls.append(('getcrc',DS+c['output'],length,payload.hex(),value))
                value=((value<<8)&65535)^TABLE[(value>>8)^header]
                actual=get(m,A['syncbuf']+r('syncbufleng')-2,2)
                if value!=actual: bad|=2
            w('syncbufleng',0)
            if bad:
                if bad==1 and ((header-m[c['countptr']])&127)>=124: continue
                if r('comreset'): w('comreset',r('comreset')-1)
                if not (m[c['errorptr']]|r('comreset')):
                    m[c['errorptr']]=2
                    w('comreset',2)
                    startcom()
                continue
            m[c['countptr']]=(m[c['countptr']]+1)&127
            if length>0 and payload[0]>=200: reserved(length)
            w('comescape',0); w('comreset',0); m[c['errorptr']]=0
            result=length
            break
    elif c['mode']>=5 and get(m,c['cursor'],2)!=get(m,c['endptr'],2):
        cursor=get(m,c['cursor'],2)
        length=m[c['ring']+cursor]+(m[c['ring']+((cursor+1)&16383)]<<8)
        assert 2<=length<=546
        packet=bytes(m[c['ring']+((cursor+i+2)&16383)] for i in range(length))
        m[A['getmess']:A['getmess']+length]=packet
        sender=packet[0]
        assert 0<=sender<16
        put(m,c['other'],sender,2)
        k=1
        for retry in range(4):
            target=packet[k]; k+=1
            if target==254:
                m[A['netincnt']+sender]=0
                sublength=length-2
            else:
                if target==255:
                    assert sender!=c['local'] and c['local'] in c['chain']
                    assert len(set(c['chain']))==len(c['chain'])
                    seq=None
                    for peer in c['chain']:
                        if peer!=sender:
                            if peer==c['local']: seq=packet[k]
                            k+=1
                    assert seq is not None
                else:
                    seq=packet[k]; k+=1
                sublength=int.from_bytes(packet[k:k+2],'little')
                k+=2
                assert k+sublength<=length
                if seq!=m[A['netincnt']+sender]:
                    k+=sublength
                    continue
                m[A['netincnt']+sender]=(m[A['netincnt']+sender]+1)&255
            payload=packet[k:k+sublength]
            m[c['output']:c['output']+sublength]=payload
            if not retry:
                put(m,c['cursor'],(cursor+length+2)&16383,2)
                if sublength>0 and payload[0]>=200:
                    if payload[0]>=253:
                        reserved(sublength)
                        if m[c['output']] in (253,254): result=0; break
                    result=sublength; break
            result=0 if sender==c['local'] else sublength
            break
        else:
            m[A['syncstate']]=(m[A['syncstate']]+1)&255
            put(m,c['cursor'],(cursor+length+2)&16383,2)
    return Observation({'ax':result&65535},{'DS':bytes(m)},tuple(calls))


def exercise(body,c):
    machine=Machine(CONTRACT,body,[Region('DS',DS,DATA_SIZE)])
    machine.add_code(RETURN,RETURN_BYTES)
    machine.write(DS,initial_memory(c))
    def startcom(m):
        vals=[get(m.read(DS+offset,width),0,width) for offset,width in
              ((c['outptr'],2),(c['resendptr'],1),(c['errorptr'],1),(A['comreset'],4))]
        m.record('startcom',*vals)
        return {'eax':0xaabbccdd}
    def getcrc(m):
        pointer,length=m.register('eax'),short(m.register('edx'))
        assert pointer==DS+c['output'] and -3<=length<=546,'unbounded CRC input'
        payload=m.read(pointer,max(0,length)); value=crc(payload)
        m.record('getcrc',pointer,length,payload.hex(),value)
        return dict(eax=0xa5a50000|value,edx=0xdeadbeef)
    def reserved(m):
        length,pointer=short(m.register('eax')),m.register('edx')
        assert pointer==DS+c['output'] and 1<=length<=546,'unbounded reserved message'
        m.record('processreservedmessage',length,pointer,m.read(pointer,length).hex())
        if 'reserved_after' in c:
            m.write(pointer,bytes([c['reserved_after']]))
        return dict(eax=0xaabbccdd,edx=0xdeadbeef)
    for name,callback in [('startcom_',startcom),('getcrc_',getcrc),('processreservedmessage_',reserved)]:
        machine.stub(F[name],callback)
    actual=machine.run(dict(eax=DS+c['other'],edx=DS+c['output'],ebx=0x12345678,
        ecx=0x87654321,esi=0x23456789,edi=0x3456789a,ebp=0x456789ab,eflags=0x202))
    return Observation({'ax':actual.registers['eax']&65535},actual.memory,actual.calls)


def reference_body(exe):
    assert sha(exe)==TARGET_SHA256,'pinned executable hash mismatch'
    assert exe[RETURN+0x25600:RETURN+0x25600+6]==RETURN_BYTES,'shared epilogue differs'
    original=exe[RAW:RAW+SIZE]
    assert len(original)==SIZE
    refs=pointer_range(read_le_fixups(exe)['pointers'],ENTRY,SIZE)
    assert len(refs)==80,'expected 80 LE sites'
    body=bytearray(original)
    for offset,target in refs.items():
        assert offset+4<=SIZE
        body[offset:offset+4]=pack('<I',target)
    return original,bytes(body),refs


def production_body(exe,obj,fragment,reference):
    """Verify the two original C sections and the actual four-byte C fragment."""
    middle_reference,middle,middle_sites=bind_bodies(exe,fragment,'getpacket_length_order_',ENTRY+914,4,
        BINDINGS,F,data_base=DS)
    assert len(middle)==4 and middle_sites==0,'unexpected length fragment shape or relocation'
    pointers=read_le_fixups(exe)['pointers']
    gap_sites=pointer_range(pointers,ENTRY+914,4)
    assert not gap_sites,'unexpected length fragment relocation'
    head_reference,head,head_sites=bind_bodies(exe,obj,'getpacket_head_',ENTRY,914,
        BINDINGS,F,data_base=DS)
    tail_reference,tail,tail_sites=bind_bodies(exe,obj,'getpacket_tail_',ENTRY+918,511,
        BINDINGS,F,data_base=DS)
    assert len(head)==914 and len(tail)==511
    assert head_sites+tail_sites==80,'combined C LE count differs'
    assert head_reference+middle_reference+tail_reference==reference
    result=head+middle+tail
    assert result==reference,'actual production packet body differs'
    return result,dict(head=head_sites,length=middle_sites,tail=tail_sites)

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--exe', type=Path, required=True)
    mode=parser.add_mutually_exclusive_group(required=True)
    mode.add_argument('--production-object',type=Path,help='Actual built netinitc.obj; exact acceptance mode')
    mode.add_argument('--original-only',action='store_true')
    parser.add_argument('--fragment-object',type=Path,help='Actual built recvlen.obj; four-byte C section')
    parser.add_argument('--output',type=Path)
    args=parser.parse_args()
    if bool(args.production_object)!=bool(args.fragment_object):
        parser.error('Use --production-object and --fragment-object together')
    exe=args.exe.read_bytes()
    raw,reference,refs=reference_body(exe)
    report=dict(fixture='receive-game-packet',status='FAIL',inventory_eligible=False,
        mode='exact-production-and-behavior' if args.production_object else 'original-model-only',
        exact_verified=False,reference_sha256=sha(exe),reference_body_sha256=sha(reference),
        reference_le_fixups=len(refs),data_bytes_compared=DATA_SIZE,cases=[],
        preserved_registers=list(CONTRACT.preserved),result_register='AX',
        instruction_limit=CONTRACT.instruction_limit,
        helper_contracts=dict(startcom='No arguments; modifies EAX only; deterministic no-drain transmitter',
            getcrc='EAX pointer/EDX signed short; modifies EAX/EDX; reverse CRC16',
            processreservedmessage='AX signed length/EDX buffer; modifies EAX/EDX; optional first-byte rewrite tests caller reload'),
        model_scope='Bounded serial streams and IPX packet/history states; synchronous rings; truncated serial frames read at most two initialized sync prefix bytes; full DS and saved-register verification; FF broadcasts require sender != local and local in the valid player chain; no live driver or concurrent producer')
    try:
        candidates={}
        if args.production_object:
            obj=args.production_object.read_bytes()
            fragment=args.fragment_object.read_bytes()
            production,fixups=production_body(exe,obj,fragment,reference)
            candidates={'production':production}
            report.update(exact_verified=True,candidate_object_sha256=sha(obj),
                fragment_object_sha256=sha(fragment),retained_asm_bytes=0,restored_c_bytes=1429,
                production_object=str(args.production_object.resolve()),
                fragment_object=str(args.fragment_object.resolve()),
                candidate_bytes=len(production),candidate_absolute_fixups=fixups,
                production_body_sha256=sha(production))
        report['high_crc_frame_exercised']=True
        selected=cases()
        for c in selected:
            expected=expected_behavior(c)
            original=exercise(reference,c)
            difference=first_difference(expected,original)
            assert not difference,'original %s: %s'%(c['name'],difference)
            hashes={}
            for name,body in candidates.items():
                actual=exercise(body,c)
                difference=first_difference(expected,actual)
                assert not difference,'%s %s: %s'%(name,c['name'],difference)
                hashes[name]=sha(actual.memory['DS'])
            report['cases'].append(dict(name=c['name'],status='PASS',
                reference_ds_sha256=sha(original.memory['DS']),candidate_ds_sha256=hashes,
                trace_sha256=sha(repr(original.calls).encode())))
        wrong_marker=bytearray(reference)
        pos=wrong_marker.index(bytes.fromhex('3d8f000000'))
        wrong_marker[pos+1]=0x8e
        wrong_wrap=bytearray(reference)
        pos=wrong_wrap.index(bytes.fromhex('80e63f'))
        wrong_wrap[pos+2]=0x1f
        wrong_history=bytearray(reference)
        pos=wrong_history.index(bytes.fromhex('83fa040f8c'))
        wrong_history[pos+2]=3
        named={c['name']:c for c in selected}
        report['negative_controls_detected']=require_mutations_detected('receive-game-packet',reference,
            [('wrong_serial_terminator',bytes(wrong_marker),named['serial_mode_1_rate_0']),
             ('wrong_serial_ring_mask',bytes(wrong_wrap),named['serial_resend']),
             ('wrong_history_retry_limit',bytes(wrong_history),named['ipx_history_retry_3'])],exercise)
        report['status']='PASS'
    except Exception as error:
        report['failure']=str(error)
        raise
    finally:
        report['cases_passed']=len(report['cases'])
        if args.output:
            args.output.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({k:v for k,v in report.items() if k!='cases'},indent=2))


if __name__=='__main__':
    main()

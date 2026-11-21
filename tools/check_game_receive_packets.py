"""Independent bounded receive_packets state/call oracle; never compiles code.

Behavior-only PASS does not qualify code bytes or LE relocations. Full DS is
compared, EAX's void result is ignored, and all six saved GP registers checked.
"""
import argparse
import hashlib
import json
from pathlib import Path
from differential import (Machine, Contract, Region, Observation, bind_bodies,
                          first_difference, require_mutations_detected)
from compare_exe import TARGET_SHA256

ENTRY, SIZE, DS, DATA_SIZE = 0x32407, 916, 0x80000, 3538944
STACK, STOP = 0x3f0000, 0x3fff00
A = dict(network_enabled=0x3c98, sync_error=0x3cda,
         event_write_index=0x3cdc, received_write_index=0x3ce0,
         event_read_index=0x3ce4, last_tick=0x3cea, player_count=0x13ce0,
         local_player=0x13ce2, packet=0x1d92c, received_checksum=0x1e5fc,
         generated_checksum=0x1f7fc, peer_ready_stage=0x20a1c,
         current_input=0x5ac3c, quit_requested=0x6793d,
         message_deadline=0x7709c, message_text=0x7aa70,
         message_length=0x7f874, connectpoint2=0x18fd78,
         connecthead=0x19028a, totalclock=0x287e88)
F = dict(getpacket_=0x42985, sendpacket_=0x424ec,
         snapshot_input_=0x2d1bd, random_value_=0x602d0)
CONTRACT = Contract(ENTRY, STOP, STACK, 4,
                    preserved=('ebx','ecx','edx','esi','edi','ebp'),
                    instruction_limit=300000, wall_timeout_us=1000000)
INITIAL = bytes(range(256))*(DATA_SIZE//256)
sha = lambda data: hashlib.sha256(data).hexdigest()


def put(m, offset, value, width=4):
    m[offset:offset+width] = (value & ((1 << (8*width))-1)).to_bytes(width,'little')


def get(m, offset, width=4):
    return int.from_bytes(m[offset:offset+width], 'little')


def host(chain, masks=None, checksums=()):
    """Encode valid wire input independently, from field tuples per player."""
    masks = [15]*len(chain) if masks is None else list(masks)
    assert len(masks)==len(chain)
    header = bytearray((len(chain)+1)//2)
    data = bytearray()
    for ordinal, (player, mask) in enumerate(zip(chain,masks)):
        assert 0 <= mask <= 15
        header[ordinal//2] |= mask << (4*(ordinal%2))
        values = ((0x91+player)&255, (0xe5-player)&255,
                  (0x7f+player*3)&255, (0x80a7+player*0x101)&65535)
        for field in range(4):
            if mask & (1 << field):
                data += values[field].to_bytes(2 if field==3 else 1,'little')
    for value in checksums:
        data += value.to_bytes(2,'little')
    wire = b'\0'+bytes(header)+bytes(data)
    assert len(wire)<=546
    return (chain[0],wire)


def client(sender, flags):
    data = bytearray([1,flags])
    for field, value in enumerate((0xff,0x80,0x7f,0x2d,0xe3)):
        if flags & (1 << field): data.append(value)
    return sender,bytes(data)


def crc(index): return ((index*0x137)^0xa65d)&65535


def cases():
    out=[]
    def add(name, **updates):
        c=dict(name=name, chain=(3,1,8), local=3, enabled=1,
               queue=[], rng=1, clock=0x34567890, tick=0x12345678,
               read=0, written=0, received=0, received_overrides={},
               end_length=0)
        c.update(updates); out.append(c)
    for mask in range(16):
        add('host_mask_%02x'%mask, queue=[host((3,1,8),[mask]*3)])
    for chain in ((7,), (9,2), (15,0,8), tuple(range(15,-1,-1))):
        add('host_chain_%d'%len(chain),chain=chain,local=chain[0],queue=[host(chain)])
    for flags in range(32): add('client_flags_%02x'%flags,queue=[client(8,flags)])
    for sender in (3,1,8): add('client_sender_%d'%sender,queue=[client(sender,31)])
    add('crc_equal',read=5,written=8,received=5,
        queue=[host((3,1,8),[0]*3,[crc(i) for i in range(5,8)])])
    add('crc_high_bit_mismatch',read=5,written=8,received=5,
        queue=[host((3,1,8),[0]*3,[crc(5),crc(6)^0x8000,crc(7)^0x0101])])
    add('crc_received_limit',read=5,written=9,received=5,
        queue=[host((3,1,8),[0]*3,[crc(5),crc(6)])])
    add('crc_generated_limit',read=5,written=6,received=5,
        queue=[host((3,1,8),[0]*3,[crc(5),crc(6),crc(7)])])
    add('crc_wrap',read=254,written=1,received=255,
        queue=[host((3,1,8),[0]*3,[crc(255)^0x8000,crc(0)^0x55])])
    add('crc_write_wrap_no_compare',read=12,written=12,received=255,
        queue=[host((3,1,8),[0]*3,[0x80ff,0x00a5])])
    add('crc_pending_without_new_words',read=4,written=7,received=6,
        received_overrides={4:crc(4)^0x100,5:crc(5)^0x8000},
        queue=[host((3,1,8),[0]*3)])
    for count in (0,1,2,254,255,256,257,545):
        wire=b'\2'+bytes((i*7+0x80)&255 for i in range(count))
        add('text_payload_%d'%count, queue=[(1,wire)])
    add('text_clock_wrap',clock=0xffffffff,queue=[(1,b'\2abc')])
    for sender in (3,1):
        for stage in (0,1,2,3,255):
            add('ready_sender_%d_stage_%d'%(sender,stage),queue=[(sender,bytes([5,stage]))])
    add('quit',queue=[(1,b'\xff')])
    for opcode in (3,4,6,17,127,254): add('unknown_%d'%opcode,queue=[(1,bytes([opcode]))])
    add('disabled',enabled=0,local=1,queue=[client(1,31),host((3,1,8)),(3,b'\5\2')])
    add('empty_leader')
    add('empty_negative_result',local=1,end_length=-1,rng=0)
    for rng in (0,1):
        for tick in (0,0xffffffff):
            add('empty_client_rng_%d_tick_%08x'%(rng,tick),local=1,rng=rng,tick=tick)
    for count in (1,2,3,4):
        for rng in (0,1):
            add('host_count_%d_rng_%d'%(count,rng),local=1,rng=rng,
                queue=[host((3,1,8),[0]*3)]*count)
    add('mixed_queue',local=1,queue=[client(8,31),(3,b'\5\2'),
        host((3,1,8),[1,2,4]),(1,b'\2hello'),(1,b'\xff'),
        host((3,1,8),[8,15,0]),(1,b'\x11')])
    return out


def initial_memory(c):
    m=bytearray(INITIAL)
    chain=c['chain']; assert 1<=len(chain)<=16 and len(set(chain))==len(chain)
    assert all(0<=p<16 for p in chain) and c['local'] in chain
    put(m,A['network_enabled'],c['enabled'],1)
    put(m,A['player_count'],len(chain),2)
    put(m,A['local_player'],c['local'],2); put(m,A['connecthead'],chain[0],2)
    for p in range(16): put(m,A['connectpoint2']+2*p,0xffff,2)
    for p,nxt in zip(chain,(*chain[1:],-1)): put(m,A['connectpoint2']+2*p,nxt,2)
    for name,key in [('event_read_index','read'),('event_write_index','written'),('received_write_index','received')]:
        assert 0<=c[key]<256; put(m,A[name],c[key])
    put(m,A['sync_error'],0xd00d,2)
    for i in range(256):
        put(m,A['generated_checksum']+2*i,crc(i),2)
        put(m,A['received_checksum']+2*i,c['received_overrides'].get(i,crc(i)),2)
    put(m,A['last_tick'],c['tick']); put(m,A['totalclock'],c['clock'])
    put(m,A['message_deadline'],0x8badf00d); put(m,A['message_length'],0xda,1)
    put(m,A['quit_requested'],0,1)
    for sender,payload in c['queue']:
        assert sender in chain and 1<=len(payload)<=546
    assert c['end_length'] in (0,-1) and c['rng'] in (0,1)
    return m


def snapshot_record(m):
    return ('snapshot',bytes(m[A['current_input']:A['current_input']+80]).hex(),
            get(m,A['sync_error'],2),get(m,A['event_read_index']),
            get(m,A['received_write_index']))


def expected_behavior(c):
    """Model complete records and ring queues, independent of machine registers."""
    m=initial_memory(c); calls=[]; snapshots=0
    if not c['enabled']: return Observation({}, {'DS':bytes(m)}, ())
    for sender,payload in c['queue']:
        m[A['packet']:A['packet']+len(payload)] = payload
        calls.append(('getpacket',sender,len(payload),payload.hex()))
        opcode=payload[0]
        if opcode==0:
            chain=c['chain']; start=1+(len(chain)+1)//2
            # Extract flags as nibbles and decode typed fields from a byte stream.
            data=iter(payload[start:])
            for ordinal,player in enumerate(chain):
                mask=(payload[1+ordinal//2] >> (4*(ordinal%2)))&15
                for field in range(4):
                    if mask & (1<<field):
                        offset=A['current_input']+5*player+field
                        m[offset]=next(data)
                        if field==3: m[offset+1]=next(data)
            remaining=bytes(data); assert len(remaining)%2==0
            cursor=get(m,A['received_write_index'])
            for at in range(0,len(remaining),2):
                put(m,A['received_checksum']+2*cursor,int.from_bytes(remaining[at:at+2],'little'),2)
                cursor=(cursor+1)%256
            put(m,A['received_write_index'],cursor)
            read=get(m,A['event_read_index']); written=get(m,A['event_write_index'])
            if read!=written and read!=cursor:
                differences=[]
                while read!=written and read!=cursor:
                    differences.append(get(m,A['generated_checksum']+2*read,2)^get(m,A['received_checksum']+2*read,2))
                    read=(read+1)%256
                    assert len(differences)<=255
                combined=0
                for word in differences: combined |= word
                put(m,A['sync_error'],combined,2)
                put(m,A['event_read_index'],read)
            calls.append(snapshot_record(m)); snapshots+=1
        elif opcode==1:
            flags=payload[1]; data=iter(payload[2:]); base=A['current_input']+5*sender
            for field in range(5):
                if flags & (1<<field): m[base+field]=next(data)
        elif opcode==2:
            size=(len(payload)-1)%256
            put(m,A['message_length'],size,1)
            m[A['message_text']:A['message_text']+size]=payload[1:1+size]
            put(m,A['message_deadline'],c['clock']+360+16*size)
        elif opcode==5:
            m[A['peer_ready_stage']+sender]=payload[1]
            if sender==c['chain'][0] and payload[1]==2:
                calls.append(('sendpacket',sender,2,payload[:2].hex()))
        elif opcode==255:
            put(m,A['quit_requested'],1,1)
    calls.append(('getpacket',None,c['end_length'],''))
    if c['local']!=c['chain'][0] and snapshots%2==0:
        calls.append(('random_value',c['rng']))
        put(m,A['last_tick'],c['tick']+(1 if c['rng'] else -1))
    return Observation({}, {'DS':bytes(m)},tuple(calls))


def exercise(body,c):
    machine=Machine(CONTRACT,body,[Region('DS',DS,DATA_SIZE)])
    machine.write(DS,initial_memory(c)); pending=list(c['queue'])
    def receive(m):
        senderptr,buf=(m.register(r) for r in ('eax','edx'))
        assert STACK-CONTRACT.stack_scratch<=senderptr<STACK-1
        assert buf==DS+A['packet']
        if pending:
            sender,payload=pending.pop(0)
            m.write(senderptr,sender.to_bytes(2,'little')); m.write(buf,payload)
            m.record('getpacket',sender,len(payload),payload.hex())
            length=len(payload)
        else:
            length=c['end_length']; m.record('getpacket',None,length,'')
        return dict(eax=0x8bad0000|(length&65535),edx=0xdeadc0de)
    def send(m):
        target,pointer,length=(m.register(r) for r in ('eax','edx','ebx'))
        assert pointer==DS+A['packet'] and length==2 and target in c['chain']
        m.record('sendpacket',target,length,m.read(pointer,length).hex())
        return dict(eax=0xaabbccdd,ebx=0xbadc0ffe,edx=0x87654321)
    def snapshot(m):
        ds=m.read(DS,DATA_SIZE)
        m.record(*snapshot_record(ds))
        return dict(eax=0xaabbccdd,ebx=0xbadc0ffe,ecx=0xcafebabe,edx=0x87654321)
    def random_value(m):
        m.record('random_value',c['rng']); return dict(eax=c['rng'])
    machine.stub(F['getpacket_'],receive); machine.stub(F['sendpacket_'],send)
    machine.stub(F['snapshot_input_'],snapshot); machine.stub(F['random_value_'],random_value)
    return machine.run(dict(eax=0x1234abcd,ebx=0x12345678,ecx=0x87654321,
                            edx=0x2468ace0,esi=0x23456789,edi=0x3456789a,
                            ebp=0x456789ab,eflags=0x202))


HYBRID_C = (('recvpkt.obj', 'receive_packets_entry_', 0, 342), ('recvpkt.obj', 'receive_packets_crc_store_', 345, 25), ('recvpkt.obj', 'receive_packets_delta_', 475, 143), ('recvpkt.obj', 'receive_packets_buttons_', 635, 51), ('recvpkt.obj', 'receive_packets_text_', 695, 43), ('recvpkt.obj', 'receive_packets_ready_', 768, 16), ('recvpkt.obj', 'receive_packets_ready_test_', 802, 19), ('recvpkt.obj', 'receive_packets_poll_', 834, 41), ('recvpkt.obj', 'receive_packets_finish_', 882, 34), ('recvcrc.obj', 'receive_packets_checksums_', 370, 105), ('recvpar.obj', 'receive_packets_parity_', 875, 7), ('recvhigh.obj', 'receive_packets_button_high_', 686, 9), ('recvhead.obj', 'receive_packets_ready_head_', 784, 18), ('recvsend.obj', 'receive_packets_ready_send_', 821, 13), ('recvfrag.obj', 'receive_packets_button_low_', 618, 17), ('recvfrag.obj', 'receive_packets_crc_order_', 342, 3), ('recvfrag.obj', 'receive_packets_message_delta_', 738, 10), ('recvfrag.obj', 'receive_packets_message_clock_', 748, 20))
HYBRID_ASM = ()


def bind_hybrid(exe, obj, build):
    from verify_c_leaf import bind_leaf_details, verify_leaf_relocations
    from le_fixups import read_le_fixups, pointer_range
    pointers=read_le_fixups(exe)['pointers']
    target=exe[ENTRY+0x25600:ENTRY+0x25600+SIZE]
    candidate=bytearray(b'\xcc'*SIZE)
    covered=set()
    native_sites=0
    functions=dict(F,receive_packets_=ENTRY,receive_ready_send_=0x3273c)
    def place(start, code):
        sites=set(range(start,start+len(code)))
        assert 0<=start and start+len(code)<=SIZE and not covered.intersection(sites)
        covered.update(sites)
        candidate[start:start+len(code)]=code
    data_values={'_'+k:v for k,v in A.items()}
    data_values.update(_receiver_button_bytes=A['current_input'],
                    _receiver_crc_words=A['received_checksum'],
                    _receiver_crc_cursor=A['received_write_index'],
                    _checksum_write_cursor=A['event_write_index'],
                    _checksum_received_cursor=A['received_write_index'],
                    _checksum_read_cursor=A['event_read_index'])
    for filename,symbol,start,size in HYBRID_C:
        blob=obj if filename=='recvpkt.obj' else (build/filename).read_bytes()
        refs={}
        code,bindings=bind_leaf_details(blob,symbol,data_values,
            address=ENTRY+start,functions=functions,code_bindings=refs)
        assert len(code)==size
        verify_leaf_relocations(code,bindings,pointers,ENTRY+start,code_bindings=refs)
        native_sites+=len(bindings)
        place(start,code)
    for filename,start,size in HYBRID_ASM:
        code=(build/'asm'/filename).read_bytes()
        assert len(code)==size
        place(start,code)
    assert covered==set(range(SIZE)), 'hybrid does not partition the whole receiver'
    assert native_sites==65, 'expected 65 selected C LE sites'
    assert bytes(candidate)==target, 'hybrid differs from pinned whole receiver'
    reference=bytearray(target)
    fixups=pointer_range(pointers,ENTRY,SIZE)
    assert len(fixups)==65
    for site,address in fixups.items():
        assert int.from_bytes(candidate[site:site+4],'little')+0x80000==address
        reference[site:site+4]=address.to_bytes(4,'little')
        candidate[site:site+4]=address.to_bytes(4,'little')
    return bytes(reference),bytes(candidate),len(fixups)


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--exe',type=Path,required=True)
    inputs=p.add_mutually_exclusive_group(required=True)
    inputs.add_argument('--object',type=Path)
    inputs.add_argument('--build',type=Path)
    p.add_argument('--behavior-only',action='store_true'); p.add_argument('--output',type=Path)
    args=p.parse_args(); exe=args.exe.read_bytes()
    object_path=args.object or args.build/'recvpkt.obj'
    obj=object_path.read_bytes()
    assert sha(exe)==TARGET_SHA256,'pinned executable hash mismatch'
    report=dict(fixture='receive_packets',status='FAIL',inventory_eligible=False,
        mode='behavior-only' if args.behavior_only else 'exact-and-behavior',
        exact_verified=False,reference_sha256=sha(exe),candidate_object_sha256=sha(obj),
        data_bytes_compared=DATA_SIZE,preserved_registers=list(CONTRACT.preserved),
        void_eax_ignored=True,cases=[],negative_controls_detected=[],
        helper_contracts=dict(getpacket='Records sender/frame; writes bounded buffer and sender short; modifies EAX/EDX',
            sendpacket='Records recipient, length and bytes; modifies EAX/EBX/EDX',
            snapshot_input='Records input and ring state; modifies EAX/EBX/ECX/EDX and preserves ESI/EDI/EBP',
            random_value='Records RNG call and returns selected 0/1; modifies EAX only'),
        model_scope='Valid terminating chains and packets, 256-word checksum rings, byte message truncation, complete DS, six preserved GP registers; helper application side effects are stubbed')
    try:
        if args.build and not args.behavior_only:
            reference,candidate,fixups=bind_hybrid(exe,obj,args.build)
            report.update(native_c_bytes=916,retained_assembly_bytes=0,native_le_sites=65)
        else:
            reference,candidate,fixups=bind_bodies(exe,obj,'receive_packets_',ENTRY,SIZE,
                {'_'+k:v for k,v in A.items()},F,data_base=DS,behavior_only=args.behavior_only)
        report.update(candidate_bytes=len(candidate),candidate_absolute_fixups=fixups,
                      exact_verified=not args.behavior_only)
        if args.build and not args.behavior_only:
            report.update(fragment_object_sha256={name:sha((args.build/name).read_bytes())
                    for name in ('recvcrc.obj','recvpar.obj','recvhigh.obj','recvhead.obj','recvsend.obj','recvfrag.obj')})
        selected=cases()
        for c in selected:
            expected=expected_behavior(c)
            for label,body in [('original',reference),('candidate',candidate)]:
                observed=exercise(body,c)
                difference=first_difference(expected,observed)
                if difference:
                    report['first_failure']=dict(implementation=label,case=c['name'],
                        difference=difference,expected_calls=expected.calls,actual_calls=observed.calls)
                    raise AssertionError('%s %s: %s'%(label,c['name'],difference))
            report['cases'].append(dict(name=c['name'],status='PASS',
                ds_sha256=sha(observed.memory['DS']),trace_sha256=sha(repr(observed.calls).encode())))
        # Actual source instruction mutations: disable network path and invert
        # the quit flag. Both must be rejected by these independent observations.
        mutations=[]
        for name,pattern,index,value,case in [
            ('skip_enabled_network',b'\x0f\x84',1,0x85,next(c for c in selected if c['name']=='quit')),
            ('lost_quit_flag',b'\xc6\x05'+(DS+A['quit_requested']).to_bytes(4,'little')+b'\x01',6,0,
             next(c for c in selected if c['name']=='quit'))]:
            altered=bytearray(reference); at=altered.index(pattern); altered[at+index]=value
            mutations.append((name,bytes(altered),case))
        report['negative_controls_detected']=require_mutations_detected('receive_packets',reference,mutations,exercise)
        report['status']='PASS'
    except Exception as error:
        report['failure']=str(error)
        if 'first_failure' not in report:
            report['first_failure']=dict(implementation=locals().get('label','binding-or-control'),
                case=locals().get('c',{}).get('name'),difference=str(error))
        raise
    finally:
        report['cases_passed']=len(report['cases'])
        if args.output: args.output.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
        print(json.dumps({k:v for k,v in report.items() if k!='cases'},indent=2))

if __name__=='__main__': main()


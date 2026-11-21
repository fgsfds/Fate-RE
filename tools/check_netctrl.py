"""Independent bounded processreservedmessage oracle; never compiles code.

Contract: initialized 225-byte packet storage, FE records of exactly 14 bytes,
valid 0..15 player slots, and removals leave the local player connected.
"""
import argparse
import hashlib
import json
from pathlib import Path
from struct import pack
import sys
ROOT = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(ROOT/'tools'), str(ROOT/'work/cache/python/095240b6cf469e2f88b1')]
from differential import Machine, Contract, Region, Observation, bind_bodies, first_difference, require_mutations_detected
from compare_exe import TARGET_SHA256
from le_fixups import read_le_fixups, pointer_range

ENTRY, RAW, SIZE = 0x432c1, 0x688c1, 719
DS, DATA_SIZE, STACK, STOP = 0x80000, 3538944, 0x3f0000, 0x3fff00
BUFFER, CAPACITY, EMPTY = 0x2c0005, 225, 0x7fffffff
A = dict(multioption=0x13cde,numplayers=0x13ce0,myconnectindex=0x13ce2,
    socket=0x13e64,connectnum=0x186d48,compaddr=0x186d88,
    myconnectnum=0x18fe30,otherconnectnum=0x18fe08,
    connectpoint2=0x18fd78,connecthead=0x19028a)
BINDINGS = {'_'+k:v for k,v in A.items()}
F = dict(netinitconnection_=0x42319,netuninitconnection_=0x4248f,sendpacket_=0x424ec)
CONTRACT = Contract(ENTRY,STOP,STACK,4,preserved=('ebx','ecx','esi','edi','ebp'),instruction_limit=300000)
INITIAL = bytes(range(256))*(DATA_SIZE//256)
sha = lambda data: hashlib.sha256(data).hexdigest()
def put(m,offset,value,width=4): m[offset:offset+width]=(value&((1<<(8*width))-1)).to_bytes(width,'little')
def get(m,offset,width=4,signed=False): return int.from_bytes(m[offset:offset+width],'little',signed=signed)
def signed(value): return (value+0x80000000)%0x100000000-0x80000000
def packet(marker,peer=30): return bytes([marker])+pack('<I',peer&0xffffffff)+bytes(range(10,20))
def listpacket(peers): return b'\xfe'+b''.join(pack('<I',p&0xffffffff)+bytes((i+p)&255 for i in range(10)) for p in peers)

def cases():
    out=[]
    def add(name,**updates):
        c=dict(name=name,mode=5,ids=(10,20),localid=10,payload=packet(253),socket=0xbad1)
        c.update(updates); out.append(c)
    for mode in (0,1,2,3,4,5,6,128,255):
        for marker in (253,254,255):
            payload=listpacket((30,40)) if marker==254 else (b'\xff\x01' if marker==255 else packet(marker))
            add('transport_%d_marker_%d'%(mode,marker),mode=mode,payload=payload)
    for marker in (0,1,127,199,200,252): add('noop_'+str(marker),payload=bytes([marker]))
    for peer in (0,1,9,10,20,21,0x7ffffffe,0x7fffffff,0x80000000,0x80000001,0xffffffff):
        add('join_%08x'%peer,payload=packet(253,peer))
    add('join_self_nonleader',localid=20,payload=packet(253,20))
    add('join_nonleader_no_reply',localid=20,payload=packet(253,30))
    add('join_old_leader_successor_reply',localid=20,payload=packet(253,10))
    add('join_third_player_no_reply',ids=(10,20,30),localid=30,payload=packet(253,10))
    add('join_precedes_local_no_reply',ids=(20,30),localid=20,payload=packet(253,10))
    add('join_full',ids=tuple(range(16)),localid=0,payload=packet(253,50))
    add('join_full_duplicate',ids=tuple(range(16)),localid=0,payload=packet(253,15))
    add('join_signed_leader',ids=(0x80000000,10),localid=0x80000000,payload=packet(253,0xffffffff))
    add('join_last_free',ids=tuple(range(15)),localid=0,payload=packet(253,50))
    for peers in ((),(10,),(20,),(30,),(30,40),(40,30),(0xffffffff,0x80000000,0,0x7ffffffe),(30,30,10),tuple(range(30,46))):
        add('list_'+str(len(out)),payload=listpacket(peers))
    for index in (0,1,2,3,7,15):
        add('remove_slot_'+str(index),ids=tuple(range(16)),localid=8,payload=bytes([255,index]))
    add('remove_head_local_later',ids=(10,20,30),localid=30,payload=b'\xff\x00')
    add('remove_tail',ids=(10,20,30),localid=10,payload=b'\xff\x02')
    assert len(out)>=40
    return out

def initial_memory(c):
    m=bytearray(INITIAL)
    ids=sorted(c['ids'],key=signed)
    assert len(ids)==len(set(ids)) and c['localid'] in ids and EMPTY not in ids
    put(m,A['multioption'],c['mode'],1); put(m,A['numplayers'],len(ids),2)
    put(m,A['myconnectindex'],ids.index(c['localid']),2); put(m,A['connecthead'],0,2)
    put(m,A['myconnectnum'],c['localid']); put(m,A['socket'],c['socket'],2)
    for i in range(16):
        put(m,A['connectnum']+4*i,ids[i] if i<len(ids) else EMPTY)
        m[A['compaddr']+12*i:A['compaddr']+12*i+12]=bytes((i*17+j)&255 for j in range(12)) if i<len(ids) else bytes(12)
        put(m,A['connectpoint2']+2*i,i+1 if i+1<len(ids) else -1,2)
    payload=c['payload']; assert len(payload)<=CAPACITY
    if payload[0]==254 and c['mode']>=5: assert (len(payload)-1)%14==0
    if payload[0]==255 and c['mode']>=5:
        assert payload[1]<len(ids) and ids[payload[1]]!=c['localid'] and len(ids)>1
    m[BUFFER:BUFFER+CAPACITY]=bytes([0x69])*CAPACITY
    m[BUFFER:BUFFER+len(payload)]=payload
    return m

def expected_behavior(c):
    m=initial_memory(c); calls=[]
    def r(k,i=0,w=4): return get(m,A[k]+i,w)
    def w(k,v,i=0,n=4): put(m,A[k]+i,v,n)
    def send(target,length): calls.append(('sendpacket',target&0xffffffff,length,DS+BUFFER,bytes(m[BUFFER:BUFFER+length]).hex()))
    def join(peer,source):
        entries=[(r('connectnum',4*i),bytes(m[A['compaddr']+12*i:A['compaddr']+12*i+12])) for i in range(16)]
        if any(p==peer for p,a in entries): return
        free=next((i for i,(p,a) in enumerate(entries) if p==EMPTY),None)
        if free is None: return
        dest=A['compaddr']+12*free
        calls.append(('memcpy',DS+dest,DS+source,10,bytes(m[source:source+10]).hex()))
        entries[free]=(peer,bytes(m[source:source+10])+pack('<H',c['socket']))
        # Exchange sorting preserves the original unused-slot address bytes too.
        for i in range(1,16):
            for j in range(i):
                if signed(entries[i][0])<signed(entries[j][0]): entries[i],entries[j]=entries[j],entries[i]
        count=r('numplayers',w=2)+1
        w('numplayers',count,n=2); w('connecthead',0,n=2)
        for i,(p,a) in enumerate(entries):
            w('connectnum',p,4*i); m[A['compaddr']+12*i:A['compaddr']+12*i+12]=a
        for i in range(count):
            w('connectpoint2',i+1 if i+1<count else -1,2*i,2)
            if entries[i][0]==c['localid']: w('myconnectindex',i,n=2)
    marker=m[BUFFER]
    if marker==253:
        peer=get(m,BUFFER+1)
        if c['mode']<5:
            w('otherconnectnum',peer); m[BUFFER]=254; send(-1,1)
            w('myconnectindex',0,n=2); w('connecthead',0,n=2)
            w('connectpoint2',1,n=2); w('connectpoint2',-1,2,2); w('numplayers',2,n=2)
        elif peer!=c['localid']:
            join(peer,BUFFER+5)
            local,head=r('myconnectindex',w=2),r('connecthead',w=2)
            if local==head or (r('connectnum',4*head)==peer and r('connectpoint2',2*head,2)==local):
                reply=b'\xfe'+b''.join(pack('<I',r('connectnum',4*i))+bytes(m[A['compaddr']+12*i:A['compaddr']+12*i+10]) for i in range(16) if r('connectnum',4*i) not in (EMPTY,peer))
                m[BUFFER:BUFFER+len(reply)]=reply
                send(-1,len(reply))
                for i in range(16):
                    if r('connectnum',4*i)==peer: send(i,len(reply)); break
    elif marker==254:
        if c['mode']<5:
            w('myconnectindex',1,n=2); w('connecthead',0,n=2)
            w('connectpoint2',1,n=2); w('connectpoint2',-1,2,2); w('numplayers',2,n=2)
        else:
            for offset in range(1,len(c['payload']),14): join(get(m,BUFFER+offset),BUFFER+offset+4)
    elif marker==255 and c['mode']>=5:
        w('connectnum',EMPTY,4*m[BUFFER+1]); w('numplayers',r('numplayers',w=2)-1,n=2)
        active=[i for i in range(16) if r('connectnum',4*i)!=EMPTY]
        w('connecthead',active[0],n=2)
        for i,nxt in zip(active,active[1:]+[-1]): w('connectpoint2',nxt,2*i,2)
    return Observation({}, {'DS':bytes(m)},tuple(calls))

def loaded_span(exe,address,size):
    body=bytearray(exe[address+0x25600:address+0x25600+size])
    assert len(body)==size
    for site,target in pointer_range(read_le_fixups(exe)['pointers'],address,size).items(): body[site:site+4]=pack('<I',target)
    return bytes(body)

HELPERS=None
def exercise(body,c):
    machine=Machine(CONTRACT,body,[Region('DS',DS,DATA_SIZE)])
    for address,helper in HELPERS: machine.add_code(address,helper)
    machine.write(DS,initial_memory(c))
    def memcpy(m):
        dest,source,count=(m.register(k) for k in ('eax','edx','ebx'))
        assert count==10 and DS+A['compaddr']<=dest<=DS+A['compaddr']+15*12
        assert DS+BUFFER<=source and source+count<=DS+BUFFER+CAPACITY
        data=m.read(source,count); m.record('memcpy',dest,source,count,data.hex()); m.write(dest,data)
        return {'eax':0xaabbccdd}
    def send(m):
        target,length,pointer=(m.register(k) for k in ('eax','ebx','edx'))
        assert target==0xffffffff or target<16
        assert pointer==DS+BUFFER and 1<=length<=CAPACITY
        m.record('sendpacket',target,length,pointer,m.read(pointer,length).hex())
        return dict(eax=0xaabbccdd,ebx=0xdeadbeef,edx=0x98765432)
    machine.stub(0x63245,memcpy); machine.stub(F['sendpacket_'],send)
    return machine.run(dict(eax=len(c['payload']),edx=DS+BUFFER,ebx=0x12345678,ecx=0x87654321,esi=0x23456789,edi=0x3456789a,ebp=0x456789ab,eflags=0x202))

def main():
    global HELPERS
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--exe',type=Path,required=True); p.add_argument('--object',type=Path,required=True); p.add_argument('--output',type=Path)
    args=p.parse_args(); exe=args.exe.read_bytes(); obj=args.object.read_bytes()
    assert sha(exe)==TARGET_SHA256,'pinned executable hash mismatch'
    reference,candidate,fixups=bind_bodies(exe,obj,'processreservedmessage_',ENTRY,SIZE,BINDINGS,F,data_base=DS)
    assert len(reference)==len(candidate)==SIZE and reference==candidate
    assert fixups==27, 'expected 27 LE sites'
    HELPERS=[(0x42319,loaded_span(exe,0x42319,374)),(0x4248f,loaded_span(exe,0x4248f,93))]
    report=dict(fixture='processreservedmessage',status='FAIL',inventory_eligible=False,exact_verified=True,
        reference_sha256=sha(exe),candidate_object_sha256=sha(obj),candidate_bytes=SIZE,
        candidate_absolute_fixups=fixups,data_bytes_compared=DATA_SIZE,
        preserved_registers=list(CONTRACT.preserved),cases=[],
        helper_contracts=dict(netinitconnection='Actual pinned 374-byte code including shared return at 0x42486',netuninitconnection='Actual pinned 93-byte code',memcpy='Copies ten bytes; modifies EAX only',sendpacket='Records target, length and wire bytes; modifies EAX/EBX/EDX only'),
        model_scope='Bounded 225-byte initialized packets; signed 32-bit peer ordering; aligned 14-byte FE records; valid player slots; removals leave local connected; complete DS and preserved registers')
    try:
        selected=cases()
        assert len(selected)==70
        for c in selected:
            expected=expected_behavior(c)
            for label,body in [('original',reference),('candidate',candidate)]:
                observed=exercise(body,c); difference=first_difference(expected,observed)
                assert not difference,'%s %s: %s'%(label,c['name'],difference)
            report['cases'].append(dict(name=c['name'],status='PASS',ds_sha256=sha(observed.memory['DS']),trace_sha256=sha(repr(observed.calls).encode())))
        mutations=[]
        for name,pattern,index,value,case in [
            ('wrong_fd_marker',b'\x3c\xfd',1,252,selected[0]),
            ('wrong_transport_split',b'\x83\xf8\x05',2,4,next(c for c in selected if c['name']=='transport_4_marker_253')),
            ('wrong_fe_record_stride',b'\x83\xc1\x0e',2,13,next(c for c in selected if c['payload']==listpacket((30,40)) and c['mode']==5))]:
            altered=bytearray(reference); at=altered.index(pattern); altered[at+index]=value
            mutations.append((name,bytes(altered),case))
        report['negative_controls_detected']=require_mutations_detected('processreservedmessage',reference,mutations,exercise)
        report['status']='PASS'
    except Exception as error:
        report['failure']=str(error); raise
    finally:
        report['cases_passed']=len(report['cases'])
        if args.output: args.output.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({k:v for k,v in report.items() if k!='cases'},indent=2))
if __name__=='__main__': main()

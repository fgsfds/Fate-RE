"""Drive the START.MAP door through melee and matching sequence routines."""
import argparse
import hashlib
import json
from pathlib import Path
import struct

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import *

import bind_melee_group as melee
import check_initksqrt as init
import check_ksqrt as sqrt
import check_start_sequence as sequence
import verify_advance_sequences as advance
import verify_init_object_sequences as descriptors
import verify_runtime_rand as random
from check_start_barrels import map_arrays, ART_SHA256
from check_start_hook import image
from check_move_listed_sprite import map_evidence
from le_fixups import read_le_fixups
from verify_assembly_suite import (
    START_SEQUENCE_POINTERS, HITSCAN_POINTERS,
)
from verify_c_leaf import (
    bind_leaf_details, verify_leaf_relocations, DATA_OFFSETS, FUNCTION_ADDRESSES,
)

DOOR = 0x2840a0+44*44


def check(exe, objects, binaries, inventory, archive, rand_object, map_path, art=None, *, reconstructed_hitscan=False):
    if reconstructed_hitscan and art is None:
        raise ValueError('Reconstructed hitscan requires the door ART fixture')
    map_hash = map_evidence(map_path)['sha256']
    sectors, walls, sprites = map_arrays(map_path.read_bytes())
    initializer, tail = init.verified_code(exe,binaries,inventory,
                                           (objects/'transcol.obj').read_bytes(),
                                           (objects/'sqrtinit.obj').read_bytes())
    pointers = read_le_fixups(exe)['pointers']
    melee_obj = (objects/'melee.obj').read_bytes()
    raw,data,code,_ = melee.bind(melee_obj)
    assert raw==exe[0x3616f:0x3633a]
    verify_leaf_relocations(raw,data|code,pointers,melee.BASE,code_bindings=code)
    advance_obj = (objects/'advance.obj').read_bytes()
    raw,refs = advance.bind(advance_obj)
    assert raw==exe[0x379d6:0x37aa1]
    verify_leaf_relocations(raw,refs,pointers,advance.ADDRESS)
    append_obj = (objects/'add.obj').read_bytes()
    raw,refs = sequence.bind_append(append_obj)
    assert raw==exe[0x38ac2:0x38b1a]
    verify_leaf_relocations(raw,refs,pointers,0x134c2)
    sqrt_obj = (objects/'ksqrt.obj').read_bytes()
    sqrt.verify(exe,sqrt_obj)
    sqrt_code,_ = bind_leaf_details(sqrt_obj,'ksqrt_',{'_sqrtable':init.TABLE},address=sqrt.ADDRESS)
    rows_obj = (objects/'initseq.obj').read_bytes()
    descriptors.verify(exe,rows_obj)
    rows = descriptors.compiled_descriptors(rows_obj)
    starter = bytearray((binaries/'startseq.bin').read_bytes())
    for site,target in START_SEQUENCE_POINTERS.items():
        struct.pack_into('<I',starter,site,target)
    bodies = {
        melee.BASE:melee.bind(melee_obj,loaded=True)[0], init.ENTRY:initializer, init.TAIL:tail,
        sqrt.ADDRESS:sqrt_code, sequence.ADDRESS:bytes(starter),
        advance.ADDRESS:advance.bind(advance_obj,loaded=True)[0],
        0x134c2:sequence.bind_append(append_obj,loaded=True)[0],
        random.ADDRESS:random.bind(exe,archive,rand_object),
    }
    if art is not None:
        if hashlib.sha256(art).hexdigest()!=ART_SHA256:
            raise ValueError('Unknown door ART')
        original = image(exe)
        original_hitscan = original[0x50f15:0x51fc1]
        if reconstructed_hitscan:
            hitscan = bytearray((binaries/'hitscan.bin').read_bytes())
            for site, target in HITSCAN_POINTERS.items():
                struct.pack_into('<I', hitscan, site, target)
            assert hitscan == original_hitscan
            bodies[0x50f15] = bytes(hitscan)
        else:
            bodies[0x50f15] = original_hitscan
        for symbol,filename,address,size in (
            ('inside_','inside',0x4c88f,189),('drawline256_','editor16',0x5446b,1123),
            ('rintersect_','rinterc',0x5272c,246),
            ('getzsofslope_','slopepr',0x5e07a,301),
        ):
            obj = (objects/(filename+'.obj')).read_bytes()
            raw,refs = bind_leaf_details(obj,symbol,DATA_OFFSETS,address=address,
                                         functions=FUNCTION_ADDRESSES)
            assert len(raw)==size and raw==exe[address+0x25600:address+0x25600+size]
            verify_leaf_relocations(raw,refs,pointers,address)
            if symbol in ('inside_', 'getzsofslope_'):
                bodies[address] = bind_leaf_details(
                    obj,symbol,{k:v+0x80000 for k,v in DATA_OFFSETS.items()},
                    address=address,functions=FUNCTION_ADDRESSES)[0]
            elif symbol=='rintersect_':
                bodies[address] = raw
            else:
                bodies[0x548c8] = raw[0x45d:]
    machine = Uc(UC_ARCH_X86,UC_MODE_32)
    machine.mem_map(0x10000,0x3f0000)
    for address,body in bodies.items():
        machine.mem_write(address,body)

    def put(fmt,address,*values):
        machine.mem_write(address,struct.pack('<'+fmt,*values))

    def get(fmt,address):
        return struct.unpack('<'+fmt,machine.mem_read(address,struct.calcsize(fmt)))[0]

    door = sprites[44*44:45*44]
    x,y,z = struct.unpack_from('<3i',door)
    sect = struct.unpack_from('<h',door,24)[0]
    assert sect==28 and struct.unpack_from('<h',door,38)[0]==28<<8
    machine.mem_write(0x2fc3a0,sectors)
    if art is not None:
        machine.mem_write(0x2b10a0,walls)
        machine.mem_write(0x30891e,struct.pack('<h',-1)*(len(sectors)//40))
        put('h',0x30891e+2*sect,44)
        put('h',0x279ca0+88,-1)
        _,_,first,last = struct.unpack_from('<4i',art)
        count = last-first+1
        for tile in (1515,1516,1517,1518,1519,1520,1521):
            i = tile-first
            put('H',0x272020+2*tile,struct.unpack_from('<H',art,16+2*i)[0])
            put('H',0x274020+2*tile,struct.unpack_from('<H',art,16+2*count+2*i)[0])
            put('I',0x26d3a0+4*tile,struct.unpack_from('<I',art,16+4*count+4*i)[0])
        put('h',0x2b00a0+2*1536,-16384)
        put('h',0x2b00a0+2*1024,0)
    machine.mem_write(DOOR-4,b'left'+door+b'edge')
    for index,row in rows.items():
        values = [row[k] for k in ('start','end','final','next')]+row['debris']+row['sounds']
        put('60h',0xe807c+120*int(index),*values)
    put('h',0xfdee6,1)
    put('H',0xdac8f,2<<13)
    put('h',0xdacfc,sect)
    put('h',0xe2f8c,100)
    put('h',0xf09dc+88,-1)
    put('h',0x2b00a0+1024,16384)
    if art is not None:
        put('h',0xe308c,512)
    put('i',0xdad5c,y)
    put('i',0xdad1c,z-4096)
    model = {'distance':128,'seed':0}
    calls = []
    punches = []
    hit_outputs = []
    pending_hits = {}
    intersections = 0

    def hook(_,address,size,data):
        nonlocal intersections
        if art is not None and address==0x5272c:
            intersections += 1
        if address in pending_hits:
            outputs = pending_hits.pop(address)
            hit_outputs.append([get(fmt,ptr) for fmt,ptr in zip(('h','h','h','i','i','i'),outputs)])
        if art is not None and address==0x50f15:
            sp = machine.reg_read(UC_X86_REG_ESP)
            pending_hits[get('I',sp)] = struct.unpack('<9I',machine.mem_read(sp+4,36))[3:]
        if address==0x602d0:
            model['seed'] = (model['seed']*1103515245+12345)&0xffffffff
            calls.append(['rand',model['seed']>>16&32767])
        if any(a<=address<a+len(body) for a,body in bodies.items()):
            return
        sp = machine.reg_read(UC_X86_REG_ESP)
        eax,edx,ebx,ecx = [machine.reg_read(r) for r in (
            UC_X86_REG_EAX,UC_X86_REG_EDX,UC_X86_REG_EBX,UC_X86_REG_ECX)]
        cleanup = 0
        if address==0x50f15:
            assert (eax,edx,ebx,ecx)==((x-model['distance'])&0xffffffff,y,z-2048,sect)
            args = struct.unpack('<9I',machine.mem_read(sp+4,36))
            assert args[:3]==(512,0,0)
            for fmt,ptr,value in zip(('h','h','h','i','i','i'),args[3:],(sect,-1,44,x,y,z-2048)):
                put(fmt,ptr,value)
            cleanup = 36
        elif address==0x34f79:
            assert (edx,ebx,ecx)==(x&0xffffffff,y,2)
            calls.append(['sound',eax])
        elif address==0x11073:
            assert bytes(machine.mem_read(edx,12))==struct.pack('<3i',x,y,z)
            assert ebx==sect
            index = 100+sum(c[0]=='spawn' for c in calls)
            calls.append(['spawn',eax,index])
            machine.mem_write(0x2840a0+44*index,bytes(44))
            machine.reg_write(UC_X86_REG_EAX,index)
        elif address==0x339b9:
            assert eax>=100 and ecx==0
            cleanup = 12
        else:
            raise AssertionError(f'Unexpected executed address {address:#x}')
        machine.reg_write(UC_X86_REG_ESP,sp+4+cleanup)
        machine.reg_write(UC_X86_REG_EIP,get('I',sp))

    machine.hook_add(UC_HOOK_CODE,hook)
    def run(address):
        saved = (UC_X86_REG_EBX,UC_X86_REG_ECX,UC_X86_REG_EDX,
                 UC_X86_REG_ESI,UC_X86_REG_EDI,UC_X86_REG_EBP)
        for reg in saved:
            machine.reg_write(reg,0x13570000)
        put('I',init.STACK,init.STOP)
        machine.reg_write(UC_X86_REG_ESP,init.STACK)
        machine.emu_start(address,init.STOP,count=500000)
        assert machine.reg_read(UC_X86_REG_EIP)==init.STOP
        assert machine.reg_read(UC_X86_REG_ESP)==init.STACK+4
        assert all(machine.reg_read(r)==0x13570000 for r in saved)
        assert get('I',random.SEED+0x80000)==model['seed']

    def punch(seed,distance=128,mapping=-1):
        model.update(seed=seed,distance=distance)
        put('I',random.SEED+0x80000,seed)
        put('i',0xdad9c,x if art is not None else x-distance)
        if art is not None:
            put('i',0xdad5c,y-distance)
        put('h',0xf09dc+88,mapping)
        run(melee.ENTRY)
        punches.append(dict(seed=seed,distance=distance,mapping=mapping,state=state()))

    def state():
        return [get('h',DOOR+14),get('H',DOOR+38)>>8,get('h',0xfdee0)]

    run(init.ENTRY)
    trace = [state()]
    for seed,distance,mapping in ((4,351,-1),(1,128,-1),(4,128,0),(4,350,-1),(4,128,-1)):
        punch(seed,distance,mapping)
        trace.append(state())
    run(advance.ADDRESS)
    trace.append(state())
    punch(4)
    trace.append(state())
    for _ in range(5):
        run(advance.ADDRESS)
        trace.append(state())
    assert trace==[[1515,28,0]]*4+[[1516,28,1]]*2+[[1516,29,0],
                   [1517,29,1],[1518,29,1],[1519,29,1],[1520,29,1],[1521,29,1],[1521,0,0]], (trace,hit_outputs)
    expected = bytearray(door)
    struct.pack_into('<h',expected,14,1521)
    struct.pack_into('<h',expected,38,0)
    assert machine.mem_read(DOOR-4,52)==b'left'+bytes(expected)+b'edge'
    if art is not None:
        assert not pending_hits and len(hit_outputs)==len(punches)
        assert intersections>=len(punches)
        assert machine.mem_read(0x2b10a0,len(walls))==walls
        assert machine.mem_read(0x2fc3a0,len(sectors))==sectors
        for hit,punch_data in zip(hit_outputs,punches):
            assert hit==[sect,-1,44,x,y,z-2048], (hit,punch_data)
    interfaces = ['sound','debris spawn','debris movement']
    if art is None:
        interfaces.insert(0,'hitscan')
    report = dict(map_sha256=map_hash,sprite=44,punches=punches,trace=trace,calls=calls,
                  original_hitscan=art is not None and not reconstructed_hitscan,
                  hits=hit_outputs, fixture_interfaces=interfaces)
    if reconstructed_hitscan:
        report['reconstructed_hitscan'] = True
    if art is not None:
        report.update(art_sha256=ART_SHA256, ray_intersection_calls=intersections)
    return report


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('executable','objects','assembly','c_inventory','archive','rand_object','map'):
        parser.add_argument(name,type=Path)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--art',type=Path)
    parser.add_argument('--reconstructed-hitscan',action='store_true')
    args = parser.parse_args()
    report = check(args.executable.read_bytes(),args.objects,args.assembly,
                   json.loads(args.c_inventory.read_text(encoding='utf-8')),
                   args.archive.read_bytes(),args.rand_object.read_bytes(),args.map,
                   args.art.read_bytes() if args.art else None,
                   reconstructed_hitscan=args.reconstructed_hitscan)
    args.output.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print('PASS: START.MAP door 44, melee gates and both sequence stages')

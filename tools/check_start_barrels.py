"""Run the matched movement chain on three START.MAP barrel placements."""
import argparse
import hashlib
import json
from pathlib import Path
import struct

from unicorn import UC_HOOK_CODE
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
    UC_X86_REG_EIP, UC_X86_REG_ESP, UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP,
)
from check_clipmove_oracle import STACK, STOP
from check_move_listed_sprite import ADDRESS, APPEND_ADDRESS, map_evidence
from check_move_collision import install, SECTORS, WALLS, SPRITES, HEADS, NEXT, PREV, words

ART_SHA256 = 'be7f38f5a4bb0eeaaa1487f0881a0a0817a70582f60583521ca8ee479ab8aa1c'


def map_arrays(blob):
    offset = 20
    for size in (40, 32, 44):
        count = struct.unpack_from('<H', blob, offset)[0]
        offset += 2
        end = offset+count*size
        yield blob[offset:end]
        offset = end


def check(exe, historical, objects, binaries, inventory, map_path, art):
    evidence = map_evidence(map_path)
    if hashlib.sha256(art).hexdigest()!=ART_SHA256:
        raise ValueError('Unknown barrel ART')
    _,_,first,last = struct.unpack_from('<4i',art)
    tile = 1362
    height = struct.unpack_from('<H',art,16+2*(last-first+1)+2*(tile-first))[0]
    assert height==65
    sectors,walls,sprites = map_arrays(map_path.read_bytes())
    machine,ranges = install(exe,historical,objects,binaries,inventory)
    machine.mem_write(SECTORS,sectors)
    machine.mem_write(WALLS,walls)
    machine.mem_write(0x309154,words(len(sectors)//40))
    machine.mem_write(0x274020+2*tile,words(height))
    visited = set()

    def guard(_,address,size,data):
        assert any(a<=address<b for a,b in ranges),hex(address)
        visited.add(address)

    machine.hook_add(UC_HOOK_CODE,guard)
    saved = (UC_X86_REG_ECX,UC_X86_REG_ESI,UC_X86_REG_EDI,UC_X86_REG_EBP)
    cases = []
    for index,dx,dy in ((47,128,0),(69,-128,0),(70,0,-128)):
        record = bytearray(sprites[index*44:(index+1)*44])
        x,y,z,cstat,picnum = struct.unpack_from('<3i2H',record)
        sector = struct.unpack_from('<h',record,24)[0]
        assert picnum==tile and sector==168 and record[21]==37
        # Reproduce the observed initialization fields for this one sprite.
        z -= height*record[21]*2
        struct.pack_into('<iH',record,8,z,cstat|0x181)
        address = SPRITES+44*index
        machine.mem_write(address-4,b'left'+bytes(record)+b'edge')
        machine.mem_write(HEADS,words(-1)*(len(sectors)//40))
        machine.mem_write(HEADS+2*sector,words(index))
        for links in (NEXT,PREV):
            machine.mem_write(links+2*index,words(-1))
        machine.mem_write(0x82be8,words(0))
        machine.mem_write(STACK,struct.pack('<I',STOP))
        machine.reg_write(UC_X86_REG_ESP,STACK)
        machine.reg_write(UC_X86_REG_EAX,index)
        machine.reg_write(UC_X86_REG_EDX,(dx<<15)&0xffffffff)
        machine.reg_write(UC_X86_REG_EBX,(dy<<15)&0xffffffff)
        for reg in saved:
            machine.reg_write(reg,0x13570000)
        visited.clear()
        machine.emu_start(ADDRESS,STOP,count=40000)
        assert machine.reg_read(UC_X86_REG_EIP)==STOP
        assert machine.reg_read(UC_X86_REG_ESP)==STACK+4
        assert all(machine.reg_read(reg)==0x13570000 for reg in saved)
        struct.pack_into('<2i',record,0,x+dx,y+dy)
        actual = machine.mem_read(address-4,52)
        assert actual==b'left'+bytes(record)+b'edge', (index,struct.unpack_from('<3i',actual,4))
        assert 0x562f9 in visited and 0x5291f in visited and APPEND_ADDRESS not in visited
        assert machine.mem_read(0x82be8,2)==words(0)
        assert machine.mem_read(HEADS+2*sector,2)==words(index)
        assert machine.mem_read(SECTORS,len(sectors))==sectors
        assert machine.mem_read(WALLS,len(walls))==walls
        cases.append(dict(sprite=index,sector=sector,position=[x+dx,y+dy,z],appended=False))
    return dict(map_sha256=evidence['sha256'],art_sha256=ART_SHA256,
                fixture='one initialized barrel at a time, original sector and wall records',
                cases=cases)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('executable','historical_object','objects','assembly','c_inventory','map','art'):
        parser.add_argument(name,type=Path)
    parser.add_argument('--output',type=Path,required=True)
    args = parser.parse_args()
    report = check(args.executable.read_bytes(),args.historical_object.read_bytes(),
                   args.objects,args.assembly,json.loads(args.c_inventory.read_text(encoding='utf-8')),
                   args.map,args.art.read_bytes())
    args.output.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print('PASS: START.MAP barrels 47, 69 and 70')

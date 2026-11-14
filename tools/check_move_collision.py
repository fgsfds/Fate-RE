"""Exercise matched movable-sprite code with FATE collision dependencies."""
import argparse
import json
from pathlib import Path
import struct

from unicorn import UC_HOOK_CODE
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX, UC_X86_REG_ESP,
    UC_X86_REG_EIP, UC_X86_REG_ECX, UC_X86_REG_ESI, UC_X86_REG_EDI,
    UC_X86_REG_EBP,
)

import check_move_listed_sprite as move
import check_spritechange as change
from check_clipmove_oracle import setup, STACK, STOP
from check_spritelists import relocated_list
from le_fixups import read_le_fixups
from verify_c_leaf import (
    bind_leaf_details, verify_leaf_relocations, DATA_OFFSETS, FUNCTION_ADDRESSES,
)
from verify_historical_zrange import ENTRY as ZRANGE, bind_verified as bind_historical_zrange
from verify_assembly_suite import COMBINED_SLOPE_POINTERS, GETZRANGE_POINTERS

SECTORS, WALLS, SPRITES = 0x2fc3a0, 0x2b10a0, 0x2840a0
HEADS, FREE, PREV, NEXT = 0x30891e, 0x30911e, 0x276020, 0x279ca0


def words(*values):
    return struct.pack('<'+'h'*len(values), *values)


def install(exe, historical, objects, binaries, inventory):
    machine, ranges = setup(exe, historical, objects, binaries, inventory, compiled=True)
    movement = (objects/'movelist.obj').read_bytes()
    move.verify(exe, movement)
    append = (objects/'add.obj').read_bytes()
    raw, refs = move.bind_append(append)
    assert raw == exe[0x38ac2:0x38b1a]
    fixups = read_le_fixups(exe)['pointers']
    verify_leaf_relocations(raw, refs, fixups, move.APPEND_ADDRESS)
    change_blob = (objects/'sprchang.obj').read_bytes()
    change.verify(exe, change_blob)
    change_code, _ = bind_leaf_details(
        change_blob, 'changespritesect_', {k:v+0x80000 for k,v in change.DATA.items()},
        address=0x50bc3, functions=change.FUNCTIONS,
    )
    historical_vertical, _ = bind_historical_zrange(exe, historical)
    vertical = bytearray((binaries/'getzrange.bin').read_bytes())
    assert vertical == historical_vertical
    for site, target in GETZRANGE_POINTERS.items():
        struct.pack_into('<I', vertical, site, target)
    slope = bytearray((binaries/'slopepair.bin').read_bytes())
    for site,target in COMBINED_SLOPE_POINTERS.items():
        struct.pack_into('<I', slope, site, target)
    editor, refs = bind_leaf_details(
        (objects/'editor16.obj').read_bytes(), 'drawline256_', DATA_OFFSETS,
        address=0x5446b, functions=FUNCTION_ADDRESSES,
    )
    assert len(editor)==1123 and editor==exe[0x79a6b:0x79ece]
    verify_leaf_relocations(editor, refs, fixups, 0x5446b)
    bodies = {
        move.ADDRESS: move.bind(movement, loaded=True)[0],
        move.APPEND_ADDRESS: move.bind_append(append, loaded=True)[0],
        0x50bc3: change_code,
        0x508cd: relocated_list('insertspritesect_', binaries),
        0x50a1d: relocated_list('deletespritesect_', binaries),
        ZRANGE: bytes(vertical), 0x5e07a: bytes(slope), 0x548c8: editor[0x45d:],
    }
    for address, body in bodies.items():
        machine.mem_write(address, body)
    return machine, ranges+tuple((a,a+len(b)) for a,b in bodies.items())


def check(exe, historical, objects, binaries, inventory):
    machine, ranges = install(exe, historical, objects, binaries, inventory)
    visited = set()

    def guard(_, address, size, data):
        assert any(a<=address<b for a,b in ranges), hex(address)
        visited.add(address)

    machine.hook_add(UC_HOOK_CODE, guard)
    saved = (UC_X86_REG_ECX, UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
    machine.mem_write(0x309154, words(2))
    machine.mem_write(0x274020+10, words(32))
    rows = []
    for portal, dx, dy, target in (
        (True, 256, 0, (1156,0,1)),
        (False, 256, 0, (989,0,0)),
        (False, 256, 128, (989,128,0)),
        (True, -128, 32, (772,32,0)),
    ):
        walls = bytearray(8*32)
        coordinates = ((-1024,-1024),(1024,-1024),(1024,1024),(-1024,1024),
                       (1024,-1024),(3072,-1024),(3072,1024),(1024,1024))
        for i,(x,y) in enumerate(coordinates):
            neighbor = {1:(7,1),7:(1,0)}.get(i,(-1,-1)) if portal else (-1,-1)
            struct.pack_into('<2i3h', walls,i*32,x,y,(i//4)*4+(i+1)%4,*neighbor)
        machine.mem_write(WALLS,bytes(walls))
        for clearance in (0, 1, 4096):
            sectors = bytearray(80)
            for i in (0,1):
                struct.pack_into('<2h2i',sectors,40*i,4*i,4,-12000,512+clearance)
            machine.mem_write(SECTORS,bytes(sectors))
            machine.mem_write(HEADS,words(0,-1))
            machine.mem_write(FREE,words(-1))
            machine.mem_write(PREV,words(-1))
            machine.mem_write(NEXT,words(-1))
            record = bytearray(44)
            struct.pack_into('<3i2h',record,0,900,0,0,1,5)
            record[18], record[21] = 17, 8
            struct.pack_into('<h',record,38,100)
            machine.mem_write(SPRITES-4,b'left'+bytes(record)+b'edge')
            machine.mem_write(0x82be8,words(0))
            machine.mem_write(0xefcbe,words(-1))
            machine.mem_write(STACK,struct.pack('<I',STOP))
            for reg in saved:
                machine.reg_write(reg,0x13570000)
            machine.reg_write(UC_X86_REG_EAX,0)
            machine.reg_write(UC_X86_REG_EDX,(dx<<15)&0xffffffff)
            machine.reg_write(UC_X86_REG_EBX,(dy<<15)&0xffffffff)
            machine.reg_write(UC_X86_REG_ESP,STACK)
            visited.clear()
            machine.emu_start(move.ADDRESS,STOP,count=30000)
            assert machine.reg_read(UC_X86_REG_EIP)==STOP
            assert machine.reg_read(UC_X86_REG_ESP)==STACK+4
            assert all(machine.reg_read(reg)==0x13570000 for reg in saved)
            x,y,sector = target
            struct.pack_into('<2i',record,0,x,y)
            struct.pack_into('<h',record,24,sector)
            if clearance:
                struct.pack_into('<3H',record,32,(dx<<7)&0xffff,(dy<<7)&0xffff,100)
                struct.pack_into('<h',record,42,0x5000)
            actual = machine.mem_read(SPRITES-4,52)
            assert actual==b'left'+bytes(record)+b'edge', (
                portal, dx, dy, clearance, struct.unpack_from('<3i',actual,4))
            assert machine.mem_read(HEADS,4)==(words(-1,0) if sector else words(0,-1))
            for address in (FREE,PREV,NEXT):
                assert machine.mem_read(address,2)==words(-1)
            assert machine.mem_read(0x82be8,2)==words(int(bool(clearance)))
            assert machine.mem_read(0xefcbe,2)==words(0 if clearance else -1)
            assert ZRANGE in visited and (0x50bc3 in visited)==bool(sector)
            assert (move.APPEND_ADDRESS in visited)==bool(clearance)
            assert machine.mem_read(SECTORS,80)==bytes(sectors)
            assert machine.mem_read(WALLS,256)==bytes(walls)
            rows.append(dict(portal=portal, displacement=[dx,dy], clearance=clearance,
                             final_position=[x,y,0], sector=sector, appended=bool(clearance)))
    return rows


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('executable','historical_object','objects','assembly','c_inventory'):
        parser.add_argument(name,type=Path)
    parser.add_argument('--output',type=Path,required=True)
    args = parser.parse_args()
    rows = check(args.executable.read_bytes(),args.historical_object.read_bytes(),
                 args.objects,args.assembly,json.loads(args.c_inventory.read_text(encoding='utf-8')))
    args.output.write_text(json.dumps(rows,indent=2)+'\n',encoding='utf-8')
    print(f'PASS: {len(rows)} movable-sprite cases with exact collision dependencies')

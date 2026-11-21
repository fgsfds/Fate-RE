"""Exercise original clipmove with verified collision dependencies."""
import argparse
import json
from pathlib import Path
import struct

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import *

from check_initksqrt import verified_code
from check_start_hook import image
from le_fixups import read_le_fixups
from verify_assembly_suite import (
    CLIPMOVE_POINTERS, GETCLIPLINES_POINTERS,
)
from verify_c_leaf import (
    LEAVES, DATA_OFFSETS, FUNCTION_ADDRESSES, bind_leaf_details,
    verify_leaf_relocations,
)
from verify_historical_cliplines import ENTRY as LINES, bind_verified

ENTRY, END, STACK, STOP = 0x5291f, 0x52c88, 0x3ff000, 0x3fff00
COORDS = 0x350004


def setup(exe, historical, objects, binaries, inventory, compiled=False):
    original = image(exe)
    init, init_tail = verified_code(exe, binaries, inventory,
                                    (objects/'transcol.obj').read_bytes(),
                                    (objects/'sqrtinit.obj').read_bytes())
    if compiled:
        lines = bytearray((binaries/'getcliplines.bin').read_bytes())
        pointers = GETCLIPLINES_POINTERS
    else:
        historical_code, ds_offsets = bind_verified(exe, historical)
        lines = bytearray(historical_code)
        pointers = {site: offset+0x80000 for site, offset in ds_offsets.items()}
    for site, target in pointers.items():
        struct.pack_into('<I', lines, site, target)
    code = {
        ENTRY: original[ENTRY:END], LINES: bytes(lines),
        0x4caaa: init, 0x4abbf: init_tail,
        0x4c944: original[0x4c944:0x4c94c],
        0x51fbb: (binaries/'hitscan.bin').read_bytes()[-6:],
        0x47f04: (binaries/'ceilscan.bin').read_bytes()[-8:],
    }
    if compiled:
        body = bytearray((binaries/'clipmove.bin').read_bytes())
        for site,target in CLIPMOVE_POINTERS.items():
            struct.pack_into('<I',body,site,target)
        code[ENTRY] = bytes(body)
    for symbol, filename in (('inside_','inside'),('addclipline_','clipadd'),
                             ('raytrace_','raytrace'),('clipinsideboxline_','clipline'),
                             ('keepaway_','keepaway'),('rintersect_','rinterc'),
                             ('getceilzofslope_','slphgt'),('getflorzofslope_','slphgt')):
        raw, size = LEAVES[symbol]
        address = raw-0x25600
        blob = (objects/(filename+'.obj')).read_bytes()
        body, refs = bind_leaf_details(blob,symbol,DATA_OFFSETS,
                                       address=address,functions=FUNCTION_ADDRESSES)
        assert len(body)==size and body==exe[raw:raw+size]
        verify_leaf_relocations(body,refs,read_le_fixups(exe)['pointers'],address)
        code[address], _ = bind_leaf_details(
            blob,symbol,{name:value+0x80000 for name,value in DATA_OFFSETS.items()},
            address=address,functions=FUNCTION_ADDRESSES)
    machine = Uc(UC_ARCH_X86,UC_MODE_32)
    machine.mem_map(0x10000,0x3f0000)
    for address,body in code.items():
        machine.mem_write(address,body)
    machine.mem_write(STACK,struct.pack('<I',STOP))
    machine.reg_write(UC_X86_REG_ESP,STACK)
    machine.emu_start(0x4caaa,STOP,count=500000)
    assert machine.reg_read(UC_X86_REG_EIP)==STOP
    return machine,tuple((a,a+len(b)) for a,b in code.items())


def check(exe, historical, objects, binaries, inventory, compiled=False):
    machine, ranges = setup(exe,historical,objects,binaries,inventory,compiled)
    sector = bytearray(40)
    struct.pack_into('<2h2i',sector,0,0,4,-12000,12000)
    machine.mem_write(0x2fc3a0,bytes(sector))
    machine.mem_write(0x30891e,struct.pack('<h',-1))
    machine.mem_write(0x309154,struct.pack('<h',1))
    walls = bytearray(128)
    for i,(x,y) in enumerate(((-1024,-1024),(1024,-1024),(1024,1024),(-1024,1024))):
        struct.pack_into('<2i3h',walls,i*32,x,y,(i+1)%4,-1,-1)
    machine.mem_write(0x2b10a0,bytes(walls))
    visited = set()

    def guard(_,address,size,data):
        assert any(a<=address<b for a,b in ranges),hex(address)
        visited.add(address)

    machine.hook_add(UC_HOOK_CODE,guard)
    saved = (UC_X86_REG_ESI,UC_X86_REG_EDI,UC_X86_REG_EBP)
    count = 0
    scenarios = [
        (origin, (vx,vy), (origin[0]+(vx>>14),origin[1]+(vy>>14)), 0)
        for origin in ((0,0),(120,-200),(-500,450))
        for vx,vy in ((0,0),(1,0),(-1,0),(0,1),(0,-1),
                      (12<<14,34<<14),(-40<<14,-50<<14),(64<<14,0))
    ]
    scenarios.extend(
        (origin,(vx<<14,vy<<14),expected,hit)
        for origin,vx,vy,expected,hit in (
            ((900,0),256,0,(991,0),0x8001),
            ((900,0),256,128,(991,128),0x8001),
            ((0,900),0,256,(0,991),0x8002),
        )
    )
    for origin,(vx,vy),destination,hit in scenarios:
            for mode in (0,1,0x100,0x101):
                start = struct.pack('<3ih',*origin,0,0)
                machine.mem_write(COORDS-4,b'left'+start+b'edge')
                machine.mem_write(STACK,struct.pack('<I2i4I',STOP,vx,vy,32,256,256,mode))
                for reg,offset in zip((UC_X86_REG_EAX,UC_X86_REG_EDX,
                                       UC_X86_REG_EBX,UC_X86_REG_ECX),(0,4,8,12)):
                    machine.reg_write(reg,COORDS+offset)
                for reg in saved:
                    machine.reg_write(reg,0x13570000)
                machine.reg_write(UC_X86_REG_ESP,STACK)
                visited.clear()
                machine.emu_start(ENTRY,STOP,count=20000)
                assert machine.reg_read(UC_X86_REG_EIP)==STOP
                assert machine.reg_read(UC_X86_REG_ESP)==STACK+28
                assert all(machine.reg_read(reg)==0x13570000 for reg in saved)
                assert (LINES in visited)==bool(vx or vy)
                if vx or vy:
                    assert machine.reg_read(UC_X86_REG_EAX)==((hit^0x8000)-0x8000)&0xffffffff
                expected = struct.pack('<3ih',*destination,0,0)
                assert machine.mem_read(COORDS-4,22)==b'left'+expected+b'edge', (
                    origin,vx,vy,struct.unpack('<3ih',machine.mem_read(COORDS,14)))
                assert machine.mem_read(0x2fc3a0,40)==bytes(sector)
                assert machine.mem_read(0x2b10a0,128)==bytes(walls)
                count += 1
    return count


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('executable','historical_object','objects','assembly','c_inventory'):
        parser.add_argument(name,type=Path)
    args = parser.parse_args()
    inputs = (args.executable.read_bytes(),args.historical_object.read_bytes(),
              args.objects,args.assembly,json.loads(args.c_inventory.read_text(encoding='utf-8')))
    original = check(*inputs)
    compiled = check(*inputs,compiled=True)
    assert original == compiled
    print(f'PASS: {original} original and {compiled} reconstructed clipmove fixtures')

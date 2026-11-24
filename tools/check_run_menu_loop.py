"""Exercise the menu-loop machine code with deterministic frame and input stubs."""
import argparse
import json
from pathlib import Path
from struct import pack, unpack

from check_start_hook import image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, bind_leaf_details, verify_leaf_relocations
import verify_c_leaf as v
from unicorn import Uc, UC_ARCH_X86, UC_HOOK_CODE, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDI,
    UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP, UC_X86_REG_EFLAGS,
)

ADDRESS, SIZE, ENTRY_SIZE = 0x3963b, 283, 17
RESET, FRAME, UPDATE, PREVIEW, TAIL = 0x36246, 0x39511, 0x39235, 0x39cfa, 0x386cd
DATA_BASE = 0x80000
STATE, PREVIEW_ENABLED = 0x12dd4, 0x1314d
DEMO_ROWS, SAVE_ROWS, ACTIVE_ROWS = 0x17455c, 0x173fc0, 0x174048
SELECTION, STORAGE, ROW_COUNT, ENABLED_ROWS = 0x1740f0, 0x1740f4, 0x1740f8, 0x1740fc
SELECTION_PTR, NORMAL_ROWS, TITLE = 0x310000, 0x320000, 0x322000
STACK, RETURN = 0x3f0000, 0x3ff000

VOLATILE_ARGS = (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX, UC_X86_REG_ECX)
SAVED_REGS = (UC_X86_REG_EBP, UC_X86_REG_EDI, UC_X86_REG_ESI)


def exercise(body, shared_tail, rows, start, updates):
    engine = Uc(UC_ARCH_X86, UC_MODE_32)
    engine.mem_map(0, 0x400000)
    engine.mem_write(ADDRESS, bytes(body))
    engine.mem_write(TAIL, bytes(shared_tail))
    for target, instruction in ((RESET, b'\xc3'), (FRAME, b'\xc2\x04\x00'),
                                (UPDATE, b'\xc3'), (PREVIEW, b'\xc3')):
        engine.mem_write(target, instruction)

    def read_dword(address):
        return unpack('<I', engine.mem_read(address, 4))[0]

    def write_data(offset, value):
        engine.mem_write(DATA_BASE + offset, pack('<I', value & 0xffffffff))

    entry_pointers = (0x330000, 0x330100, 0x330200)
    room_count = len(entry_pointers)
    for index, entry in enumerate(entry_pointers):
        engine.mem_write(entry, bytes([int(index != 1)]))
        engine.mem_write(rows + index * 4, pack('<I', entry))
    # Enter with enabled rows left over from a previous menu.
    write_data(ENABLED_ROWS, 0xffffffff)
    engine.mem_write(SELECTION_PTR, pack('<I', start))
    events = []
    input_events = iter(updates)

    def hook(cpu, address, _size, _userdata):
        if address == RESET:
            assert read_dword(DATA_BASE + STORAGE) == SELECTION_PTR
            assert read_dword(DATA_BASE + SELECTION) == start
            assert read_dword(DATA_BASE + ROW_COUNT) == room_count
            assert read_dword(DATA_BASE + ENABLED_ROWS) == 0b101
            assert unpack('<3I', cpu.mem_read(DATA_BASE + ACTIVE_ROWS, 12)) == entry_pointers
            events.append(('reset',))
            cpu.reg_write(UC_X86_REG_EAX, 0x11111111)
        elif address == FRAME:
            selection, count, tile, title = (cpu.reg_read(reg) for reg in VOLATILE_ARGS)
            assert count == room_count and title == TITLE
            assert read_dword(cpu.reg_read(UC_X86_REG_ESP) + 4) == rows
            events.append(('frame', selection, tile))
            for reg in VOLATILE_ARGS:
                cpu.reg_write(reg, 0x22222222)
        elif address == UPDATE:
            selection, state, preview_enabled = next(input_events)
            write_data(SELECTION, selection)
            write_data(STATE, state)
            cpu.mem_write(DATA_BASE + PREVIEW_ENABLED, bytes([preview_enabled]))
            cpu.reg_write(UC_X86_REG_EAX, 0x33333333)
        elif address == PREVIEW:
            events.append(('preview', cpu.reg_read(UC_X86_REG_EAX)))
            cpu.reg_write(UC_X86_REG_EAX, 0x44444444)

    for target in (RESET, FRAME, UPDATE, PREVIEW):
        engine.hook_add(UC_HOOK_CODE, hook, begin=target, end=target)

    incoming = dict(zip(SAVED_REGS, (0x9abc0001, 0x9abc0002, 0x9abc0003)))
    incoming.update(zip(VOLATILE_ARGS, (SELECTION_PTR, room_count, 0xabcdfffe, TITLE)))
    incoming[UC_X86_REG_ESP] = STACK
    for reg, value in incoming.items():
        engine.reg_write(reg, value)
    engine.mem_write(STACK, pack('<II', RETURN, rows) + b'\xa5' * 16)
    engine.emu_start(ADDRESS, RETURN, count=2000)
    assert engine.reg_read(UC_X86_REG_EIP) == RETURN
    assert engine.reg_read(UC_X86_REG_ESP) == STACK + 8
    assert engine.mem_read(STACK + 8, 16) == b'\xa5' * 16
    assert all(engine.reg_read(reg) == incoming[reg] for reg in SAVED_REGS)
    assert next(input_events, None) is None
    return events, engine.reg_read(UC_X86_REG_EAX), read_dword(DATA_BASE + STATE)


def frame_oracle(entry,cleanup):
    """Check the actual entry/cleanup against independent register and frame rules."""
    cases=0
    registers=(UC_X86_REG_EAX,UC_X86_REG_EBX,UC_X86_REG_ECX,UC_X86_REG_EDX,
               UC_X86_REG_ESI,UC_X86_REG_EDI,UC_X86_REG_EBP)
    for seed in range(4):
        for count in (0,1,32,0xfffffff0):
            for flags in (0x202,0x8d7):
                cpu=Uc(UC_ARCH_X86,UC_MODE_32);cpu.mem_map(0,0x400000)
                cpu.mem_write(ADDRESS,entry)
                want={r:0xabc00000+seed*0x101+i for i,r in enumerate(registers)}
                want[UC_X86_REG_EDX]=count
                incoming=dict(want);rows=0x320000+seed*16
                frame=bytearray(bytes((i*73+seed)&255 for i in range(256))*2)
                frame[256:264]=pack('<II',RETURN,rows)
                cpu.mem_write(STACK-256,bytes(frame));expected=bytearray(frame)
                for offset,reg in ((252,UC_X86_REG_ESI),(248,UC_X86_REG_EDI),(244,UC_X86_REG_EBP)):
                    expected[offset:offset+4]=pack('<I',incoming[reg])
                expected[236:240]=pack('<I',count)
                for r,value in incoming.items():cpu.reg_write(r,value)
                cpu.reg_write(UC_X86_REG_ESP,STACK);cpu.reg_write(UC_X86_REG_EFLAGS,flags)
                cpu.emu_start(ADDRESS,ADDRESS+17,count=20)
                want.update({UC_X86_REG_ESI:rows,UC_X86_REG_EDI:incoming[UC_X86_REG_EBX],UC_X86_REG_EBP:incoming[UC_X86_REG_ECX]})
                assert all(cpu.reg_read(r)==value for r,value in want.items())
                assert cpu.reg_read(UC_X86_REG_ESP)==STACK-20
                assert cpu.reg_read(UC_X86_REG_EIP)==ADDRESS+17
                assert cpu.reg_read(UC_X86_REG_EFLAGS)&0xed5==0x10|(flags&0x600)
                assert cpu.mem_read(STACK-256,512)==expected
                cases+=1
    for result in (0,1,0xffffffff):
        cpu=Uc(UC_ARCH_X86,UC_MODE_32);cpu.mem_map(0,0x400000)
        address=ADDRESS+275;cpu.mem_write(address,cleanup)
        want={r:0xabc00000+i for i,r in enumerate(registers)};want[UC_X86_REG_EAX]=result
        for r,value in want.items():cpu.reg_write(r,value)
        frame=b'\xa5'*512;cpu.mem_write(STACK-256,frame)
        cpu.reg_write(UC_X86_REG_ESP,STACK-20);cpu.reg_write(UC_X86_REG_EFLAGS,0x8d7)
        cpu.emu_start(address,address+3,count=2)
        assert cpu.reg_read(UC_X86_REG_ESP)==STACK-12
        assert cpu.reg_read(UC_X86_REG_EIP)==address+3
        assert all(cpu.reg_read(r)==value for r,value in want.items())
        assert cpu.reg_read(UC_X86_REG_EFLAGS)&0xed5==0x10
        assert cpu.mem_read(STACK-256,512)==frame
    return cases,3


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    parser.add_argument('return_object', type=Path, help='normal-return compiler context')
    parser.add_argument('--output',type=Path)
    args = parser.parse_args()

    executable = args.executable.read_bytes()
    obj = args.object.read_bytes()
    unrelocated, refs = bind_leaf_details(
        obj, 'run_menu_loop_', DATA_OFFSETS, address=ADDRESS + ENTRY_SIZE, functions=FUNCTION_ADDRESSES)
    verify_leaf_relocations(unrelocated, refs, read_le_fixups(executable)['pointers'], ADDRESS + ENTRY_SIZE)
    assert len(unrelocated) == 258 and len(refs) == 19
    compiled, _ = bind_leaf_details(
        obj, 'run_menu_loop_', {name: DATA_BASE + offset for name, offset in DATA_OFFSETS.items()},
        address=ADDRESS + ENTRY_SIZE, functions=FUNCTION_ADDRESSES)
    placed=bytearray(SIZE);canonical=bytearray(SIZE);covered=set(range(17,275))
    canonical[17:275]=unrelocated;placed[17:275]=compiled
    return_obj=args.return_object.read_bytes();objects={'menuloop':obj,'mnuret':return_obj}
    phases=[r for r in v.CONTROLLER_PREFIX_LAYOUT['phases'] if r['routine']=='run_menu_loop']
    for phase in phases:
        address=phase['address'];offset=address-ADDRESS;size=phase['end']-phase['begin']
        sites=set(range(offset,offset+size));assert not covered&sites;covered|=sites
        raw,bindings=bind_leaf_details(objects[phase['object']],phase['phase'],DATA_OFFSETS,address=address,functions=FUNCTION_ADDRESSES)
        verify_leaf_relocations(raw,bindings,read_le_fixups(executable)['pointers'],address)
        canonical[offset:offset+size]=raw
        code,_=bind_leaf_details(objects[phase['object']],phase['phase'],{name:DATA_BASE+value for name,value in DATA_OFFSETS.items()},address=address,functions=FUNCTION_ADDRESSES)
        placed[offset:offset+size]=code
    assert covered==set(range(SIZE))
    assert canonical==executable[0x25600+ADDRESS:0x25600+ADDRESS+SIZE]
    compiled=bytes(placed)
    entry_cases,cleanup_cases=frame_oracle(compiled[:17],compiled[275:278])
    private=[]
    for public,blob,size in (('run_menu_loop_',obj,283),('menu_loop_context_',return_obj,284)):
        alias=public+'complete_private_check'
        v.LEAF_CODE_SLICES[alias]=(public,0,size,size)
        try:code,_=bind_leaf_details(blob,alias,{name:DATA_BASE+value for name,value in DATA_OFFSETS.items()},address=ADDRESS,functions=FUNCTION_ADDRESSES)
        finally:del v.LEAF_CODE_SLICES[alias]
        private.append(code)
    from check_ripple_stack import mutate_public_byte
    from check_ripple_control import rename_external
    controls=0
    def rejected(blob,phase,message):
        nonlocal controls
        try:bind_leaf_details(blob,phase['phase'],DATA_OFFSETS,address=phase['address'],functions=FUNCTION_ADDRESSES)
        except ValueError as error:
            assert message in str(error).lower();controls+=1
        else:raise AssertionError('Menu private context mutation escaped')
    first=next(r for r in phases if r['phase']=='run_menu_entry_frame_phase_')
    cleanup=next(r for r in phases if r['object']=='mnuret')
    rejected(mutate_public_byte(obj,'run_menu_loop_',275),first,'context')
    rejected(mutate_public_byte(return_obj,'menu_loop_context_',283),cleanup,'context')
    rejected(rename_external(obj,b'presentation_reset_',b'presentation_reseu_'),first,'fixup')
    digest=v.LEAF_CONTEXT_SHA256.pop('menu_loop_context_')
    try:rejected(mutate_public_byte(return_obj,'menu_loop_context_',28),cleanup,'addend')
    finally:v.LEAF_CONTEXT_SHA256['menu_loop_context_']=digest
    linked = image(executable)
    cases = (
        (NORMAL_ROWS, 2, ((1, -1, 1),),
         ([('reset',), ('frame', 2, 0xfffffffe)], 0, 0)),
        (DATA_BASE + DEMO_ROWS, 0, ((1, 1, 0), (2, 1, 0), (2, 2, 0)),
         ([('reset',), ('frame', 0, 0x874), ('frame', 1, 0x875), ('frame', 2, 0x875)], 1, 2)),
        (DATA_BASE + SAVE_ROWS, 0, ((1, 1, 1), (1, 1, 1), (2, 1, 2), (2, 1, 1), (0, -1, 1)),
         ([('reset',), ('frame', 0, 0xfffffffe), ('preview', 1), ('frame', 1, 0xfffffffe),
           ('frame', 1, 0xfffffffe), ('frame', 2, 0xfffffffe), ('frame', 2, 0xfffffffe), ('preview', 0)],
          0, 0)),
    )
    for rows, initial, updates, expected in cases:
        for body in (linked[ADDRESS:ADDRESS + SIZE], compiled,*private):
            assert exercise(body, linked[TAIL:TAIL + 6], rows, initial, updates) == expected
    result=dict(status='PASS',scenarios=len(cases),reference_executions=len(cases),placed_executions=len(cases),
                private_executions=len(cases)*len(private),entry_frame_cases=entry_cases,cleanup_cases=cleanup_cases,
                context_controls=controls,le_sites=len(refs),c_object_bytes=283,retained_assembly_bytes=0)
    output=args.output or args.object.parent/'menu-loop.json'
    output.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(result))


if __name__ == '__main__':
    main()

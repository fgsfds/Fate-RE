"""Differential and exact checks for the original level-sector puzzle."""
import argparse
import hashlib
import itertools
import json
from pathlib import Path
from struct import pack, unpack

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import *
from check_start_hook import DS, image
from compare_exe import TARGET_SHA256
from le_fixups import read_le_fixups
from verify_c_leaf import (DATA_OFFSETS, FUNCTION_ADDRESSES, LEAF_CODE_SLICES,
                           LEAF_SECTION_BRANCHES, LEAVES, bind_leaf_details,
                           verify_leaf_relocations)
from verify_c_suite import OBJECT_NAMES
from capstone import Cs, CS_ARCH_X86, CS_MODE_32
from capstone.x86_const import X86_OP_IMM

ENTRY, RAW, SIZE = 0x1daea, 0x430ea, 932
STACK, STOP = 0x3ff000, 0x3fff00
SAVED = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
         UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
# Original executable aliases are fixed independently of candidate symbols.
DATA = {
    'sprite_tile': 0x2040ae, 'player_x': 0x5ad9c, 'player_y': 0x5ad5c,
    'last_tile_step': 0x127e8, 'puzzle_solved': 0x127ec,
    'key_sprite_consumed': 0x127f0, 'game_clock': 0x287e88,
    'effect_active': 0x85198, 'previous_effect_active': 0x85194,
    'effect_x': 0x8519c, 'effect_y': 0x851a0,
    'sector_14_lotag': 0x27c5f2, 'sector_15_lotag': 0x27c61a,
    'sector_30_lotag': 0x27c872, 'sector_30_wall_start': 0x27c850,
    'sector_30_wall_count': 0x27c852, 'sector_floor_tile': 0x27c3b8,
    'sector_107_floor_tile': 0x27d470, 'sector_108_floor_tile': 0x27d498,
    'sector_109_floor_tile': 0x27d4c0, 'trigger_count': 0x3be6,
    'trigger_sprite': 0x77124, 'trigger_target': 0x77126,
    'wall_tile': 0x238bf0, 'transition_marker': 0x7deee,
    'destination_level': 0x2040, 'destination_x': 0x7a998,
    'destination_y': 0x7a99c,
}
FUNCS = {'absolute_long_': 0x602c3, 'activate_sector_': 0x28710,
         'remove_sprite_': 0x10f9f, 'spawn_level_effect_': 0x13752}
def s32(x): return ((x + 0x80000000) & 0xffffffff) - 0x80000000
def u32(x): return x & 0xffffffff
def s16(x): return ((x + 32768) & 0xffff) - 32768

def cases():
    out=[]
    # Position selection, strict threshold edges, signed subtraction wrap, and clock wrap.
    positions=[(0x7e6e,0x6408),(0x7e6e+0x3ff,0x6408),(0x7e6e+0x400,0x6408),
      (0x93f6,0x79f7),(0x93f6-0x400,0x79f7),(0x69f8,0x79ea),
      (0x69f8,0x79ea+0x400),(0,0),(0x7fffffff,0x80000000),
      (0x80000000,0x7fffffff)]
    for x,y in positions:
      for delta in (0,0xb4,0xb5):
        out.append(dict(x=s32(x),y=s32(y),clock=180+delta,last=180,solved=0))
    # Probe each selected pad's independent x/y radius at both strict edges.
    for cx,cy in ((0x7e6e,0x6408),(0x93f6,0x79f7),(0x69f8,0x79ea)):
      for dx in (-0x401,-0x400,-0x3ff,0,0x3ff,0x400,0x401):
        out.append(dict(x=cx+dx,y=cy,clock=181,last=0,solved=0))
      for dy in (-0x401,-0x400,-0x3ff,0,0x3ff,0x400,0x401):
        out.append(dict(x=cx,y=cy+dy,clock=181,last=0,solved=0))
    for clock,last in ((0,0xffffffff),(0xb4,0xffffffff),(0xb5,0xffffffff)):
      out.append(dict(x=0x7e6e,y=0x6408,clock=clock,last=last,solved=0))
    for count in (0,1,2):
      out.append(dict(x=0,y=0,clock=181,last=0,solved=1,triggers=[(3,0x4029,0x224)]*count))
    for clock,last in ((181,0),(180,0),(181,1)):
      out.append(dict(x=0x93f6,y=0x79f7,clock=clock,last=last,solved=0))
    for solved in (0,1,2):
      for x,y in ((0x7e6e,0x6408),(0,0)):
        out.append(dict(x=x,y=y,clock=181,last=0,solved=solved))
    # Floor tile advancement, wrap boundary, and solved puzzle completion.
    for tiles in ((0x68e,0x693,0x694),(0x68f,0x693,0x694),
                  (0x68f,0x694,0x694),(0x68f,0x693,0x695),
                  (0x7fff,0x8000,0x1234)):
      out.append(dict(x=0x7e6e,y=0x6408,clock=181,last=0,solved=0,tiles=tiles))
    # Trigger tables include key/exit tags, wrong targets/tiles, signed sprite indices, and bounds.
    trigger_sets=[[],[(3,0x406a,0x20f)],[(4,0x4029,0x224)],
      [(3,0x406a,0x20f),(4,0x4029,0x224)],[(3,0xc06a,0x20f),(4,0xc029,0x224)],
      [(3,0x406a,0),(4,0x4029,0)],[(0,0x406a,0x20f),(1,0x4029,0x224)],
      [(32767,0x406a,0x20f)], [(-1,0x4029,0x224)]]
    for solved,key in itertools.product((0,1),(0,1)):
      for triggers in trigger_sets:
        out.append(dict(x=0x7e6e,y=0x6408,clock=181,last=0,solved=solved,
                        key=key,triggers=triggers))
    return out

def exercise(memory, body, c):
    cpu=Uc(UC_ARCH_X86,UC_MODE_32);cpu.mem_map(0,len(memory));cpu.mem_write(0,memory)
    cpu.mem_write(ENTRY,body)
    def put(off,fmt,val):
        if fmt == 'h': val = s16(val)
        elif fmt == 'H': val &= 0xffff
        elif fmt == 'i': val = s32(val)
        cpu.mem_write(DS+off,pack('<'+fmt,val))
    def get(off,fmt):return unpack('<'+fmt,cpu.mem_read(DS+off,__import__('struct').calcsize('<'+fmt)))[0]
    for off,n in ((DATA['sector_floor_tile'],40*110),(DATA['trigger_sprite'],4*16),
                  (DATA['sprite_tile'],44*16)):
        cpu.mem_write(DS+off,b'\xa5'*n)
    put(DATA['player_x'],'i',c['x']);put(DATA['player_y'],'i',c['y'])
    put(DATA['game_clock'],'I',u32(c['clock']));put(DATA['last_tile_step'],'I',u32(c['last']))
    put(DATA['puzzle_solved'],'i',c.get('solved',0));put(DATA['key_sprite_consumed'],'i',c.get('key',0))
    put(DATA['effect_active'],'i',0);put(DATA['previous_effect_active'],'i',0)
    put(DATA['sector_30_wall_start'],'h',3);put(DATA['sector_30_wall_count'],'h',2)
    tiles=c.get('tiles',(0x68e,0x693,0x694))
    for off,val in zip((DATA['sector_107_floor_tile'],DATA['sector_109_floor_tile'],DATA['sector_108_floor_tile']),tiles):put(off,'h',val)
    triggers=c.get('triggers',[]);put(DATA['trigger_count'],'h',len(triggers))
    for i,(sprite,target,tile) in enumerate(triggers,1):
        put(DATA['trigger_sprite']+4*i,'h',sprite);put(DATA['trigger_target']+4*i,'H',target)
        if sprite>=0:put(DATA['sprite_tile']+44*sprite,'h',tile)
    calls=[]
    def ret(clean=0):
        sp=cpu.reg_read(UC_X86_REG_ESP);target,=unpack('<I',cpu.mem_read(sp,4))
        cpu.reg_write(UC_X86_REG_ESP,sp+4+clean);cpu.reg_write(UC_X86_REG_EIP,target)
    def hook(e,a,size,u):
        if a not in FUNCS.values():return
        name=next(k for k,v in FUNCS.items() if v==a)
        eax=e.reg_read(UC_X86_REG_EAX);edx=e.reg_read(UC_X86_REG_EDX)
        ebx=e.reg_read(UC_X86_REG_EBX);ecx=e.reg_read(UC_X86_REG_ECX)
        if name=='absolute_long_':
            v=s32(eax);res=abs(v) if v!=-0x80000000 else v
            calls.append((name,u32(eax),u32(res)));e.reg_write(UC_X86_REG_EAX,u32(res));ret();return
        if name=='activate_sector_':calls.append((name,eax, get(DATA['sector_14_lotag'],'h'),get(DATA['sector_15_lotag'],'h'),get(DATA['sector_30_lotag'],'h')))
        elif name=='remove_sprite_':calls.append((name,eax))
        else:
            sp=e.reg_read(UC_X86_REG_ESP);arg5,=unpack('<h',e.mem_read(sp+4,2))
            calls.append((name,eax,edx,ebx,ecx,arg5,unpack('<I',e.mem_read(sp+8,4))[0]))
            for reg in (UC_X86_REG_EAX,UC_X86_REG_EDX,UC_X86_REG_EBX,UC_X86_REG_ECX):e.reg_write(reg,0xaaaa0000+reg)
            ret(4);return
        e.reg_write(UC_X86_REG_EAX,0x12345678)
        ret()
    cpu.hook_add(UC_HOOK_CODE,hook)
    for i,r in enumerate(SAVED):cpu.reg_write(r,0xabcd1000+i)
    cpu.reg_write(UC_X86_REG_EAX,0xdeadbeef)
    cpu.mem_write(STACK,pack('<I',STOP)+b'\x5a'*32);cpu.reg_write(UC_X86_REG_ESP,STACK)
    try:
        cpu.emu_start(ENTRY,STOP,count=50000)
    except Exception as error:
        raise RuntimeError(f'guest fault at {cpu.reg_read(UC_X86_REG_EIP):#x}: {error}') from error
    assert cpu.reg_read(UC_X86_REG_EIP)==STOP
    assert cpu.reg_read(UC_X86_REG_ESP)==STACK+4
    assert cpu.mem_read(STACK+4,32)==b'\x5a'*32
    assert all(cpu.reg_read(r)==0xabcd1000+i for i,r in enumerate(SAVED))
    return calls,bytes(cpu.mem_read(DS,len(memory)-DS-0x10000)),cpu.reg_read(UC_X86_REG_ESP)


PHASES = ('puzzle_tile_solution_', 'puzzle_activate_walls_', 'puzzle_key_effect_exit_')
PHASE_LAYOUT = ((0, 410), (0x19a, 64), (0x1da, 458))
BRANCHES = ((0x00d, 0x1da), (0x12b, 0x1da), (0x17c, 0x1da),
            (0x18a, 0x1da), (0x198, 0x1da))
LOADED_DATA = {name: DS + offset for name, offset in DATA_OFFSETS.items()}
FUNCTIONS = FUNCTION_ADDRESSES


def instruction_boundaries(code):
    reader = Cs(CS_ARCH_X86, CS_MODE_32)
    instructions = tuple(reader.disasm(code, ENTRY))
    if not instructions or sum(i.size for i in instructions) != len(code):
        raise ValueError('incomplete puzzle instruction decoding')
    return {i.address - ENTRY for i in instructions} | {len(code)}


def verify_phase_edges(code):
    boundaries = {start for start, _ in PHASE_LAYOUT} | {SIZE}
    if not boundaries.issubset(instruction_boundaries(code)):
        raise ValueError('a puzzle phase boundary splits an instruction')
    reader = Cs(CS_ARCH_X86, CS_MODE_32)
    reader.detail = True
    edges = {}
    for instruction in reader.disasm(code, ENTRY):
        if not instruction.mnemonic.startswith('j'):
            continue
        if instruction.operands[0].type != X86_OP_IMM:
            raise ValueError('unexpected indirect puzzle branch')
        site, target = instruction.address - ENTRY, instruction.operands[0].imm - ENTRY
        phase = next((start, size) for start, size in PHASE_LAYOUT
                     if start <= site < start + size)
        if not phase[0] <= target < phase[0] + phase[1]:
            edges[site] = target
    if edges != dict(BRANCHES):
        raise ValueError('unexpected or missing cross-phase puzzle edges')


def bind_candidate(executable, build):
    """Bind all three registered production slices and verify original fixups."""
    obj_names = [OBJECT_NAMES[symbol] for symbol in PHASES]
    if obj_names != ['sectpuz', 'puzact', 'sectpuz']:
        raise ValueError(f'unexpected puzzle object registrations: {obj_names}')
    objects = {name: (build / (name + '.obj')).read_bytes() for name in set(obj_names)}
    pointers = read_le_fixups(executable)['pointers']
    original_image = image(executable)
    loaded_parts, phase_report = [], []
    for symbol, (start, size) in zip(PHASES, PHASE_LAYOUT):
        raw, registered_size = LEAVES[symbol]
        entry = raw - 0x25600
        if raw != RAW + start or registered_size != size:
            raise ValueError(f'{symbol} placement/extent differs from the three-phase span')
        public, compiler_start, compiler_end, _extent = LEAF_CODE_SLICES[symbol]
        context, _ = bind_leaf_details(objects[OBJECT_NAMES[symbol]], public,
                                       DATA_OFFSETS, address=ENTRY, functions=FUNCTIONS)
        if not {compiler_start, compiler_end}.issubset(instruction_boundaries(context)):
            raise ValueError('compiler puzzle slice splits an instruction')
        exact, refs = bind_leaf_details(objects[OBJECT_NAMES[symbol]], symbol,
                                        DATA_OFFSETS, address=entry, functions=FUNCTIONS)
        if len(exact) != size:
            raise ValueError(f'{symbol} selected {len(exact)} bytes; expected {size}')
        reference = executable[raw:raw + size]
        if exact != reference:
            raise ValueError(f'{symbol} code slice differs from original executable')
        verify_leaf_relocations(exact, refs, pointers, entry)
        loaded, _ = bind_leaf_details(objects[OBJECT_NAMES[symbol]], symbol,
                                      LOADED_DATA, address=entry, functions=FUNCTIONS)
        loaded_parts.append((start, loaded))
        phase_report.append({'symbol': symbol, 'bytes': size, 'le_sites': len(refs)})

    full_reference = original_image[ENTRY:ENTRY + SIZE]
    if len(full_reference) != SIZE:
        raise ValueError('Original puzzle span is truncated')
    # Decode both sides of every phase boundary and check every selected
    # non-CALL cross-phase edge, with no unregistered or missing edges.
    disassembler = Cs(CS_ARCH_X86, CS_MODE_32)
    instructions = tuple(disassembler.disasm(full_reference, ENTRY, SIZE))
    starts = {instruction.address - ENTRY for instruction in instructions}
    boundaries = {start for start, _size in PHASE_LAYOUT}
    boundaries.add(SIZE)
    if not boundaries.issubset(starts | {SIZE}):
        raise ValueError('a puzzle phase boundary is not an instruction boundary')
    registered = LEAF_SECTION_BRANCHES['update_level_sector_puzzle_'][2]
    if set(registered) != {site for site, _target in BRANCHES}:
        raise ValueError('registered cross-phase branch set differs from the five expected edges')
    for site, target in BRANCHES:
        if site not in starts:
            raise ValueError(f'cross-phase branch at {site:#x} is not an instruction boundary')
        opcode, compiled_target, _placed_target = LEAF_SECTION_BRANCHES['update_level_sector_puzzle_'][2][site]
        if full_reference[site:site + len(opcode)] != opcode:
            raise ValueError(f'cross-phase branch opcode changed at {site:#x}')
        width = 1 if len(opcode) == 1 else 4
        end = site + len(opcode) + width
        displacement = int.from_bytes(full_reference[site + len(opcode):end], 'little', signed=True)
        if end + displacement != target or target != _placed_target or compiled_target != 0x1db:
            raise ValueError(f'cross-phase branch target changed at {site:#x}')

    verify_phase_edges(full_reference)

    candidate = bytearray(full_reference)
    for start, code in loaded_parts:
        candidate[start:start + len(code)] = code
    if len(candidate) != SIZE:
        raise ValueError('assembled puzzle extent differs')
    verify_phase_edges(candidate)
    return full_reference, bytes(candidate), phase_report


def compare_case(memory, reference, candidate, case):
    expected = exercise(memory, reference, case)
    actual = exercise(memory, candidate, case)
    if actual != expected:
        raise AssertionError(f"{case.get('name', 'case')}: calls={expected[0]!r}/{actual[0]!r}; "
                             f"DATA equal={expected[1] == actual[1]}")
    return expected


def negative_controls(memory, reference, candidate):
    """Ensure the fixture rejects a wrong activation tag and wrong exit target."""
    trigger_cases = (
        dict(name='activation tag', x=0x7e6e, y=0x6408, clock=181, last=0,
             solved=0, tiles=(0x68e, 0x693, 0x694)),
        dict(name='exit destination', x=0x7e6e, y=0x6408, clock=181, last=0,
             solved=1, triggers=[(3, 0x4029, 0x224)]),
    )
    rejected = []
    tag_mutant = bytearray(candidate)
    tag_anchor = b'\xb8\x06\x00\x00\x00'
    if tag_mutant.count(tag_anchor) != 1:
        raise AssertionError('activation tag mutation anchor is not unique')
    tag_mutant[tag_mutant.index(tag_anchor) + 1] = 7
    activation_reference = exercise(memory, reference, trigger_cases[0])
    activation_candidate = exercise(memory, candidate, trigger_cases[0])
    if activation_candidate != activation_reference:
        raise AssertionError('activation negative-control case is not covered by the candidate')
    if not any(call[0] == 'activate_sector_' and call[-1] == 6
               for call in activation_reference[0]):
        raise AssertionError('activation tag call was not observed on the targeted path')
    if exercise(memory, bytes(tag_mutant), trigger_cases[0]) == activation_reference:
        raise AssertionError('mutated activation tag escaped the differential check')
    rejected.append('activation')

    dest_mutant = bytearray(candidate)
    dest_anchor = b'\xb4\x04'  # mov ah, 4; the following store writes destination_level.
    if dest_mutant.count(dest_anchor) != 1:
        raise AssertionError('exit destination mutation anchor is not unique')
    decoded = tuple(Cs(CS_ARCH_X86, CS_MODE_32).disasm(candidate, ENTRY, SIZE))
    destination_store = f'byte ptr [{DS + DATA_OFFSETS["_destination_level"]:#x}], ah'
    anchor_address = ENTRY + dest_mutant.index(dest_anchor)
    anchor_instruction = next((i for i in decoded if i.address == anchor_address), None)
    if anchor_instruction is None or anchor_instruction.mnemonic != 'mov' or anchor_instruction.op_str != 'ah, 4':
        raise AssertionError('exit destination immediate is not the expected MOV AH, 4')
    if not any(i.address > anchor_address and i.mnemonic == 'mov' and i.op_str == destination_store
               for i in decoded):
        raise AssertionError('exit destination immediate does not feed the destination_level store')
    dest_mutant[dest_mutant.index(dest_anchor) + 1] = 5
    exit_reference = exercise(memory, reference, trigger_cases[1])
    exit_candidate = exercise(memory, candidate, trigger_cases[1])
    if exit_candidate != exit_reference:
        raise AssertionError('exit negative-control case is not covered by the candidate')
    if exit_reference[1][DATA['destination_level']] != 4:
        raise AssertionError('exit destination was not written on the targeted path')
    if exercise(memory, bytes(dest_mutant), trigger_cases[1]) == exit_reference:
        raise AssertionError('mutated exit destination escaped the differential check')
    rejected.append('destination')
    if rejected != ['activation', 'destination']:
        raise AssertionError(f'negative controls were not rejected: {rejected}')
    return len(rejected)


def run(executable, build, output):
    if hashlib.sha256(executable).hexdigest() != TARGET_SHA256:
        raise ValueError('unsupported executable')
    memory = image(executable)
    reference, candidate, phases = bind_candidate(executable, build)
    test_cases = cases()
    for case in test_cases:
        compare_case(memory, reference, candidate, case)
    result = {'original_bytes': SIZE, 'candidate_bytes': len(candidate),
              'compared_data_bytes': len(memory) - DS - 0x10000,
              'cases': len(test_cases), 'phases': phases,
              'cross_phase_branches': len(BRANCHES),
              'negative_controls_rejected': negative_controls(memory, reference, candidate),
              'object_sha256': {name: hashlib.sha256((build / (name + '.obj')).read_bytes()).hexdigest()
                                for name in sorted({OBJECT_NAMES[symbol] for symbol in PHASES})},
              'result': 'original/candidate differential passed'}
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--exe', required=True, type=Path)
    parser.add_argument('--build', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    print(json.dumps(run(args.exe.read_bytes(), args.build, args.output), indent=2))


if __name__ == '__main__':
    main()

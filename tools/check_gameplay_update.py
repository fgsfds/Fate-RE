"""Verify the complete C gameplay controller, row handoff, and 32 behavior cases.

Bindings below are independent constants captured from the original ASM equates.
This checker reads existing build products and never invokes a compiler.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
from struct import pack, unpack
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(ROOT / 'tools'), str(ROOT / 'work/cache/python/095240b6cf469e2f88b1')]
from differential import (BehaviorMismatch, Machine, Contract, Region, bind_bodies,
                          first_difference, require_mutations_detected)
from le_fixups import read_le_fixups, pointer_range

ENTRY, SIZE, DS, DATA_SIZE = 0x14133, 1245, 0x80000, 0x360000
STACK, STOP = 0x3f0000, 0x3fff00
SOURCE = ROOT / 'src/fate/gameplay_update.c'
ROW_SOURCE = ROOT / 'src/fate/gameplay_row.c'
GAP_START, GAP_END = 550, 568
EXPECTED_LE_SITES = 113
CALL_NAMES = (
    'select_item', 'refresh_inventory', 'check_teleport_terminals', 'absolute_long',
    'activate_sector', 'update_sector_events', 'update_periodic_sequences',
    'update_proximity_sprites', 'update_float_sprites', 'update_moving_sprite_physics',
    'update_projectiles', 'update_sector_panning', 'update_fall_triggers',
    'update_level_effects', 'save_level_and_load_board', 'initialize_destination',
    'update_actor_states')
# Independent original-ASM address oracle; do not import production binding tables.
A = {
    'select_item': 0x380d8,
    'refresh_inventory': 0x2944b,
    'check_teleport_terminals': 0x13d9f,
    'absolute_long': 0x602c3,
    'activate_sector': 0x28710,
    'update_sector_events': 0x29cd4,
    'update_periodic_sequences': 0x123d6,
    'update_proximity_sprites': 0x102ca,
    'update_float_sprites': 0x136af,
    'update_moving_sprite_physics': 0x13860,
    'update_projectiles': 0x13237,
    'update_sector_panning': 0x11e8e,
    'update_fall_triggers': 0x10b8f,
    'update_level_effects': 0x40662,
    'save_level_and_load_board': 0x13eed,
    'initialize_destination': 0x26a2a,
    'update_actor_states': 0x1e7b0,
    'inventory_override_request': 0x6797e,
    'inventory_override': 0x4d14,
    'previous_override': 0x4d16,
    'status_right_tenths': 0x6319c,
    'saved_status_right': 0x4d18,
    'item_enabled': 0x2267,
    'item_stock': 0x2277,
    'item_alternate_stock': 0x2287,
    'saved_item_enabled': 0x7f94e,
    'saved_item_stock': 0x7f93e,
    'saved_item_alternate_stock': 0x7f92e,
    'left_icon': 0x2038,
    'middle_icon': 0x203a,
    'right_icon': 0x203c,
    'effect_count': 0x225d,
    'status_flag': 0x2261,
    'saved_left_icon': 0x7f92c,
    'saved_middle_icon': 0x7f92a,
    'saved_right_icon': 0x7f928,
    'saved_effect_count': 0x7f926,
    'saved_status_flag': 0x7f924,
    'game_clock': 0x287e88,
    'last_step_clock': 0x7a990,
    'advance_clock': 0x229b,
    'level_sector_ids': 0x7639c,
    'level_sector_active': 0x7639e,
    'sector_hitag': 0x27c3c4,
    'level_sector_x': 0x7499c,
    'level_sector_y': 0x749a0,
    'player_x': 0x5ad9c,
    'player_y': 0x5ad5c,
    'actor_active': 0x7ecb6,
    'actor_level': 0x7eac1,
    'actor_sprite': 0x7dab8,
    'sprite_x': 0x2040a0,
    'sprite_y': 0x2040a4,
    'current_level': 0x7f87e,
    'level_sector_count': 0x7aa3c,
    'player_sector': 0x5acfc,
    'special_sector': 0x7dee4,
    'last_sequence_clock': 0x2030,
    'destination_level': 0x2040,
    'loaded_level': 0x7f87d,
    'level_left_icon': 0x7a9a0,
    'level_middle_icon': 0x7a9a2,
    'level_right_icon': 0x7a9a4,
    'modified_levels': 0x7dea2,
    'mod_extension': 0x2d0,
    'destination_entry': 0x7deee,
    'destination_x': 0x7a998,
    'destination_y': 0x7a99c,
}
DATA = {'_' + name: value for name, value in A.items() if name not in CALL_NAMES}
FUNCTIONS = {name + '_': A[name] for name in CALL_NAMES}
REGISTERS = dict(eax=0x12345678, ebx=0x21436587, ecx=0x32457698, edx=0x435687a9,
                 esi=0x546798ba, edi=0x6578a9cb, ebp=0x7689badc, eflags=0x202)
CONTRACT = Contract(ENTRY, STOP, STACK, 4,
                    preserved=('ebx', 'ecx', 'edx', 'esi', 'edi', 'ebp'),
                    instruction_limit=100000)
INITIAL_DATA = bytes((i * 37 + 19) & 255 for i in range(256)) * (DATA_SIZE // 256)


def sha(payload):
    return hashlib.sha256(payload).hexdigest()


def cases():
    inventory = [('off', 0, 0, 0), ('toggle_on', 0, 0, 1),
                 ('toggle_off', -1, -1, 1), ('save', -1, 0, 0),
                 ('restore', 0, -1, 0), ('grant', -1, -1, 0),
                 ('noncanonical_save', 0x1234, 0, 0),
                 ('noncanonical_toggle', 0x1234, 0x1234, 255)]
    clocks = [(100, 86, 89), (100, 85, 88),
              (5, 0xfffffff6, 0xfffffff9), (0x80000020, 0, 0)]
    result = []
    for i in range(32):
        mode, override, previous, request = inventory[i // 4]
        current = i // 8
        presence = ('player', 'actor0', 'actor500', 'none')[(i // 2) % 4]
        now, step, sequence = clocks[i % 4]
        destination = (-1, current, (current + 1) % 4, (current + 2) % 4)[i % 4]
        result.append(dict(name=f'{i:02d}_{mode}_{presence}_clock{i % 4}',
            override=override, previous=previous, request=request,
            clock=now, last_step=step, last_sequence=sequence,
            presence=presence, active=i % 2, current=current, destination=destination,
            sector_count=0 if i == 0 else 2, player_distance=1499 if i % 4 == 0 else 0,
            special=bool(i % 2), clock_bump=3 if i in (17, 29) else 0,
            sequence_bump=7 if i in (6, 22) else 0,
            callback_destination=(current + 1) % 4 if i == 28 else None,
            actor_disabled=i == 13, actor_wrong_level=i == 11))
    return result


def exercise(body, case, *, initialize_ret4=True):
    m = Machine(CONTRACT, body, [Region('DS', DS, DATA_SIZE)])
    m.write(DS, INITIAL_DATA)

    def put(name, fmt, value, offset=0):
        mask = (1 << (8 * {'B': 1, 'H': 2, 'I': 4}[fmt])) - 1
        m.write(DS + A[name] + offset, pack('<' + fmt, value & mask))

    def get(name, fmt, offset=0):
        size = {'B': 1, 'H': 2, 'I': 4}[fmt]
        return unpack('<' + fmt, m.read(DS + A[name] + offset, size))[0]

    for name, value in [('inventory_override', case['override']),
                        ('previous_override', case['previous']), ('advance_clock', 0x55aa),
                        ('player_sector', 3), ('special_sector', 99), ('destination_entry', -123)]:
        put(name, 'H', value)
    for name, value in [('inventory_override_request', case['request']),
                        ('current_level', case['current']), ('loaded_level', case['current']),
                        ('destination_level', case['destination'])]:
        put(name, 'B', value)
    for name, value in [('status_right_tenths', 0x12345678), ('saved_status_right', 0x89abcdef),
                        ('game_clock', case['clock']), ('last_step_clock', case['last_step']),
                        ('last_sequence_clock', case['last_sequence']),
                        ('player_x', 20000), ('player_y', -30000),
                        ('destination_x', 0x12348765), ('destination_y', 0xfedc1234)]:
        put(name, 'I', value)
    for array, base in [('item_enabled', 101), ('item_stock', 201),
                        ('item_alternate_stock', 301), ('saved_item_enabled', 401),
                        ('saved_item_stock', 501), ('saved_item_alternate_stock', 601)]:
        for index in range(1, 9):
            put(array, 'H', base + index * 13, index * 2)
    for i, name in enumerate(('left_icon', 'middle_icon', 'right_icon', 'effect_count', 'status_flag')):
        put(name, 'H', 70 + i)
        put('saved_' + name, 'H', 170 + i)
    m.write(DS + A['mod_extension'], b'.MOD\0')
    m.write(DS + A['actor_active'], b'\xff' * 501)
    m.write(DS + A['actor_level'], b'\xfe' * 501)
    for level in range(4):
        put('level_sector_count', 'H', case['sector_count'] if level == case['current'] else 0, level * 2)
        put('modified_levels', 'B', level & 1, level)
        for name, base in [('level_left_icon', 1000), ('level_middle_icon', 2000), ('level_right_icon', 3000)]:
            put(name, 'H', base + level * 17, level * 6)
    for sector in (3, 4, 7, 8):
        put('sector_hitag', 'H', 0, sector * 40)
    put('sector_hitag', 'H', 0x400 if case['special'] else 0, 4 * 40)
    put('sector_hitag', 'H', 0x101, 7 * 40)  # low-byte match despite upper bits
    put('sector_hitag', 'H', 2, 8 * 40)       # non-trigger skip
    for slot, sector in ((1, 7), (2, 8)):
        put('level_sector_ids', 'H', sector, case['current'] * 128 + slot * 4)
        put('level_sector_active', 'H', case['active'], case['current'] * 128 + slot * 4)
        put('level_sector_x', 'I', 20000, case['current'] * 256 + slot * 8)
        put('level_sector_y', 'I', -30000, case['current'] * 256 + slot * 8)
    if case['presence'] == 'player':
        put('player_x', 'I', 20000 + case['player_distance'])
    else:
        put('player_x', 'I', 21500)  # equality is outside the strict proximity bound
    actor = {'actor0': 0, 'actor500': 500}.get(case['presence'])
    if actor is not None:
        put('actor_active', 'B', -1 if case['actor_disabled'] else 0, actor)
        put('actor_level', 'B', case['current'] + (1 if case['actor_wrong_level'] else 0), actor)
        put('actor_sprite', 'H', 4095 if actor == 500 else 0, actor * 2)
        sprite = 4095 if actor == 500 else 0
        put('sprite_x', 'I', 18501, sprite * 44)
        put('sprite_y', 'I', -31499, sprite * 44)

    def callback(name):
        def invoke(machine):
            args, mutations = [], []

            def change(field, fmt, value, offset=0):
                before = get(field, fmt, offset)
                put(field, fmt, value, offset)
                mutations.append((field, offset, before, get(field, fmt, offset)))

            if name in ('select_item', 'absolute_long', 'activate_sector', 'update_level_effects'):
                args.append(machine.register('eax'))
            if name == 'absolute_long':
                value = args[0]
                signed = value - 0x100000000 if value & 0x80000000 else value
                changed = {'eax': abs(signed)}
            elif name == 'save_level_and_load_board':
                pointer = machine.register('edx')
                args = [machine.register('eax'), pointer, machine.read(pointer, 5).hex()]
                change('destination_x', 'I', 0x88abcdef)
                change('destination_y', 'I', 0xffeeddcc)
                change('destination_entry', 'H', -321)
                change('modified_levels', 'B', 0x81, get('current_level', 'B'))
                changed = {'eax': 0x91a2b3c4, 'edx': 0xd1e2f3a4}
            elif name == 'initialize_destination':
                args = [machine.register(reg) for reg in ('eax', 'edx', 'ebx', 'ecx')]
                args.append(unpack('<I', machine.read(machine.register('esp') + 4, 4))[0])
                level = get('current_level', 'B')
                for field, value in [('level_left_icon', 4101), ('level_middle_icon', 4202), ('level_right_icon', 4303)]:
                    change(field, 'H', value + level, level * 6)
                changed = dict(eax=0xa1b2c3d4, ebx=0xb1c2d3e4, ecx=0xc1d2e3f4, edx=0xd1e2f3a4)
            else:
                changed = {'eax': 0xe0000000 + CALL_NAMES.index(name) * 0x101}
                if name == 'select_item':
                    change('left_icon', 'H', 77)
                elif name == 'refresh_inventory':
                    change('item_stock', 'H', get('item_stock', 'H', 8) + 17, 8)
                elif name == 'check_teleport_terminals' and case['clock_bump']:
                    change('game_clock', 'I', get('game_clock', 'I') + case['clock_bump'])
                elif name == 'activate_sector':
                    assert args[0] == 7
                    off = case['current'] * 128 + 4
                    change('level_sector_active', 'H', 1 - get('level_sector_active', 'H', off), off)
                elif name == 'update_sector_events':
                    change('player_sector', 'H', 4)
                elif name == 'update_periodic_sequences' and case['sequence_bump']:
                    change('game_clock', 'I', get('game_clock', 'I') + case['sequence_bump'])
                elif name == 'update_level_effects' and case['callback_destination'] is not None:
                    change('destination_level', 'B', case['callback_destination'])
            # Every non-mathematical callback leaves an observable order-sensitive mark.
            if name != 'absolute_long':
                offset = 0x350000 + 4 * CALL_NAMES.index(name)
                before = unpack('<I', machine.read(DS + offset, 4))[0]
                after = (before + len(machine.calls) + 1) & 0xffffffff
                machine.write(DS + offset, pack('<I', after))
                mutations.append(('callback_marker', offset, before, after))
            machine.record(name, args, mutations, changed)
            return changed
        return invoke

    for name in CALL_NAMES:
        if name == 'initialize_destination':
            m.add_code(A[name], b'\xc2\x04\x00' if initialize_ret4 else b'\xc3')
            m.stubs[A[name]] = callback(name)
        else:
            m.stub(A[name], callback(name))
    return m.run(REGISTERS)


def check_reference(case, observation):
    names = [call[0] for call in observation.calls]
    assert names[-1] == 'update_actor_states'
    assert names.count('check_teleport_terminals') == 1
    assert names.count('select_item') == int(case['request'] != 0)
    final_override = (~case['override'] & 0xffff) if case['request'] else case['override'] & 0xffff
    assert names.count('refresh_inventory') == int(final_override != (case['previous'] & 0xffff) and final_override == 0)
    nearby = case['presence'] == 'player' or (case['presence'] in ('actor0', 'actor500') and not case['actor_disabled'] and not case['actor_wrong_level'])
    expected_activation = case['sector_count'] != 0 and (case['active'] == (0 if nearby else 1))
    assert names.count('activate_sector') == int(expected_activation)
    destination = case['callback_destination'] if case['callback_destination'] is not None else case['destination']
    transition = destination != -1 and destination != case['current']
    assert names.count('save_level_and_load_board') == int(transition)
    assert names.count('initialize_destination') == int(transition)
    def state(field, fmt):
        width = {'H': 2, 'I': 4}[fmt]
        return unpack('<' + fmt, observation.memory['DS'][A[field]:A[field] + width])[0]
    step_delta = (case['clock'] - case['last_step']) & 0xffffffff
    advance = 15 <= step_delta < 0x80000000
    assert state('advance_clock', 'H') == int(advance)
    assert state('last_step_clock', 'I') == (case['clock'] if advance else case['last_step'])
    now = (case['clock'] + case['clock_bump']) & 0xffffffff
    sequence_delta = (now - case['last_sequence']) & 0xffffffff
    sequence = 12 <= sequence_delta < 0x80000000
    assert names.count('update_periodic_sequences') == int(sequence)
    assert state('last_sequence_clock', 'I') == ((now + case['sequence_bump']) & 0xffffffff if sequence else case['last_sequence'])
    assert state('special_sector', 'H') == (4 if case['special'] else 99)


def bind_integrated(executable, obj, row_obj):
    """Check every compiler supplier and LE site before loading the complete body."""
    pointers = read_le_fixups(executable)['pointers']
    all_sites = pointer_range(pointers, ENTRY, SIZE)
    if len(all_sites) != EXPECTED_LE_SITES:
        raise ValueError('Unexpected gameplay-update reference LE count')
    gap_sites = pointer_range(pointers, ENTRY + GAP_START, GAP_END-GAP_START)
    if gap_sites != {14: DS + A['level_sector_ids']}:
        raise ValueError(f'Unexpected row LE sites/targets: {gap_sites}')
    head_reference, head, head_fixups = bind_bodies(executable, obj,
        'update_gameplay_head_', ENTRY, GAP_START, DATA, FUNCTIONS, data_base=DS)
    tail_reference, tail, tail_fixups = bind_bodies(executable, obj,
        'update_gameplay_tail_', ENTRY + GAP_END, SIZE - GAP_END, DATA, FUNCTIONS,
        data_base=DS)
    row_reference, row, row_fixups = bind_bodies(executable, row_obj,
        'update_gameplay_row_setup_', ENTRY+GAP_START, GAP_END-GAP_START,
        DATA, FUNCTIONS, data_base=DS)
    reference = head_reference + row_reference + tail_reference
    candidate = head + row + tail
    if len(reference) != SIZE or len(candidate) != SIZE:
        raise ValueError('Complete C span has the wrong size')
    if head_fixups + tail_fixups + row_fixups != EXPECTED_LE_SITES:
        raise ValueError('Combined C LE count differs')
    return reference, candidate, dict(head=head_fixups, row=row_fixups, tail=tail_fixups)


def check_row_handoff(blob):
    """Independent word/offset oracle, including the private return contract."""
    from unicorn import Uc, UC_ARCH_X86, UC_MODE_32
    from unicorn.x86_const import (UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX,
        UC_X86_REG_EDX, UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP,
        UC_X86_REG_ESP, UC_X86_REG_EIP, UC_X86_REG_EFLAGS)
    import verify_c_leaf as v
    from check_ripple_stack import mutate_public_byte
    from check_ripple_control import rename_external
    registers=(UC_X86_REG_EAX,UC_X86_REG_EBX,UC_X86_REG_ECX,UC_X86_REG_EDX,
               UC_X86_REG_ESI,UC_X86_REG_EDI,UC_X86_REG_EBP)
    address=0x400000
    full='gameplay_row_private_check_'
    v.LEAF_CODE_SLICES[full]=('gameplay_row_word_',0,19,19)
    try:
        placed=v.bind_leaf_details(blob,'update_gameplay_row_setup_',{'_level_sector_ids':DS+A['level_sector_ids']},address=address)[0]
        private=v.bind_leaf_details(blob,full,{'_level_sector_ids':DS+A['level_sector_ids']},address=address)[0]
    finally:del v.LEAF_CODE_SLICES[full]
    cases=0
    base=bytes(range(256))*(DATA_SIZE//256)
    for row in (0,1,12,25):
        for column in (0,1,15,31):
            for word in (-32768,-1,0,32767):
                for poison in (0x12340000,0xfedc0000):
                    for is_private,code in ((False,placed),(True,private)):
                        cpu=Uc(UC_ARCH_X86,UC_MODE_32);cpu.mem_map(0,0x500000)
                        expected=bytearray(base)
                        site=A['level_sector_ids']+row*128+column*4
                        expected[site:site+2]=pack('<h',word)
                        cpu.mem_write(DS,bytes(expected));cpu.mem_write(address,code)
                        frame=pack('<I',STOP)+b'\xa5'*60
                        cpu.mem_write(STACK,frame);cpu.mem_write(STACK-128,b'\x6c'*128)
                        want={r:0xabc00000+i for i,r in enumerate(registers)}
                        want.update({UC_X86_REG_ESI:poison|column,UC_X86_REG_EDX:row})
                        for r,value in want.items():cpu.reg_write(r,value)
                        cpu.reg_write(UC_X86_REG_ESP,STACK);cpu.reg_write(UC_X86_REG_EFLAGS,0x8d7)
                        end=STOP if is_private else address+18
                        cpu.emu_start(address,end,count=10)
                        want.update({UC_X86_REG_EAX:word&0xffff,UC_X86_REG_ECX:column,UC_X86_REG_EBP:row*128})
                        assert all(cpu.reg_read(r)==value for r,value in want.items())
                        assert cpu.reg_read(UC_X86_REG_ESP)==STACK+(4 if is_private else 0)
                        assert cpu.reg_read(UC_X86_REG_EIP)==end
                        assert cpu.mem_read(DS,DATA_SIZE)==expected
                        assert cpu.mem_read(STACK,len(frame))==frame and cpu.mem_read(STACK-128,128)==b'\x6c'*128
                        flags=(0x40 if row==0 else 0)|(4 if row%2==0 else 0)
                        assert cpu.reg_read(UC_X86_REG_EFLAGS)&0xc5==flags
                        cases+=1
    controls=0
    def rejected(bad,message):
        nonlocal controls
        try:v.bind_leaf_details(bad,'update_gameplay_row_setup_',DATA,address=ENTRY+GAP_START)
        except ValueError as error:
            assert message in str(error).lower();controls+=1
        else:raise AssertionError('Row context mutation escaped')
    rejected(mutate_public_byte(blob,'gameplay_row_word_',18),'context')
    rejected(rename_external(blob,b'_level_sector_ids',b'_level_sector_idt'),'fixup')
    digest=v.LEAF_CONTEXT_SHA256.pop('gameplay_row_word_')
    try:rejected(mutate_public_byte(blob,'gameplay_row_word_',14),'addend')
    finally:v.LEAF_CONTEXT_SHA256['gameplay_row_word_']=digest
    return cases,controls


def negative_controls(reference):
    """Prove the fixture rejects changed bounds, register loss, and bad cleanup."""
    selected = cases()
    mutations = []
    for name, offset, before, after, case_index in [
        ('step_15_to_16', 500, '83f80f', '83f810', 1),
        ('sequence_12_to_13', 929, '83f80c', '83f80d', 1),
        ('actor_500_excluded', 770, '3df4010000', '3df3010000', 12),
        ('player_boundary_1499_excluded', 637, '3ddc050000', '3ddb050000', 8),
    ]:
        before, after = bytes.fromhex(before), bytes.fromhex(after)
        if reference[offset:offset + len(before)] != before:
            raise ValueError(f'Negative-control instruction changed: {name}')
        mutant = reference[:offset] + after + reference[offset + len(before):]
        mutations.append((name, mutant, selected[case_index]))
    if reference[-7:] != bytes.fromhex('5d5f5e5a595bc3'):
        raise ValueError('Negative-control epilogue changed')
    mutant = bytearray(reference)
    mutant[-4] = 0x58  # POP EAX in place of POP EDX: stack balanced, EDX lost.
    mutations.append(('preserved_edx_lost', bytes(mutant), selected[0]))
    mutations.append(('public_wrong_ret4', reference[:-1] + bytes.fromhex('c20400'), selected[0]))
    detected = require_mutations_detected('gameplay-update', reference, mutations, exercise)
    transition = selected[2]
    exercise(reference, transition)  # A valid reference must succeed first.
    try:
        exercise(reference, transition, initialize_ret4=False)
    except BehaviorMismatch:
        detected.append('initializer_missing_ret4')
    else:
        raise AssertionError('Negative control missed initializer cleanup')
    return detected


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--exe', type=Path, required=True)
    parser.add_argument('--build', type=Path, required=True)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    output = args.output or args.build / 'gameplay-update-behavior.json'
    obj_path = args.build / 'gamup.obj'
    row_path = args.build / 'gamrow.obj'
    inputs = {name: path.read_bytes() for name, path in
              [('source', SOURCE), ('object', obj_path), ('reference', args.exe),
               ('row_object', row_path), ('row_source', ROW_SOURCE)]}
    reference, candidate, fixups = bind_integrated(inputs['reference'], inputs['object'], inputs['row_object'])
    row_cases,row_controls=check_row_handoff(inputs['row_object'])
    report = dict(fixture='gameplay-update', mode='exact-and-behavior', exact_verified=True,
        inventory_eligible=False, status='FAIL', source=str(SOURCE), object=str(obj_path.resolve()),
        source_sha256=sha(inputs['source']), object_sha256=sha(inputs['object']),
        reference_sha256=sha(inputs['reference']), row_object_sha256=sha(inputs['row_object']),
        row_source_sha256=sha(inputs['row_source']), reference_bytes=len(reference),
        candidate_bytes=len(candidate), restored_c_bytes=SIZE, retained_asm_bytes=0,
        row_handoff_cases=row_cases,row_context_controls=row_controls,reference_body_sha256=sha(reference),
        candidate_body_sha256=sha(candidate), absolute_fixups=fixups,
        data_base=DS, data_bytes_compared=DATA_SIZE,
        preserved_registers=list(CONTRACT.preserved), stack_cleanup=4,
        initialize_destination_stub='C2 04 00; callback never changes ESP',
        callback_contracts={'normal': ['eax'], 'save_level_and_load_board': ['eax', 'edx'],
            'initialize_destination': ['eax', 'ebx', 'ecx', 'edx']}, cases=[])
    try:
        for case in cases():
            expected = exercise(reference, case)
            check_reference(case, expected)
            actual = exercise(candidate, case)
            difference = first_difference(expected, actual)
            row = dict(case=case, status='FAIL' if difference else 'PASS',
                       reference_calls=expected.calls, candidate_calls=actual.calls,
                       reference_ds_sha256=sha(expected.memory['DS']),
                       candidate_ds_sha256=sha(actual.memory['DS']))
            report['cases'].append(row)
            if difference:
                raise AssertionError(f"{case['name']}: {difference}")
        report['negative_controls_detected'] = negative_controls(reference)
        report['status'] = 'PASS'
        report['cases_passed'] = len(report['cases'])
    except Exception as error:
        report['failure'] = str(error)
        raise
    finally:
        report['case_count'] = len(cases())
        output.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(f"PASS: gameplay-update: {len(report['cases'])}/32 cases, "
          f"{len(report['negative_controls_detected'])} negative controls; "
          f"complete C body/113 LE sites, {row_cases} row handoffs; all {DATA_SIZE:,} DS bytes, calls and ABI")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())

"""Verify the complete C status panel and both guarded compiler contexts.

Uses 40 independent bounded cases, full DS comparisons, live callback mutations,
and the original six-register preservation contract. The decimal-format helper
covers clamped values 0..999 only; larger output strings are outside this fixture.
"""
import argparse
import hashlib
import json
from pathlib import Path
from struct import pack, unpack
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(ROOT / 'tools'), str(ROOT / 'work/cache/python/095240b6cf469e2f88b1')]
from differential import Machine, Contract, Region, bind_bodies, first_difference, require_mutations_detected
from le_fixups import read_le_fixups, pointer_range

ENTRY, SIZE, RAW = 0x1067a, 692, 0x35c7a
DS, DATA_SIZE, STACK, STOP = 0x80000, 0x300000, 0x3f0000, 0x3fff00
REFERENCE_SHA = '61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f'
ENTRY_SOURCE = ROOT / 'src/fate/status_panel_entry.c'
PREFIX_SIZE = 84
SOURCE = ROOT / 'src/fate/status_panel.c'
A = dict(number_format=0xe4, show_left_icon=0x2038, show_middle_icon=0x203a,
         show_right_icon=0x203c, status_left_value=0x225d, status_left_tenths=0x2263,
         status_right_values=0x2277, status_right_index=0x2be2,
         status_right_tenths=0x6319c, panel_top=0x7f898, window_bottom=0x286b90,
         window_top=0x286b94, window_right=0x286b98, window_left=0x286b9c)
FUNCTIONS = dict(format_string_=0x601f3, draw_number_text_=0x385f4, draw_tile_=0x57181)
CONTRACT = Contract(ENTRY, STOP, STACK, 4,
                    preserved=('ebx', 'ecx', 'edx', 'esi', 'edi', 'ebp'))
CLOBBERS = dict(eax=0xa1b2c3d4, ebx=0xb1c2d3e4, ecx=0xc1d2e3f4, edx=0xd1e2f3a4)
INITIAL = bytes(range(256)) * (DATA_SIZE // 256)
sha = lambda data: hashlib.sha256(data).hexdigest()
s16 = lambda n: (n & 0xffff) - (0x10000 if n & 0x8000 else 0)
s32 = lambda n: (n & 0xffffffff) - (0x100000000 if n & 0x80000000 else 0)
u32 = lambda n: n & 0xffffffff


def cases():
    result = []
    def add(name, **updates):
        case = dict(name=name, icons=[0, 0, 0], left=123, index=3,
                    left_tenths=987, right_tenths=4321, right=456,
                    clip=[11, 23, 307, 181], initial_panel=-991, mutations={})
        case.update(updates)
        result.append(case)
    for mask in range(8):
        add(f'icons_{mask:03b}', icons=[(-1 if mask & (1 << i) else 0) for i in range(3)])
    for value in (-32768, -1000, -10, -9, -1, 0, 1, 9, 10, 99, 100, 999):
        add(f'signed_fields_{value}', left=value, right=value,
            left_tenths=value, right_tenths=value, icons=[1, 2, 0x8000])
    for value in (-2147483648, -11, 9990, 9999):
        add(f'right_div10_{value}', right_tenths=value)
    for index in (-32768, -1, 0, 1, 3, 7, 127, 255):
        add(f'index_{index}', index=index, right=211 + (index & 127))
    # Mutate after every possible drawing point. Later calls must reload panel,
    # clip bounds, field values, and icon flags from live memory.
    for after in range(1, 9):
        changes = dict(panel_top=-7 + after * 3, window_left=-100 - after,
                       window_top=50 + after, window_right=400 + after,
                       window_bottom=200 + after, status_left_value=321,
                       status_right_index=7, status_left_tenths=4567,
                       status_right_tenths=7654, show_left_icon=1,
                       show_middle_icon=2, show_right_icon=0xffff)
        add(f'callback_mutation_after_draw_{after}', icons=[1, 1, 1], mutations={after: changes})
    assert len(result) == 40
    return result


def initial_memory(case):
    memory = bytearray(INITIAL)
    def put(name, value, width=4):
        offset = A[name]
        memory[offset:offset + width] = int(value & ((1 << (width * 8)) - 1)).to_bytes(width, 'little')
    memory[A['number_format']:A['number_format'] + 4] = b'%3d\0'
    for name, value in zip(('show_left_icon', 'show_middle_icon', 'show_right_icon'), case['icons']):
        put(name, value, 2)
    for name, value in [('status_left_value', case['left']), ('status_right_index', case['index']),
                        ('status_left_tenths', case['left_tenths'])]:
        put(name, value, 2)
    for i in range(256):
        offset = A['status_right_values'] + 2 * i
        memory[offset:offset + 2] = pack('<H', (100 + i) % 1000)
    if case['index'] >= 0:
        offset = A['status_right_values'] + case['index'] * 2
        memory[offset:offset + 2] = pack('<H', case['right'] & 0xffff)
    put('status_right_tenths', case['right_tenths'])
    put('panel_top', case['initial_panel'])
    for name, value in zip(('window_left', 'window_top', 'window_right', 'window_bottom'), case['clip']):
        put(name, value)
    return memory


def mutation(memory, case, draw_count):
    for name, value in case['mutations'].get(draw_count, {}).items():
        width = 2 if name.startswith('show_') or name in ('status_left_value', 'status_right_index', 'status_left_tenths') else 4
        memory[A[name]:A[name] + width] = int(value & ((1 << (width * 8)) - 1)).to_bytes(width, 'little')


def expected_behavior(case):
    memory, calls, draw_count = initial_memory(case), [], 0
    def read(name, width=4):
        return int.from_bytes(memory[A[name]:A[name] + width], 'little', signed=True)
    def after_draw():
        nonlocal draw_count
        draw_count += 1
        mutation(memory, case, draw_count)
        offset = 0x2f0000 + draw_count * 4
        memory[offset:offset + 4] = pack('<I', 0x12340000 + draw_count)
    def tile(x, y, tile_id):
        clip = [read(name) for name in ('window_left', 'window_top', 'window_right', 'window_bottom')]
        calls.append(('draw_tile', tuple(map(u32, (x, y, 0x10000, 0, tile_id, 0, 0, 0x82, *clip)))))
        after_draw()
    def number(value, x, offset, style):
        value = max(0, value)
        assert value <= 999, 'test exceeds bounded format contract'
        rendered = f'{value:3d}'.encode() + b'\0'
        calls.append(('format_string', STACK - 28, DS + A['number_format'], value, rendered.hex()))
        calls.append(('draw_number_text', tuple(map(u32, (x, read('panel_top') + offset, style, STACK - 28, 0))), rendered.hex()))
        after_draw()
    memory[A['panel_top']:A['panel_top'] + 4] = pack('<I', 4)
    tile(5 << 16, 4 << 16, 0x828)
    tile(262 << 16, read('panel_top') << 16, 0x82c)
    number(read('status_left_value', 2), 27, 13, -1)
    index = read('status_right_index', 2)
    right = int.from_bytes(memory[A['status_right_values'] + index * 2:A['status_right_values'] + index * 2 + 2], 'little', signed=True) if index >= 0 else 0
    number(right, 27, 31, 1)
    trunc10 = lambda n: (abs(n) // 10) * (-1 if n < 0 else 1)
    number(trunc10(read('status_left_tenths', 2)), 284, 13, -1)
    number(trunc10(read('status_right_tenths')), 284, 31, 1)
    for name, x, tile_id in [('show_left_icon', 9, 0x82a), ('show_middle_icon', 26, 0x829), ('show_right_icon', 42, 0x82b)]:
        if read(name, 2):
            tile(x << 16, (read('panel_top') + 2) << 16, tile_id)
    return tuple(calls), bytes(memory)


def exercise(body, case):
    m = Machine(CONTRACT, body, [Region('DS', DS, DATA_SIZE)])
    m.write(DS, initial_memory(case))
    draw_count = 0
    def after_draw(machine):
        nonlocal draw_count
        draw_count += 1
        for name, value in case['mutations'].get(draw_count, {}).items():
            width = 2 if name.startswith('show_') or name in ('status_left_value', 'status_right_index', 'status_left_tenths') else 4
            machine.write(DS + A[name], int(value & ((1 << (width * 8)) - 1)).to_bytes(width, 'little'))
        machine.write(DS + 0x2f0000 + draw_count * 4, pack('<I', 0x12340000 + draw_count))
        return CLOBBERS
    def formatter(machine):
        buffer, fmt, raw = unpack('<3I', machine.read(machine.register('esp') + 4, 12))
        assert machine.read(fmt, 4) == b'%3d\0', 'unexpected format string'
        value = s32(raw)
        assert 0 <= value <= 999, 'format argument outside bounded contract'
        rendered = f'{value:3d}'.encode() + b'\0'
        machine.write(buffer, rendered)
        machine.record('format_string', buffer, fmt, value, rendered.hex())
        return {'eax': 3}
    def number(machine):
        args = tuple(machine.register(r) for r in ('eax', 'edx', 'ebx', 'ecx'))
        args += unpack('<I', machine.read(machine.register('esp') + 4, 4))
        rendered = machine.read(args[3], 4)
        machine.record('draw_number_text', args, rendered.hex())
        return after_draw(machine)
    def tile(machine):
        args = tuple(machine.register(r) for r in ('eax', 'edx', 'ebx', 'ecx'))
        args += unpack('<8I', machine.read(machine.register('esp') + 4, 32))
        machine.record('draw_tile', args)
        return after_draw(machine)
    m.stub(FUNCTIONS['format_string_'], formatter)
    for address, callback, cleanup in [(FUNCTIONS['draw_number_text_'], number, 4), (FUNCTIONS['draw_tile_'], tile, 32)]:
        m.add_code(address, b'\xc2' + pack('<H', cleanup))
        m.stubs[address] = callback
    return m.run(dict(eax=0x10203040, ebx=0x21324354, ecx=0x32435465,
                      edx=0x43546576, esi=0x54657687, edi=0x65768798,
                      ebp=0x768798a9, eflags=0x202))


def check_reference(case, observation):
    calls, memory = expected_behavior(case)
    assert observation.calls == calls, f"{case['name']}: independent call model mismatch: {first_difference(type(observation)({}, {}, calls), type(observation)({}, {}, observation.calls))}"
    assert observation.memory['DS'] == memory, f"{case['name']}: independent DS model mismatch"


def reference_body(executable):
    if sha(executable) != REFERENCE_SHA:
        raise ValueError('Reference executable SHA-256 mismatch')
    body = bytearray(executable[RAW:RAW + SIZE])
    pointers = pointer_range(read_le_fixups(executable)['pointers'], ENTRY, SIZE)
    assert len(pointers) == 41, 'reference must have exactly 41 LE pointer sites'
    for site, target in pointers.items():
        body[site:site + 4] = pack('<I', target)
    return bytes(body)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--exe', required=True, type=Path)
    parser.add_argument('--build', required=True, type=Path)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    exe = args.exe.read_bytes()
    reference = reference_body(exe)
    object_path = args.build / 'statpan.obj'
    import verify_c_leaf as v
    from check_ripple_stack import mutate_public_byte
    from check_ripple_control import rename_external
    obj = object_path.read_bytes()
    entry_obj = (args.build/'statpent.obj').read_bytes()
    objects={'statpan':obj,'statpent':entry_obj}
    data={'_'+name:offset for name,offset in A.items()}
    phases=sorted((r for r in v.CONTROLLER_PREFIX_LAYOUT['phases'] if r['routine']=='draw_status_panel'),key=lambda r:r['address'])
    loaded_prefix=bytearray();prefix_fixups=0;cursor=ENTRY
    for phase in phases:
        assert phase['address']==cursor
        size=phase['end']-phase['begin']
        ref,code,count=bind_bodies(exe,objects[phase['object']],phase['phase'],cursor,size,data,FUNCTIONS,data_base=DS)
        assert ref==reference[cursor-ENTRY:cursor-ENTRY+size]
        loaded_prefix.extend(code);prefix_fixups+=count;cursor+=size
    assert cursor==ENTRY+PREFIX_SIZE and prefix_fixups==5
    reference_tail, candidate_tail, fixups = bind_bodies(
        exe, obj, 'draw_status_panel_', ENTRY + PREFIX_SIZE, SIZE - PREFIX_SIZE,
        data, FUNCTIONS,
        data_base=DS, behavior_only=False, execution_functions=FUNCTIONS)
    assert len(candidate_tail) == SIZE - PREFIX_SIZE == 608
    assert fixups == 36, 'C tail must have exactly 36 LE operands'
    assert reference[PREFIX_SIZE:] == reference_tail, 'tail reference rebasing differs'
    candidate = bytes(loaded_prefix) + candidate_tail
    assert len(candidate) == SIZE
    private_contexts=[]
    for public,blob,size in (('draw_status_panel_',obj,692),('draw_status_panel_entry_',entry_obj,693)):
        alias=public+'full_private_check'
        v.LEAF_CODE_SLICES[alias]=(public,0,size,size)
        try:
            code,_=v.bind_leaf_details(blob,alias,{name:DS+offset for name,offset in data.items()},address=ENTRY,functions=FUNCTIONS)
        finally:del v.LEAF_CODE_SLICES[alias]
        private_contexts.append(code)
    context_controls=0
    def rejected(blob,phase,message):
        nonlocal context_controls
        try:v.bind_leaf_details(blob,phase['phase'],data,address=phase['address'],functions=FUNCTIONS)
        except ValueError as error:
            assert message in str(error).lower();context_controls+=1
        else:raise AssertionError('Panel context mutation escaped')
    first=phases[0];store=next(r for r in phases if r['object']=='statpan')
    rejected(mutate_public_byte(obj,'draw_status_panel_',0),store,'context')
    rejected(mutate_public_byte(entry_obj,'draw_status_panel_entry_',692),first,'context')
    rejected(rename_external(entry_obj,b'draw_tile_',b'draw_tilf_'),first,'fixup')
    public='draw_status_panel_entry_'
    context=next(c for o in v.CONTROLLER_PREFIX_LAYOUT['objects'] for c in o['contexts'] if c['public']==public)
    site=next(int(site) for site,spec in context['fixups'].items() if int(site)>=84 and not spec[1])
    digest=v.LEAF_CONTEXT_SHA256.pop(public)
    try:rejected(mutate_public_byte(entry_obj,public,site),first,'addend')
    finally:v.LEAF_CONTEXT_SHA256[public]=digest
    output = args.output or args.build / 'status-panel-behavior.json'
    report = dict(fixture='status-panel', status='FAIL', exact_verified=True, inventory_eligible=False,
        mode='exact-and-behavior', reference_sha256=sha(exe), entry_source_sha256=sha(ENTRY_SOURCE.read_bytes()),
        source_sha256=sha(SOURCE.read_bytes()), object_sha256=sha(obj),
        entry_object_sha256=sha(entry_obj),c_prefix_sha256=sha(loaded_prefix),c_prefix_bytes=len(loaded_prefix),
        c_prefix_le_fixups=prefix_fixups,retained_asm_bytes=0,c_tail_bytes=len(candidate_tail),
        c_tail_le_fixups=fixups, reference_body_sha256=sha(reference),
        candidate_body_sha256=sha(candidate), candidate_bytes=len(candidate),
        reference_le_fixups=41, data_base=DS, data_bytes_compared=DATA_SIZE, stack_cleanup=4,
        preserved_registers=list(CONTRACT.preserved),
        format_fixture_limit='clamped decimal values 0..999; four bytes including NUL',
        helper_contracts={'format_string':'caller cleans 3 stack args; EAX only; %3d NUL, 0..999',
                          'draw_number_text':'4 register args + one stack arg; RET 4; clobbers EAX EBX ECX EDX',
                          'draw_tile':'4 register args + eight stack args; RET 32; clobbers EAX EBX ECX EDX'},
        private_context_cases=0,context_controls=context_controls,cases=[])
    try:
        for case in cases():
            expected = exercise(reference, case)
            check_reference(case, expected)
            actual = exercise(candidate, case)
            difference = first_difference(expected, actual)
            report['cases'].append(dict(name=case['name'], status='FAIL' if difference else 'PASS',
                calls=len(expected.calls), reference_call_sha256=sha(repr(expected.calls).encode()),
                candidate_call_sha256=sha(repr(actual.calls).encode()),
                reference_ds_sha256=sha(expected.memory['DS']), candidate_ds_sha256=sha(actual.memory['DS'])))
            if difference:
                raise AssertionError(f"{case['name']}: {difference}")
            for private in private_contexts:
                private_result=exercise(private,case)
                difference=first_difference(expected,private_result)
                assert not difference,(case['name'],difference)
                report['private_context_cases']+=1
        changed_tile = bytearray(reference)
        site = changed_tile.index(pack('<I', 0x828))
        changed_tile[site:site + 4] = pack('<I', 0x829)
        assert reference[-1:] == b'\xc3'
        report['negative_controls_detected'] = require_mutations_detected('status-panel', reference,
            [('wrong_panel_tile', bytes(changed_tile), cases()[0]),
             ('wrong_return_cleanup', reference[:-1] + b'\xc2\x04\x00', cases()[0])], exercise)
        report['status'] = 'PASS'
    except Exception as error:
        report['failure'] = str(error)
        raise
    finally:
        report['case_count'] = len(cases())
        report['cases_passed'] = sum(c['status'] == 'PASS' for c in report['cases'])
        output.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(f"PASS: {report['cases_passed']}/{report['case_count']} placed and {report['private_context_cases']} private cases; full DS, independent calls, ABI, callback mutations; complete 692-byte C routine, 41 LE operands")


if __name__ == '__main__':
    main()

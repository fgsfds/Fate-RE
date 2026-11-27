"""Compare original and C mouse-button assignment, conflict handling, and ABI."""
import argparse
from hashlib import sha256
import random
from pathlib import Path
from struct import pack, unpack

from differential import (
    Contract, Machine, Region, add_arguments, bind_bodies, compare_cases,
    failure_path, finish, require_mutations_detected, selected_cases,
)

ENTRY, SIZE, STACK, STOP = 0x3abbc, 550, 0x3f0000, 0x3ff000
POLL, DRAW, MENU, FORMAT = 0x3625c, 0x39511, 0x3963b, 0x601f3
RECORDS, LABELS, NAMES = 0x300000, 0x310000, 0x320000
BASE, FIXTURE = 0x80000, 'mouse-button-menu'
OFFSETS = dict(
    _mouse_row_format=0x122c, _mouse_blank=0x1232, _mouse_empty_format=0x1233,
    _mouse_menu_title=0x123b, _mouse_menu_prompt=0x1248, _mouse_action_labels=0x13558,
    _mouse_bindings=0x139f4, _mouse_button_names=0x139f7, _mouse_menu_entries=0x1741f4,
    _mouse_menu_rows=0x174268, _mouse_menu_selection=0x1745ac, _mouse_buttons=0x7dee2,
)
FUNCTIONS = dict(presentation_input_=POLL, draw_menu_frame_=DRAW,
                 run_menu_loop_=MENU, format_string_=FORMAT)
DATA = {name.removeprefix('_mouse_'): BASE + offset for name, offset in OFFSETS.items()}


def named_cases():
    yield dict(name='leave without edits', bindings=(0, 1, 2), events=[])
    yield dict(name='duplicate initial bindings choose first', bindings=(4, 4, 4), events=[])
    yield dict(name='unassigned and out-of-menu bindings persist', bindings=(255, 25, 200), events=[])
    for mask in (0, 1, 2, 4, 3, 7, 0x8000):
        yield dict(name=f'capture button mask {mask:#x}', bindings=(1, 2, 3),
                   events=[dict(selection=24, buttons=mask, idle=1)])
    yield dict(name='rebinding removes previous owners', bindings=(0, 1, 2),
               events=[dict(selection=24, buttons=1, idle=0),
                       dict(selection=0, buttons=1, idle=2),
                       dict(selection=0, buttons=2, idle=0),
                       dict(selection=24, buttons=4, idle=1)])
    yield dict(name='last owner wins even at a lower row index', bindings=(0, 1, 2),
               events=[dict(selection=24, buttons=1, idle=0),
                       dict(selection=1, buttons=1, idle=0)])


def randomized_cases(count=48, seed=0xFACE):
    generator = random.Random(seed)
    for index in range(count):
        yield dict(name=f'seeded mouse assignment {index + 1}',
                   bindings=tuple(generator.choice((*range(25), 255)) for _ in range(3)),
                   events=[dict(selection=generator.randrange(25),
                                buttons=generator.choice((0, 1, 2, 3, 4, 7, 0x8000)),
                                idle=generator.randrange(3))
                           for _ in range(generator.randrange(5))])


def expected_bindings(case):
    bindings = list(case['bindings'])
    owners = [bindings.index(action) if action in bindings else -1 for action in range(25)]
    for event in case['events']:
        buttons = event['buttons']
        if not buttons:
            continue
        button = 0 if buttons & 1 else 2 if buttons & 2 else 1
        owners = [-1 if owner == button else owner for owner in owners]
        owners[event['selection']] = button
    for action, button in enumerate(owners):
        if button != -1:
            bindings[button] = action
    return bytes(bindings)


def exercise(body, case):
    writable = [Region('bindings', DATA['bindings'], 3),
                Region('rows', DATA['menu_rows'], 25 * 30)]
    writable.extend(Region(f'value{index}', RECORDS + index * 21 + 7, 4) for index in range(25))
    contract = Contract(ENTRY, STOP, STACK, 4,
                        preserved=('ebx', 'ecx', 'edx', 'esi', 'edi', 'ebp'), results=('eax',))
    machine = Machine(contract, body, writable)
    machine.write(DATA['bindings'], bytes(case['bindings']))
    machine.write(DATA['menu_rows'], b'\xaa' * 750)
    for index in range(25):
        machine.write(DATA['menu_entries'] + index * 4, pack('<I', RECORDS + index * 21))
        machine.write(RECORDS + index * 21, b'\x55' * 21)
        machine.write(DATA['action_labels'] + index * 8, pack('<I', LABELS + index * 40))
    for button in range(3):
        machine.write(DATA['button_names'] + button * 4, pack('<I', NAMES + button * 16))
    events = iter(case['events'])
    current = None
    idle = 0

    def format_row(cpu):
        destination, fmt, label, button = unpack('<4I', cpu.read(cpu.register('esp') + 4, 16))
        assert DATA['menu_rows'] <= destination < DATA['menu_rows'] + 750
        assert (destination - DATA['menu_rows']) % 30 == 0
        assert label in {LABELS + index * 40 for index in range(25)}
        assert fmt in (DATA['row_format'], DATA['empty_format'])
        assert button in (DATA['blank'], NAMES, NAMES + 16, NAMES + 32)
        cpu.record('format', destination, fmt, label, button)
        text = f'{(label-LABELS)//40}:{button:#x}'.encode()
        cpu.write(destination, text.ljust(30, b'\0'))
        return {'eax': len(text)}

    def menu(cpu):
        nonlocal current, idle
        rows, = unpack('<I', cpu.read(cpu.register('esp') + 4, 4))
        args = tuple(cpu.register(name) for name in ('eax', 'edx', 'ebx', 'ecx'))
        assert args == (DATA['menu_selection'], 25, 0x83d, DATA['menu_title'])
        assert rows == DATA['menu_entries']
        current = next(events, None)
        cpu.record('menu', *args, rows, current['selection'] if current else -1)
        if current:
            idle = current['idle']
            cpu.write(DATA['menu_selection'], pack('<I', current['selection']))
        return {'eax': 1 if current else 0, 'ebx': 0xbad1, 'ecx': 0xbad2, 'edx': 0xbad30000}

    def poll(cpu):
        nonlocal idle
        assert current is not None
        if idle:
            idle -= 1
            cpu.record('poll', 0)
            return {'eax': 0}
        cpu.write(DATA['buttons'], pack('<H', current['buttons']))
        cpu.record('poll', 1, current['buttons'])
        return {'eax': 1}

    def draw(cpu):
        rows, = unpack('<I', cpu.read(cpu.register('esp') + 4, 4))
        args = tuple(cpu.register(name) for name in ('eax', 'edx', 'ebx', 'ecx'))
        assert args == (current['selection'], 25, 0x83d, DATA['menu_prompt'])
        assert rows == DATA['menu_entries']
        cpu.record('draw', *args, rows)
        return {'eax': 0xdeadface}

    machine.stub(FORMAT, format_row)
    machine.stub(POLL, poll)
    # These two menu APIs consume their one stack argument themselves.
    for address, callback in ((MENU, menu), (DRAW, draw)):
        machine.add_code(address, b'\xc2\x04\x00')
        machine.stubs[address] = callback
    return machine.run(dict(eax=0x100, ebx=0x200, ecx=0x300, edx=0x400,
                            esi=0x500, edi=0x600, ebp=0x700))


def check_reference(case, observation):
    assert observation.registers['eax'] == 0
    assert observation.memory['bindings'] == expected_bindings(case), 'binding ownership differs'
    for index in range(25):
        assert observation.memory[f'value{index}'] == bytes(4), 'temporary row value not cleared'


def mutation_checks(reference):
    # Mutate semantic operations, never LE fields or arbitrary instruction bytes.
    anchor = b'\xc7\x40\x07' + b'\xff' * 4
    if reference.count(anchor) != 2 or reference[-1:] != b'\xc3':
        raise AssertionError('Mouse ownership/return mutation anchors changed')
    index = reference.rfind(anchor)
    missing_clear = reference[:index] + b'\x90' * len(anchor) + reference[index + len(anchor):]
    wrong_saved = reference[:-2] + b'\x5a\xc3'  # Restore EBX from the wrong stack slot/register.
    scenario = list(named_cases())[-1]
    return require_mutations_detected(FIXTURE, reference, (
        ('missing previous-owner clear', missing_clear, scenario),
        ('missing EBX preservation', wrong_saved, scenario),
    ), exercise)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    add_arguments(parser)
    args = parser.parse_args()
    obj = args.object.read_bytes()
    args.object_sha256 = sha256(obj).hexdigest()
    reference, candidate, pointers = bind_bodies(
        args.executable.read_bytes(), obj, 'run_mouse_button_menu_', ENTRY, SIZE,
        OFFSETS, FUNCTIONS, behavior_only=args.behavior_only)
    count = compare_cases(
        FIXTURE, reference, candidate,
        selected_cases(args, FIXTURE, named_cases(), randomized_cases), exercise,
        seed=args.seed, failure_output=failure_path(args, FIXTURE),
        check_reference=check_reference, reuse_identical=not args.behavior_only)
    if not args.behavior_only:
        print(f'PASS: {len(mutation_checks(reference))} mouse-menu fixture mutations rejected')
    finish(args, FIXTURE, count, len(candidate), pointers)


if __name__ == '__main__':
    main()

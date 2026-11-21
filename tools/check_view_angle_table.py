"""Exact/differential checks for fixed-point view angles and the shared epilogue."""
import argparse
from functools import partial
from hashlib import sha256
from pathlib import Path
import random
from struct import pack

from differential import (
    Contract, Machine, Region, add_arguments, bind_bodies, compare_cases,
    failure_path, finish, require_mutations_detected, selected_cases,
)

ENTRY, SIZE, TAIL, STACK, STOP = 0x56e8f, 123, 0x4abbf, 0x3f0000, 0x3ff000
BASE, FIXTURE, CAPACITY = 0x80000, 'view-angle-table', 1280
OFFSETS = dict(_radarang=0x287e94, _column_angles=0x1dcde0,
               _view_width_reciprocal=0x286b04)
DATA = {name: BASE + offset for name, offset in OFFSETS.items()}
FUNCTIONS = dict(shared_graphics_epilogue_=TAIL)


def named_cases():
    for columns in (-1, 0, 1, 2, 17, 320, 640):
        for reciprocal in (0, 1, 65536, 838860, 13421772):
            yield dict(name=f'{columns} columns reciprocal {reciprocal}',
                       columns=columns, reciprocal=reciprocal, table_seed=0xA613)


def randomized_cases(count=48, seed=0xFACE):
    generator = random.Random(seed)
    for index in range(count):
        yield dict(name=f'seeded view angles {index + 1}',
                   columns=generator.randrange(1, 641), reciprocal=generator.randrange(13421773),
                   table_seed=generator.getrandbits(32))


def angle_table(case):
    generator = random.Random(case['table_seed'])
    return [generator.randrange(-32768, 32768) for _ in range(CAPACITY)]


def model(case):
    table = angle_table(case)
    output = bytearray(b'\xa5' * (CAPACITY * 2))
    step = (320 * case['reciprocal']) >> 16
    for column in range(max(case['columns'], 0)):
        # Use column * step rather than the implementation's register recurrence.
        phase = (column * step) & 0xffffffff
        integer, fraction = divmod(phase, 65536)
        if integer + 1 >= CAPACITY:
            raise ValueError('Fixture phase exceeds its angle table')
        interpolated = table[integer]
        if fraction:
            interpolated += ((table[integer + 1] - interpolated) * fraction) >> 16
        output[2 * column:2 * column + 2] = pack('<h', interpolated >> 6)
    return bytes(output)


def exercise(body, case, *, tail):
    machine = Machine(Contract(
        ENTRY, STOP, STACK, 4, preserved=('ebx', 'ecx', 'edx', 'esi', 'edi', 'ebp')),
        body, [Region('columns', DATA['_column_angles'], CAPACITY * 2)])
    # Execute the pinned original shared restore; don't substitute a RET stub.
    machine.add_code(TAIL, tail)
    machine.write(DATA['_radarang'], pack('<' + 'h' * CAPACITY, *angle_table(case)))
    machine.write(DATA['_view_width_reciprocal'], pack('<i', case['reciprocal']))
    machine.write(DATA['_column_angles'], b'\xa5' * (CAPACITY * 2))
    return machine.run(dict(eax=case['columns'], ebx=0x12345678, ecx=0x23456789,
                            edx=0x6789abcd, esi=0x3456789a, edi=0x456789ab, ebp=0x56789abc))


def check_reference(case, observation):
    if observation.memory['columns'] != model(case):
        raise AssertionError('view-angle interpolation specification differs')


def mutation_checks(reference, run):
    # Changing the interpolation divisor and dropping frame cleanup must fail.
    shift = b'\x0f\xac\xd0\x10'
    if reference.count(shift) != 2:
        raise AssertionError('View-angle multiply anchors changed')
    if reference[-8:-5] != b'\x83\xc4\x08' or reference[-5] != 0xe9:
        raise AssertionError('View-angle shared-frame cleanup changed')
    cases = list(named_cases())
    wrong_fraction = reference[:reference.rfind(shift)] + reference[reference.rfind(shift):].replace(
        shift, b'\x0f\xac\xd0\x0f', 1)
    return require_mutations_detected(FIXTURE, reference, (
        ('wrong interpolation scale', wrong_fraction, cases[-1]),
        ('missing shared-frame cleanup', reference[:-8] + b'\x90' * 3 + reference[-5:],
         cases[0]),
    ), run)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    add_arguments(parser)
    args = parser.parse_args()
    image, obj = args.executable.read_bytes(), args.object.read_bytes()
    args.object_sha256 = sha256(obj).hexdigest()
    reference, candidate, pointers = bind_bodies(
        image, obj, 'rebuild_view_angle_table_', ENTRY, SIZE, OFFSETS, FUNCTIONS,
        behavior_only=args.behavior_only)
    tail = image[TAIL + 0x25600:TAIL + 0x25600 + 6]
    if tail != b'\x5f\x5e\x5a\x59\x5b\xc3':
        raise AssertionError('Pinned shared graphics epilogue changed')
    run = partial(exercise, tail=tail)
    count = compare_cases(
        FIXTURE, reference, candidate,
        selected_cases(args, FIXTURE, named_cases(), randomized_cases), run,
        seed=args.seed, failure_output=failure_path(args, FIXTURE),
        check_reference=check_reference, reuse_identical=not args.behavior_only)
    if not args.behavior_only:
        print(f'PASS: {len(mutation_checks(reference, run))} view-angle mutations rejected')
    finish(args, FIXTURE, count, len(candidate), pointers)


if __name__ == '__main__':
    main()

"""Exact/behavioral checks for Build's overlapping wall-bunch scan selection."""
import argparse
from hashlib import sha256
from pathlib import Path
import random
from struct import pack

from differential import (
    Contract, Machine, add_arguments, bind_bodies, compare_cases, failure_path,
    finish, require_mutations_detected, selected_cases,
)

ENTRY, SIZE, STACK, STOP = 0x45576, 154, 0x3f0000, 0x3ff000
BASE, FIXTURE, WALLFRONT = 0x80000, 'bunchfront', 0x45313
FIRST, SECOND, SECOND_SCAN, SCAN_STRIDE = 2, 5, 16, 2
OFFSETS = dict(_bunchfirst=0x1d7560, _bunchlast=0x1d9560, _p2=0x1d8560,
               _xb1=0x1c5160, _xb2=0x1c3160)
FUNCTIONS = dict(wallfront_=WALLFRONT)


def scenario(name, first, second, result=1):
    return dict(name=name, first=first, second=second, result=result)


def named_cases():
    yield scenario('first entirely left', [(0, 2)], [(3, 8)])
    yield scenario('second entirely left', [(3, 8)], [(0, 2)])
    yield scenario('equal starts choose first wall against second', [(2, 4)], [(2, 6)], -1)
    yield scenario('shared right endpoint still overlaps', [(0, 3)], [(3, 8)], 0)
    yield scenario('first starts later without advancing second', [(3, 6)], [(0, 8)], 0)
    yield scenario('first starts later advances second chain', [(8, 10)],
                   [(0, 2), (3, 5), (6, 9), (10, 13)])
    yield scenario('second starts later advances first chain',
                   [(0, 2), (3, 5), (6, 9), (10, 13)], [(8, 10)], -1)
    yield scenario('negative screen coordinates', [(-20, -10), (-9, -1)],
                   [(-12, -5), (-4, 2)])
    yield scenario('one-column overlap', [(4, 4)], [(4, 4)])


def randomized_cases(count=48, seed=0xFACE):
    generator = random.Random(seed)

    def chain():
        left = generator.randrange(-30, 31)
        result = []
        for _ in range(generator.randrange(1, 9)):
            right = left + generator.randrange(1, 8)
            result.append((left, right))
            left = right + 1
        return result

    for index in range(count):
        yield scenario(f'seeded wall bunches {index + 1}', chain(), chain(),
                       generator.choice((-1, 0, 1, 0x12345678)))


def model(case):
    """Select by horizontal intervals independently of register/index arithmetic."""
    first, second = case['first'], case['second']
    if first[0][0] > second[-1][1] or second[0][0] > first[-1][1]:
        return 0xffffffff, ()
    if first[0][0] >= second[0][0]:
        index = next(i for i, (_, right) in enumerate(second) if right >= first[0][0])
        arguments = (0, SECOND_SCAN + SCAN_STRIDE * index)
    else:
        index = next(i for i, (_, right) in enumerate(first) if right >= second[0][0])
        arguments = (SCAN_STRIDE * index, SECOND_SCAN)
    return case['result'] & 0xffffffff, (('wallfront', *arguments),)


def exercise(body, case):
    machine = Machine(Contract(
        ENTRY, STOP, STACK, 4, preserved=('ebx', 'ecx', 'esi', 'edi', 'ebp'),
        results=('eax',)), body)
    for bunch, start, intervals in ((FIRST, 0, case['first']),
                                    (SECOND, SECOND_SCAN, case['second'])):
        machine.write(BASE + OFFSETS['_bunchfirst'] + 2 * bunch, pack('<h', start))
        machine.write(BASE + OFFSETS['_bunchlast'] + 2 * bunch,
                      pack('<h', start + SCAN_STRIDE * (len(intervals) - 1)))
        # Leave holes so walking p2 cannot accidentally pass as index++.
        for relative, (left, right) in enumerate(intervals):
            index = start + SCAN_STRIDE * relative
            machine.write(BASE + OFFSETS['_xb1'] + 4 * index, pack('<i', left))
            machine.write(BASE + OFFSETS['_xb2'] + 4 * index, pack('<i', right))
            machine.write(BASE + OFFSETS['_p2'] + 2 * index, pack('<h', index + SCAN_STRIDE))

    def classify(cpu):
        cpu.record('wallfront', cpu.register('eax'), cpu.register('edx'))
        return dict(eax=case['result'], edx=0xbad0bad0)

    machine.stub(WALLFRONT, classify)
    return machine.run(dict(eax=FIRST, edx=SECOND, ebx=0x12345678, ecx=0x23456789,
                            esi=0x3456789a, edi=0x456789ab, ebp=0x56789abc))


def check_reference(case, observation):
    result, calls = model(case)
    if observation.registers['eax'] != result or observation.calls != calls:
        raise AssertionError(f'bunchfront specification expected {(result, calls)}, got {observation}')


def mutation_checks(reference):
    no_overlap = b'\xb8\xff\xff\xff\xff'
    arguments = b'\x89\xc2\x89\xf8'
    if reference.count(no_overlap) != 1 or reference.count(arguments) != 1:
        raise AssertionError('Bunchfront mutation anchors changed')
    if reference[-2:] != b'\x5b\xc3':
        raise AssertionError('Bunchfront register restore changed')
    cases = list(named_cases())
    return require_mutations_detected(FIXTURE, reference, (
        ('lost no-overlap sentinel', reference.replace(no_overlap, b'\xb8\0\0\0\0'), cases[0]),
        ('wrong first wallfront argument',
         reference.replace(arguments, b'\x89\xc2\x89\xf0'), cases[5]),
        ('wrong EBX restore', reference[:-2] + b'\x5a\xc3', cases[5]),
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
        args.executable.read_bytes(), obj, 'bunchfront_', ENTRY, SIZE,
        OFFSETS, FUNCTIONS, behavior_only=args.behavior_only)
    count = compare_cases(
        FIXTURE, reference, candidate,
        selected_cases(args, FIXTURE, named_cases(), randomized_cases), exercise,
        seed=args.seed, failure_output=failure_path(args, FIXTURE),
        check_reference=check_reference, reuse_identical=not args.behavior_only)
    if not args.behavior_only:
        print(f'PASS: {len(mutation_checks(reference))} bunchfront mutations rejected')
    finish(args, FIXTURE, count, len(candidate), pointers)


if __name__ == '__main__':
    main()

"""Exact/differential tests for the smaller-sector portal search and its ABI."""
import argparse
from hashlib import sha256
from pathlib import Path
import random
from struct import pack

from differential import (
    Contract, Machine, add_arguments, bind_bodies, compare_cases, failure_path,
    finish, require_mutations_detected, selected_cases,
)

ENTRY, SIZE, STACK, STOP = 0x2f3ce, 157, 0x3f0000, 0x3ff000
BASE, FIXTURE = 0x80000, 'sector-portal'
OFFSETS = dict(_sector_wall_counts=0x27c3a2, _sector_wall_starts=0x27c3a0, _wall=0x2310a0)
FIRST, SECOND = 3, 7


def scenario(name, first, second, **changes):
    return dict(name=name, first=list(first), second=list(second),
                count_first=len(first), count_second=len(second)) | changes


def named_cases():
    yield scenario('both sectors empty', [], [])
    yield scenario('first sector empty', [], [FIRST])
    yield scenario('second sector empty', [SECOND], [])
    yield scenario('first smaller finds first wall', [SECOND, -1], [-1] * 3)
    yield scenario('first smaller finds last wall', [-1, SECOND], [-1] * 3)
    yield scenario('second smaller finds last wall', [-1] * 3, [-1, FIRST])
    yield scenario('equal counts choose second sector', [SECOND], [-1])
    yield scenario('equal counts find second sector portal', [-1], [FIRST])
    yield scenario('neither sector has a portal', [-1, 2], [1, 4, 5])
    yield scenario('negative first count does not scan', [], [FIRST], count_first=-1)
    yield scenario('negative second count does not scan', [SECOND], [], count_second=-1)


def randomized_cases(count=48, seed=0xFACE):
    generator = random.Random(seed)
    for index in range(count):
        yield scenario(f'seeded sector portals {index + 1}',
                       [generator.choice((-1, 0, SECOND, 9)) for _ in range(generator.randrange(9))],
                       [generator.choice((-1, 0, FIRST, 9)) for _ in range(generator.randrange(9))])


def expected_result(case):
    if case['count_second'] > case['count_first']:
        return int(case['count_first'] > 0 and SECOND in case['first'][:case['count_first']])
    return int(case['count_second'] > 0 and FIRST in case['second'][:case['count_second']])


def exercise(body, case):
    contract = Contract(ENTRY, STOP, STACK, 4,
                        preserved=('ebx', 'ecx', 'esi', 'edi', 'ebp'), results=('eax',))
    machine = Machine(contract, body)
    for sector, start, count, walls in (
            (FIRST, 0, case['count_first'], case['first']),
            (SECOND, 16, case['count_second'], case['second'])):
        machine.write(BASE + OFFSETS['_sector_wall_starts'] + 40 * sector, pack('<hh', start, count))
        for index, adjacent in enumerate(walls):
            machine.write(BASE + OFFSETS['_wall'] + 32 * (start + index) + 12, pack('<h', adjacent))
    # The public consumes signed short IDs in full-width ABI registers. Poison
    # their upper halves to catch accidental use of the unnarrowed inputs.
    return machine.run(dict(eax=0xbeef0000 | FIRST, edx=0xcafe0000 | SECOND,
                            ebx=0x12345678, ecx=0x23456789, esi=0x3456789a,
                            edi=0x456789ab, ebp=0x56789abc))


def check_reference(case, observation):
    expected = expected_result(case)
    if observation.registers['eax'] != expected:
        raise AssertionError(f'portal search expected {expected}, got {observation.registers["eax"]}')


def mutation_checks(reference):
    result = b'\xba\x01\x00\x00\x00'
    tie = b'\x7e\x2f'
    if reference.count(result) != 1 or reference.count(tie) != 1:
        raise AssertionError('Portal result/tie mutation anchors changed')
    missing_result = reference.replace(result, b'\xba\x00\x00\x00\x00')
    wrong_tie = reference.replace(tie, b'\x7f\x2f')
    cases = list(named_cases())
    return require_mutations_detected(FIXTURE, reference, (
        ('success result lost', missing_result, cases[3]),
        ('wrong equal-count scan side', wrong_tie, cases[7]),
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
        args.executable.read_bytes(), obj, 'sectors_share_portal_', ENTRY, SIZE,
        OFFSETS, {}, behavior_only=args.behavior_only)
    count = compare_cases(
        FIXTURE, reference, candidate,
        selected_cases(args, FIXTURE, named_cases(), randomized_cases), exercise,
        seed=args.seed, failure_output=failure_path(args, FIXTURE),
        check_reference=check_reference, reuse_identical=not args.behavior_only)
    if not args.behavior_only:
        print(f'PASS: {len(mutation_checks(reference))} sector-portal mutations rejected')
    finish(args, FIXTURE, count, len(candidate), pointers)


if __name__ == '__main__':
    main()

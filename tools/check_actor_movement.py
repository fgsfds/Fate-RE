"""Exact or research-only differential checks for actor movement and turning."""
import argparse
import random
from hashlib import sha256
from pathlib import Path
from struct import pack, unpack

from differential import (
    Contract, Machine, Region, add_arguments, bind_bodies, compare_cases,
    failure_path, finish, require_mutations_detected, selected_cases,
)

ENTRY, SIZE, DATA_BASE = 0x196b2, 326, 0x80000
ABS_LONG, ABS_INT, GET_ANGLE, ROUTE = 0x602c3, 0x6032c, 0x4c94c, 0x1d3ee
STACK, STOP, SHARED_RETURN, SUPPORT = 0x3f0000, 0x3ff000, 0x197f0, 0x3e0000
OFFSETS = {
    '_movement_actor_sprite': 0x7dab8, '_movement_sprite_x': 0x2040a0,
    '_movement_sprite_y': 0x2040a4, '_movement_sprite_angle': 0x2040bc,
    '_advance_clock': 0x229b, '_actor_kind': 0x7f0a0,
}
FUNCTIONS = {
    'absolute_long_': ABS_LONG, 'absolute_int_': ABS_INT, 'getangle_': GET_ANGLE,
    'route_actor_toward_target_': ROUTE, 'move_actor_return_': SHARED_RETURN,
}
DATA = {name: DATA_BASE + offset for name, offset in OFFSETS.items()}
ACTOR, SPRITE, POSITION, ATTACK_TARGET = 3, 7, (1000, -600), -6
SAVED = dict(zip(('ebp', 'esi', 'edi'), (0xbadd0001, 0xbadd0002, 0xbadd0003)))
FIXTURE = 'actor-movement'


def signed(value):
    value &= 0xffffffff
    return value - 0x100000000 if value & 0x80000000 else value


def named_cases():
    near, turn = (1512, -1112), (1234, -789)
    close = [('abs_long', 512), ('abs_long', -512)]
    turn_calls = [*close, ('angle', 234, -189)]
    rows = (
        (((1513, -600), turn, 1, 111, 0),
         (1, 111, [('abs_long', 513), ('route', ACTOR, 1513, -600, ATTACK_TARGET)])),
        (((1512, -1113), turn, 1, 222, 0),
         (1, 222, [('abs_long', 512), ('abs_long', -513), ('route', ACTOR, 1512, -1113, ATTACK_TARGET)])),
        ((near, (0, 0), 1, 800, 0), (0, 800, close)),
        ((near, turn, 0, 800, 0), (9, 800, close)),
        ((near, turn, 1, 810, 900), (0, 900, [*turn_calls, ('abs_angle', 90)])),
        ((near, turn, 1, 300, 1100), (2, 556, [*turn_calls, ('abs_angle', 800), ('abs_angle', 544)])),
        ((near, turn, 1, 900, 300), (2, 644, [*turn_calls, ('abs_angle', -600), ('abs_angle', -344)])),
        ((near, turn, 1, 1900, 50), (2, 50, [*turn_calls, ('abs_angle', -1850), ('abs_angle', -58)])),
        ((near, turn, 1, 25, 1900), (2, 1900, [*turn_calls, ('abs_angle', 1875), ('abs_angle', 83)])),
        ((near, turn, 1, 13, 269), (2, 269, [*turn_calls, ('abs_angle', 256), ('abs_angle', 0)])),
    )
    return [dict(name=f'named movement {index}', destination=args[0], turning_point=args[1],
                 clock=args[2], old_angle=args[3], desired_angle=args[4], expected=expected)
            for index, (args, expected) in enumerate(rows, 1)]


def randomized_cases(count=48, seed=0xFACE):
    generator = random.Random(seed)
    deltas = (-0x80000000, -513, -512, -511, -1, 0, 1, 511, 512, 513, 0x7fffffff)
    angles = (0, 1, 255, 256, 257, 1023, 1024, 1025, 1791, 1792, 2047)
    for index in range(count):
        yield dict(name=f'seeded movement {index + 1}',
                   destination=tuple(signed(position + generator.choice(deltas)) for position in POSITION),
                   turning_point=generator.choice(((0, 0), (1234, -789), (-0x80000000, 0x7fffffff))),
                   clock=generator.choice((-32768, -1, 0, 1, 32767)),
                   old_angle=generator.choice(angles), desired_angle=generator.choice(angles))


def boundary_cases():
    for old, desired in ((0, 255), (0, 256), (0, 257), (0, 1023), (0, 1024),
                         (0, 1025), (2047, 0), (0, 2047), (-32768, 0), (32767, 0)):
        yield dict(name=f'angle boundary {old} to {desired}', destination=POSITION,
                   turning_point=(1234, -789), clock=1, old_angle=old, desired_angle=desired)


def exercise(body, case, shared_tail):
    kind = DATA['_actor_kind'] + ACTOR
    angle = DATA['_movement_sprite_angle'] + 44 * SPRITE
    machine = Machine(Contract(ENTRY, STOP, STACK, 12, instruction_limit=1000), body,
                      (Region('actor_kind', kind, 1), Region('angle', angle, 2)))
    # A candidate may have a different extent. Its external shared return is
    # placed outside both bodies instead of assuming the original tail offset.
    machine.add_code(SUPPORT, shared_tail)

    def absolute_long(cpu):
        value = signed(cpu.register('eax'))
        cpu.record('abs_long', value)
        return {'eax': abs(value)}

    def absolute_int(cpu):
        value = signed(cpu.register('eax'))
        cpu.record('abs_angle', value)
        return {'eax': abs(value)}

    def angle_call(cpu):
        cpu.record('angle', signed(cpu.register('eax')), signed(cpu.register('edx')))
        return {'eax': case['desired_angle']}

    def route(cpu):
        cpu.record('route', *(signed(cpu.register(name)) for name in ('eax', 'edx', 'ebx', 'ecx')))
        return {'eax': 0xdeadface}  # Only EAX is volatile in this observed ABI.

    for address, callback in ((ABS_LONG, absolute_long), (ABS_INT, absolute_int),
                              (GET_ANGLE, angle_call), (ROUTE, route)):
        machine.stub(address, callback)
    machine.write(DATA['_movement_actor_sprite'] + 2 * ACTOR, pack('<h', SPRITE))
    machine.write(DATA['_movement_sprite_x'] + 44 * SPRITE, pack('<i', POSITION[0]))
    machine.write(DATA['_movement_sprite_y'] + 44 * SPRITE, pack('<i', POSITION[1]))
    machine.write(angle, pack('<h', case['old_angle']))
    machine.write(kind, b'\x09')
    machine.write(DATA['_advance_clock'], pack('<h', case['clock']))
    return machine.run(dict(eax=0xbeef0000 | ACTOR, edx=case['destination'][0],
                            ebx=case['destination'][1], ecx=0xcafe0000 | (ATTACK_TARGET & 0xffff),
                            **SAVED), case['turning_point'])


def check_reference(case, observation):
    if 'expected' not in case:
        return
    state, angle, calls = case['expected']
    actual = (observation.memory['actor_kind'][0], unpack('<h', observation.memory['angle'])[0],
              list(observation.calls))
    expected = (state, angle, [tuple(call) for call in calls])
    if actual != expected:
        raise AssertionError(f'original violates named expectation: {actual} != {expected}')


def mutation_checks(reference):
    cases = named_cases()
    tail = reference[SHARED_RETURN - ENTRY:]
    execute = lambda body, case: exercise(body, case, tail)
    # This is a semantic state store, not a relocation or arbitrary instruction byte.
    store = b'\xc6\x81' + DATA['_actor_kind'].to_bytes(4, 'little') + b'\x02'
    offset = reference.find(store)
    if offset < 0:
        raise AssertionError('Actor-state mutation anchor disappeared')
    missing = reference[:offset] + b'\x90' * len(store) + reference[offset + len(store):]
    ret = reference.rfind(b'\xc2\x08\x00')
    if ret < 0:
        raise AssertionError('Actor stack-cleanup mutation anchor disappeared')
    cleanup = reference[:ret] + b'\xc2\x04\x00' + reference[ret + 3:]
    branch = reference.find(bytes.fromhex('3d 00 02 00 00 0f 8f'))
    if branch < 0 or reference[ret-2:ret] != b'\x5f\x5e':
        raise AssertionError('Actor branch/preserved-register mutation anchor disappeared')
    wrong_branch = bytearray(reference)
    wrong_branch[branch + 6] = 0x8e
    wrong_saved = bytearray(reference)
    wrong_saved[ret - 2] = 0x5b
    return require_mutations_detected(FIXTURE, reference, (
        ('missing actor-state store', missing, cases[5]),
        ('wrong stack cleanup', cleanup, cases[0]),
        ('wrong distance branch', bytes(wrong_branch), cases[0]),
        ('missing EDI preservation', bytes(wrong_saved), cases[0]),
    ), execute)


def check(executable, obj, args):
    original, candidate, pointers = bind_bodies(
        executable, obj, 'move_actor_', ENTRY, SIZE, OFFSETS, FUNCTIONS,
        behavior_only=args.behavior_only,
        execution_functions={**FUNCTIONS, 'move_actor_return_': SUPPORT})
    tail = original[SHARED_RETURN - ENTRY:]
    count = compare_cases(
        FIXTURE, original, candidate,
        selected_cases(args, FIXTURE, [*named_cases(), *boundary_cases()], randomized_cases),
        lambda body, case: exercise(body, case, tail), seed=args.seed,
        failure_output=failure_path(args, FIXTURE), check_reference=check_reference,
        reuse_identical=not args.behavior_only)
    if not args.behavior_only:
        print(f'PASS: {len(mutation_checks(original))} actor fixture mutations rejected')
    finish(args, FIXTURE, count, len(candidate), pointers)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    add_arguments(parser)
    args = parser.parse_args()
    obj = args.object.read_bytes()
    args.object_sha256 = sha256(obj).hexdigest()
    check(args.executable.read_bytes(), obj, args)

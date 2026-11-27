"""Verify the exact tile-copy body and its column-major copying behavior."""

import argparse
import random
from hashlib import sha256
from pathlib import Path
from struct import pack

from differential import (
    Contract, Machine, Observation, Region, add_arguments, bind_bodies, compare_cases, failure_path,
    finish, first_difference, require_mutations_detected, selected_cases,
)
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES


ADDRESS = 0x4CB3A
TARGET_SIZE = 336
STACK = 0x3F0000
RETURN = 0x3FF000
LOADTILE = 0x4BB0D
TILESIZX = 0x1F2020
TILESIZY = 0x1F4020
WALOFF = 0x1FFCA0
SOURCE_TILE = 3
DESTINATION_TILE = 4
SOURCE_POINTER = 0x300000
DESTINATION_POINTER = 0x301000
FIXTURE = 'copytilepiece'


CASES = (
    {
        "name": "column-major copy",
        "sizes": (3, 4, 5, 6),
        "pixels": (bytes([10, 11, 12, 20, 21, 22, 30, 31, 32, 255, 41, 42]), bytes([0xAA] * 30)),
        "source": (0, 1), "copy": (2, 3), "destination": (1, 2),
    },
    {
        "name": "opaque and transparent pixels",
        "sizes": (3, 4, 5, 6),
        "pixels": (bytes([10, 11, 12, 20, 21, 22, 30, 255, 32, 40, 41, 42]), bytes([0x33] * 30)),
        "source": (1, 0), "copy": (1, 4), "destination": (2, 1),
    },
    {
        "name": "source wrapping and destination clipping",
        "sizes": (3, 2, 4, 5),
        "pixels": (bytes([1, 2, 3, 4, 5, 6]), bytes([0x77] * 20)),
        "source": (1, 1), "copy": (5, 4), "destination": (-1, 1),
    },
    {
        "name": "transparent pixels and lazy tile loads",
        "sizes": (3, 4, 5, 6),
        "pixels": (bytes([255] * 12), bytes([0x55] * 30)),
        "source": (2, 3), "copy": (3, 2), "destination": (2, 4), "lazy": True,
    },
    {
        "name": "single missing tile buffer",
        "sizes": (3, 4, 5, 6),
        "pixels": (bytes(range(12)), bytes([0x66] * 30)),
        "source": (1, 1), "copy": (1, 2), "destination": (1, 1),
        "lazy": True, "unloaded_tiles": (DESTINATION_TILE,),
    },
    {
        "name": "zero-sized source exits before loading",
        "sizes": (0, 4, 5, 6),
        "pixels": (bytes([0]), bytes([0x44] * 30)),
        "source": (0, 0), "copy": (1, 1), "destination": (0, 0), "lazy": True,
    },
    {
        "name": "zero row count still resolves tile buffers",
        "sizes": (3, 4, 5, 6),
        "pixels": (bytes(range(12)), bytes([0x22] * 30)),
        "source": (0, 0), "copy": (2, 0), "destination": (0, 0), "lazy": True,
    },
    {
        "name": "all unsigned pixel values including transparency",
        "sizes": (16, 16, 16, 16),
        "pixels": (bytes(range(256)), bytes([0x55] * 256)),
        "source": (0, 0), "copy": (16, 16), "destination": (0, 0),
    },
)


def randomized_cases(count=48, seed=0xFACE):
    """Yield repeatable valid and boundary-heavy combinations for differential execution."""
    generator = random.Random(seed)
    for index in range(count):
        source_width = generator.randint(0, 8)
        source_height = generator.randint(0, 8)
        destination_width = generator.randint(0, 8)
        destination_height = generator.randint(0, 8)
        source_size = max(1, source_width * source_height)
        destination_size = max(1, destination_width * destination_height)
        source = (
            generator.randrange(source_width) if source_width else 0,
            generator.randrange(source_height) if source_height else 0,
        )
        unloaded = tuple(tile for tile in (SOURCE_TILE, DESTINATION_TILE)
                         if generator.randrange(2))
        yield {
            "name": f"seeded differential case {index + 1}",
            "sizes": (source_width, source_height, destination_width, destination_height),
            "pixels": (
                bytes(generator.randrange(256) for _ in range(source_size)),
                bytes(generator.randrange(256) for _ in range(destination_size)),
            ),
            "source": source,
            "copy": (generator.randint(0, 10), generator.randint(0, 10)),
            "destination": (
                generator.randint(-4, destination_width + 3),
                generator.randint(-4, destination_height + 3),
            ),
            "unloaded_tiles": unloaded,
        }


def boundary_cases():
    for name, changes in (
            ('negative column count', {'copy': (-1, 1)}),
            ('negative row count', {'copy': (1, -1)}),
            ('destination exactly at right edge', {'destination': (1, 0)}),
            ('destination exactly at bottom edge', {'destination': (0, 1)}),
            ('negative source width', {'sizes': (-1, 1, 1, 1)}),
            ('negative destination height', {'sizes': (1, 1, 1, -1)})):
        yield dict(name=name, sizes=(1, 1, 1, 1), pixels=(b'\x12', b'\xaa'),
                   source=(0, 0), copy=(1, 1), destination=(0, 0)) | changes
    for offset in (0, 1, 3):
        yield dict(name=f'overlapping tile buffers +{offset}', sizes=(3, 4, 3, 4),
                   pixels=(bytes(range(12)), bytes(range(101, 113))), source=(0, 0),
                   copy=(3, 4), destination=(0, 0), alias_offset=offset)
    yield dict(name='forward overlap propagates earlier writes', sizes=(1, 4, 1, 4),
               pixels=(b'\x01\x02\x03\x04', b'\x09\x0a\x0b\x0c'), source=(0, 0),
               copy=(1, 4), destination=(0, 0), alias_offset=1)


def model(case):
    """Independent column-major specification for the bounded fixture inputs.

    Use one backing store so overlapping buffers observe prior pixel writes.
    This deliberately is not a snapshot copy or memcpy/memmove specification.
    """
    sw, sh, dw, dh = case['sizes']
    source, destination = case['pixels']
    dp = SOURCE_POINTER + case['alias_offset'] if 'alias_offset' in case else DESTINATION_POINTER
    base = min(SOURCE_POINTER, dp)
    memory = bytearray(max(SOURCE_POINTER + len(source), dp + len(destination)) - base)
    sp, dest = SOURCE_POINTER - base, dp - base
    memory[sp:sp + len(source)] = source
    memory[dest:dest + len(destination)] = destination
    unloaded = set(case.get('unloaded_tiles',
                            (SOURCE_TILE, DESTINATION_TILE) if case.get('lazy') else ()))
    pointers = [0 if tile in unloaded else pointer
                for tile, pointer in ((SOURCE_TILE, SOURCE_POINTER), (DESTINATION_TILE, dp))]
    calls = []
    if min(sw, sh, dw, dh) > 0:
        for index, tile in enumerate((SOURCE_TILE, DESTINATION_TILE)):
            if tile in unloaded:
                calls.append(('loadtile', tile))
                pointers[index] = (SOURCE_POINTER, dp)[index]
        sx = case['source'][0]
        for column in range(case['copy'][0]):
            sy = case['source'][1]
            for row in range(case['copy'][1]):
                dx, dy = case['destination'][0] + column, case['destination'][1] + row
                if 0 <= dx < dw and 0 <= dy < dh:
                    color = memory[sp + sx * sh + sy]
                    if color != 255:
                        memory[dest + dx * dh + dy] = color
                sy += 1
                if sy >= sh:
                    sy = 0
            sx += 1
            if sx >= sw:
                sx = 0
    return Observation({}, dict(destination=bytes(memory[dest:dest + len(destination)]),
                                tile_pointers=pack('<2I', *pointers)), tuple(calls))


def check_reference(case, observation):
    difference = first_difference(model(case), observation)
    if difference:
        raise AssertionError('original violates tile-copy specification: ' + difference)


def execute(body, case):
    source_width, source_height, destination_width, destination_height = case["sizes"]
    source_pixels, destination_pixels = case["pixels"]
    destination_pointer = (SOURCE_POINTER + case['alias_offset'] if 'alias_offset' in case
                           else DESTINATION_POINTER)
    machine = Machine(Contract(ADDRESS, RETURN, STACK, 20), body, (
        Region('destination', destination_pointer, len(destination_pixels)),
        Region('tile_pointers', WALOFF + SOURCE_TILE * 4, 8),
    ))
    machine.write(TILESIZX + SOURCE_TILE * 2, pack("<h", source_width))
    machine.write(TILESIZY + SOURCE_TILE * 2, pack("<h", source_height))
    machine.write(TILESIZX + DESTINATION_TILE * 2, pack("<h", destination_width))
    machine.write(TILESIZY + DESTINATION_TILE * 2, pack("<h", destination_height))
    machine.write(SOURCE_POINTER, source_pixels)
    machine.write(destination_pointer, destination_pixels)
    unloaded = set(case.get(
        "unloaded_tiles",
        (SOURCE_TILE, DESTINATION_TILE) if case.get("lazy") else (),
    ))
    if SOURCE_TILE not in unloaded:
        machine.write(WALOFF + SOURCE_TILE * 4, pack("<I", SOURCE_POINTER))
    if DESTINATION_TILE not in unloaded:
        machine.write(WALOFF + DESTINATION_TILE * 4, pack("<I", destination_pointer))

    def load_tile(cpu):
        tile = cpu.register('eax') & 0xffff
        cpu.record('loadtile', tile)
        pointer = {SOURCE_TILE: SOURCE_POINTER, DESTINATION_TILE: destination_pointer}[tile]
        cpu.write(WALOFF + tile * 4, pack('<I', pointer))
        return {'eax': 0xdeadface}

    machine.stub(LOADTILE, load_tile)
    return machine.run(dict(eax=SOURCE_TILE, edx=case['source'][0], ebx=case['source'][1],
                            ecx=case['copy'][0], ebp=0xbadd0001, esi=0xbadd0002, edi=0xbadd0003),
                       (case['copy'][1], DESTINATION_TILE, *case['destination']))


def replace_once(body, anchor, replacement):
    if len(anchor) != len(replacement) or body.count(anchor) != 1:
        raise AssertionError('Tile mutation anchor changed or is ambiguous')
    return body.replace(anchor, replacement, 1)


def mutation_checks(reference):
    return require_mutations_detected(FIXTURE, reference, (
        ('missing pixel store', replace_once(reference, b'\x88\x19', b'\x90\x90'), CASES[0]),
        ('wrong transparency branch',
         replace_once(reference, bytes.fromhex('81 fe ff 00 00 00 74 02'),
                      bytes.fromhex('81 fe ff 00 00 00 75 02')), CASES[1]),
        ('wrong stack cleanup', replace_once(reference, b'\xc2\x10\x00', b'\xc2\x0c\x00'), CASES[0]),
        ('right-edge off-by-one',
         replace_once(reference, b'\x7d\x3e', b'\x7f\x3e'), list(boundary_cases())[2]),
    ), execute)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("executable", type=Path)
    parser.add_argument("object", type=Path, help="Watcom object containing copytilepiece_")
    add_arguments(parser)
    args = parser.parse_args()

    executable = args.executable.read_bytes()
    obj = args.object.read_bytes()
    args.object_sha256 = sha256(obj).hexdigest()
    target, candidate, pointers = bind_bodies(
        executable, obj, 'copytilepiece_', ADDRESS, TARGET_SIZE,
        DATA_OFFSETS, dict(FUNCTION_ADDRESSES, loadtile_=LOADTILE),
        data_base=0, behavior_only=args.behavior_only)
    count = compare_cases(
        FIXTURE, target, candidate,
        selected_cases(args, FIXTURE, [*CASES, *boundary_cases()], randomized_cases),
        execute, seed=args.seed, failure_output=failure_path(args, FIXTURE),
        check_reference=check_reference, reuse_identical=not args.behavior_only)
    if not args.behavior_only:
        print(f'PASS: {len(mutation_checks(target))} tile fixture mutations rejected')
    finish(args, FIXTURE, count, len(candidate), pointers)


if __name__ == "__main__":
    main()

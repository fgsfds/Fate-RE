"""Place the verified C, NASM and library spans into contiguous LE object images."""
import argparse
import hashlib
import json
from pathlib import Path

from bind_crush_init_group import bind as bind_crush
from bind_melee_group import bind as bind_melee
from compare_exe import TARGET_SHA256
from graphics_font_dependency import GRAPH_LIBRARY, load_fonts
from match_objects import read_object
from verify_c_leaf import CODE_OFFSETS, DATA_OFFSETS, FUNCTION_ADDRESSES, bind_leaf_details
from verify_cache_unit import verify_unit_layout
from verify_network_defaults import SCALARS, verify_object


CODE_RAW, CODE_SIZE = 0x35600, 414639
DATA_RAW, DATA_SIZE = 0x9b600, 104931
ROOT = Path(__file__).resolve().parents[1]


def digest(payload):
    return hashlib.sha256(payload).hexdigest()


def read_inventory(name):
    inventory = json.loads((ROOT / 'tools/data' / (name + '.json')).read_text(encoding='utf-8'))
    if inventory['target_sha256'] != TARGET_SHA256:
        raise ValueError(f'Wrong executable inventory: {name}')
    return inventory['spans'] + inventory.get('non_routine_code_spans', [])


def place(spans, start, size):
    result = bytearray()
    cursor = start
    for address, payload in sorted(spans):
        if address != cursor:
            raise ValueError(f'Gap or overlap at file offset {cursor:#x}: next span starts at {address:#x}')
        result.extend(payload)
        cursor += len(payload)
    if cursor != start + size:
        raise ValueError(f'Object image size differs at file offset {cursor:#x}')
    return result


def checked_slice(payload, row, hash_field):
    offset = row.get('binary_offset', 0)
    value = payload[offset:offset + row['bytes']]
    hashed = payload if 'loaded_bytes' in row else value
    if (len(value) != row['bytes']
            or len(hashed) != row.get('loaded_bytes', row['bytes'])
            or digest(hashed) != row[hash_field]):
        raise ValueError(f'Verified span changed at file offset {row["raw_offset"]}')
    return value


def code_images(objects, binaries):
    for row in read_inventory('matching-assembly'):
        yield int(row['raw_offset'], 16), checked_slice(
            (binaries / row['binary']).read_bytes(), row, 'sha256')
    groups = {'melee.obj': (bind_melee, 32), 'crushini.obj': (bind_crush, 60)}
    for row in read_inventory('matching-routines'):
        address = int(row['raw_offset'], 16)
        name = row['object']
        blob = (objects / name).read_bytes()
        if name in groups:
            binder, prefix = groups[name]
            code = binder(blob)[0]
            payload = code[prefix:] if 'symbol' in row else code[:prefix]
        else:
            payload, _ = bind_leaf_details(blob, row['symbol'], DATA_OFFSETS,
                                           address=address - 0x25600, functions=FUNCTION_ADDRESSES,
                                           absolute_code=CODE_OFFSETS, code_bindings={})
        if len(payload) != row['bytes'] or digest(payload) != row['sha256']:
            raise ValueError(f'Verified CODE span differs in {name} at {address:#x}')
        yield address, payload


def data_images(objects, binaries, library):
    network = {name: offset for name, offset, _, _ in SCALARS}
    for row in read_inventory('matching-initialized'):
        if 'binary' in row:
            payload = checked_slice((binaries / row['binary']).read_bytes(), row, 'payload_sha256')
        else:
            name = row['object']
            blob = (objects / name).read_bytes()
            if digest(blob) != row['object_sha256']:
                raise ValueError(f'Verified object changed: {name}')
            if name == 'cacheunt.obj':
                segments, _, chosen = verify_unit_layout(blob)
                payload = bytes(segments[chosen[row['kind'].split()[-1]]]['data'])
            elif name == 'netdefs.obj':
                offset = network[row['symbol']]
                payload = verify_object(blob)[offset:offset + row['bytes']]
            else:
                segments, _ = read_object(blob)
                payload, = (bytes(s['data']) for s in segments[1:]
                             if s['cls'] == 'DATA' and s['data'])
        if len(payload) != row['bytes']:
            raise ValueError(f'Verified DATA span size differs at {row["raw_offset"]}')
        yield int(row['raw_offset'], 16), payload
    for _, _, ds, payload in load_fonts(library):
        yield DATA_RAW + ds, payload


def build(objects, binaries, library):
    return (place(code_images(objects, binaries), CODE_RAW, CODE_SIZE),
            place(data_images(objects, binaries, library), DATA_RAW, DATA_SIZE))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('objects', type=Path)
    parser.add_argument('binaries', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--graph-library', type=Path, default=ROOT / GRAPH_LIBRARY)
    args = parser.parse_args()
    code, data = build(args.objects, args.binaries, args.graph_library.read_bytes())
    args.output.mkdir(parents=True, exist_ok=True)
    (args.output / 'code.bin').write_bytes(code)
    (args.output / 'data.bin').write_bytes(data)
    print(f'CODE: {len(code)} bytes, SHA-256 {digest(code)}')
    print(f'DATA: {len(data)} bytes, SHA-256 {digest(data)}')

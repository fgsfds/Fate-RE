"""Read the exact font data from pinned Watcom 10.5 GRAPH.LIB members."""
import argparse
import hashlib
import json
from pathlib import Path

from compare_exe import TARGET_SHA256
from le_fixups import read_le_fixups


GRAPH_LIBRARY = 'tools/inputs/watcom/lib386/dos/GRAPH.LIB'
GRAPH_SHA256 = '95a4c2dd3b078e65f3793e0451b654abadf63ce0d73a5a5c53b9a9f78f087c04'
FONT_SPANS = (
    ('std', 0x2be90, 0x2c91a, 0xa26, 0x1749c, 0xa26,
     '5aa1df2c6a3dd3eb052e34c1608c429f4488a580d974921aac5dad1c4346c95d'),
    ('font8x8', 0x18380, 0x19066, 0xc98, 0x17ec4, 0xc82,
     'efb60ec9ef6a49cec53ce027d64e55d3b463ed7b0d4b7b928a4fa4b9b68fbe37'),
    ('hercfont', 0x14830, 0x156a3, 0xe00, 0x18b5c, 0xe00,
     'ecfb950862bb0c49424897413f473a991048a8830303862fe184e66e8ea45a0e'),
)


def member_data(member, size):
    """Decode LEDATA and the single-byte repeat LIDATA used by these members."""
    data = bytearray(size)
    cursor = 0
    while cursor < len(member):
        kind = member[cursor]
        end = cursor + 3 + int.from_bytes(member[cursor + 1:cursor + 3], 'little')
        if end < cursor + 4 or end > len(member):
            raise ValueError('Invalid GRAPH.LIB OMF record')
        record = member[cursor + 3:end - 1]
        cursor = end
        if kind not in (0xa0, 0xa2):
            continue
        if len(record) < 5 or record[0] != 1:
            raise ValueError('Unexpected GRAPH.LIB data segment')
        offset = int.from_bytes(record[1:5], 'little')
        payload = record[5:]
        if kind == 0xa2:
            if len(payload) != 6 or payload[2:5] != b'\0\0\1':
                raise ValueError('Unexpected GRAPH.LIB LIDATA block')
            payload = payload[5:] * int.from_bytes(payload[:2], 'little')
        if offset + len(payload) > size:
            raise ValueError('GRAPH.LIB record exceeds its font segment')
        data[offset:offset + len(payload)] = payload
    return data


def load_fonts(library):
    if hashlib.sha256(library).hexdigest() != GRAPH_SHA256:
        raise ValueError('Unexpected Watcom 10.5 GRAPH.LIB hash')
    for name, start, end, size, ds, count, digest in FONT_SPANS:
        member = library[start:end]
        if hashlib.sha256(member).hexdigest() != digest:
            raise ValueError(f'Unexpected GRAPH.LIB member hash for {name}')
        yield name, digest, ds, bytes(member_data(member, size)[:count])


def verify(executable, library):
    if hashlib.sha256(executable).hexdigest() != TARGET_SHA256:
        raise ValueError('Unknown FATE.EXE')
    le = read_le_fixups(executable)
    rows = []
    for name, digest, ds, payload in load_fonts(library):
        size = len(payload)
        raw = 0x9b600 + ds
        address = 0x80000 + ds
        if (payload != executable[raw:raw + size]
                or any(address <= site < address + size for site in le['pointers'])):
            raise ValueError(f'{name} DATA differs')
        rows.append(dict(member=name, member_sha256=digest,
                         payload_sha256=hashlib.sha256(payload).hexdigest(),
                         ds_offset=hex(ds), raw_offset=hex(raw), bytes=size))
    return dict(target_sha256=TARGET_SHA256, library=GRAPH_LIBRARY,
                library_sha256=GRAPH_SHA256, dependency_data_bytes=sum(r['bytes'] for r in rows),
                spans=rows)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('library', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    result = verify(args.executable.read_bytes(), args.library.read_bytes())
    args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(f"PASS: {result['dependency_data_bytes']} pinned GRAPH.LIB DATA bytes")

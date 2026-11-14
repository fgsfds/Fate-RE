"""Pack the rebuilt object images into the original DOS/4G LE layout."""
import argparse
import json
import struct
from pathlib import Path

from build_object_images import CODE_SIZE, DATA_SIZE, ROOT, build, digest
from compare_exe import TARGET_SHA256
from graphics_font_dependency import GRAPH_LIBRARY


TARGET_SIZE = 741_347
PAGE_SIZE = 4096
OBJECTS = ((CODE_SIZE, 0x10000, 0x2005, 1, 102, 0),
           (0x28a300, 0x80000, 0x2003, 103, 26, 0))
STUB_SIZE = 0x2a50
STUB_SHA256 = 'b852ae395b9ad04503fc907ad03fa28ea6a17bf5f6c2be045bf96f7177592699'
EDITART_SHA256 = {
    '0e11c1c7edf4f265e7db56168322509b8e6ea1c7191c5a3e5994354dbbff78b9',
    'ce919580b77a87de6fa657a280831df0afba3946565697889fb25bb70f9d3611',
}


def fixup_tables(pages, body):
    if len(pages) != 128:
        raise ValueError('Incorrect fixup page count')
    offsets = [0]
    records = bytearray()
    seen = set()
    duplicates = set()
    for page, entries in enumerate(pages):
        owner = OBJECTS[page >= 102]
        object_page = page - owner[3] + 1
        for source, target_object in entries:
            if not -3 <= source < PAGE_SIZE or not 1 <= target_object <= len(OBJECTS):
                raise ValueError('Invalid fixup operands')
            source_in_object = object_page * PAGE_SIZE + source
            if not 0 <= source_in_object <= owner[0] - 4:
                raise ValueError('Fixup outside its source object')
            offset = PAGE_SIZE * page + source
            if offset >= len(body):
                raise ValueError('Fixup operand is outside stored pages')
            if source < 0:
                if offset not in seen or offset in duplicates:
                    raise ValueError('Unexpected duplicate cross-page fixup')
                duplicates.add(offset)
            elif offset in seen:
                raise ValueError('Duplicate fixup in its source page')
            seen.add(offset)
            # The final CRT pointer ends in a zero byte in the virtual tail.
            target = int.from_bytes(body[offset:offset + 4], 'little')
            if target >= OBJECTS[target_object - 1][0]:
                raise ValueError('Fixup target outside its object')
            wide = target > 0xffff
            records.extend(struct.pack('<BBhB', 7, 16 if wide else 0, source, target_object))
            records.extend(target.to_bytes(4 if wide else 2, 'little'))
        offsets.append(len(records))
    if len(seen) != 23350 or len(duplicates) != 9:
        raise ValueError('Unexpected fixup site count')
    return struct.pack(f'<{len(offsets)}I', *offsets), records


def pack(code, data, editart, order):
    stub = editart[:STUB_SIZE]
    if len(editart) != STUB_SIZE and digest(editart) not in EDITART_SHA256:
        raise ValueError('Unrecognized EDITART.EXE dependency')
    if digest(stub) != STUB_SHA256:
        raise ValueError('Unrecognized DOS stub')
    if order['target_sha256'] != TARGET_SHA256:
        raise ValueError('Unexpected relocation inventory target')
    if len(code) != CODE_SIZE or len(data) != DATA_SIZE:
        raise ValueError('Unexpected object image lengths')
    body = code + bytes(102 * PAGE_SIZE - len(code)) + data
    page_fixups, fixups = fixup_tables(order['pages'], body)
    header = bytearray(0xc4)
    header[:2] = b'LE'
    struct.pack_into('<HH', header, 8, 2, 1)
    objects = b''.join(struct.pack('<6I', *obj) for obj in OBJECTS)
    page_map = b''.join(struct.pack('>I', page << 8) for page in range(1, 129))
    resident_names = b'\x04fate\0\0\0'
    loader = objects + page_map + resident_names + b'\0'
    fixup_page_offset = len(header) + len(loader)
    fixup_record_offset = fixup_page_offset + len(page_fixups)
    import_offset = fixup_record_offset + len(fixups)
    fixup_section = page_fixups + fixups + b'\0'
    data_start = 0x35600
    fields = {
        0x10: 0x200, 0x14: 128, 0x18: 1, 0x1c: 0x4ff08,
        0x20: 2, 0x24: OBJECTS[1][0], 0x28: PAGE_SIZE, 0x2c: len(data) % PAGE_SIZE,
        0x30: len(fixup_section), 0x38: import_offset - len(header) + 1,
        0x40: len(header), 0x44: len(OBJECTS), 0x48: len(header) + len(objects),
        0x50: len(header) + len(objects) + len(page_map),
        0x58: len(header) + len(objects) + len(page_map),
        0x5c: fixup_page_offset - 1, 0x68: fixup_page_offset, 0x6c: fixup_record_offset,
        0x70: import_offset, 0x78: import_offset, 0x80: data_start, 0x94: 2,
    }
    for offset, value in fields.items():
        struct.pack_into('<I', header, offset, value)
    prefix = stub + header + loader + fixup_section
    if len(prefix) > data_start:
        raise ValueError('LE tables exceed the start of the stored pages')
    return prefix + bytes(data_start - len(prefix)) + body


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('objects', type=Path)
    parser.add_argument('binaries', type=Path)
    parser.add_argument('stub_source', type=Path, help='DOS stub or pinned EDITART.EXE')
    parser.add_argument('output', type=Path)
    parser.add_argument('--graph-library', type=Path, default=ROOT / GRAPH_LIBRARY)
    args = parser.parse_args()
    order = json.loads((ROOT / 'tools/data/le-relocation-order.json').read_text(encoding='utf-8'))
    code, data = build(args.objects, args.binaries, args.graph_library.read_bytes())
    executable = pack(code, data, args.stub_source.read_bytes(), order)
    if len(executable) != TARGET_SIZE:
        raise SystemExit(f'FATE.EXE size mismatch: expected {TARGET_SIZE}, got {len(executable)} bytes')
    actual = digest(executable)
    if actual != TARGET_SHA256:
        args.output.with_suffix('.unmatched').write_bytes(executable)
        raise SystemExit(f'FATE.EXE differs: SHA-256 {actual}')
    args.output.write_bytes(executable)
    print(f'PASS: {len(executable)} bytes, SHA-256 {actual}')

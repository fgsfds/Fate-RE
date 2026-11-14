"""Read-only Fate demo format survey. Python 3.10+, no third-party modules."""
import argparse
import collections
import hashlib
import json
from pathlib import Path
import re
import struct


def unpack(fmt, data, offset=0):
    return struct.unpack_from('<' + fmt, data, offset)


def inspect_map(data):
    version, x, y, z, angle, sector = unpack('4ihh', data)
    if version != 7:
        raise ValueError(f'unsupported map version {version}')
    offset = 20
    result = dict(version=version, start=dict(x=x, y=y, z=z, angle=angle, sector=sector))
    records = {}
    for name, size in [('sectors', 40), ('walls', 32), ('sprites', 44)]:
        count, = unpack('H', data, offset)
        offset += 2
        if offset + count * size > len(data):
            raise ValueError(f'truncated {name}')
        rows = [data[offset+i*size:offset+(i+1)*size] for i in range(count)]
        records[name] = rows
        tagoffset = {'sectors': 34, 'walls': 26, 'sprites': 38}[name]
        tags = collections.Counter(unpack('h', row, tagoffset)[0] for row in rows)
        result[name] = dict(count=count, lotags=dict(sorted(tags.items())))
        offset += count * size
    result['standard_bytes'] = offset
    result['trailing_bytes'] = len(data)-offset
    result['trailing_prefix_hex'] = data[offset:offset+64].hex()
    result['sprite_tiles'] = dict(sorted(collections.Counter(unpack('h', r, 14)[0] for r in records['sprites']).items()))
    errors = []
    ns, nw = len(records['sectors']), len(records['walls'])
    for i, row in enumerate(records['sectors']):
        first, count = unpack('hh', row)
        if first < 0 or count < 0 or first+count > nw:
            errors.append(f'sector {i}: invalid wall range')
    for i, row in enumerate(records['walls']):
        point, wall, sec = unpack('hhh', row, 8)
        if not 0 <= point < nw or not -1 <= wall < nw or not -1 <= sec < ns:
            errors.append(f'wall {i}: invalid index')
    for i, row in enumerate(records['sprites']):
        sec, = unpack('h', row, 24)
        if not 0 <= sec < ns:
            errors.append(f'sprite {i}: invalid sector {sec}')
    result['structural_errors'] = errors
    return result


def inspect_art(data):
    version, total, first, last = unpack('4i', data)
    if version != 1 or first < 0 or last < first:
        raise ValueError('unsupported ART header')
    count = last-first+1
    widths = unpack(f'{count}H', data, 16)
    heights = unpack(f'{count}H', data, 16+2*count)
    expected = 16+8*count+sum(w*h for w, h in zip(widths, heights))
    return dict(version=version, legacy_numtiles=total, first=first, last=last,
                populated=sum(w*h > 0 for w, h in zip(widths, heights)),
                expected_bytes=expected, trailing_bytes=len(data)-expected)


def inspect_exe(data):
    result = dict(signature=data[:2].decode('ascii', errors='replace'))
    if data[:2] == b'MZ':
        next_header, = unpack('I', data, 0x3c)
        result['extended_header_offset'] = next_header
        result['extended_signature'] = data[next_header:next_header+2].decode('ascii', errors='replace')
        if data[next_header:next_header+2] == b'LE':
            h = next_header
            table, count = unpack('II', data, h+0x40)
            result['le'] = dict(page_size=unpack('I', data, h+0x28)[0],
                                data_pages_offset=unpack('I', data, h+0x80)[0],
                                entry_object=unpack('I', data, h+0x18)[0],
                                entry_offset=unpack('I', data, h+0x1c)[0], objects=[])
            for i in range(count):
                size, base, flags, page, pages, reserved = unpack('6I', data, h+table+24*i)
                result['le']['objects'].append(dict(virtual_size=size, relocation_base=base,
                                                    flags=flags, first_page=page, pages=pages))
    result['strings'] = [dict(offset=m.start(), text=m.group().decode('ascii'))
                         for m in re.finditer(rb'[ -~]{6,}', data)
                         if re.search(rb'[A-Za-z]{4}', m.group())]
    return result


def inspect_sounds(data):
    """Fate demo: last 4096-byte block contains 12-byte directory entries.

    The third field's meaning and the sample rate remain unverified.
    Reject overlapping, out-of-bounds and non-contiguous sample blocks.
    """
    if len(data) < 4096 or len(data) % 4096:
        raise ValueError('SOUNDS is not block-aligned')
    directory = len(data)-4096
    entries = []
    next_block = 0
    for offset in range(directory, len(data)-11, 12):
        block, size, unknown = unpack('III', data, offset)
        if not (block or size or unknown):
            if any(data[offset:]):
                raise ValueError('nonzero data after sound directory terminator')
            break
        if not size or block != next_block or block*4096+size > directory:
            raise ValueError('invalid sound directory entry')
        entries.append(dict(id=len(entries), block=block, offset=block*4096,
                            bytes=size, unknown=unknown))
        next_block = block+(size+4095)//4096
    if next_block*4096 != directory:
        raise ValueError('sound blocks do not cover data area')
    return dict(directory_offset=directory, block_size=4096, entries=entries,
                sample_encoding='unverified', sample_rate='unverified')


def survey(root):
    report = {'files': {}}
    for path in sorted(root.iterdir()):
        if not path.is_file():
            continue
        data = path.read_bytes()
        item = dict(bytes=len(data), sha256=hashlib.sha256(data).hexdigest())
        suffix = path.suffix.upper()
        if suffix == '.MAP':
            item['map'] = inspect_map(data)
        elif suffix == '.ART':
            item['art'] = inspect_art(data)
        elif suffix == '.EXE':
            item['exe'] = inspect_exe(data)
        elif path.name.upper() == 'SOUNDS':
            item['sound_bank'] = inspect_sounds(data)
        elif path.name.upper() == 'PALETTE.DAT':
            shades, = unpack('H', data, 768)
            expected = 770+256*shades+65536
            item['palette'] = dict(shades=shades, standard_bytes=expected,
                                   unexplained_trailing_bytes=len(data)-expected,
                                   max_color_component=max(data[:768]))
        elif path.name.upper() == 'TEXT.DAT':
            if len(data) % 46:
                raise ValueError('TEXT.DAT has a partial 46-byte record')
            item['text_record_bytes'] = 46
            item['messages'] = [dict(unknown=unpack('I', data, i)[0],
                                     text=data[i+4:i+46].split(b'\0', 1)[0].decode('ascii', errors='replace'))
                                for i in range(0, len(data), 46)]
        report['files'][path.name] = item
    return report


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('demo', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(survey(args.demo), indent=2) + '\n', encoding='utf-8')

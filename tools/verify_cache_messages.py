"""Check compiler-generated cache diagnostic arrays, separately from code coverage."""
import argparse
import hashlib
import json
from pathlib import Path
import struct
from compare_exe import TARGET_SHA256
from match_objects import read_object
from omf_fixups import read_fixups
from verify_c_leaf import DATA_OFFSETS

MESSAGES = {'_cache_size_format': 16, '_cache_request_format': 47,
            '_cache_too_big': 33, '_cache_zero_lock': 34, '_cache_all_locked': 28,
            '_cache_report_size': 17, '_cache_report_count': 14,
            '_cache_report_index': 6, '_cache_report_handle': 12,
            '_cache_report_length': 12, '_cache_report_lock': 11,
            '_cache_report_total': 24, '_group_list_allocation_error': 44,
            '_group_offsets_allocation_error': 44, '_group_too_many_files': 45}


def verify(exe, blob):
    if hashlib.sha256(exe).hexdigest() != TARGET_SHA256:
        raise ValueError('Unknown FATE.EXE')
    segments, publics = read_object(blob)
    if read_fixups(blob):
        raise ValueError('Unexpected relocation in diagnostic arrays')
    header = struct.unpack_from('<I', exe, 60)[0]
    def field(offset):
        return struct.unpack_from('<I', exe, header+offset)[0]
    data_object = struct.unpack_from('<6I', exe, header+field(0x40)+24)
    if data_object[1] != 0x80000 or field(0x28) != 4096:
        raise ValueError('Unexpected FATE data layout')
    if len(publics) != len(MESSAGES) or {name for _, _, name in publics} != set(MESSAGES):
        raise ValueError('Unexpected diagnostic public inventory')
    populated = [i for i, segment in enumerate(segments) if segment and segment['data']]
    if len(populated) != 1 or segments[populated[0]]['cls'] != 'DATA':
        raise ValueError('Expected one populated DATA segment and no other payload')
    expected_offset = 0
    for symbol, size in MESSAGES.items():
        if publics.count((populated[0], expected_offset, symbol)) != 1:
            raise ValueError('Diagnostic arrays must be distinct, contiguous and ordered')
        expected_offset += size
    if len(segments[populated[0]]['data']) != expected_offset:
        raise ValueError('Unexpected bytes outside diagnostic arrays')
    original_ranges = sorted((DATA_OFFSETS[name], DATA_OFFSETS[name] + size)
                             for name, size in MESSAGES.items())
    if any(left[1] > right[0] for left, right in zip(original_ranges, original_ranges[1:])):
        raise ValueError('Original diagnostic ranges overlap')
    raw_ranges = []
    rows = []
    for symbol, size in MESSAGES.items():
        matches = [(segment, offset) for segment, offset, name in publics if name == symbol]
        if len(matches) != 1:
            raise ValueError(f'Missing/duplicate data symbol {symbol}')
        segment, offset = matches[0]
        if segments[segment]['cls'] != 'DATA':
            raise ValueError('Expected compiler-generated DATA array')
        generated = bytes(segments[segment]['data'][offset:offset+size])
        ds = DATA_OFFSETS[symbol]
        page, within = divmod(ds, 4096)
        if within+size > 4096 or page >= data_object[4]:
            raise ValueError('Expected initialized single-page diagnostic')
        entry = header+field(0x48)+(data_object[3]+page-1)*4
        physical = int.from_bytes(exe[entry:entry+3], 'big')
        if not physical or exe[entry+3] != 0:
            raise ValueError('Expected physical initialized LE page')
        raw = field(0x80)+(physical-1)*4096+within
        raw_ranges.append((raw, raw + size))
        if raw + size > len(exe):
            raise ValueError('Diagnostic extends beyond executable')
        if generated != exe[raw:raw+size] or generated[-1:] != b'\0':
            raise ValueError(f'Diagnostic array differs: {symbol}')
        rows.append(dict(symbol=symbol, ds_offset=hex(ds), loaded_address=hex(ds+0x80000),
                         raw_offset=hex(raw), bytes=size, sha256=hashlib.sha256(generated).hexdigest()))
    raw_ranges.sort()
    if any(left[1] > right[0] for left, right in zip(raw_ranges, raw_ranges[1:])):
        raise ValueError('Original physical diagnostic ranges overlap')
    result = dict(target_sha256=TARGET_SHA256, object_sha256=hashlib.sha256(blob).hexdigest(),
                  matching_initialized_data_bytes=sum(MESSAGES.values()),
                  final_linked_placement_verified=False, arrays=rows)
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    result = verify(args.executable.read_bytes(), args.object.read_bytes())
    if args.output:
        args.output.write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
    print(f"PASS: {len(result['arrays'])} compiler-generated arrays, "
          f"{result['matching_initialized_data_bytes']} data bytes; final placement unresolved")

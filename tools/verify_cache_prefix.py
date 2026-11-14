"""Verify the jointly compiled cache/archive prefix using the existing C binder.

This proves one source-generated code prefix, not a complete CACHE1D module.
"""
import argparse
import hashlib
import json
from pathlib import Path
from compare_exe import TARGET_SHA256
from le_fixups import read_le_fixups
from match_objects import read_object
from omf_fixups import read_externals, read_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, bind_leaf_details, verify_leaf_relocations

ADDRESS = 0x40c49
FILE_OFFSET = 0x66249
SIZE = 2273
PUBLICS = [('initcache_', 0), ('allocache_', 42), ('agecache_', 740),
           ('reportandexit_', 853), ('initgroupfile_', 1042),
           ('uninitgroupfile_', 1539), ('kopen4load_', 1592), ('kread_', 1844),
           ('klseek_', 2056), ('kfilelength_', 2178), ('kclose_', 2234)]


def verify(exe, blob):
    if hashlib.sha256(exe).hexdigest() != TARGET_SHA256:
        raise ValueError('Unknown FATE.EXE')
    segments, publics = read_object(blob)
    code_segments = [index for index, segment in enumerate(segments[1:], 1)
                     if segment['cls'] == 'CODE']
    if len(code_segments) != 1:
        raise ValueError('Expected exactly one prefix CODE segment')
    segment = code_segments[0]
    if len(segments[segment]['data']) != SIZE:
        raise ValueError('Unexpected prefix CODE size')
    if any(item['data'] for index, item in enumerate(segments[1:], 1) if index != segment):
        raise ValueError('Prefix must keep non-code data external')
    expected_publics = [(segment, offset, symbol) for symbol, offset in PUBLICS]
    if sorted(publics) != sorted(expected_publics):
        raise ValueError('Prefix public names/offsets differ from original layout')
    # Keep all relocation semantics in the existing tested binder. Internal names
    # resolve from this object's verified public layout, not arbitrary symbol maps.
    functions = dict(FUNCTION_ADDRESSES)
    functions.update({symbol: ADDRESS+offset for symbol, offset in PUBLICS})
    code, bindings, rows = bytearray(), {}, []
    for index, (symbol, offset) in enumerate(PUBLICS):
        end = PUBLICS[index+1][1] if index+1 < len(PUBLICS) else SIZE
        span, pointers = bind_leaf_details(blob, symbol, DATA_OFFSETS,
                                            address=ADDRESS+offset, functions=functions)
        if len(span) != end-offset:
            raise ValueError('Unexpected prefix public span length')
        code.extend(span)
        bindings.update({offset+site: target for site, target in pointers.items()})
        rows.append(dict(symbol=symbol, object_offset=hex(offset), loaded_address=hex(ADDRESS+offset),
                         bytes=len(span), le_pointers=len(pointers)))
    if bytes(code) != exe[FILE_OFFSET:FILE_OFFSET+SIZE]:
        raise ValueError('Joint prefix differs from original code bytes')
    verify_leaf_relocations(code, bindings, read_le_fixups(exe)['pointers'], ADDRESS)
    fixups = read_fixups(blob)
    names = read_externals(blob)
    relative = [fix for fix in fixups if fix.segment == segment and fix.relative]
    internal_names = {symbol for symbol, _ in PUBLICS}
    internal = sum(fix.target[0] == 2 and names[fix.target[1]] in internal_names for fix in relative)
    return dict(target_sha256=TARGET_SHA256, object_sha256=hashlib.sha256(blob).hexdigest(),
                raw_offset=hex(FILE_OFFSET), loaded_address=hex(ADDRESS),
                bytes=SIZE, le_pointers=len(bindings), relative_references=len(relative),
                internal_relative_references=internal,
                exact_code_equal=True, original_le_targets_equal=True,
                source_coverage_change=0, complete_original_module=False,
                globals_and_runtime_dependencies_external=True, spans=rows)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    result = verify(args.executable.read_bytes(), args.object.read_bytes())
    args.output.write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
    print(f"PASS: joint prefix {result['bytes']} bytes, {result['le_pointers']} LE pointers, "
          f"{result['internal_relative_references']} internal relative references; coverage unchanged")

"""Attribute exact-build C inventory bytes by checked Watcom marker pairs."""
import argparse
from collections import Counter, defaultdict
from hashlib import sha256
import json
from pathlib import Path
import re

from build_object_images import CODE_RAW, CODE_SIZE
from compare_exe import TARGET_SHA256
from compare_watcom_markers import compare
from verify_c_leaf import (LEAF_ENTRY_PREFIXES, LEAF_CODE_SLICES,
                           leaf_public_name, leaf_code_bounds)
from match_objects import read_object


def error_reason(error):
    if isinstance(error, KeyError):
        return 'Unresolved local branch or symbol'
    if isinstance(error, StopIteration):
        return 'Inventory symbol is not an object public'
    if isinstance(error, FileNotFoundError):
        return 'Missing ordinary or marker object'
    return str(error).split(':', 1)[0].split(' at ', 1)[0]


def verified_switch_tables(inventory, filename, obj):
    table_rows = [row for row in inventory['non_routine_code_spans']
                  if row['object'] == filename and row['kind'] == 'compiler-generated jump table']
    routine_rows = [row for row in inventory['spans'] if row['object'] == filename]
    if not table_rows:
        if any(row['symbol'] == 'setgamemode_display_reset_' for row in routine_rows):
            from bind_setgamemode_display import verified_context_tables
            return verified_context_tables(obj, routine_rows)
        if any(leaf_public_name(row['symbol']) == 'dispatch_main_menu_' for row in routine_rows):
            # A checked but unlinked table can normalize marker comparisons.
            # It stays outside the credited inventory and contributes zero bytes.
            from bind_main_menu_sections import verified_context_tables
            return verified_context_tables(obj, routine_rows)
        return ()
    segments, public_rows = read_object(obj)
    by_name = {name: (seg, offset) for seg, offset, name in public_rows}
    placement = {(by_name[row['symbol']][0], int(row['raw_offset'], 16) - by_name[row['symbol']][1])
                 for row in routine_rows}
    if len(placement) != 1:
        raise ValueError('Switch tables lack a single verified code-section placement')
    segment, base = placement.pop()
    if not segment or segments[segment]['cls'] != 'CODE':
        raise ValueError('Switch tables do not belong to a CODE section')
    return tuple((segment, int(row['raw_offset'], 16) - base, row['bytes'])
                 for row in table_rows)


def placed_measurement(symbol, length, measurement, invocation_ranges=None):
    size, inline, ranges, widths, invocations = measurement
    start, end = leaf_code_bounds(symbol, size)
    if end - start != length:
        raise ValueError('Inventory extent does not match object public span')
    if symbol in LEAF_CODE_SLICES:
        invocation_ranges = invocation_ranges or []
        if (len(invocation_ranges) != invocations
                or sum(b - a for a, b in invocation_ranges) != inline
                or any(not 0 <= a < b <= size for a, b in invocation_ranges)):
            raise ValueError('Cannot attribute inline invocations in a sliced public')
        selected = [(a, b) for a, b in invocation_ranges if a < end and b > start]
        if any(a < start or b > end for a, b in selected):
            raise ValueError('An inline invocation crosses a selected slice boundary')
        placed = [(max(a, start) - start, min(b, end) - start)
                  for a, b in ranges if a < end and b > start]
        inline_bytes = sum(b - a for a, b in placed)
        if inline_bytes != sum(b - a for a, b in selected):
            raise ValueError('Inline byte coverage differs from selected invocations')
        return (length, inline_bytes, placed,
                [(site - start, *details) for site, *details in widths if start <= site < end],
                len(selected))
    if any(a < start for a, _ in ranges) or any(site < start for site, *_ in widths):
        raise ValueError('Cannot attribute a marker or changed branch in the retained prefix')
    return (length, inline, [(a - start, b - start) for a, b in ranges],
            [(site - start, *details) for site, *details in widths], invocations)


def report(build, marker_dir, retry_dir=None):
    inventory_file = build / 'c.json'
    inventory = json.loads(inventory_file.read_text(encoding='utf-8'))
    image = (build / 'FATE.EXE').read_bytes()
    image_digest = sha256(image).hexdigest()
    for directory in (marker_dir, retry_dir):
        if directory and (directory / 'done.txt').read_text(encoding='ascii').strip() != 'DONE':
            raise ValueError(f'Marker compilation did not complete in {directory}')
    if image_digest != TARGET_SHA256 or image_digest != inventory['target_sha256']:
        raise ValueError('Inventory executable hash differs')
    input_spans = inventory['spans'] + inventory['non_routine_code_spans']
    if sum(row['bytes'] for row in input_spans) != inventory['unique_code_bytes']:
        raise ValueError('Inventory span total differs')

    files = {}
    marked_files = {}
    result = []
    spans = []
    errors = defaultdict(lambda: {'routines': 0, 'bytes': 0})
    totals = Counter()
    for row in input_spans:
        offset = int(row['raw_offset'], 16)
        length = row['bytes']
        exe_span = image[offset:offset + length]
        if len(exe_span) != length or sha256(exe_span).hexdigest() != row['sha256']:
            raise ValueError(f'Inventory executable span differs at {offset:#x}')
        spans.append((offset, offset + length))
        filename = row['object']
        seen_digest, original = files.get(filename, (None, None))
        if original is None:
            original = (build / filename).read_bytes()
            seen_digest = sha256(original).hexdigest()
            files[filename] = seen_digest, original
        if seen_digest != row['object_sha256']:
            raise ValueError(f'Inventory ordinary object digest differs: {filename}')
        if 'symbol' not in row:
            totals['non_routine_code_bytes'] += length
            continue
        symbol = row['symbol']
        identity = {'symbol': symbol, 'object': filename, 'raw_offset': row['raw_offset'], 'bytes': length}
        def measure(directory):
            path = directory / filename
            log_path = directory / (Path(filename).stem + '.log')
            if not log_path.is_file():
                raise ValueError('No diagnostic compiler log')
            log = log_path.read_text(encoding='ascii', errors='replace')
            if re.search(r'\bError!', log) or not re.search(r',\s*0 errors', log):
                detail = next((line.strip() for line in log.splitlines() if 'Error!' in line), log[:120])
                raise ValueError('Diagnostic compile failed: '+detail)
            if path not in marked_files:
                marked_files[path] = path.read_bytes()
            invocation_ranges = []
            measurement = compare(original, marked_files[path], leaf_public_name(symbol),
                                  verified_switch_tables(inventory, filename, original),
                                  invocation_ranges=invocation_ranges)
            return placed_measurement(symbol, length, measurement, invocation_ranges)

        exceptions = (ValueError, KeyError, StopIteration, OSError)
        try:
            try:
                measurement = measure(marker_dir)
            except exceptions as primary:
                if not retry_dir or not (retry_dir / filename).is_file():
                    raise
                try:
                    measurement = measure(retry_dir)
                except exceptions as retry_failure:
                    raise primary from retry_failure
        except exceptions as error:
            reason = error_reason(error)
            result.append(identity | {'status': 'unknown', 'reason': reason, 'detail': str(error)})
            errors[reason]['routines'] += 1
            errors[reason]['bytes'] += length
        else:
            _, inline, inline_ranges, branch_changes, invocations = measurement
            totals['measured_routines'] += 1
            totals['inline_bytes'] += inline
            totals['native_generated_bytes'] += length - inline
            totals['changed_branch_widths'] += len(branch_changes)
            result.append(identity | {
                'status': 'measured', 'inline_bytes': inline, 'native_generated_bytes': length - inline,
                'inline_invocations': invocations, 'inline_offsets': inline_ranges,
                'branch_width_changes': branch_changes,
            })
    spans.sort()
    if any(a[1] > b[0] for a, b in zip(spans, spans[1:])):
        raise ValueError('Inventory span overlap')
    totals['unknown_routines'] = sum(row['routines'] for row in errors.values())
    totals['unknown_bytes'] = sum(row['bytes'] for row in errors.values())
    totals['target_routines'] = inventory['routines']
    totals['target_c_code_bytes'] = inventory['unique_code_bytes']
    accounted = sum(totals[k] for k in ('inline_bytes', 'native_generated_bytes',
                                         'unknown_bytes', 'non_routine_code_bytes'))
    if accounted != inventory['unique_code_bytes']:
        raise ValueError('Classified bytes do not sum to verified coverage')
    assembly = json.loads((build / 'assembly.json').read_text(encoding='utf-8'))
    if assembly['target_sha256'] != image_digest:
        raise ValueError('Assembly inventory executable hash differs')
    for row in assembly['spans'] + assembly['non_routine_code_spans']:
        offset, length = int(row['raw_offset'], 16), row['bytes']
        spans.append((offset, offset + length))
    spans.sort()
    if (not spans or spans[0][0] != CODE_RAW or spans[-1][1] != CODE_RAW + CODE_SIZE
            or any(a[1] != b[0] for a, b in zip(spans, spans[1:]))):
        raise ValueError('Inventories do not partition the CODE segment')
    categories = {
        'compiler_generated': totals['native_generated_bytes'],
        'inline_assembly': totals['inline_bytes'],
        'standalone_assembly': assembly['unique_code_bytes'],
        'unattributed': totals['unknown_bytes'] + totals['non_routine_code_bytes'],
    }
    if sum(categories.values()) != CODE_SIZE:
        raise ValueError('Classification does not cover the CODE segment')
    return {
        'code_segment': {key: {'bytes': count, 'percent': 100 * count / CODE_SIZE}
                         for key, count in categories.items()},
        'target_sha256': image_digest,
        'inventory_sha256': sha256(inventory_file.read_bytes()).hexdigest(),
        'totals': dict(totals),
        'unknown_by_reason': dict(sorted(errors.items(), key=lambda item: -item[1]['bytes'])),
        'routines': result,
    }


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('build', type=Path)
    parser.add_argument('marker_dir', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--retry-marker-dir', type=Path,
                        help='Retry failures with a targeted distinct-end build')
    args = parser.parse_args()
    result = report(args.build, args.marker_dir, args.retry_marker_dir)
    args.output.write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
    for section in ('code_segment', 'totals', 'unknown_by_reason'):
        print(json.dumps(result[section], indent=2))

"""Compare diagnostic marker objects with ordinary Watcom leaf objects."""
import argparse
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path

from capstone import CS_ARCH_X86, CS_MODE_32, CS_GRP_CALL, CS_GRP_JUMP, Cs
from capstone.x86_const import X86_OP_IMM

from match_objects import read_object
from omf_fixups import read_externals, read_fixups
from verify_c_leaf import flat_frame_groups

# These literal short branches cross linked routine boundaries. The exact
# linker verifies their final displacements. Marker objects keep the same
# encoded operands, since their code sections are never linked or executed.
FIXED_SHORT_BRANCHES = {
    # Truncation branches enter other spans at fixed executable addresses.
    'truncate_float_': {2: bytes.fromhex('79 08')},
    'truncate_magnitude_': {2: bytes.fromhex('74 35'), 11: bytes.fromhex('72 2c'),
                            23: bytes.fromhex('73 13'), 28: bytes.fromhex('73 07')},
    # The signed wrapper tail-transfers to the adjacent unsigned entry.
    'i32_to_float_': {2: bytes.fromhex('79 d1')},
    # The four short player palette cases jump to the fixed shared placement.
    'board_entry_palette_4_': {21: b'\xeb\x57'},
    'board_entry_palette_5_': {21: b'\xeb\x40'},
    'board_entry_palette_6_': {21: b'\xeb\x29'},
    'board_entry_palette_7_': {21: b'\xeb\x12'},
    # Rejected floor planes jump back to the shared ceiling stack restore.
    'florscan_check_height_': {0x11: bytes.fromhex('7f a1')},
    # Transfer to wallmost_left_height_ in the separately placed wallset object.
    'wallmost_slope_coefficient_': {0x34: bytes.fromhex('eb 1e')},
    # Transfer to wallmost_check_bottom_ in the separately placed wallclip object.
    'wallmost_clip_flags_': {0x111: bytes.fromhex('75 46')},
    'run_palette_fade_': {7: b'\x74\xf6', 46: b'\xeb\x10',
                          55: b'\x74\xc6', 62: b'\xeb\x3b'},
    'palette_fade_out_entry_': {5: b'\xeb\x3c'},
    'resolve_route_waypoint_': {58: b'\x7d\x24'},
    'route_cross_zone_': {199: b'\xeb\x65'},
    'route_choose_actor_target_': {9: b'\x75\x61'},
    'env_scan_strings_': {19: b'\x74\x13'},
    'env_allocate_and_copy_': {43: b'\x74\x54', 64: b'\x74\x1a'},
    'env_finish_vector_': {35: b'\xeb\x07'},
    'pan_floor_cases_': {34: b'\xeb\x5b', 42: b'\xeb\x53'},
    'pan_ceiling_cases_': {38: b'\xeb\x25', 46: b'\xeb\x1d', 54: b'\xeb\x15'},
    'pan_ceiling_y_normal_': {6: b'\xeb\xe1'},
    'initialize_board_routes_': {625: b'\xeb\x6a', 652: b'\xeb\x4f',
                                 679: b'\xeb\x34', 706: b'\xeb\x19'},
}

MARK_BEGIN, MARK_END = b'\xf1', b'\xf4'


@dataclass(frozen=True)
class Span:
    instructions: list
    positions: dict
    inline: list
    references: dict
    invocations: int
    offset: int
    publics: tuple


@dataclass(frozen=True)
class JumpTable:
    segment: int
    offset: int
    dispatch_field: int
    targets: tuple


def switch_layout(blob, verified_sizes, expected_offsets=None):
    """Recognize only direct-indexed, FLAT same-CODE-segment switch tables."""
    segments, publics = read_object(blob)
    flat = flat_frame_groups(blob)
    fixes = read_fixups(blob)

    def local_dword(fix):
        return (fix.location == 9 and fix.width == 4 and not fix.relative
                and not fix.displacement and fix.frame[0] == 1 and fix.frame[1] in flat
                and fix.target == (0, fix.segment) and segments[fix.segment]['cls'] == 'CODE')

    def word(segment, site):
        return int.from_bytes(segments[segment]['data'][site:site + 4], 'little')

    # Discover dispatch fields by the exact jmp dword cs:[index*4+disp32] encoding.
    # The caller subsequently proves each dispatch is an instruction boundary.
    dispatches = []
    for fix in fixes:
        if not local_dword(fix) or fix.offset < 4:
            continue
        code = segments[fix.segment]['data']
        prefix, first, second, sib = code[fix.offset - 4:fix.offset]
        if (prefix, first, second) == (0x2e, 0xff, 0x24) and sib & 0xc7 == 0x85 and (sib >> 3) & 7 != 4:
            dispatches.append((fix.segment, fix.offset, word(fix.segment, fix.offset)))
    dispatches.sort()
    if len(dispatches) != len(verified_sizes):
        raise ValueError('Switch dispatch count differs from verified table inventory')
    if expected_offsets is not None:
        if tuple(sorted((seg, off) for seg, _, off in dispatches)) != tuple(sorted(expected_offsets)):
            raise ValueError('Switch dispatch targets differ from verified table inventory')
        verified_sizes = tuple(verified_sizes[(seg, off)] for seg, _, off in dispatches)

    tables = []
    for (segment, field, offset), size in zip(dispatches, verified_sizes):
        if not size or size % 4 or offset % 4 or offset + size > len(segments[segment]['data']):
            raise ValueError('Invalid switch table extent')
        following_public = min((off for seg, off, _ in publics if seg == segment and off >= offset),
                               default=None)
        if following_public != offset + size:
            raise ValueError('Switch table does not end at its following public')
        table_fixes = [fix for fix in fixes if fix.segment == segment
                       and fix.offset < offset + size and fix.offset + fix.width > offset]
        if (sorted(fix.offset for fix in table_fixes) != list(range(offset, offset + size, 4))
                or not all(local_dword(fix) for fix in table_fixes)):
            raise ValueError('Switch table relocation fields differ')
        tables.append(JumpTable(segment, offset, field, tuple(
            word(segment, site) for site in range(offset, offset + size, 4)
        )))

    intervals = sorted((t.segment, t.offset, t.offset + 4 * len(t.targets)) for t in tables)
    if any(a[0] == b[0] and a[2] > b[1] for a, b in zip(intervals, intervals[1:])):
        raise ValueError('Switch tables overlap')
    if any(t.segment == seg and t.offset <= field < t.offset + 4 * len(t.targets)
           for t in tables for seg, field, _ in dispatches):
        raise ValueError('Switch dispatch field overlaps table data')
    return tuple(tables)


@lru_cache(maxsize=512)
def decode(blob, symbol, marked, tables=()):
    segments, publics = read_object(blob)
    segment, start = next((seg, off) for seg, off, name in publics if name == symbol)
    stop = min((off for seg, off, name in publics if seg == segment and off > start),
               default=len(segments[segment]['data']))
    table_stop = min((t.offset for t in tables if t.segment == segment and start <= t.offset < stop),
                     default=stop)
    body = segments[segment]['data'][start:table_stop]
    decoder = Cs(CS_ARCH_X86, CS_MODE_32)
    decoder.detail = True
    raw = list(decoder.disasm(body, 0))
    if not raw or raw[-1].address + raw[-1].size != len(body):
        raise ValueError(f'Could not decode complete routine {symbol}')

    if table_stop < stop:
        # Watcom can insert one-byte NOPs before the next public's table.
        # Skip only these decoded terminal alignment bytes after a RET and
        # its optional closing marker. The inventory still checks base size.
        padding = 0
        while raw and bytes(raw[-1].bytes) == b'\x90':
            padding += raw[-1].size
            raw.pop()
        end = -2 if raw and marked and bytes(raw[-1].bytes) == MARK_END else -1
        if len(raw) < -end or padding > 3 or raw[end].mnemonic not in ('ret', 'retf'):
            raise ValueError('Unexpected alignment before a switch table')
        stop = table_stop - padding
        if padding and any(fix.segment == segment and fix.offset < table_stop and fix.offset + fix.width > stop
                           for fix in read_fixups(blob)):
            raise ValueError('Relocation overlaps switch alignment')
    active, invocations = False, 0
    instructions, inline, positions = [], [], {}
    for insn in raw:
        positions[insn.address] = len(instructions)
        opcode = bytes(insn.bytes)
        end_marker = opcode == MARK_END or (
            len(opcode) == 2 and opcode[0] == 0xcd and opcode[1] >= 0x80
        )
        if opcode == MARK_BEGIN or end_marker:
            if not marked or end_marker != active:
                raise ValueError(f'Conflicting marker at {symbol}+{insn.address:#x}')
            active = not active
            if active:
                invocations += 1
        else:
            instructions.append(insn)
            inline.append(active)
    if active:
        raise ValueError(f'Unbalanced markers in {symbol}')
    positions[stop - start] = len(instructions)

    externals = read_externals(blob)
    boundaries = [insn.address for insn in instructions]
    references = {}
    for item in read_fixups(blob):
        if item.segment != segment or not start <= item.offset < stop:
            continue
        site = item.offset - start
        # Each fixup must be fully contained in a decoded nonmarker instruction.
        index = max((i for i, off in enumerate(boundaries) if off <= site), default=-1)
        if index < 0:
            raise ValueError('Fixup precedes first instruction')
        insn = instructions[index]
        if site + item.width > insn.address + insn.size:
            raise ValueError('Fixup spans opcode or marker boundary')
        if item.target[0] == 2:
            target = externals[item.target[1]]
        else:
            slot = next((i for i, t in enumerate(tables)
                         if t.segment == segment and t.dispatch_field == item.offset), None)
            if (slot is None or insn.mnemonic != 'jmp' or insn.size != 8
                    or insn.bytes[0] != 0x2e or insn.disp_offset != 4 or insn.disp_size != 4
                    or site != insn.address + 4):
                raise ValueError('Nonexternal fixup requires special handling')
            target = ('switch', slot)
        details = (site - insn.address, item.width, item.location, item.relative,
                   item.frame, target, item.displacement)
        references.setdefault(index, []).append(details)

    segment_publics = tuple(sorted((off, name) for seg, off, name in publics if seg == segment))
    return Span(instructions, positions, inline, references, invocations,
                start, segment_publics)


def direct_branch(insn):
    return (insn.group(CS_GRP_JUMP) or insn.group(CS_GRP_CALL)) and len(insn.operands) == 1 \
        and insn.operands[0].type == X86_OP_IMM


def branch_target_pair(ordinary, marked, symbol, base, probe, before, after,
                       ordinary_tables, marked_tables):
    if (base.positions.get(before, len(base.instructions)) < len(base.instructions)
            and probe.positions.get(after, len(probe.instructions)) < len(probe.instructions)):
        return base.positions[before] == probe.positions[after]

    def owner(blob, span, address, is_marked, tables):
        absolute = (span.offset + address) & 0xffffffff
        offset, name = max((item for item in span.publics if item[0] <= absolute), default=(0, None))
        if name is None or name == symbol:
            raise KeyError(address)
        owner_span = decode(blob, name, is_marked, tables)
        return name, owner_span, owner_span.positions[absolute - offset], absolute == offset

    name_a, owner_a, index_a, entry_a = owner(ordinary, base, before, False, ordinary_tables)
    name_b, owner_b, index_b, entry_b = owner(marked, probe, after, True, marked_tables)
    if name_a != name_b or index_a != index_b:
        return False

    # Exact public entry points are stable symbolic targets. Their bodies
    # are audited independently of each caller.
    if entry_a or entry_b:
        return entry_a and entry_b

    # Shared tails may sit inside an earlier public. Require the complete
    # branch target suffix to be identical after stripping its marker bytes.
    suffix_a = owner_a.instructions[index_a:]
    suffix_b = owner_b.instructions[index_b:]
    if not suffix_a or len(suffix_a) != len(suffix_b):
        return False
    for i, (a, b) in enumerate(zip(suffix_a, suffix_b), index_a):
        if a.bytes != b.bytes or owner_a.references.get(i) != owner_b.references.get(i):
            return False
        # Only accept a verified straight-line tail. Other cross-public
        # transfers require a section-wide branch/relocation model.
        if direct_branch(a):
            return False
    return True


def compare(ordinary, marked, symbol, verified_tables=()):
    ordinary_tables, marked_tables = (), ()
    if verified_tables:
        sizes = {(segment, offset): size for segment, offset, size in verified_tables}
        ordinary_tables = switch_layout(ordinary, sizes, tuple(sizes))
        marked_tables = switch_layout(marked, tuple(4 * len(t.targets) for t in ordinary_tables))
    base = decode(ordinary, symbol, False, ordinary_tables)
    probe = decode(marked, symbol, True, marked_tables)
    if len(base.instructions) != len(probe.instructions):
        raise ValueError(f'Instruction count changed from {len(base.instructions)} to {len(probe.instructions)}')
    if base.references != probe.references:
        raise ValueError('OMF references changed')
    widened = []
    spans = []
    for index, (original, counting) in enumerate(zip(base.instructions, probe.instructions)):
        if original.mnemonic != counting.mnemonic:
            raise ValueError(f'Opcode changed at {original.address:#x}: {original.mnemonic} vs {counting.mnemonic}')
        fixed = FIXED_SHORT_BRANCHES.get(symbol, {}).get(original.address)
        if fixed is not None:
            unchanged = (probe.inline[index] and index not in base.references
                         and original.bytes == counting.bytes == fixed)
        elif direct_branch(original) and index not in base.references:
            unchanged = (direct_branch(counting) and
                         branch_target_pair(ordinary, marked, symbol, base, probe,
                                            original.operands[0].imm, counting.operands[0].imm,
                                            ordinary_tables, marked_tables))
        elif any(isinstance(ref[5], tuple) for ref in base.references.get(index, ())):
            if len(base.references[index]) != 1:
                raise ValueError('Ambiguous switch dispatch instruction')
            slot = base.references[index][0][5][1]
            a = ordinary_tables[slot]
            b = marked_tables[slot]
            target_a = tuple(base.positions.get(target - base.offset, -1) for target in a.targets)
            target_b = tuple(probe.positions.get(target - probe.offset, -1) for target in b.targets)
            unchanged = (original.bytes[:4] == counting.bytes[:4] and target_a == target_b
                         and all(0 <= entry < len(base.instructions) for entry in target_a))
        else:
            unchanged = original.bytes == counting.bytes
        if not unchanged:
            raise ValueError(f'Instruction changed at {original.address:#x}: {original.op_str} vs {counting.op_str}')
        if original.size != counting.size:
            widened.append((original.address, original.mnemonic, original.size, counting.size))
        if probe.inline[index]:
            start, end = original.address, original.address + original.size
            if spans and spans[-1][1] == start:
                spans[-1] = (spans[-1][0], end)
            else:
                spans.append((start, end))

    inline_bytes = sum(end - start for start, end in spans)
    total = sum(insn.size for insn in base.instructions)
    return total, inline_bytes, spans, widened, probe.invocations


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('ordinary', type=Path)
    parser.add_argument('marked', type=Path)
    parser.add_argument('symbol')
    args = parser.parse_args()
    total, inline, spans, widened, invocations = compare(
        args.ordinary.read_bytes(), args.marked.read_bytes(), args.symbol,
    )
    print(f'{args.symbol}: {total} total, {inline} inline, {total - inline} compiler-generated bytes')
    print(f'{invocations} inline invocations, {len(spans)} merged spans, {len(widened)} branch widths changed')
    print('inline spans:', ' '.join(f'{start:#x}-{end:#x}' for start, end in spans))
    print('branch changes:', ', '.join(f'{off:#x} {op} {before}->{after}' for off, op, before, after in widened))

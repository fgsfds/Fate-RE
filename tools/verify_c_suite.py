"""Verify every reconstructed C span and emit an auditable coverage inventory."""
import argparse
import hashlib
import json
from pathlib import Path
from compare_exe import TARGET_SHA256
from le_fixups import read_le_fixups
from match_objects import read_object
from verify_c_leaf import (LEAVES, DATA_OFFSETS, CODE_OFFSETS, FUNCTION_ADDRESSES,
                           bind_leaf_details, verify_leaf_relocations)

OBJECT_NAMES = {'activate_crush_sector_': 'crushact', 'deletesprite_': 'sprlists', 'loadtables_': 'loadtabl', 'changespritesect_': 'sprchang', 'changespritestat_': 'sprchang', 'animation_prestep_': 'prestep', 'audio_volume_': 'avol', 'move_listed_sprite_': 'movelist', 'netuninitconnection_': 'netuninc', 'convalloc32_': 'convallo', 'uninstallbicomhandlers_': 'uninstbc', 'add_listed_sprite_': 'add', 'insertsprite_': 'insert', 'spawn_template_sprite_': 'spawn', 'getpalookup_': 'pallook', 'netinitconnection_': 'netinitc', 'lookup_type_index_': 'reclook', 'transmaskvline_': 'transcol', 'lookup_record_value_': 'reclook', 'stereoinit_': 'stereo', 'stereoblit_': 'stereo', 'remove_listed_sprite_': 'remove', 'clippoly4_': 'clippoly', 'clipinsideboxline_': 'clipline', 'clipinsidebox_': 'clbox',
                'animateoffs_': 'animate', 'getmousevalues_': 'mouse',
                'spritewallfront_': 'sprfront', 'updatesector_': 'updsect',
                'alignceilslope_': 'slopes', 'alignflorslope_': 'slopes',
                'allocatepermanenttile_': 'alloctil', 'allocache_': 'allocach',
                'initcache_': 'initcach', 'kfilelength_': 'kfilelen',
                'plotpixel_': 'pixels', 'getpixel_': 'pixels', 'clear2dscreen_': 'editor16',
                'drawline256_': 'editor16', 'drawline16_': 'editor16',
                'qsetmode640350_': 'editor16', 'qsetmode640480_': 'editor16',
                'draw2dgrid_': 'editor16', 'uninitgroupfile_': 'uninitgr',
                'kopen4load_': 'kopen4', 'initgroupfile_': 'initgr', 'reportandexit_': 'report'}
# The cache/archive spans are checked from their jointly compiled prefix.
OBJECT_NAMES.update({'ceilspritescan_': 'ceilspr',
 'ceilspritehline_': 'ceilspr',
 'advance_sequences_': 'advance',
 'addclipline_': 'clipadd',
 'installbicomhandlers_': 'instbico',
 'append_sprite_event_': 'event',
 'comhandler_': 'comhandl',
 'simulateint_': 'simint',
 'activate_initial_crushers_': 'crdisp',
 'find_crush_sector_': 'crdisp',
 'loop_finish_': 'presgrp',
 'getanimationgoal_': 'anim',
 'setanimation_': 'anim',
 'dispatch_ticks_': 'presgrp',
 'dispatch_period_': 'presgrp',
 'dispatch_menu_': 'dispatch',
 'main_step_d_': 'dispatch',
 'game_loop_': 'frameprf',
 'is_crush_sector_': 'crushchk',
 'clear_crush_bank_': 'crushclr',
 'init_object_sequences_': 'initseq',
 'main_load_selection_': 'frameprf',
 'main_run_': 'frameprf',
 'main_': 'startgrp',
 'main_prepare_callback_': 'startgrp',
 'dispatch_prepare_': 'presgrp',
 'dispatch_poll_': 'presgrp',
 'setinterpolation_': 'interp',
 'stopinterpolation_': 'interp',
 'updateinterpolations_': 'interp',
 'dointerpolations_': 'intdraw',
 'restoreinterpolations_': 'intrest',
 'doanimations_': 'animstep',
 'presentation_reset_': 'presinp',
 'presentation_input_': 'presinp'})
from verify_cache_prefix import PUBLICS as CACHE_PUBLICS
from verify_cache_unit import verify as verify_cache_unit
from verify_network_defaults import verify as verify_network_defaults
OBJECT_NAMES.update({symbol: 'cacheunt' for symbol, _ in CACHE_PUBLICS})

GROUPS = {
    'sprchang': (160, ('changespritesect_', 'changespritestat_')),
    'presinp': (191, ('presentation_reset_', 'presentation_input_')),
    'presgrp': (920, ('loop_finish_', 'dispatch_ticks_', 'dispatch_period_', 'dispatch_prepare_', 'dispatch_poll_')),
    'interp': (200, ('setinterpolation_', 'stopinterpolation_', 'updateinterpolations_')),
    'anim': (148, ('getanimationgoal_', 'setanimation_')),
    'distime': (97, ('dispatch_ticks_', 'dispatch_period_')),
    'crdisp': (198, ('activate_initial_crushers_', 'find_crush_sector_')),
    'dispatch': (127, ('dispatch_menu_', 'main_step_d_')),
    'frameprf': (700, ('main_run_', 'main_load_selection_', 'game_loop_')),
    'startgrp': (272, ('main_prepare_callback_', 'main_')),
    'ceilspr': (1157, ('ceilspritescan_', 'ceilspritehline_')),
    'reclook': (128, ('lookup_record_value_', 'lookup_type_index_')),
    'slopes': (425, ('alignceilslope_', 'alignflorslope_')),
    'editor16': (3516, ('drawline256_', 'drawline16_', 'qsetmode640350_',
                       'qsetmode640480_', 'clear2dscreen_', 'draw2dgrid_')),
}


def verify_group_layout(blob, size, layout):
    """Require one complete CODE group and exact public offsets, including tails."""
    segments, publics = read_object(blob)
    code_segments = [i for i, segment in enumerate(segments[1:], 1) if segment['cls'] == 'CODE']
    if len(code_segments) != 1:
        raise ValueError('Expected exactly one group CODE segment')
    segment = code_segments[0]
    if len(segments[segment]['data']) != size:
        raise ValueError('Unexpected group CODE size')
    expected = sorted((segment, offset, symbol) for symbol, offset in layout)
    if sorted(publics) != expected:
        raise ValueError('Group public names/offsets differ from original layout')
    if any(item['data'] for i, item in enumerate(segments[1:], 1) if i != segment):
        raise ValueError('Group must keep non-code data external')


def verify_compiler_groups(exe, directory):
    for name, (size, symbols) in GROUPS.items():
        base = LEAVES[symbols[0]][0]
        layout = [(symbol, LEAVES[symbol][0]-base) for symbol in symbols]
        verify_group_layout((directory/(name+'.obj')).read_bytes(), size, layout)
    verify_cache_unit(exe, (directory/'cacheunt.obj').read_bytes())
    verify_network_defaults(exe, (directory/'netdefs.obj').read_bytes())


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('directory', type=Path)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    exe = args.executable.read_bytes()
    if hashlib.sha256(exe).hexdigest() != TARGET_SHA256:
        parser.error('Unknown FATE.EXE')
    pointers = read_le_fixups(exe)['pointers']
    verify_compiler_groups(exe, args.directory)
    rows, covered = [], set()
    for symbol, (offset, size) in sorted(LEAVES.items(), key=lambda item: item[1][0]):
        filename = OBJECT_NAMES.get(symbol, symbol[:-1])+'.obj'
        blob = (args.directory/filename).read_bytes()
        code_bindings = {}
        code, bindings = bind_leaf_details(blob, symbol, DATA_OFFSETS,
                                            address=offset-0x25600, functions=FUNCTION_ADDRESSES,
                                            absolute_code=CODE_OFFSETS, code_bindings=code_bindings)
        if code != exe[offset:offset+size]:
            raise ValueError(f'Code mismatch: {symbol}')
        verify_leaf_relocations(code, bindings, pointers, offset-0x25600,
                                code_bindings=code_bindings)
        sites = set(range(offset, offset+size))
        if covered & sites:
            raise ValueError('Overlapping coverage spans')
        covered.update(sites)
        rows.append(dict(symbol=symbol, object=filename,
                         object_sha256=hashlib.sha256(blob).hexdigest(),
                         sha256=hashlib.sha256(code).hexdigest(),
                         raw_offset=hex(offset), loaded_address=hex(offset-0x25600),
                         bytes=size, le_pointers=len(bindings)))
    # Generated CODE tables precede these functions but are not extra routines.
    from bind_melee_group import bind as bind_melee, BASE as MELEE_BASE, SIZE as MELEE_SIZE
    from bind_crush_init_group import bind as bind_crush, BASE as CRUSH_BASE, SIZE as CRUSH_SIZE
    prefixes = []
    for filename, binder, base, size, prefix_size, prefix_le, symbol, counts in [
            ('melee.obj', bind_melee, MELEE_BASE, MELEE_SIZE, 32, 8, 'melee_trigger_', (16, 9, 11)),
            ('crushini.obj', bind_crush, CRUSH_BASE, CRUSH_SIZE, 60, 15, 'init_crush_bank_', (18, 16, 4))]:
        blob = (args.directory/filename).read_bytes()
        code, data_bindings, code_bindings, calls = binder(blob)
        offset = base+0x25600
        if len(code) != size or code != exe[offset:offset+size]:
            raise ValueError('Generated-table compiler group differs: '+filename)
        if (len(data_bindings), len(code_bindings), len(calls)) != counts:
            raise ValueError('Unexpected group binding inventory: '+filename)
        bindings = data_bindings | code_bindings
        verify_leaf_relocations(code, bindings, pointers, base, code_bindings=code_bindings)
        if len([site for site in bindings if site < prefix_size]) != prefix_le:
            raise ValueError('Generated table relocation count differs: '+filename)
        sites = set(range(offset, offset+size))
        if covered & sites:
            raise ValueError('Overlapping compiler group coverage: '+filename)
        covered.update(sites)
        digest = hashlib.sha256(blob).hexdigest()
        prefixes.append(dict(kind='compiler-generated jump table', object=filename,
                             object_sha256=digest, raw_offset=hex(offset),
                             sha256=hashlib.sha256(code[:prefix_size]).hexdigest(),
                             loaded_address=hex(base), bytes=prefix_size, le_pointers=prefix_le))
        rows.append(dict(symbol=symbol, object=filename, object_sha256=digest,
                         sha256=hashlib.sha256(code[prefix_size:]).hexdigest(),
                         raw_offset=hex(offset+prefix_size), loaded_address=hex(base+prefix_size),
                         bytes=size-prefix_size, le_pointers=len(bindings)-prefix_le))
    rows.sort(key=lambda row: int(row['raw_offset'], 16))
    result = dict(target_sha256=TARGET_SHA256, routines=len(rows), unique_code_bytes=len(covered),
                  le_pointers=sum(row['le_pointers'] for row in rows+prefixes),
                  non_routine_code_spans=prefixes,
                  complete_modules=0, complete_executable=False,
                  note='Isolated spans/compiler groups, including generated jump-table prefixes; no complete original modules.', spans=rows)
    if args.output:
        args.output.write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
    print(f"PASS: {result['routines']} routines, {len(covered)} unique bytes, {result['le_pointers']} LE targets")

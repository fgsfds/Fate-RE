"""Independent bounded play_sound oracle; behavior PASS is never exact acceptance.
Reads existing objects only. All addresses below are frozen original-ASM aliases.
"""
import argparse
import hashlib
import json
from pathlib import Path
from struct import pack, unpack
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(ROOT / 'tools'), str(ROOT / 'work/cache/python/095240b6cf469e2f88b1')]
from differential import Machine, Contract, Region, Observation, bind_bodies, first_difference, require_mutations_detected
from le_fixups import read_le_fixups, pointer_range
from compare_exe import TARGET_SHA256

ENTRY, RAW, SIZE = 0x34f79, 0x5a579, 755
DS, DATA_SIZE, STACK, STOP = 0x80000, 0x360000, 0x3f0000, 0x3fff00
A = dict(invalid_sound_number=0x936, frame_state_12cd0=0x12cd0,
         frame_state_12cd4=0x12cd4, frame_state_12cd8=0x12cd8,
         frame_state_12cec=0x12cec, error_buffer=0x67e3c,
         sound_slots=0x854dc, frame_state_16fb1c=0x16fb1c,
         frame_state_16fdac=0x16fdac, frame_state_16fdb0=0x16fdb0,
         frame_state_1705dc=0x1705dc, sound_archive_handle=0x1714e0,
         audio_enabled=0x171602, frame_state_17160b=0x17160b,
         frame_state_17160f=0x17160f)
F = dict(format_string_=0x601f3, memset_=0x61350, lseek_=0x615b6,
         read_=0x615f7, audio_pan_=0x34e77, audio_volume_=0x34e1b,
         queue_audio_sample_=0x621b4)
CALLBACKS = dict(sound_callback_return_offset_=0x24c35, sound_sample_done_offset_=0x24c36)
CONTRACT = Contract(ENTRY, STOP, STACK, 4, preserved=('esi', 'edi', 'ebp'), results=('eax',))
INITIAL = bytes(range(256)) * (DATA_SIZE // 256)
ERROR = b'Invalid sound number\0'
u32 = lambda x: x & 0xffffffff
sha = lambda x: hashlib.sha256(x).hexdigest()
slot = lambda i: 0x290000 + i * 0x40
entry = lambda i: 0x291000 + (i + 1) * 0x10
buffer = lambda i: 0x2a0000 + i * 0x100
sample = lambda i: A['frame_state_1705dc'] + i * 240

def put(mem, off, value, width=4):
    mem[off:off+width] = (value & ((1 << (width*8))-1)).to_bytes(width, 'little')
def get(mem, off):
    return int.from_bytes(mem[off:off+4], 'little')
def pan(x, y):
    return u32(0x12348000 + x * 3 - y * 5)
def volume(x, y):
    return u32(0x76543210 - x * 7 + y * 11)
def payload(n):
    return bytes((i * 13 + 0x5b) & 255 for i in range(n))

def cases():
    result = []
    def add(name, **updates):
        c = dict(name=name, number=17, x=0, y=0, flags=0, free=0,
                 disabled=False, ready4=1, ready8=1, duplicate=-1,
                 cache_gate=-1, cache_hit=-1, read_result=37, seek_result=0,
                 queue_result=0x13572468, length=37)
        c.update(updates)
        result.append(c)
    for k, v in [('disabled', True), ('ready4', 0), ('ready8', 0)]:
        add('readiness_'+k, **{k:v})
    add('invalid_164', number=164)
    add('invalid_signed_max', number=0x7fffffff)
    add('full_slots', free=16)
    add('full_slots_duplicate', free=16, duplicate=15, flags=4)
    for i in [0, 1, 7, 15]:
        add('free_slot_'+str(i), free=i)
    add('duplicate_before_free', free=7, duplicate=3, flags=4)
    add('duplicate_after_free', free=3, duplicate=7, flags=4)
    add('duplicate_without_flag', free=7, duplicate=3)
    add('duplicate_at_free', free=3, duplicate=3, flags=4)
    add('selected_cache_minus_one_ignores_hit', cache_hit=12)
    add('last_selected_cache_minus_one_ignores_hit', free=15, cache_hit=0)
    for i in [0, 3, 15]:
        add('cache_reuse_'+str(i), free=7, cache_gate=99, cache_hit=i)
    add('cache_reuse_selected', free=7, cache_gate=99, cache_hit=7)
    add('cache_search_miss', free=7, cache_gate=99)
    add('ignored_seek_error', seek_result=-1)
    add('ignored_seek_error_after_search', cache_gate=99, seek_result=-1)
    for n in [-1, 0, 1, 36, 38]:
        add('read_result_'+str(n), read_result=n)
    for f in [1, 4, 8, 16, 9, 17, 24, 29, 0x80010001, 0xffff0001, 0x12340000]:
        add('center_flags_'+hex(f), flags=f)
        add('position_flags_'+hex(f), flags=f, x=-123456, y=98765)
    add('x_only', x=15)
    add('y_only', y=-19)
    add('id_zero', number=0)
    add('id_163', number=163)
    add('signed_negative_backed_id', number=-1)
    add('zero_length', length=0, read_result=0)
    add('queue_failure', queue_result=-1)
    add('queue_failure_sprite', flags=0xbeef0001, x=91, y=-71, queue_result=-1)
    add('queue_failure_reused_cache', free=15, cache_gate=99, cache_hit=4, flags=28, queue_result=-1)
    assert len(result) == 60
    return result

def initial_memory(c):
    m = bytearray(INITIAL)
    for k, v in [('audio_enabled', not c['disabled']), ('frame_state_12cd4', c['ready4']),
                 ('frame_state_12cd8', c['ready8']), ('frame_state_12cd0', 0x11223344),
                 ('sound_archive_handle', 23), ('frame_state_17160b', 0x87654321),
                 ('frame_state_17160f', 0xabcdef12), ('frame_state_12cec', 0x13579135)]:
        put(m, A[k], int(v), 1 if k == 'audio_enabled' else 4)
    m[A['invalid_sound_number']:A['invalid_sound_number']+len(ERROR)] = ERROR
    for i in range(16):
        put(m, A['sound_slots']+i*4, DS+slot(i))
        put(m, slot(i), -1 if i == c['free'] else 0x100+i)
        put(m, slot(i)+4, c['number'] if i == c['duplicate'] else 300+i)
        put(m, A['frame_state_16fdac']+i*8, DS+buffer(i))
        put(m, A['frame_state_16fdb0']+i*8, 500+i)
    if c['free'] < 16:
        put(m, A['frame_state_16fdb0']+c['free']*8, c['cache_gate'])
    if c['cache_hit'] >= 0:
        put(m, A['frame_state_16fdb0']+c['cache_hit']*8, c['number'])
    for i in range(-1, 164):
        put(m, A['frame_state_16fb1c']+i*4, DS+entry(i))
        put(m, entry(i)+4, 0x4000+i*101)
        put(m, entry(i)+8, c['length'])
    return m

def expected_behavior(c):
    m, calls = initial_memory(c), []
    def done(result):
        return Observation({'eax':u32(result)}, {'DS':bytes(m)}, tuple(calls))
    if c['disabled'] or not c['ready4'] or not c['ready8']:
        return done(-1)
    if c['number'] > 163:
        calls.append(('format_string', DS+A['error_buffer'], DS+A['invalid_sound_number']))
        m[A['error_buffer']:A['error_buffer']+len(ERROR)] = ERROR
        return done(-1)
    selected = 16
    for i in range(16):
        put(m, A['frame_state_17160f'], i)
        if get(m, slot(i)) == 0xffffffff:
            selected = i
            break
        if c['flags'] & 4 and get(m, slot(i)+4) == u32(c['number']):
            return done(-1)
    put(m, A['frame_state_17160f'], selected)
    if selected == 16:
        return done(-1)
    s = sample(selected)
    calls.append(('memset', DS+s, 0, 240))
    m[s:s+240] = bytes(240)
    data = None
    if get(m, A['frame_state_16fdb0']+selected*8) != 0xffffffff:
        for i in range(16):
            put(m, A['frame_state_17160b'], i)
            if get(m, A['frame_state_16fdb0']+i*8) == u32(c['number']):
                data = get(m, A['frame_state_16fdac']+i*8)
                break
        if data is None:
            put(m, A['frame_state_17160b'], 16)
    if data is None:
        calls.append(('lseek', 23, u32(0x4000+c['number']*101), 0))
        data = DS+buffer(selected)
        calls.append(('read', 23, data, c['length']))
        n = max(0, min(c['length'], c['read_result']))
        m[data-DS:data-DS+n] = payload(n)
        put(m, A['frame_state_12cec'], c['read_result'])
        if c['read_result'] != c['length']:
            return done(-1)
        put(m, A['frame_state_16fdb0']+selected*8, c['number'])
    values = {0:data, 0xc:c['length'], 0x10:0, 0x1c:selected, 0x30:0,
              0x34:0x2b11, 0x38:8, 0x3c:1, 0x40:0x8000,
              0x5c:0x34c35, 0x60:0x34c36, 0x64:0x34c35}
    if c['x'] == c['y'] == 0:
        values.update({0x44:0x8000, 0x2c:0x7fff7fff})
    else:
        calls.append(('audio_pan', u32(c['x']), u32(c['y'])))
        values[0x44] = pan(c['x'], c['y'])
        if c['flags'] & 4:
            values[0x2c] = 0x6fff6fff
        else:
            calls.append(('audio_volume', u32(c['x']), u32(c['y'])))
            values[0x2c] = volume(c['x'], c['y'])
    if c['flags'] & 1:
        put(m, slot(selected)+0xe, c['flags'] >> 16, 2)
        values[0x30] = -1
    if c['flags'] & 24:
        values.update({0x30:-1, 0x2c:0})
    for off, value in values.items():
        put(m, s+off, value)
    for off, value in [(4,c['number']), (0x10,c['x']), (0x14,c['y']), (0x18,c['flags'])]:
        put(m, slot(selected)+off, value)
    calls.append(('queue_audio_sample', 0x11223344, DS+s, bytes(m[s:s+240]).hex(),
                  bytes(m[slot(selected):slot(selected)+0x1c]).hex()))
    put(m, slot(selected), c['queue_result'])
    if c['queue_result'] == -1:
        put(m, slot(selected)+0xe, 0, 2)
        put(m, slot(selected)+0x18, 0)
        return done(-1)
    return done(selected)

def exercise(body, c):
    machine = Machine(CONTRACT, body, [Region('DS', DS, DATA_SIZE)])
    machine.write(DS, initial_memory(c))
    def args(m, *regs):
        return tuple(m.register(r) for r in regs)
    def formatter(m):
        dst, fmt = unpack('<2I', m.read(m.register('esp')+4,8))
        assert m.read(fmt,len(ERROR)) == ERROR
        m.record('format_string',dst,fmt)
        m.write(dst,ERROR)
        return {'eax':len(ERROR)-1}
    def clear(m):
        dst, fill, count = args(m,'eax','edx','ebx')
        assert count == 240 and fill == 0
        m.record('memset',dst,fill,count)
        m.write(dst,bytes(count))
        return {'edx':0xdadadada}
    def seek(m):
        m.record('lseek',*args(m,'eax','edx','ebx'))
        return {'eax':c['seek_result'], 'ebx':0xbad00001, 'edx':0xbad00002}
    def read(m):
        fd,dst,count = args(m,'eax','edx','ebx')
        m.record('read',fd,dst,count)
        n = max(0,min(count,c['read_result']))
        m.write(dst,payload(n))
        return {'eax':c['read_result'], 'ebx':0xbad00003, 'edx':0xbad00004}
    def positional(name, fn):
        def call(m):
            x,y = args(m,'eax','edx')
            m.record(name,x,y)
            signed = lambda n: n-(1<<32) if n & 0x80000000 else n
            return {'eax':fn(signed(x),signed(y)), 'edx':0xdead0005}
        return call
    def queue(m):
        driver,desc = args(m,'eax','edx')
        i = get(bytearray(m.read(desc,240)),0x1c)
        ptr = unpack('<I',m.read(DS+A['sound_slots']+i*4,4))[0]
        m.record('queue_audio_sample',driver,desc,m.read(desc,240).hex(),m.read(ptr,0x1c).hex())
        return {'eax':c['queue_result'], 'edx':0xdead0006}
    for name, fn in [('format_string_',formatter),('memset_',clear),('lseek_',seek),
                     ('read_',read),('audio_pan_',positional('audio_pan',pan)),
                     ('audio_volume_',positional('audio_volume',volume)),('queue_audio_sample_',queue)]:
        machine.stub(F[name],fn)
    return machine.run(dict(eax=u32(c['number']),edx=u32(c['x']),ebx=u32(c['y']),
                            ecx=c['flags'],esi=0x23456789,edi=0x3456789a,ebp=0x456789ab,eflags=0x202))

def reference_body(exe):
    assert sha(exe) == TARGET_SHA256, 'pinned executable hash mismatch'
    body = bytearray(exe[RAW:RAW+SIZE])
    refs = pointer_range(read_le_fixups(exe)['pointers'],ENTRY,SIZE)
    assert len(refs) == 57
    for off,target in refs.items():
        body[off:off+4] = pack('<I',target)
    return bytes(body)


def exercise_archive_full_guard(body):
    """Enter the normally preempted archive guard with the real playback frame."""
    from unicorn import UC_HOOK_CODE
    c = cases()[0] | {'disabled': False, 'free': 16}
    memory = initial_memory(c)
    put(memory, A['frame_state_17160f'], 16)
    contract = Contract(0x3507b, STOP, STACK, 4, preserved=(),
        results=('eax','esi','edi','ebp','ecx'))
    machine = Machine(contract, body, [Region('DS',DS,DATA_SIZE)], code_address=ENTRY)
    machine.write(DS,memory)
    saved = (0x456789ab,0x3456789a,0x23456789)
    machine.write(STACK-20,pack('<5I',0xa7a7a7a7,u32(c['x']),*saved))
    def seed_frame(_cpu,address,_size,_user):
        if address == contract.entry:
            machine.set_register('esp',STACK-20)
    hook = machine.cpu.hook_add(UC_HOOK_CODE,seed_frame)
    try:
        observed = machine.run(dict(eax=0xbad00001,ebx=0xbad00002,edx=0xbad00003,
            esi=DS+sample(0),edi=c['number'],ebp=u32(c['y']),ecx=c['flags'],eflags=0x202))
    finally:
        machine.cpu.hook_del(hook)
    expected = Observation(dict(eax=0xffffffff,ebp=saved[0],edi=saved[1],esi=saved[2],ecx=c['flags']),
        {'DS':bytes(memory)},())
    difference = first_difference(expected,observed)
    assert not difference, 'archive full-slot direct guard: '+str(difference)
    return observed

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--exe', type=Path, required=True)
    group = p.add_mutually_exclusive_group()
    group.add_argument('--object',type=Path,help='existing candidate OMF; research behavior only')
    group.add_argument('--build',type=Path,help='production build containing split sound assembly and sndscan/sndcache/sndarch/sndopts/snddesc/sndpos/sndqueue objects')
    p.add_argument('--symbol',default='play_sound_')
    p.add_argument('--output',type=Path,help='optional report; omitted means no files written')
    a = p.parse_args()
    exe = a.exe.read_bytes()
    ref = reference_body(exe)
    report = dict(fixture='play-sound',mode='behavior-only' if a.object else 'original-model-only',exact_verified=False,
                  inventory_eligible=False,reference_sha256=sha(exe),reference_body_sha256=sha(ref),
                  reference_le_fixups=57,data_bytes_compared=DATA_SIZE,preserved_registers=list(CONTRACT.preserved),
                  case_count=len(cases()),cases=[],status='FAIL',
                  helper_contracts={'format_string':'caller stack, EAX only; bounded invalid-number literal',
                    'memset':'EAX/EDX/EBX args; model retains EAX/ECX/ESI and poisons EDX',
                    'lseek_read':'EAX/EDX/EBX args; EAX/EBX/EDX clobbered',
                    'pan_volume_queue':'EAX/EDX args; EAX/EDX clobbered; ECX retained'},
                  model_scope='60 bounded cases; 0..163 plus backed -1 ID; formatting, memset, seek/read, pan/volume and queue are stubbed; no asset or live driver verification')
    try:
        observations = []
        # Validate the independent state/trace model against original before binding candidate.
        for c in cases():
            observed = exercise(ref,c)
            difference = first_difference(expected_behavior(c),observed)
            assert not difference, f"original {c['name']}: {difference}"
            observations.append(observed)
        report['original_model_cases_passed'] = len(observations)
        candidate = None
        if a.build:
            from verify_c_leaf import bind_leaf_details, verify_leaf_relocations, DATA_OFFSETS, CODE_OFFSETS, FUNCTION_ADDRESSES
            from check_ripple_stack import mutate_public_byte
            from check_ripple_control import rename_external
            pointers = read_le_fixups(exe)['pointers']

            def checked_phase(obj, symbol, address, size, *, data_offsets=DATA_OFFSETS, code_offsets=CODE_OFFSETS,
                              functions=FUNCTION_ADDRESSES):
                code_refs = {}
                part, bindings = bind_leaf_details(obj, symbol, data_offsets, address=address,
                    functions=functions, absolute_code=code_offsets, code_bindings=code_refs)
                assert len(part) == size, 'Sound selected extent differs'
                assert part == exe[address+0x25600:address+0x25600+size], 'Sound selected bytes differ'
                verify_leaf_relocations(part, bindings, pointers, address, code_bindings=code_refs)
                return part

            obj = (a.build/'sndopts.obj').read_bytes()
            kwargs = dict(address=0x35178, functions=FUNCTION_ADDRESSES, absolute_code=CODE_OFFSETS, code_bindings={})
            phase = checked_phase(obj, 'sound_playback_options_', 0x35178, 80)
            for bad, expected_error in ((mutate_public_byte(obj, 'playback_options_', 80), 'private context digest'),
                        (rename_external(obj, b'sound_sample_done_offset_', b'sound_sample_done_offseu_'), 'context fixup target/form/addend')):
                try:
                    bind_leaf_details(bad, 'sound_playback_options_', DATA_OFFSETS, **(kwargs | {'code_bindings': {}}))
                except ValueError as error:
                    assert expected_error in str(error), str(error)
                else:
                    raise AssertionError('Sound private context mutation escaped')
            retained = (a.build/'asm/play_sound.bin').read_bytes()
            description_obj = (a.build/'snddesc.obj').read_bytes()
            description = checked_phase(description_obj, 'sound_playback_description_', 0x350f1, 69)
            try:
                bind_leaf_details(mutate_public_byte(description_obj, 'playback_description_', 69),
                    'sound_playback_description_', DATA_OFFSETS, address=0x350f1, absolute_code=CODE_OFFSETS, code_bindings={})
            except ValueError as error:
                assert 'private context digest' in str(error), str(error)
            else:
                raise AssertionError('Descriptor private cleanup mutation escaped')
            position_obj = (a.build/'sndpos.obj').read_bytes()
            position = checked_phase(position_obj, 'sound_playback_position_', 0x35136, 66)
            for bad, expected_error in ((mutate_public_byte(position_obj, 'playback_position_', 73), 'context digest'),
                (rename_external(position_obj, b'sound_sample_done_offset_', b'sound_sample_done_offseu_'), 'context fixup target/form/addend')):
                try:
                    bind_leaf_details(bad, 'sound_playback_position_', DATA_OFFSETS, address=0x35136,
                        functions=FUNCTION_ADDRESSES, absolute_code=CODE_OFFSETS, code_bindings={})
                except ValueError as error:
                    assert expected_error in str(error), str(error)
                else:
                    raise AssertionError('Unlinked positioning continuation mutation escaped')
            archive_obj = (a.build/'sndarch.obj').read_bytes()
            archive = checked_phase(archive_obj, 'sound_playback_archive_', 0x3507b, 118)
            archive_controls = []
            for offset,mask in ((0,1),(11,1),(97,1),(121,1),(124,1),(10,0xe7),(96,0xe7)):
                try:
                    checked_phase(mutate_public_byte(archive_obj,'playback_archive_',offset,mask=mask),
                        'sound_playback_archive_', 0x3507b, 118)
                except ValueError as error:
                    assert 'context digest' in str(error), str(error)
                else:
                    raise AssertionError('Archive private context mutation escaped')
                archive_controls.append('byte_'+str(offset))
            try:
                checked_phase(rename_external(archive_obj, b'playback_archive_failure_', b'playback_archive_failurf_'),
                    'sound_playback_archive_', 0x3507b, 118)
            except ValueError as error:
                assert 'context fixup records' in str(error), str(error)
            else:
                raise AssertionError('Archive failure continuation mutation escaped')
            archive_controls.append('failure_target_name')
            from dataclasses import replace
            from check_encounter_actor import rewrite_fixup
            unchanged,changed = rewrite_fixup(archive_obj,lambda f:False,lambda f:f)
            assert not changed
            assert checked_phase(unchanged,'sound_playback_archive_',0x3507b,118) == archive
            for name,change in (
                    ('frame',lambda f:replace(f,frame=(1,1))),
                    ('unknown_group',lambda f:replace(f,frame=(1,127))),
                    ('target',lambda f:replace(f,target=(2,1))),
                    ('displacement',lambda f:replace(f,displacement=1))):
                bad,changed = rewrite_fixup(archive_obj,lambda f:f.offset==12,change)
                assert changed
                try:
                    checked_phase(bad,'sound_playback_archive_',0x3507b,118)
                except ValueError as error:
                    assert 'context fixup records' in str(error), str(error)
                else:
                    raise AssertionError('Archive fixup '+name+' mutation escaped')
                archive_controls.append(name)
            import verify_c_leaf as leaf
            archive_digest = leaf.LEAF_CONTEXT_SHA256.pop('playback_archive_')
            try:
                try:
                    checked_phase(mutate_public_byte(archive_obj,'playback_archive_',12),
                        'sound_playback_archive_', 0x3507b, 118)
                except ValueError as error:
                    assert 'context fixup target/form/addend' in str(error), str(error)
                else:
                    raise AssertionError('Archive relative jump addend mutation escaped')
            finally:
                leaf.LEAF_CONTEXT_SHA256['playback_archive_'] = archive_digest
            archive_controls.append('jump_addend')
            cache_obj = (a.build/'sndcache.obj').read_bytes()
            cache = checked_phase(cache_obj,'sound_playback_cache_',0x3502d,78)
            cache_controls = []
            def reject_cache(blob,message):
                try:
                    checked_phase(blob,'sound_playback_cache_',0x3502d,78)
                except ValueError as error:
                    assert message in str(error), str(error)
                else:
                    raise AssertionError('Cache context mutation escaped')
            for offset,mask in ((78,1),(23,1),(24,1),(76,1),(77,1),(10,1),(9,0xe7),(55,1)):
                reject_cache(mutate_public_byte(cache_obj,'playback_cache_lookup_',offset,mask=mask),'context digest')
                cache_controls.append('byte_'+str(offset))
            reject_cache(rename_external(cache_obj,b'playback_cached_sample_',b'playback_cached_samplf_'),'context fixup records')
            cache_controls.append('hit_target_name')
            unchanged,changed = rewrite_fixup(cache_obj,lambda f:False,lambda f:f)
            assert not changed
            assert checked_phase(unchanged,'sound_playback_cache_',0x3502d,78) == cache
            for name,change in (
                    ('frame',lambda f:replace(f,frame=(1,1))),
                    ('unknown_group',lambda f:replace(f,frame=(1,127))),
                    ('target',lambda f:replace(f,target=(2,1))),
                    ('displacement',lambda f:replace(f,displacement=1))):
                bad,changed = rewrite_fixup(cache_obj,lambda f:f.offset==11,change)
                assert changed
                reject_cache(bad,'context fixup records')
                cache_controls.append(name)
            cache_digest = leaf.LEAF_CONTEXT_SHA256.pop('playback_cache_lookup_')
            try:
                reject_cache(mutate_public_byte(cache_obj,'playback_cache_lookup_',11),'context fixup target/form/addend')
            finally:
                leaf.LEAF_CONTEXT_SHA256['playback_cache_lookup_'] = cache_digest
            cache_controls.append('failure_jump_addend')
            scan_obj = (a.build/'sndscan.obj').read_bytes()
            scan = checked_phase(scan_obj,'sound_playback_slots_',0x34fd0,93)
            scan_controls = []
            def reject_scan(blob,message,**kwargs):
                try:
                    checked_phase(blob,'sound_playback_slots_',0x34fd0,93,**kwargs)
                except (ValueError,AssertionError) as error:
                    assert message in str(error), str(error)
                else:
                    raise AssertionError('Slot scan context mutation escaped')
            for offset,mask in ((93,1),(103,1),(108,1),(56,1),(71,0xe7),(72,1),(62,1),(91,1),(92,1)):
                reject_scan(mutate_public_byte(scan_obj,'playback_slot_scan_',offset,mask=mask),'context digest')
                scan_controls.append('byte_'+str(offset))
            reject_scan(rename_external(scan_obj,b'memset_',b'memseu_'),'context fixup records')
            scan_controls.append('clear_target_name')
            unchanged,changed = rewrite_fixup(scan_obj,lambda f:False,lambda f:f)
            assert not changed
            assert checked_phase(unchanged,'sound_playback_slots_',0x34fd0,93) == scan
            for name,change in (
                    ('frame',lambda f:replace(f,frame=(1,1))),
                    ('unknown_group',lambda f:replace(f,frame=(1,127))),
                    ('target',lambda f:replace(f,target=(2,1))),
                    ('displacement',lambda f:replace(f,displacement=1))):
                bad,changed = rewrite_fixup(scan_obj,lambda f:f.offset==104,change)
                assert changed
                reject_scan(bad,'context fixup records')
                scan_controls.append('excluded_'+name)
            scan_digest = leaf.LEAF_CONTEXT_SHA256.pop('playback_slot_scan_')
            try:
                for offset in (57,95,104):
                    reject_scan(mutate_public_byte(scan_obj,'playback_slot_scan_',offset),'context fixup target/form/addend')
                    scan_controls.append('addend_'+str(offset))
            finally:
                leaf.LEAF_CONTEXT_SHA256['playback_slot_scan_'] = scan_digest
            selected = leaf.LEAF_CODE_SLICES['sound_playback_slots_']
            try:
                for end in (108,109):
                    leaf.LEAF_CODE_SLICES['sound_playback_slots_'] = (selected[0],0,end,109)
                    reject_scan(scan_obj,'Sound selected extent differs')
                    scan_controls.append('extent_'+str(end))
            finally:
                leaf.LEAF_CODE_SLICES['sound_playback_slots_'] = selected
            for name in ('memset_','playback_archive_failure_'):
                wrong = dict(FUNCTION_ADDRESSES)
                wrong[name] += 1
                reject_scan(scan_obj,'Sound selected bytes differ',functions=wrong)
                scan_controls.append('binding_'+name)
            full_refs = {}
            full,bindings = bind_leaf_details(scan_obj,'playback_slot_scan_',DATA_OFFSETS,address=0x34fd0,
                functions=FUNCTION_ADDRESSES,absolute_code=CODE_OFFSETS,code_bindings=full_refs)
            assert not full_refs and full[:93] == scan and full[93:108] == cache[:15] and full[108:] == b'\xc3'
            verify_leaf_relocations(full[93:108],{off-93:value for off,value in bindings.items() if 93<=off<108},
                pointers,0x3502d,code_bindings={})
            # Preserve raw operands while changing their LE object class. These
            # must fail typed binding checks before reference-loaded replay.
            for control_obj, symbol, address, size, name, was_code in (
                    (obj, 'sound_playback_options_', 0x35178, 80, 'sound_sample_done_offset_', True),
                    (description_obj, 'sound_playback_description_', 0x350f1, 69, '_frame_state_16fb18', False),
                    (archive_obj, 'sound_playback_archive_', 0x3507b, 118, '_frame_state_16fdac', False),
                    (cache_obj, 'sound_playback_cache_', 0x3502d, 78, '_frame_state_17160b', False),
                    (scan_obj, 'sound_playback_slots_', 0x34fd0, 93, '_frame_state_1705dc', False)):
                data_offsets, code_offsets = dict(DATA_OFFSETS), dict(CODE_OFFSETS)
                source, destination = (code_offsets, data_offsets) if was_code else (data_offsets, code_offsets)
                destination[name] = source.pop(name)
                try:
                    checked_phase(control_obj, symbol, address, size,
                        data_offsets=data_offsets, code_offsets=code_offsets)
                except ValueError as error:
                    assert 'Original LE relocation sites or targets differ' in str(error), str(error)
                else:
                    raise AssertionError('Sound relocation class mutation escaped')
            report['relocation_class_controls_rejected'] = 5
            queue_obj = (a.build/'sndqueue.obj').read_bytes()
            queue_parts = []
            for role, address, size in (('metadata',0x351c8,61),('y',0x35205,3),
                                        ('descriptor',0x35208,2),('compare',0x3520a,43)):
                code_refs = {}
                part, bindings = bind_leaf_details(queue_obj, 'sound_queue_'+role+'_', DATA_OFFSETS,
                    address=address, functions=FUNCTION_ADDRESSES, absolute_code=CODE_OFFSETS, code_bindings=code_refs)
                assert not code_refs, 'Queue phase LE fields must all be DATA'
                assert len(part) == size and part == exe[address+0x25600:address+0x25600+size]
                verify_leaf_relocations(part, bindings, pointers, address, code_bindings=code_refs)
                queue_parts.append(part)
            queue = b''.join(queue_parts)
            for offset in (61,63,150,154,158):
                try:
                    bind_leaf_details(mutate_public_byte(queue_obj,'playback_queue_',offset),
                        'sound_queue_metadata_', DATA_OFFSETS, address=0x351c8,
                        functions=FUNCTION_ADDRESSES, absolute_code=CODE_OFFSETS, code_bindings={})
                except ValueError as error:
                    assert 'context digest' in str(error), str(error)
                else:
                    raise AssertionError('Queue private context mutation escaped')
            import verify_c_leaf as leaf
            digest = leaf.LEAF_CONTEXT_SHA256.pop('playback_queue_')
            try:
                try:
                    bind_leaf_details(mutate_public_byte(queue_obj,'playback_queue_',154),
                        'sound_queue_metadata_', DATA_OFFSETS, address=0x351c8,
                        functions=FUNCTION_ADDRESSES, absolute_code=CODE_OFFSETS, code_bindings={})
                except ValueError as error:
                    assert 'context fixup target/form/addend' in str(error), str(error)
                else:
                    raise AssertionError('Off-slice queue addend mutation escaped')
                try:
                    bind_leaf_details(mutate_public_byte(queue_obj,'playback_queue_',110),
                        'sound_queue_metadata_', DATA_OFFSETS, address=0x351c8,
                        functions=FUNCTION_ADDRESSES, absolute_code=CODE_OFFSETS, code_bindings={})
                except ValueError as error:
                    assert 'Section branch compiler target differs' in str(error), str(error)
                else:
                    raise AssertionError('Off-slice queue branch mutation escaped')
            finally:
                leaf.LEAF_CONTEXT_SHA256['playback_queue_'] = digest
            queue_results=[]
            for role,address,size in (('cleanup',0x35235,41),('success',0x35260,5)):
                code_refs={}
                part,bindings=bind_leaf_details(queue_obj,'sound_queue_'+role+'_',DATA_OFFSETS,
                    address=address,functions=FUNCTION_ADDRESSES,absolute_code=CODE_OFFSETS,code_bindings=code_refs)
                assert not code_refs and len(part)==size
                assert part==exe[address+0x25600:address+0x25600+size]
                verify_leaf_relocations(part,bindings,pointers,address,code_bindings=code_refs)
                queue_results.append(part)
            assert len(retained) == 96
            ending=queue_results[0]+retained[87:89]+queue_results[1]+retained[89:]
            assembled = retained[:87] + scan + cache + archive + description + position + phase + queue + ending
            natural = retained[:87] + scan + cache + archive + description + position + phase + b''.join(queue_parts[i] for i in (0,2,1,3)) + ending
            report.update(restored_c_bytes=659, retained_asm_bytes=96,
                context_mutations_rejected=12+len(archive_controls)+len(cache_controls)+len(scan_controls),
                archive_context_controls=archive_controls,cache_context_controls=cache_controls,scan_context_controls=scan_controls,
                swap_scope='mapped writable slot and normal completion; placed order matches original even at fault/interrupt boundaries')
            assert len(assembled) == SIZE, 'reconstructed routine must be 755 bytes'
            assert assembled == exe[RAW:RAW+SIZE], 'reconstructed routine differs from pinned original'
            refs = pointer_range(read_le_fixups(exe)['pointers'],ENTRY,SIZE)
            assert len(refs) == 57, 'reconstructed routine requires 57 LE sites'
            candidate = bytearray(assembled)
            for off,target in refs.items():
                assert off+4 <= SIZE, 'partial LE operand at assembly boundary'
                candidate[off:off+4] = pack('<I',target)
            candidate = bytes(candidate)
            assert exercise_archive_full_guard(candidate) == exercise_archive_full_guard(ref)
            report['direct_archive_full_guard_cases_passed'] = 1
            natural_loaded = bytearray(natural)
            for off, target in refs.items():
                natural_loaded[off:off+4] = pack('<I',target)
            natural_candidate = bytes(natural_loaded)
            report['natural_queue_cases_passed'] = 0
            assert candidate == ref
            report.update(mode='mixed-C-assembly-and-behavior',exact_verified=True,
                          reconstructed_raw_sha256=sha(assembled),routine_bytes=SIZE,routine_le_fixups=57)
        if a.object:
            from verify_c_leaf import CODE_OFFSETS
            saved = dict(CODE_OFFSETS)
            try:
                CODE_OFFSETS.update(CALLBACKS)
                rebound,candidate,fixups = bind_bodies(exe,a.object.read_bytes(),a.symbol,ENTRY,SIZE,
                    {'_'+name:off for name,off in A.items()},F,data_base=DS,behavior_only=True)
            finally:
                CODE_OFFSETS.clear()
                CODE_OFFSETS.update(saved)
            assert rebound == ref
            report.update(candidate_object_sha256=sha(a.object.read_bytes()),candidate_bytes=len(candidate),
                          candidate_body_sha256=sha(candidate),candidate_absolute_fixups=fixups)
        for c, observed in zip(cases(),observations):
            actual = exercise(candidate,c) if candidate is not None else observed
            difference = first_difference(observed,actual)
            report['cases'].append(dict(name=c['name'],status='FAIL' if difference else 'PASS',
                calls=len(observed.calls),reference_ds_sha256=sha(observed.memory['DS']),
                candidate_ds_sha256=sha(actual.memory['DS']),trace_sha256=sha(repr(observed.calls).encode())))
            assert not difference, f"candidate {c['name']}: {difference}"
            if a.build:
                natural_result = exercise(natural_candidate,c)
                difference = first_difference(observed,natural_result)
                assert not difference, f"natural queue {c['name']}: {difference}"
                report['natural_queue_cases_passed'] += 1
        wrong = bytearray(ref)
        pos = wrong.index(pack('<I',0x7fff7fff))
        wrong[pos:pos+4] = pack('<I',0x7ffe7ffe)
        report['negative_controls_detected'] = require_mutations_detected('play-sound',ref,
            [('wrong_center_volume',bytes(wrong),cases()[7]),
             ('wrong_stack_cleanup',ref[:-1]+b'\xc2\x04\x00',cases()[0])],exercise)
        report['status'] = 'PASS'
    except Exception as e:
        report['failure'] = str(e)
        raise
    finally:
        report['cases_passed'] = sum(c['status']=='PASS' for c in report['cases'])
        if a.output:
            a.output.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({k:v for k,v in report.items() if k != 'cases'},indent=2))

if __name__ == '__main__':
    main()

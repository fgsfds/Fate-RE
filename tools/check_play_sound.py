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

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--exe', type=Path, required=True)
    group = p.add_mutually_exclusive_group()
    group.add_argument('--object',type=Path,help='existing candidate OMF; research behavior only')
    group.add_argument('--build',type=Path,help='production build containing split sound assembly, sndopts.obj and snddesc.obj')
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
                    'memset':'EAX/EDX/EBX args, EAX retained, EDX clobbered',
                    'lseek_read':'EAX/EDX/EBX args; EAX/EBX/EDX clobbered',
                    'pan_volume_queue':'EAX/EDX args; EAX/EDX clobbered; ECX retained'},
                  model_scope='60 bounded cases; 0..163 plus backed -1 ID; deterministic read, pan, volume and queue stubs; no asset or live driver verification')
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
            from verify_c_leaf import bind_leaf_details, DATA_OFFSETS, CODE_OFFSETS, FUNCTION_ADDRESSES
            from check_ripple_stack import mutate_public_byte
            from check_ripple_control import rename_external
            obj = (a.build/'sndopts.obj').read_bytes()
            kwargs = dict(address=0x35178, functions=FUNCTION_ADDRESSES, absolute_code=CODE_OFFSETS, code_bindings={})
            phase, _ = bind_leaf_details(obj, 'sound_playback_options_', DATA_OFFSETS, **kwargs)
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
            description, _ = bind_leaf_details(description_obj, 'sound_playback_description_', DATA_OFFSETS,
                address=0x350f1, functions=FUNCTION_ADDRESSES, absolute_code=CODE_OFFSETS, code_bindings={})
            try:
                bind_leaf_details(mutate_public_byte(description_obj, 'playback_description_', 69),
                    'sound_playback_description_', DATA_OFFSETS, address=0x350f1, absolute_code=CODE_OFFSETS, code_bindings={})
            except ValueError as error:
                assert 'private context digest' in str(error), str(error)
            else:
                raise AssertionError('Descriptor private cleanup mutation escaped')
            assert len(retained) == 606
            assembled = retained[:376] + description + retained[376:442] + phase + retained[442:]
            report.update(restored_c_bytes=149, retained_asm_bytes=606, context_mutations_rejected=3)
            assert len(assembled) == SIZE, 'reconstructed routine must be 755 bytes'
            assert assembled == exe[RAW:RAW+SIZE], 'reconstructed routine differs from pinned original'
            refs = pointer_range(read_le_fixups(exe)['pointers'],ENTRY,SIZE)
            assert len(refs) == 57, 'reconstructed routine requires 57 LE sites'
            candidate = bytearray(assembled)
            for off,target in refs.items():
                assert off+4 <= SIZE, 'partial LE operand at assembly boundary'
                candidate[off:off+4] = pack('<I',target)
            candidate = bytes(candidate)
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

"""Verify the exact actor-common leaf and its bounded behavior cases."""
import argparse
from math import isqrt
from pathlib import Path
from struct import pack, unpack
from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import *
import hashlib
import sys
from check_start_hook import DS, image
from compare_exe import TARGET_SHA256
from le_fixups import pointer_range, read_le_fixups
from verify_c_leaf import (DATA_OFFSETS, FUNCTION_ADDRESSES, bind_leaf_details,
                           verify_leaf_relocations)
ENTRY, RAW, SIZE = 0x14897, 0x39e97, 697
EXPECTED_LE_SITES = 41
STACK, STOP, ACTOR, SLOT, SECTOR = 0x3ff000, 0x3fff00, 3, 7, 2
DATA = DATA_OFFSETS
FUNCS = FUNCTION_ADDRESSES
SAVED = (UC_X86_REG_EBX,UC_X86_REG_ECX,UC_X86_REG_EDX,UC_X86_REG_ESI,
         UC_X86_REG_EDI,UC_X86_REG_EBP)
def u32(x): return x & 0xffffffff
def s32(x): return ((x+0x80000000)&0xffffffff)-0x80000000
def s16(x): return ((x+32768)&65535)-32768
def rem(x,d): return x % d if x>=0 else -((-x)%d)
def addr(name): return DS+DATA['_'+name]

def oracle(c):
    state=dict(kind=c['kind'],counter=c['counter'],health=c['health'],z=-9988,
               cstat=0x4321,repeat=c['repeat'])
    calls=[]; ri=0
    def random():
        nonlocal ri
        value=s32(c['random'][ri % len(c['random'])]);ri+=1
        calls.append(('random',value))
        return value
    for step in range(c['steps']):
        if state['kind']==3: continue
        if state['counter'] and c['clock']:
            state['counter']=(state['counter']+1)&255
            if state['counter']>6: state['counter']=0;state['kind']=0
        if state['health']<=0:
            state.update(z=c['floor'],cstat=0,repeat=(state['repeat']*2)&255,kind=3)
            calls.append(('sequence',SLOT))
            continue
        if c['alternate']:
            dx=s32(c['x']-c['px']);dy=s32(c['y']-c['py'])
            squared=u32(dx*dx+dy*dy);calls.append(('sqrt',squared))
            if isqrt(squared)<350:
                calls.append(('angle',u32(dx),u32(dy)))
                delta=s16(c['angle'])-s16(c['player_angle'])
                calls.append(('abs',u32(delta)));delta=abs(delta)
                facing=2047-delta if s16(delta)>1024 else delta
                if s16(facing)<120:
                    if (c['input']&0xffff)>>13:
                        state['kind']=4;state['health']=s16(state['health']-300)
                    elif (random()&3)==3 or c['mode']==2:
                        state['kind']=5;state['health']=s16(state['health']-200)
        if state['kind'] in (4,5) and state['counter']==0:
            sounds={0x966:(0x24,4),0x9b8:(0x3a,2),0xa02:(0x57,2),0xa70:(0x49,2)}
            if c['tile'] in sounds:
                base,divisor=sounds[c['tile']]
                sound=base+rem(random(),divisor)
                calls.append(('sound',u32(sound),u32(c['x']),u32(c['y']),0))
            state['counter']=3
    return state,calls

def exercise(memory,body,c):
    cpu=Uc(UC_ARCH_X86,UC_MODE_32);cpu.mem_map(0,len(memory));cpu.mem_write(0,memory)
    cpu.mem_write(ENTRY,body)
    arrays={}
    for name,length in [('actor_kind',501),('actor_recovery_counter',501),('actor_health',1002),
                        ('actor_sprite',1002),('saved_actor_mode',501),('restored_actor_tiles',9018)]:
        arrays[name]=bytearray(b'\xa5'*length)
    arrays['actor_kind'][ACTOR]=c['kind'];arrays['actor_recovery_counter'][ACTOR]=c['counter']
    arrays['actor_health'][ACTOR*2:ACTOR*2+2]=pack('<h',c['health'])
    arrays['actor_sprite'][ACTOR*2:ACTOR*2+2]=pack('<h',SLOT)
    arrays['saved_actor_mode'][ACTOR]=c['mode']
    arrays['restored_actor_tiles'][ACTOR*18:ACTOR*18+2]=pack('<H',c['tile'])
    for name,data in arrays.items():cpu.mem_write(addr(name),bytes(data))
    sprites=bytearray(b'\xc9'*(16*44))
    row=memoryview(sprites)[SLOT*44:(SLOT+1)*44]
    row[:12]=pack('<iii',c['x'],c['y'],-9988);row[12:14]=pack('<H',0x4321)
    row[18]=c['repeat'];row[24:26]=pack('<h',SECTOR)
    cpu.mem_write(addr('sprite'),bytes(sprites))
    cpu.mem_write(addr('sector_floor_z')+SECTOR*40,pack('<i',c['floor']))
    for name,value,fmt in [('advance_clock',c['clock'],'h'),
        ('alternate_fire_requested',c['alternate'],'h'),('player_x',c['px'],'i'),
        ('player_y',c['py'],'i'),('player_angle',c['player_angle'],'h'),
        ('rotate_player_input_word',s16(c['input']),'h')]:
        cpu.mem_write(addr(name),pack('<'+fmt,value))
    calls=[]; ri=0
    def ret(engine):
        sp=engine.reg_read(UC_X86_REG_ESP)
        target,=unpack('<I',engine.mem_read(sp,4))
        engine.reg_write(UC_X86_REG_ESP,sp+4);engine.reg_write(UC_X86_REG_EIP,target)
    def hook(engine,address,size,data):
        nonlocal ri
        eax=engine.reg_read(UC_X86_REG_EAX);edx=engine.reg_read(UC_X86_REG_EDX)
        if address==FUNCS['ksqrt_']:
            calls.append(('sqrt',eax));result=isqrt(eax)
        elif address==FUNCS['getangle_']:
            calls.append(('angle',eax,edx));result=0x5a5a0000|(c['angle']&65535)
            # The real helper clobbers EDX; catch callers that keep stale DY there.
            engine.reg_write(UC_X86_REG_EDX,0xd4d4d4d4)
        elif address==FUNCS['absolute_int_']:
            calls.append(('abs',eax));result=abs(s32(eax))
        elif address==FUNCS['random_value_']:
            result=u32(c['random'][ri%len(c['random'])]);ri+=1
            calls.append(('random',s32(result)))
        elif address==FUNCS['start_sequence_']:
            calls.append(('sequence',eax));result=0x94949494
        else:
            calls.append(('sound',eax,edx,engine.reg_read(UC_X86_REG_EBX),
                          engine.reg_read(UC_X86_REG_ECX)))
            # Conservative scratch sound ABI: only ESI/EDI/EBP are preserved.
            for register,value in [(UC_X86_REG_EBX,0xb1b1b1b1),(UC_X86_REG_ECX,0xc2c2c2c2),
                                   (UC_X86_REG_EDX,0xd3d3d3d3)]:
                engine.reg_write(register,value)
            result=0x92929292
        engine.reg_write(UC_X86_REG_EAX,u32(result));ret(engine)
    for name in ['ksqrt_','getangle_','absolute_int_','random_value_','start_sequence_','play_sound_']:
        address=FUNCS[name];cpu.hook_add(UC_HOOK_CODE,hook,begin=address,end=address)
    for step in range(c['steps']):
        cpu.mem_write(STACK-128,b'\x17'*128)
        cpu.mem_write(STACK,pack('<I',STOP)+b'\x83'*32)
        saved={register:0x16340000+register for register in SAVED}
        for register,value in saved.items():cpu.reg_write(register,value)
        cpu.reg_write(UC_X86_REG_EAX,0xafe50000|ACTOR)
        cpu.reg_write(UC_X86_REG_ESP,STACK)
        cpu.emu_start(ENTRY,STOP,count=4000)
        assert cpu.reg_read(UC_X86_REG_EIP)==STOP
        assert cpu.reg_read(UC_X86_REG_ESP)==STACK+4
        assert all(cpu.reg_read(r)==v for r,v in saved.items()),'saved-register ABI'
        assert cpu.mem_read(STACK+4,32)==b'\x83'*32,'caller stack'
        assert cpu.mem_read(STACK-128,32)==b'\x17'*32,'frame guard'
    state,expected=oracle(c)
    assert calls==expected,(calls,expected)
    arrays['actor_kind'][ACTOR]=state['kind']
    arrays['actor_recovery_counter'][ACTOR]=state['counter']
    arrays['actor_health'][ACTOR*2:ACTOR*2+2]=pack('<h',state['health'])
    for name,data in arrays.items():assert cpu.mem_read(addr(name),len(data))==data, name
    row[8:12]=pack('<i',state['z']);row[12:14]=pack('<H',state['cstat']);row[18]=state['repeat']
    assert cpu.mem_read(addr('sprite'),len(sprites))==sprites,'sprite fields and neighbors'

def cases():
    base=dict(kind=0,counter=0,health=500,repeat=64,clock=0,alternate=0,x=100,y=-200,
              px=100,py=-200,angle=0,player_angle=0,input=0,mode=0,tile=0x966,
              random=[3,5],floor=123456789,steps=1)
    out=[]
    def add(**kwargs):out.append(dict(base,**kwargs))
    for kind in (0,3,4,5):
        for counter in (0,1,6,7,255):
            for clock in (0,1):add(kind=kind,counter=counter,clock=clock)
    for health in (0,-1,-32768):
        for repeat in (0,127,128,255):add(health=health,repeat=repeat)
    for distance in (0,349,350,351,65536,0x7fffffff):
        add(alternate=1,x=s32(100+distance),input=0x2000)
    for dx,dy in ((0,349),(0,-349),(0,350),(0,-350),(-349,0),(-100,-200),
                  (210,280),(-210,-280),(209,280),(-209,-280),
                  (-0x80000000,1),(0x7fffffff,-0x80000000)):
        add(alternate=1,x=s32(100+dx),y=s32(-200+dy),input=0x4000)
    add(kind=4,clock=1,steps=8)
    add(alternate=1,input=0x4000,health=5000,clock=1,steps=8)
    for angle in (119,120,1024,1025,1927,1928,2047,-1,-32768,32767):
        for player_angle in (0,32767,-32768):
            add(alternate=1,angle=angle,player_angle=player_angle,input=0x2000,random=[-1])
    for input_word in (0x1fff,0x2000,0x4000,0x8000,0xffff):
        for random in (0,2,3,-1):
            for mode in (0,2):add(alternate=1,input=input_word,random=[random,-3],mode=mode)
    for kind in (4,5):
        for tile in (0,0x965,0x966,0x967,0x9b7,0x9b8,0x9b9,0xa01,0xa02,0xa03,0xa70,0xa71,0xffff):
            for random in (-0x80000000,-3,0,3,0x7fffffff):add(kind=kind,tile=tile,random=[random])
    add(alternate=1,input=0x2000,health=1,clock=1,steps=3)
    add(alternate=1,input=0,health=1,random=[3,-1],clock=1,steps=3)
    return out

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('executable', type=Path)
    p.add_argument('object', type=Path)
    a = p.parse_args()
    exe = a.executable.read_bytes()
    if hashlib.sha256(exe).hexdigest() != TARGET_SHA256:
        p.error('Executable is not the pinned FATE target')
    mem = image(exe)
    raw_reference = exe[RAW:RAW + SIZE]
    if len(raw_reference) != SIZE:
        raise ValueError('Pinned actor-common raw span must be 697 bytes')
    reference = bytes(mem[ENTRY:ENTRY + SIZE])
    if len(reference) != SIZE:
        raise ValueError('Loaded actor-common span must be 697 bytes')
    pointers = read_le_fixups(exe)['pointers']
    original_fixups = pointer_range(pointers, ENTRY, SIZE)
    if len(original_fixups) != EXPECTED_LE_SITES:
        raise ValueError(f'Expected {EXPECTED_LE_SITES} original LE sites, got {len(original_fixups)}')
    code_bindings = {}
    raw_body, bindings = bind_leaf_details(
        a.object.read_bytes(), 'update_actor_common_', DATA, address=ENTRY,
        functions=FUNCS, code_bindings=code_bindings)
    if len(raw_body) != SIZE or raw_body != raw_reference:
        raise ValueError('Candidate actor-common raw bytes differ from the pinned 697-byte reference')
    verify_leaf_relocations(raw_body, bindings, pointers, ENTRY,
                            code_bindings=code_bindings)
    body, _ = bind_leaf_details(
        a.object.read_bytes(), 'update_actor_common_',
        {key: DS + offset for key, offset in DATA.items()}, address=ENTRY,
        functions=FUNCS)
    if body != reference:
        raise ValueError('Relocated actor-common bytes differ from the loaded reference')
    group = cases()
    if len(group) != 274:
        raise ValueError(f'Behavior fixture case count changed: expected 274, got {len(group)}')
    for label, code in [('original', reference), ('restored', body)]:
        for n, case in enumerate(group):
            try:
                exercise(mem, code, case)
            except Exception as error:
                raise AssertionError((label, n, case, error)) from error
    print(f'PASS: {SIZE} exact bytes, {EXPECTED_LE_SITES} verified LE sites, '
          f'{len(group)} original and {len(group)} restored actor cases')


if __name__ == '__main__':
    main()

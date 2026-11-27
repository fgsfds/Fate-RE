"""Differential dispatcher behavior against the pinned independent binary."""
from pathlib import Path
import argparse,hashlib,json,itertools
from le_fixups import pointer_range,read_le_fixups
from verify_c_leaf import verify_leaf_relocations
from struct import pack,unpack
from unicorn import Uc,UC_ARCH_X86,UC_MODE_32,UC_HOOK_CODE
from unicorn.x86_const import *
from check_start_hook import image,DS
from compare_exe import TARGET_SHA256
from verify_c_leaf import DATA_OFFSETS,FUNCTION_ADDRESSES,bind_leaf_details
ENTRY=0x14610;RAW=0x39c10;SIZE=647;EXPECTED_LE_SITES=31;STACK=0x3ff000;STOP=0x3fff00
DATA=DATA_OFFSETS
FUNCS=FUNCTION_ADDRESSES
ALIASES={key[1:]:value for key,value in DATA.items() if key.startswith('_')}
CALLS={v:k[:-1] for k,v in FUNCS.items() if k.startswith('profile_') or k=='update_actor_common_'}
REGS=(UC_X86_REG_EAX,UC_X86_REG_EDX,UC_X86_REG_EBX,UC_X86_REG_ECX)
SAVED=(UC_X86_REG_ESI,UC_X86_REG_EDI,UC_X86_REG_EBP)

def exercise(memory,body,c):
    slot,mode,prev,profile,kind,defer,mutate=c
    cpu=Uc(UC_ARCH_X86,UC_MODE_32);cpu.mem_map(0,len(memory));cpu.mem_write(0,memory);cpu.mem_write(ENTRY,body)
    def put(name,fmt,v,off=0):cpu.mem_write(DS+ALIASES[name]+off,pack('<'+fmt,v))
    for name,v in [('actor_mode',mode),('previous_mode',prev),('actor_profile',profile),('actor_kind',kind),('actor_state_byte',0xa7),('actor_delay_byte',0xb8),('actor_recovery_counter',0xc9),('actor_sequence_initial',0xda)]:put(name,'B',v,slot)
    put('defer_mode_change','h',defer);put('actor_sprite_index','h',7,slot*2)
    put('sprite_x','i',123456,7*44);put('sprite_y','i',-345678,7*44);put('sprite_sector','h',17,7*44);put('sprite_tile','h',-81,7*44)
    put('actor_x','i',-9,slot*4);put('actor_y','i',-10,slot*4);put('actor_sector','h',-11,slot*2)
    for i in range(9):put('actor_tiles','h',(-1 if i%2 else 1)*(1200+i),slot*18+i*2)
    trace=[]
    def hook(engine,addr,size,data):
        name=CALLS.get(addr)
        if name is None:return
        sp=engine.reg_read(UC_X86_REG_ESP)
        args=tuple(engine.reg_read(r) for r in REGS)
        if name=='update_actor_common':
            trace.append((name,args[0]))
            if mutate:
                for i in range(1,7):put('actor_tiles','h',-2400-i,slot*18+i*2)
                put('actor_kind','B',3,slot)
            engine.reg_write(UC_X86_REG_EAX,0xfedc1234);pop=0
        else:
            pop=12 if name.endswith('mode_two') else 0
            stack=unpack('<iii',engine.mem_read(sp+4,12)) if pop else ()
            # Non-mode-two callees consume only actor and tile; EBX/ECX are live but not arguments.
            trace.append((name,args if pop else args[:2],stack))
            for r in (REGS if pop else REGS[:2]):engine.reg_write(r,0xabcde123)
        target=unpack('<I',engine.mem_read(sp,4))[0]
        engine.reg_write(UC_X86_REG_ESP,sp+4+pop);engine.reg_write(UC_X86_REG_EIP,target)
    cpu.hook_add(UC_HOOK_CODE,hook)
    for r,v in zip(REGS,(0xabcd0000|slot,0x9876fffe,0x10203040,0xfedcba98)):cpu.reg_write(r,v)
    for i,r in enumerate(SAVED):cpu.reg_write(r,0x45670000+i)
    sentinel=b'\x5a'*16
    cpu.mem_write(STACK,pack('<IIi',STOP,0x789abcde,-123)+sentinel);cpu.reg_write(UC_X86_REG_ESP,STACK)
    cpu.emu_start(ENTRY,STOP,count=1000)
    assert cpu.reg_read(UC_X86_REG_EIP)==STOP
    assert cpu.reg_read(UC_X86_REG_ESP)==STACK+12
    assert bytes(cpu.mem_read(STACK+12,16))==sentinel
    assert all(cpu.reg_read(r)==0x45670000+i for i,r in enumerate(SAVED))
    # Compare all game data, including adjacent sentinel bytes and callee mutations.
    return trace,bytes(cpu.mem_read(DS,len(memory)-DS-0x10000))

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable',type=Path)
    parser.add_argument('object',type=Path)
    args=parser.parse_args()
    exe=args.executable.read_bytes()
    if hashlib.sha256(exe).hexdigest()!=TARGET_SHA256:
        parser.error('Unknown FATE.EXE')
    mem=image(exe);original=bytes(mem[ENTRY:ENTRY+SIZE]);raw_reference=exe[RAW:RAW+SIZE]
    if len(original)!=SIZE or len(raw_reference)!=SIZE:
        raise ValueError('Pinned actor-dispatch span must be exactly 647 bytes')
    pointers=read_le_fixups(exe)['pointers']
    original_fixups=pointer_range(pointers,ENTRY,SIZE)
    if len(original_fixups)!=EXPECTED_LE_SITES:
        raise ValueError(f'Expected {EXPECTED_LE_SITES} original LE sites, got {len(original_fixups)}')
    code_bindings={}
    raw_body,bindings=bind_leaf_details(args.object.read_bytes(),'dispatch_actor_update_',DATA,
        address=ENTRY,functions=FUNCS,code_bindings=code_bindings)
    if len(raw_body)!=SIZE or raw_body!=raw_reference:
        raise ValueError('Candidate actor-dispatch raw bytes differ from the pinned 647-byte reference')
    verify_leaf_relocations(raw_body,bindings,pointers,ENTRY,code_bindings=code_bindings)
    body,_=bind_leaf_details(args.object.read_bytes(),'dispatch_actor_update_',
        {key:DS+offset for key,offset in DATA.items()},address=ENTRY,functions=FUNCS)
    if body!=original:
        raise ValueError('Relocated actor-dispatch bytes differ from the loaded reference')
    cases=[]
    for mode,profile,kind,defer,mutate in itertools.product(range(7),range(4),(0,3,5),(0,1),(False,True)):
        cases.append((3,mode,(mode+1)%7,profile,kind,defer,mutate))
    cases += [(slot,mode,mode,profile,0,0,True) for slot,mode,profile in itertools.product((0,500),range(7),(1,2))]
    cases += [(3,255,255,p,0,0,False) for p in (0,1,2,255)]
    for i,c in enumerate(cases):
        a=exercise(mem,original,c);b=exercise(mem,body,c)
        assert a==b,(i,c,a[0],b[0],'memory_equal',a[1]==b[1])
    print(json.dumps({'bytes':SIZE,'le_sites':len(original_fixups),'cases':len(cases),'original_and_candidate':'passed'}))
if __name__=='__main__':main()


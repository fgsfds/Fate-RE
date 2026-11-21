"""Exercise the rebuilt DOS child-environment builder with heap calls stubbed."""
import argparse
from pathlib import Path
from struct import pack, unpack
from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX, UC_X86_REG_EIP,
    UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP, UC_X86_REG_ESP, UC_X86_REG_DS,
    UC_X86_REG_ES, UC_X86_REG_SS, UC_X86_REG_GDTR,
)
from check_start_hook import DS, image
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES

ARGV, ENVP, DEFAULT, OUT, HEAP = 0x390000,0x390100,0x390200,0x390300,0x391000
STACK, STOP = 0x3ff000,0x3fff00
ENTRY = LEAVES['build_child_environment_'][0] - 0x25600

def check(memory, argv, env, *, includes_name=False, fail=0, error=None, fallback=()):
    cpu = Uc(UC_ARCH_X86,UC_MODE_32)
    cpu.mem_map(0,len(memory))
    cpu.mem_write(0,memory)
    cpu.mem_write(0x1000,pack('<QQQ',0,0x00cf9a000000ffff,0x00cf92000000ffff))
    cpu.reg_write(UC_X86_REG_GDTR,(0,0x1000,23,0))
    for reg in (UC_X86_REG_DS,UC_X86_REG_ES,UC_X86_REG_SS):
        cpu.reg_write(reg,0x10)

    def vector(base, entries):
        if entries is None:
            return 0
        addresses = []
        for i,value in enumerate(entries):
            address = 0x39f000+(base-0x390000)*16+0x100*i
            addresses.append(address)
            cpu.mem_write(address,value+b'\0')
        cpu.mem_write(base,pack('<'+'I'*(len(addresses)+1),*addresses,0))
        return base

    env_ptr = vector(ENVP,env)
    vector(ARGV,argv)
    fallback_ptr = vector(DEFAULT,fallback)
    unit = DS+DATA_OFFSETS['_minimum_heap_growth']
    cpu.mem_write(DS+DATA_OFFSETS['_environment_vector'],pack('<I',fallback_ptr))
    cpu.mem_write(unit,pack('<I',0x400))
    cpu.mem_write(OUT,b'\xa5'*16)
    cpu.mem_write(HEAP,b'\xa5'*512)
    cpu.mem_write(STACK,pack('<IIII',STOP,OUT+8,OUT+12,includes_name))
    seen = []
    stubs = {FUNCTION_ADDRESSES[name+'_']:name for name in ('malloc','free','set_errno','set_runtime_error')}
    for address in stubs:
        cpu.mem_write(address,b'\xc3')

    strings = env if env is not None else fallback or ()
    expected = b''.join(value+b'\0' for value in strings)+b'\0'
    if includes_name:
        expected += b'\xa5\xa5'+argv[0]+b'\0'
    allocations = []

    def visit(cpu,address,size,context):
        name = stubs.get(address)
        if not name:
            return
        value = cpu.reg_read(UC_X86_REG_EAX)
        seen.append((name,value))
        if name == 'malloc':
            assert value == len(expected)+15
            assert unpack('<I',cpu.mem_read(unit,4))[0] == 16
            allocations.append(value)
            cpu.reg_write(UC_X86_REG_EAX, HEAP if len(allocations)>fail else 0)

    cpu.hook_add(UC_HOOK_CODE,visit)
    for reg,val in ((UC_X86_REG_EAX,ARGV),(UC_X86_REG_EDX,env_ptr),(UC_X86_REG_EBX,OUT),
                    (UC_X86_REG_ECX,OUT+4),(UC_X86_REG_ESP,STACK)):
        cpu.reg_write(reg,val)
    preserved = (UC_X86_REG_ESI,UC_X86_REG_EDI,UC_X86_REG_EBP)
    for reg in preserved:
        cpu.reg_write(reg,0x12300000+reg)
    cpu.emu_start(ENTRY,STOP,count=20000)
    assert cpu.reg_read(UC_X86_REG_EIP)==STOP and cpu.reg_read(UC_X86_REG_ESP)==STACK+16
    assert all(cpu.reg_read(reg)==0x12300000+reg for reg in preserved)
    assert unpack('<I',cpu.mem_read(unit,4))[0] == 0x400

    result = cpu.reg_read(UC_X86_REG_EAX)
    if error == 'allocation':
        assert result == 0xffffffff and cpu.mem_read(OUT,16)==b'\xa5'*16
        assert len(allocations)==2 and seen[-2:]==[('set_errno',5),('set_runtime_error',8)]
    else:
        assert cpu.mem_read(HEAP,len(expected)) == expected
        if error == 'length':
            assert result==0xffffffff and seen[-3:]==[('set_errno',2),('set_runtime_error',10),('free',HEAP)]
        else:
            assert result==(len(expected)+15)//16
            assert unpack('<IIII',cpu.mem_read(OUT,16)) == (HEAP,HEAP,0,144)
            assert len(seen)==len(allocations)==fail+1


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("executable", type=Path)
    memory = image(parser.parse_args().executable.read_bytes())
    check(memory, [b'FATE.EXE'],[])
    check(memory, [b'FATE.EXE',b'-SETUP'],[b'LANG=EN',b'PATH=C:\\DOS'])
    check(memory, [b'FATE.EXE'],None,fallback=[b'PATH=D:\\GAMES'],includes_name=True)
    check(memory, [b'FATE.EXE'],None,fallback=None)
    check(memory, [b'FATE.EXE'],[],fail=1)
    check(memory, [b'FATE.EXE'],[],fail=2,error='allocation')
    check(memory, [b'FATE.EXE',b'x'*126],[])
    check(memory, [b'FATE.EXE',b'x'*125,b'y'],[],error='length')
    print('PASS: eight DOS child environment and command-tail cases')

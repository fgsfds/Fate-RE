"""Check DOS PATH retries with process launches and error reporting stubbed."""
import argparse
from pathlib import Path
from struct import pack, unpack
from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX, UC_X86_REG_EIP,
    UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP, UC_X86_REG_ESP, UC_X86_REG_DS,
    UC_X86_REG_ES, UC_X86_REG_SS, UC_X86_REG_GDTR,
)
from check_start_hook import image
from verify_c_leaf import FUNCTION_ADDRESSES

PROGRAM, ENV, ERRNO, ARGV, ENVP = 0x390000,0x390100,0x390200,0x390204,0x390208
STACK, STOP = 0x3ff000,0x3fff00

def check(memory, program, path, statuses, attempts, result, errors=()):
    cpu = Uc(UC_ARCH_X86,UC_MODE_32)
    cpu.mem_map(0,len(memory))
    cpu.mem_write(0,memory)
    cpu.mem_write(0x1000,pack('<QQQ',0,0x00cf9a000000ffff,0x00cf92000000ffff))
    cpu.reg_write(UC_X86_REG_GDTR,(0,0x1000,23,0))
    for reg in (UC_X86_REG_DS,UC_X86_REG_ES,UC_X86_REG_SS):
        cpu.reg_write(reg,0x10)
    cpu.mem_write(PROGRAM,program+b'\0')
    if path is not None:
        cpu.mem_write(ENV,path+b'\0')
    cpu.mem_write(STACK,pack('<I',STOP))
    called, translated = [], []
    pending = iter(statuses)
    stubs = {FUNCTION_ADDRESSES[name+'_']:name for name in ('spawnve','getenv','get_errno_address','set_errno','set_runtime_error','check_stack')}
    for address,name in stubs.items():
        cpu.mem_write(address,b'\xc2\x04\0' if name == 'check_stack' else b'\xc3')

    def visit(cpu,address,size,context):
        name = stubs.get(address)
        if name == 'spawnve':
            assert cpu.reg_read(UC_X86_REG_EAX)==1
            assert cpu.reg_read(UC_X86_REG_EBX)==ARGV and cpu.reg_read(UC_X86_REG_ECX)==ENVP
            pointer = cpu.reg_read(UC_X86_REG_EDX)
            called.append(bytes(cpu.mem_read(pointer,256)).split(b'\0')[0])
            status,errno = next(pending)
            cpu.reg_write(UC_X86_REG_EAX,status & 0xffffffff)
            cpu.mem_write(ERRNO,pack('<I',errno))
        elif name == 'getenv':
            pointer = cpu.reg_read(UC_X86_REG_EAX)
            assert cpu.mem_read(pointer,5)==b'PATH\0'
            cpu.reg_write(UC_X86_REG_EAX,ENV if path is not None else 0)
        elif name == 'get_errno_address':
            cpu.reg_write(UC_X86_REG_EAX,ERRNO)
        elif name in ('set_errno','set_runtime_error'):
            translated.append((name,cpu.reg_read(UC_X86_REG_EAX)))

    cpu.hook_add(UC_HOOK_CODE,visit)
    for reg,value in ((UC_X86_REG_EAX,1),(UC_X86_REG_EDX,PROGRAM),(UC_X86_REG_EBX,ARGV),
                      (UC_X86_REG_ECX,ENVP),(UC_X86_REG_ESP,STACK)):
        cpu.reg_write(reg,value)
    preserved = (UC_X86_REG_ESI,UC_X86_REG_EDI,UC_X86_REG_EBP)
    for reg in preserved:
        cpu.reg_write(reg,0x12300000+reg)
    cpu.emu_start(FUNCTION_ADDRESSES['search_and_spawn_'],STOP,count=20000)
    assert cpu.reg_read(UC_X86_REG_EIP)==STOP and cpu.reg_read(UC_X86_REG_ESP)==STACK+4
    assert all(cpu.reg_read(reg)==0x12300000+reg for reg in preserved)
    assert called==attempts and cpu.reg_read(UC_X86_REG_EAX)==result & 0xffffffff
    assert translated==list(errors) and next(pending,None) is None


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("executable", type=Path)
    memory = image(parser.parse_args().executable.read_bytes())
    check(memory, b'fate.exe',None,[(3,0)],[b'fate.exe'],3)
    check(memory, b'fate.exe',None,[(-1,1)],[b'fate.exe'],-1)
    check(memory, b'fate.exe',b'', [(-1,1)],[b'fate.exe'],-1)
    check(memory, b'\\fate.exe',b'C:\\DOS', [(-1,1)],[b'\\fate.exe'],-1)
    check(memory, b'C:fate.exe',b'C:\\DOS', [(-1,1)],[b'C:fate.exe'],-1)
    check(memory, b'fate.exe',b'C:\\DOS;D:\\GAME\\',[(-1,1),(-1,1),(42,0)],
          [b'fate.exe',b'C:\\DOS\\fate.exe',b'D:\\GAME\\fate.exe'],42)
    check(memory, b'fate.exe',b'C:\\DOS;D:\\GAME',[(-1,1),(-1,5)],[b'fate.exe',b'C:\\DOS\\fate.exe'],-1)
    check(memory, b'fate.exe',b'x'*147,[(-1,1)],[b'fate.exe'],-1,(('set_errno',2),('set_runtime_error',10)))
    max_prefix = b'x' * 134 + b'\\'
    check(memory, b'fate.exe', max_prefix, [(-1, 1), (0, 0)],
          [b'fate.exe', max_prefix + b'fate.exe'], 0)
    check(memory, b'fate.exe', b'x' + max_prefix, [(-1, 1)],
          [b'fate.exe'], -1, (('set_errno', 2), ('set_runtime_error', 10)))
    print('PASS: ten DOS PATH search scenarios')

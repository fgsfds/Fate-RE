"""Check the rebuilt printf driver with a recording writer."""
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
from verify_c_leaf import CODE_OFFSETS, FUNCTION_ADDRESSES

PATTERN, PAYLOAD, CURSOR, ARGS, COUNT = 0x390000,0x390100,0x390200,0x390300,0x390400
STACK, STOP, CALLBACK = 0x3ff000,0x3fff00,0x3fff10
CONVERT = FUNCTION_ADDRESSES['convert_format_value_']

def check(memory, pattern, expected, *, converted=None, args=b'', stores=(), payload=b''):
    cpu = Uc(UC_ARCH_X86,UC_MODE_32)
    cpu.mem_map(0,len(memory))
    cpu.mem_write(0,memory)
    cpu.mem_write(0x1000,pack('<QQQ',0,0x00cf9a000000ffff,0x00cf92000000ffff))
    cpu.reg_write(UC_X86_REG_GDTR,(0,0x1000,23,0))
    for reg in (UC_X86_REG_DS,UC_X86_REG_ES,UC_X86_REG_SS):
        cpu.reg_write(reg,0x10)
    for offset,data in ((PATTERN,pattern+b'\0'),(CURSOR,pack('<I',ARGS)),(ARGS,args),
                        (COUNT,b'\xa5'*32),(STACK,pack('<I',STOP)),(CALLBACK,b'\xc3'),(PAYLOAD,payload)):
        if data:
            cpu.mem_write(offset,data)
    output = bytearray()
    if converted is not None:
        cpu.mem_write(CONVERT, b'\xc3')
    else:
        # The DOS code segment starts at 0x10000. Mirror its radix tables
        # at the CS-relative offsets used by this flat emulator fixture.
        for symbol in ('_format_digits', '_integer_digits'):
            offset = CODE_OFFSETS[symbol]
            start = offset + 0x10000
            cpu.mem_write(offset, memory[start:start + 37])
    conversions = iter(converted or ())

    def dword(address):
        return unpack('<I',cpu.mem_read(address,4))[0]

    def visit(cpu,address,size,context):
        if address == CALLBACK:
            state = cpu.reg_read(UC_X86_REG_EAX)
            output.append(cpu.reg_read(UC_X86_REG_EDX))
            cpu.mem_write(state+16,pack('<I',dword(state+16)+1))
        if address == CONVERT and converted is not None:
            state = cpu.reg_read(UC_X86_REG_EBX)
            kind = cpu.mem_read(state+21,1)
            want,text,prefix,zeros = next(conversions)
            assert kind==want
            length = len(text)//2 if want==b's' and cpu.mem_read(state+20,1)[0]&0x20 else len(text)
            spaced = max(0,dword(state+4)-length-len(prefix)-zeros)
            cpu.mem_write(state+4,pack('<III',spaced,length,zeros))
            cpu.mem_write(state+23,prefix+b'\0')
            cpu.mem_write(PAYLOAD,text+b'\0')
            cpu.reg_write(UC_X86_REG_EAX,PAYLOAD)
            cpu.reg_write(UC_X86_REG_EDX,0x10)

    cpu.hook_add(UC_HOOK_CODE,visit)
    for reg,val in ((UC_X86_REG_EAX,0x39a000),(UC_X86_REG_EDX,PATTERN),(UC_X86_REG_EBX,CURSOR),
                    (UC_X86_REG_ECX,CALLBACK),(UC_X86_REG_ESP,STACK)):
        cpu.reg_write(reg,val)
    preserved = (UC_X86_REG_ESI,UC_X86_REG_EDI,UC_X86_REG_EBP)
    for reg in preserved:
        cpu.reg_write(reg,0x12300000+reg)
    cpu.emu_start(FUNCTION_ADDRESSES['format_engine_'],STOP,count=20000)
    assert cpu.reg_read(UC_X86_REG_EIP)==STOP and cpu.reg_read(UC_X86_REG_ESP)==STACK+4
    assert cpu.reg_read(UC_X86_REG_ES)==0x10 and all(cpu.reg_read(r)==0x12300000+r for r in preserved)
    assert bytes(output)==expected and cpu.reg_read(UC_X86_REG_EAX)==len(expected),(pattern,output)
    assert next(conversions,None) is None
    assert dword(CURSOR)==ARGS+len(args)
    for offset,value in stores:
        assert cpu.mem_read(COUNT+offset,len(value))==value


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("executable", type=Path)
    memory = image(parser.parse_args().executable.read_bytes())
    check(memory, b'',b'')
    check(memory, b'Fate DOS',b'Fate DOS')
    check(memory, b'hi%',b'hi')
    check(memory, b'%%!',b'%!',converted=((b'%',b'%',b'',0),))
    check(memory, b'%6d',b'    42',converted=((b'd',b'42',b'',0),))
    check(memory, b'%+08d',b'+0000042',converted=((b'd',b'42',b'+',0),))
    check(memory, b'%#8.4x',b'  0x002a',converted=((b'x',b'2a',b'0x',2),))
    check(memory, b'%-7s',b'hi     ',converted=((b's',b'hi',b'',0),))
    check(memory, b'%ws',b'ab',converted=((b's',b'a\0b\0',b'',0),))
    check(memory, b'abc%hn|%Fn|%ln|%Nn!',b'abc|||!',
          args=pack('<IIIII',COUNT,COUNT+4,0x10,COUNT+8,COUNT+12),
          stores=((0,pack('<H',3)+b'\xa5\xa5'),(4,pack('<III',4,5,6))))
    check(memory, b'%08d', b'-0000042', args=pack('<i', -42))
    check(memory, b'%*.*d', b'0042    ', args=pack('<iii', -8, 4, 42))
    check(memory, b'%*.*d', b'    42', args=pack('<iii', 6, -1, 42))
    check(memory, b'%#.5X', b'0X00ABC', args=pack('<I', 0xabc))
    check(memory, b'%o/%u', b'77/63', args=pack('<II', 63, 63))
    check(memory, b'%hd/%hu', b'-123/65413', args=pack('<II', 0xdeadff85, 0xdeadff85))
    check(memory, b'[%.0u]', b'[]', args=pack('<I', 0))
    check(memory, b'%8.3s', b'     Fat', args=pack('<I', PAYLOAD), payload=b'Fate\0')
    check(memory, b'%Fs', b'Fate', args=pack('<II', PAYLOAD, 0x10), payload=b'Fate\0')
    check(memory, b'%FP', b'0010:000ABCDE', args=pack('<II', 0xabcde, 0x10))
    check(memory, b'%hf', b'1.5000', args=pack('<I', 0x18000))
    check(memory, b'%.2hf', b'2.00', args=pack('<I', 0x1ffff))
    check(memory, b'%.3hf', b'-1.500', args=pack('<i', -0x18000))
    check(memory, b'%c%?', b'Z?', args=pack('<I', ord('Z')))
    print('PASS: 24 printf output, conversion, and %n scenarios')

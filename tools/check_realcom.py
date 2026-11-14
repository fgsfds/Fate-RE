"""Exact initialized handler payload and emulated 16-bit UART IRQ behavior."""
import argparse
import hashlib
import json
from pathlib import Path
import struct
from unicorn import Uc,UC_ARCH_X86,UC_MODE_16,UC_HOOK_INSN,UC_HOOK_CODE
from unicorn.x86_const import *
from compare_exe import TARGET_SHA256
from le_fixups import read_le_fixups


def verify(exe,payload):
    assert hashlib.sha256(exe).hexdigest()==TARGET_SHA256
    assert len(payload)==384 and payload[:14]==bytes(14) and payload[199:]==bytes(185)
    header=struct.unpack_from('<I',exe,60)[0]
    def field(o):return struct.unpack_from('<I',exe,header+o)[0]
    objects=[struct.unpack_from('<6I',exe,header+field(0x40)+24*i) for i in range(field(0x44))]
    owner,=[o for o in objects if o[1]==0x80000]
    page,within=divmod(0x13ce4,4096);slot=header+field(0x48)+(owner[3]+page-1)*4
    physical=int.from_bytes(exe[slot:slot+3],'big');assert physical and exe[slot+3]==0
    raw=field(0x80)+(physical-1)*4096+within
    assert raw+384<=len(exe) and payload==exe[raw:raw+384]
    assert not any(0x93ce4<=s<0x93e64 for s in read_le_fixups(exe)['pointers'])
    return dict(ds_offset='0x13ce4',raw_offset=hex(raw),initialized_bytes=384,
                state_header_bytes=14,instruction_bytes=185,implicit_zero_tail_bytes=185,
                payload_sha256=hashlib.sha256(payload).hexdigest(),original_le_pointers=0)


def scenario(payload, fifo, resend=0, error=0, receive=None, empty=False, idle=False):
    machine=Uc(UC_ARCH_X86,UC_MODE_16);machine.mem_map(0,0x100000)
    base=0x10000;port=0x3f8;start=16382
    machine.mem_write(base,payload)
    end=start if empty else (start+32)&16383
    machine.mem_write(base,struct.pack('<5H4B',0,start,start,end,port,fifo,error,resend,0x55))
    for i in range(32):machine.mem_write(base+384+16384+((start+i)&16383),bytes([(i*11+7)&255]))
    regs={UC_X86_REG_EAX:0x12345678,UC_X86_REG_EBX:0x3456789a,
          UC_X86_REG_ECX:0x56789abc,UC_X86_REG_EDX:0x789abcde}
    for r,v in regs.items():machine.reg_write(r,v)
    machine.reg_write(UC_X86_REG_CS,0x1000);machine.reg_write(UC_X86_REG_DS,0x2000)
    machine.reg_write(UC_X86_REG_SS,0x9000);machine.reg_write(UC_X86_REG_SP,0xf000)
    machine.mem_write(0x9f000,struct.pack('<3H',0x200,0x1000,0x202))
    machine.reg_write(UC_X86_REG_EFLAGS,2)
    incoming=list(receive or []);iir=([1] if idle else [4 if receive is not None else 2,1])
    writes=[];reads=[]
    def inp(uc,p,size,data):
        assert size==1;reads.append(p)
        if p==port+2:
            assert iir;return iir.pop(0)
        if p==port:
            assert incoming;return incoming.pop(0)
        assert p==port+5;return 1 if incoming else 0
    def out(uc,p,size,value,data):
        assert size==1 and p in (port,0x20);writes.append((p,value))
    def guard(uc,address,size,data):assert base+14<=address<base+199
    machine.hook_add(UC_HOOK_INSN,inp,None,1,0,UC_X86_INS_IN)
    machine.hook_add(UC_HOOK_INSN,out,None,1,0,UC_X86_INS_OUT)
    machine.hook_add(UC_HOOK_CODE,guard)
    machine.emu_start(base+14,base+0x200,count=30000)
    assert machine.reg_read(UC_X86_REG_IP)==0x200 and machine.reg_read(UC_X86_REG_SP)==0xf006
    assert all(machine.reg_read(r)==v for r,v in regs.items())
    assert machine.reg_read(UC_X86_REG_DS)==0x2000 and machine.reg_read(UC_X86_REG_EFLAGS)&0xffff==0x202
    assert writes[-1:]==[(0x20,0x20)] and not iir
    if receive is not None:
        consumed=len(receive) if fifo==16 else 1
        assert len(incoming)==len(receive)-consumed and writes==[(0x20,0x20)]
        assert struct.unpack('<H',machine.mem_read(base+2,2))[0]==(start+consumed)&16383
        for i,value in enumerate(receive[:consumed]):
            assert machine.mem_read(base+384+((start+i)&16383),1)==bytes([value])
    else:
        output=[];q=start;r=resend;e=error
        for i in range(0 if idle else fifo):
            if 1<=r<128:output.append(0x8f if r==1 else 0x83);r-=1
            elif 1<=e<128:output.append(0x55 if e==1 else 0x83);e-=1
            elif q!=end:output.append((((q-start)&16383)*11+7)&255);q=(q+1)&16383
            else:break
        assert writes==[(port,x) for x in output]+[(0x20,0x20)]
        assert machine.mem_read(base+11,2)==bytes([e,r])
        assert struct.unpack('<H',machine.mem_read(base+4,2))[0]==q


def check(payload):
    count=0
    for fifo in (0,1,2,16):
        for resend in (0,1,2,127,128,255):
            for error in (0,1,2,127,128,255):
                for empty in (False,True):
                    scenario(payload,fifo,resend,error,empty=empty);count+=1
    for fifo in (1,16):
        for length in (1,2,16):
            scenario(payload,fifo,receive=[(i*19+3)&255 for i in range(length)]);count+=1
    scenario(payload,16,idle=True);return count+1


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('executable',type=Path)
    p.add_argument('payload',type=Path);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
    payload=a.payload.read_bytes();result=verify(a.executable.read_bytes(),payload)
    result.update(behavior_cases=check(payload),execution_mode='emulated real-mode IRQ with UART/PIC hooks',
                  physical_device_io=False,source_code_coverage_change=0,
                  storage_class='original initialized DATA',final_linked_placement_verified=False)
    a.output.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('PASS: 384 source-generated initialized bytes; '+str(result['behavior_cases'])+' IRQ cases')

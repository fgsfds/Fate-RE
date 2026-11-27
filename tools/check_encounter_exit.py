"""Differential fixture for the frozen encounter exit phase."""
import argparse
import hashlib
import json
import struct
from pathlib import Path

from capstone import Cs, CS_ARCH_X86, CS_MODE_32, x86_const
from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import *
from check_start_hook import DS, image
from compare_exe import TARGET_SHA256
from le_fixups import read_le_fixups
from verify_c_leaf import (DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES,
                           bind_leaf_details, verify_leaf_relocations)
from verify_c_suite import OBJECT_NAMES

SYMBOL = 'level_encounter_exit_'
ENTRY, RAW, SIZE = 0x1e30b, 0x4390b, 261
EPILOGUE = bytes.fromhex('81c4b80000005d5f5e5a595bc3')
EPILOGUE_SHA256 = '5d1adf2f63680fb8ddf16ca1ee796d1772f329e3c52bfdd2dbc81f23f1339322'
DATA_SIZE = 0x360000
STACK, STOP = 0x3fe000, 0x3fff00
SAVED = (UC_X86_REG_EBP, UC_X86_REG_EDI, UC_X86_REG_ESI,
         UC_X86_REG_EDX, UC_X86_REG_ECX, UC_X86_REG_EBX)
# Independent offsets copied from the frozen DATA map, not derived from candidate names.
DATA = {'board4_sector_events': 0x7659c, 'first_trigger_state': 0x127f4,
        'second_trigger_state': 0x127f6, 'exit_scan_initialized': 0x12806,
        'exit_scan_index': 0x851a8, 'encounter_position': 0x729e0,
        'first_actor_state': 0x7e32b, 'first_actor_kind': 0x7f0de,
        'first_actor_mode': 0x7f6bd, 'exit_sequence': 0x12808,
        'second_trigger_sprite': 0x74950}
CALLEES = {'update_actor_common_': 0x14897, 'update_sprite_sequence_state_': 0x10433, 'deletesprite_': 0x50a09}
FUNCTIONS = dict(FUNCTION_ADDRESSES) | CALLEES

def signed16(x): return ((x + 0x8000) & 0xffff) - 0x8000

def cases():
    out=[]
    for latch in (0,1):
      for match in (1,31,32):
       for state in (0,1,2,3,-1):
        for kind,near,active,seq,mode in ((3,0,0,0,1),(1,1,0,0,0),(1,0,1,0,0),(1,0,0,1,0)):
         out.append(dict(latch=latch,match=match,state=state,kind=kind,near=near,active=active,seq=seq,
                         mode=mode,sprite=-1))
    # Keep explicit state and signed sprite edges covered across both transition and deletion paths.
    for state in (0,1,2,3,-1):
      for sprite in (-32768,-1,0,1,32767):
       out.append(dict(latch=1,match=1,state=1,kind=1,near=0,active=0,seq=0,
                       mode=1,actor_state=state,sprite=sprite))
    return out

def read_i(mem, addr, fmt): return struct.unpack('<'+fmt, mem.mem_read(addr, struct.calcsize('<'+fmt)))[0]
def put(mem, addr, fmt, value): mem.mem_write(addr, struct.pack('<'+fmt, value))

def invoke(memory, body, case, incoming, flags):
    cpu=Uc(UC_ARCH_X86,UC_MODE_32); cpu.mem_map(0,len(memory)); cpu.mem_write(0,memory)
    cpu.mem_write(ENTRY,body)
    # Sector ID is the first word; the active flag is the second. Slot32
    # is deliberately observed by the original after an unsuccessful scan.
    for i in range(33):
        put(cpu, DS+DATA['board4_sector_events']+4*i, 'h', 0)
        put(cpu, DS+DATA['board4_sector_events']+4*i+2, 'h', 0)
    if case['match'] != 32:
        put(cpu, DS+DATA['board4_sector_events']+4*case['match'], 'h', 11)
    put(cpu,DS+DATA['board4_sector_events']+4*case['match']+2,'h',case['active'])
    put(cpu,DS+DATA['exit_scan_initialized'],'h',case['latch'])
    put(cpu,DS+DATA['exit_scan_index'],'h',case['match'])
    put(cpu,DS+DATA['first_trigger_state'],'h',case['state'])
    put(cpu,DS+DATA['second_trigger_state'],'h',0)
    put(cpu,DS+DATA['encounter_position'],'h',case['near'])
    put(cpu,DS+DATA['first_actor_kind'],'B',case['kind'])
    put(cpu,DS+DATA['first_actor_state'],'B',case.get('actor_state',case['seq']) & 0xff)
    put(cpu,DS+DATA['first_actor_mode'],'B',case['mode'])
    put(cpu,DS+DATA['exit_sequence'],'I',0x80000+DATA['exit_sequence'])
    put(cpu,DS+DATA['second_trigger_sprite'],'h',case['sprite'])
    calls=[]
    def ret(clean=0):
        sp=cpu.reg_read(UC_X86_REG_ESP); dest=read_i(cpu,sp,'I')
        cpu.reg_write(UC_X86_REG_ESP,sp+4+clean); cpu.reg_write(UC_X86_REG_EIP,dest)
    def hook(e,a,size,_):
        if a not in CALLEES.values(): return
        name=next(n for n,v in CALLEES.items() if v==a)
        if name=='update_actor_common_':
            calls.append((name,e.reg_read(UC_X86_REG_EAX))); e.reg_write(UC_X86_REG_EAX,0x13579bdf); ret()
        elif name=='update_sprite_sequence_state_':
            sp=e.reg_read(UC_X86_REG_ESP)
            args=(read_i(e,sp+4,'I'),read_i(e,sp+8,'I'))
            regs=tuple(e.reg_read(r) for r in (UC_X86_REG_EAX,UC_X86_REG_EDX,UC_X86_REG_EBX,UC_X86_REG_ECX))
            if regs != (62,0x1df4,0x18f8,0x410a) or args != (0x1800,DS+DATA['exit_sequence']):
                raise AssertionError('sequence argument ABI differs')
            calls.append((name,regs,args))
            for r,v in zip((UC_X86_REG_EAX,UC_X86_REG_EDX,UC_X86_REG_EBX,UC_X86_REG_ECX),(0x11111111,0x22222222,0x33333333,0x44444444)):e.reg_write(r,v)
            ret(8)
        else:
            sid=signed16(e.reg_read(UC_X86_REG_EAX)); calls.append((name,sid))
            e.reg_write(UC_X86_REG_EAX,0x2468ace0); ret()
    cpu.hook_add(UC_HOOK_CODE,hook)
    # Stack: 184-byte scratch, six saved registers, then STOP return address.
    cpu.mem_write(STACK,b'\xa7'*184+struct.pack('<6I',*incoming)+struct.pack('<I',STOP)+b'\x5c'*64)
    entry_sp=STACK; cpu.reg_write(UC_X86_REG_ESP,entry_sp)
    for r,v in zip((UC_X86_REG_EAX,UC_X86_REG_EBX,UC_X86_REG_ECX,UC_X86_REG_EDX,UC_X86_REG_ESI,UC_X86_REG_EDI,UC_X86_REG_EBP),incoming+(0xdeadbeef,)):
        cpu.reg_write(r,v)
    cpu.reg_write(UC_X86_REG_EFLAGS,flags)
    try: cpu.emu_start(ENTRY,STOP,count=5000)
    except Exception as e: raise RuntimeError(f'guest fault at {cpu.reg_read(UC_X86_REG_EIP):#x}: {e}') from e
    if cpu.reg_read(UC_X86_REG_EIP)!=STOP: raise AssertionError('phase did not reach STOP')
    if cpu.reg_read(UC_X86_REG_ESP)!=entry_sp+212: raise AssertionError('final ESP is not entry ESP + 212')
    if cpu.mem_read(STACK,184)!=b'\xa7'*184: raise AssertionError('scratch guard changed')
    if cpu.mem_read(entry_sp+184,28)!=struct.pack('<6I',*incoming)+struct.pack('<I',STOP): raise AssertionError('saved registers/return guard changed')
    if cpu.mem_read(entry_sp+212,64)!=b'\x5c'*64: raise AssertionError('caller guard changed')
    preserved=tuple(cpu.reg_read(r) for r in SAVED)
    if preserved!=incoming: raise AssertionError('saved GP registers were not restored')
    return (tuple(calls),bytes(cpu.mem_read(DS,DATA_SIZE)),preserved,cpu.reg_read(UC_X86_REG_ESP))

def boundaries(code):
    ins=tuple(Cs(CS_ARCH_X86,CS_MODE_32).disasm(code,ENTRY))
    if not ins or sum(i.size for i in ins)!=len(code): raise ValueError('phase/epilogue decode incomplete')
    return ins

def validate_epilogue(code):
    if code != EPILOGUE or hashlib.sha256(code).hexdigest() != EPILOGUE_SHA256:
        raise ValueError('original epilogue hash guard failed')


def validate_phase_edges(code):
    decoded = boundaries(code)
    starts = {i.address for i in decoded}
    if ENTRY+SIZE not in starts:
        raise ValueError('phase/epilogue boundary splits instruction')
    reader = Cs(CS_ARCH_X86, CS_MODE_32)
    reader.detail = True
    exits, calls = {}, {}
    for ins in reader.disasm(code, ENTRY):
        if ins.address >= ENTRY+SIZE:
            continue
        if ins.mnemonic.startswith('ret'):
            raise ValueError('unexpected private return in phase')
        if ins.mnemonic.startswith('j') or ins.mnemonic == 'call':
            if len(ins.operands) != 1 or ins.operands[0].type != x86_const.X86_OP_IMM:
                raise ValueError('unexpected indirect phase transfer')
            target = ins.operands[0].imm
            if ins.mnemonic == 'call':
                calls[ins.address] = target
            elif not ENTRY <= target < ENTRY+SIZE:
                exits[ins.address] = target
            elif target not in starts:
                raise ValueError('phase jump splits an instruction')
    expected = (0x1e354,0x1e364,0x1e3a5,0x1e3b0,0x1e3b8,0x1e3ee)
    if exits != dict.fromkeys(expected, ENTRY+SIZE):
        raise ValueError('unexpected phase exit edges')
    if calls != {0x1e3bf:0x14897,0x1e3e2:0x10433,0x1e3fe:0x50a09}:
        raise ValueError('unexpected phase call edges')


def bind(executable,build):
    objname=OBJECT_NAMES[SYMBOL]
    if objname!='encexit': raise ValueError('unexpected exit object registration')
    blob=(build/(objname+'.obj')).read_bytes()
    raw,size=LEAVES[SYMBOL]
    if (raw,size)!=(RAW,SIZE): raise ValueError('frozen exit placement/size changed')
    ref=executable[RAW:RAW+SIZE]
    if len(ref)!=SIZE: raise ValueError('truncated pinned phase')
    original_epilogue=executable[RAW+SIZE:RAW+SIZE+len(EPILOGUE)]
    validate_epilogue(original_epilogue)
    exact,refs=bind_leaf_details(blob,SYMBOL,DATA_OFFSETS,address=ENTRY,functions=FUNCTIONS)
    if len(exact)!=SIZE or exact!=ref: raise ValueError('261-byte original code mismatch')
    pointers=read_le_fixups(executable)['pointers']
    verify_leaf_relocations(exact,refs,pointers,ENTRY)
    loaded,_=bind_leaf_details(blob,SYMBOL,{n:DS+v for n,v in DATA_OFFSETS.items()},address=ENTRY,functions=FUNCTIONS)
    validate_phase_edges(ref+original_epilogue)
    return image(executable)[ENTRY:ENTRY+SIZE+len(EPILOGUE)],loaded+original_epilogue,hashlib.sha256(blob).hexdigest(),len(refs)

def mutate(reference, which):
    code=bytearray(reference)
    if which=='scan':
        ins=next(i for i in boundaries(code) if i.address==0x1e332)
        if ins.mnemonic!='cmp' or ins.op_str!='eax, 0xb': raise ValueError('scan mutation anchor changed')
        code[ins.address-ENTRY+ins.size-1]=12
    else:
        ins=next(i for i in boundaries(code) if i.address==0x1e3f0)
        if ins.mnemonic!='mov' or ins.op_str!='cl, 2': raise ValueError('deletion mutation anchor changed')
        code[ins.address-ENTRY+1]=3
    return bytes(code)

def run(executable,build,output):
    if hashlib.sha256(executable).hexdigest()!=TARGET_SHA256: raise ValueError('unsupported pinned executable')
    memory=image(executable); reference,candidate,objhash,lecount=bind(executable,build)
    suite=cases(); incoming_sets=((0x10203040,0x21314151,0x32425262,0x43536373,0x54647484,0x65758595),(0xfedcba98,0xedcba987,0xdcba9876,0xcba98765,0xba987654,0xa9876543))
    deletion_ids, scan_indices = set(), set()
    for n,c in enumerate(suite):
        inc=incoming_sets[n%2]; flags=(0x202 if n%2 else 0x8d7)
        exp=invoke(memory,reference,c,inc,flags); got=invoke(memory,candidate,c,inc,flags)
        if got!=exp: raise AssertionError(f"{c}: calls/data/preserved state differ")
        deletion_ids.update(call[1] for call in exp[0] if call[0] == 'deletesprite_')
        if c['latch'] == 0:
            index=struct.unpack_from('<h',exp[1],DATA['exit_scan_index'])[0]
            if index != c['match']: raise AssertionError('original scan setup did not exercise intended index')
            scan_indices.add(index)
    if deletion_ids != {-32768,-1,0,1,32767} or scan_indices != {1,31,32}:
        raise AssertionError('required signed deletion/scan paths not exercised')
    controls=[]
    for label,which,case,predicate in (
      ('scan match 1','scan',next(c for c in suite if c['latch']==0 and c['match']==1 and c['state']==0 and c['kind']==3),lambda r:struct.unpack_from('<h',r[1],DATA['exit_scan_index'])[0]==1),
      ('deletion','delete',next(c for c in suite if c['latch']==1 and c['state']==1 and c['kind']==1 and c['near']==0 and c.get('actor_state',c['seq'])==0),lambda r:any(x[0]=='deletesprite_' for x in r[0]))):
        inc=incoming_sets[0]; base=invoke(memory,reference,case,inc,0x202); cand=invoke(memory,candidate,case,inc,0x202)
        if base!=cand or not predicate(base): raise AssertionError(f'{label} control path not exercised')
        mutant=mutate(reference,which)
        if invoke(memory,mutant,case,inc,0x202)==base: raise AssertionError(f'{label} executable mutation escaped')
        controls.append(label)
    result={'status':'PASS','cases':len(suite),'controls':controls,'phase_bytes':SIZE,'LE_sites':lecount,'DS_bytes':DATA_SIZE,'object_sha256':objhash,'epilogue_sha256':EPILOGUE_SHA256,'deletion_ids':sorted(deletion_ids),'scan_indices':sorted(scan_indices)}
    output.parent.mkdir(parents=True,exist_ok=True);output.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');return result

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--exe',required=True,type=Path);p.add_argument('--build',required=True,type=Path);p.add_argument('--output',required=True,type=Path);a=p.parse_args();print(json.dumps(run(a.exe.read_bytes(),a.build,a.output),indent=2))
if __name__=='__main__':main()

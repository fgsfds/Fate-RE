"""Independent stable-memory model of collect_input offsets 411..699.

All arithmetic wraps to 32 bits before signed comparisons. Key indices are
unsigned bytes; toggle/reset require exactly one rather than any nonzero byte.
"""
from dataclasses import dataclass, replace
from random import Random

def u32(value):
    return value & 0xffffffff

def s32(value):
    value = u32(value)
    return value - 0x100000000 if value & 0x80000000 else value

@dataclass(frozen=True)
class Case:
    keys: bytes
    indices: tuple  # strafe, left, right, toggle_word, reset_view
    turn: int
    strafe: int
    step: int
    limit: int
    toggled_word: int
    view: int

def model(case):
    keys = bytearray(case.keys)
    modifier, left, right, toggle, reset = case.indices
    turn, strafe = u32(case.turn), u32(case.strafe)
    word, view = case.toggled_word & 0xffff, u32(case.view)
    writes = []
    if not keys[modifier]:
        if keys[left]:
            turn = u32(max(s32(turn - 48), -128))
            writes.append(('keyboard_turn', 4, turn))
        if keys[right]:
            turn = u32(min(s32(turn + 48), 127))
            writes.append(('keyboard_turn', 4, turn))
    else:
        if keys[left]:
            strafe = u32(min(s32(strafe + 3 * case.step), s32(case.limit)))
            writes.append(('keyboard_strafe', 4, strafe))
        if keys[right]:
            strafe = u32(max(s32(strafe - 3 * case.step), s32(-case.limit)))
            writes.append(('keyboard_strafe', 4, strafe))
    if keys[toggle] == 1:
        keys[toggle] = 0
        word ^= 0xffff
        writes.extend((('key_state', toggle, 0), ('toggled_word', 2, word)))
    if keys[reset] == 1:
        keys[reset] = 0
        view = 100
        writes.extend((('key_state', reset, 0), ('view_adjustment', 4, view)))
    return (bytes(keys), turn, strafe, word, view), tuple(writes)

def cases():
    rng = Random(0x2d6b5)
    boundaries = (0, 1, -1, -177, -176, -129, -128, -127, 79, 80,
                  126, 127, 128, 175, 176, 0x7fffffff, 0x80000000, 0xffffffff)
    base = Case(bytes(256), (240, 241, 242, 243, 244), 0, 0, 1, 127, 0x835a, 0xf1234567)
    for mask in range(32):
        keys = bytearray(256)
        for i, index in enumerate(base.indices):
            keys[index] = 1 if mask & (1 << i) else 0
        for turn in boundaries:
            yield replace(base, keys=bytes(keys), turn=turn)
        for step in boundaries:
            for limit in (127, -128, 0, 0x7fffffff, 0x80000000):
                yield replace(base, keys=bytes(keys), strafe=rng.choice(boundaries), step=step, limit=limit)
    # Alias every pair of configurable indices and include unsigned key values.
    for a in range(5):
        for b in range(a + 1, 5):
            indices = list(base.indices)
            indices[b] = indices[a]
            for value in (0, 1, 2, 128, 255):
                yield replace(base, indices=tuple(indices), keys=bytes([value]) * 256,
                              turn=rng.choice(boundaries), strafe=rng.choice(boundaries),
                              step=rng.choice(boundaries), limit=rng.choice(boundaries))
    # Every byte value is representable as an index, including high-bit indices.
    for index in range(256):
        yield replace(base, indices=(index,) * 5, keys=bytes([1]) * 256)


def main():
    import argparse, hashlib, json
    from pathlib import Path
    from struct import pack
    from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_MEM_WRITE, UC_HOOK_CODE
    from unicorn import x86_const as x
    from compare_exe import TARGET_SHA256
    from check_input_selection import bind_production, validate_layout, relocated, branch, decode
    from bind_input_selection import LAYOUT

    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--exe',type=Path,required=True)
    parser.add_argument('--build',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args();exe=args.exe.read_bytes()
    assert hashlib.sha256(exe).hexdigest()==TARGET_SHA256
    blob,original,placed,private,sites,private_sites=bind_production(exe,args.build)
    rows=validate_layout(LAYOUT,original,private)
    start,begin,end,stack=0x2d51a,411,699,0x200000
    names={n[1:]:0x80000+a for n,a in LAYOUT['DATA'].items()}
    expected_names={'key_strafe':0x13642,'key_left':0x1363f,'key_right':0x13640,
                    'key_toggle_word':0x13653,'key_reset_view':0x13649,
                    'keyboard_turn':0x770ec,'keyboard_strafe':0x770e4,
                    'strafe_step':0x13ba3,'strafe_limit':0x13b9f,
                    'toggled_word':0x203e,'view_adjustment':0x62f8c,'key_state':0x6793c}
    assert all(names[n]==0x80000+a for n,a in expected_names.items()),'motion model bindings'
    general=('eax','ebx','ecx','edx','esi','edi','ebp')
    reg={n:getattr(x,'UC_X86_REG_'+n.upper()) for n in (*general,'esp','eip','eflags')}

    class Replay:
        def __init__(self,code):
            self.cpu=Uc(UC_ARCH_X86,UC_MODE_32);self.cpu.mem_map(0,0x210000)
            self.cpu.mem_write(start,code)
            self.cpu.hook_add(UC_HOOK_MEM_WRITE,self.on_write)
            self.cpu.hook_add(UC_HOOK_CODE,self.on_pc)

        def on_pc(self,cpu,pc,size,user):
            assert start+begin<=pc and pc+size<=start+end,'motion execution extent'
            self.path.append(pc-start)

        def on_write(self,cpu,access,address,size,value,user):
            if names['key_state']<=address<names['key_state']+256:
                assert size==1
                self.writes.append(('key_state',address-names['key_state'],value))
            else:
                field=next(n for n in ('keyboard_turn','keyboard_strafe','toggled_word','view_adjustment') if names[n]==address)
                assert size==(2 if field=='toggled_word' else 4)
                self.writes.append((field,size,value))

        def run(self,case):
            cpu=self.cpu
            cpu.mem_write(names['key_state'],case.keys)
            for n,value in zip(('key_strafe','key_left','key_right','key_toggle_word','key_reset_view'),case.indices):
                cpu.mem_write(names[n],bytes([value]))
            for n,value in zip(('keyboard_turn','keyboard_strafe','strafe_step','strafe_limit','view_adjustment'),(case.turn,case.strafe,case.step,case.limit,case.view)):
                cpu.mem_write(names[n],pack('<I',u32(value)))
            cpu.mem_write(names['toggled_word'],pack('<H',case.toggled_word))
            for i,n in enumerate(general):cpu.reg_write(reg[n],0x81a3b5c7+i)
            cpu.mem_write(stack-64,b'\xa5'*128)
            cpu.reg_write(reg['esp'],stack);cpu.reg_write(reg['eflags'],0xa97)
            self.writes=[];self.path=[];cpu.emu_start(start+begin,start+end,count=150)
            assert cpu.reg_read(reg['eip'])==start+end and cpu.reg_read(reg['esp'])==stack
            assert cpu.mem_read(stack-64,128)==b'\xa5'*128,'motion stack guard'
            for i,n in enumerate(general[4:],4):assert cpu.reg_read(reg[n])==0x81a3b5c7+i,'motion saved register'
            memory=(bytes(cpu.mem_read(names['key_state'],256)),*(int.from_bytes(cpu.mem_read(names[n],s),'little') for n,s in (('keyboard_turn',4),('keyboard_strafe',4),('toggled_word',2),('view_adjustment',4))))
            return (memory,tuple(self.writes)),tuple(cpu.reg_read(reg[n]) for n in general),cpu.reg_read(reg['eflags'])&0x8c5

    orig=Replay(relocated(original,sites));production=Replay(relocated(placed,sites));natural=Replay(relocated(private,private_sites))
    all_cases=list(cases());outcomes={off:set() for off,ins in rows.items() if off>=begin and branch(ins) is not None}
    for case in all_cases:
        expected=orig.run(case)
        assert expected==production.run(case)==natural.run(case),'motion original/placed/private mismatch'
        assert expected[0]==model(case),'motion independent model mismatch'
        for here,next_pc in zip(orig.path,orig.path[1:]+[end]):
            if here in outcomes:
                taken=next_pc==branch(rows[here]);assert taken or next_pc==here+rows[here].size
                outcomes[here].add(taken)
    assert len(all_cases)==3762 and len(outcomes)==12
    assert all(values==({True} if rows[off].mnemonic=='jmp' else {False,True})
               for off,values in outcomes.items()),outcomes

    controls=[]
    def reject(label,code):
        replay=Replay(relocated(bytes(code),sites))
        for case in all_cases:
            try:actual=replay.run(case)
            except (AssertionError,StopIteration):controls.append(label);return
            if actual[0]!=model(case):controls.append(label);return
        raise AssertionError('Motion mutation escaped: '+label)
    from capstone import CS_OP_IMM
    for label,ins,replacement in (
        ('modifier_branch',next(i for off,i in rows.items() if off>=begin and i.mnemonic=='jne'),None),
        ('signed_turn_clamp',next(i for off,i in rows.items() if off>=begin and i.mnemonic=='jg'),0x77),
        ('word_complement',next(i for off,i in rows.items() if off>=begin and i.mnemonic=='not'),None),
        ('reset_view_value',next(i for off,i in rows.items() if off>=begin and i.mnemonic=='mov' and len(i.operands)==2 and i.operands[1].type==CS_OP_IMM and i.operands[1].imm==100),None)):
        code=bytearray(placed)
        if label=='modifier_branch':code[ins.address]^=1
        elif label=='signed_turn_clamp':code[ins.address]=replacement
        elif label=='word_complement':code[ins.address+ins.modrm_offset]^=8
        else:code[ins.address+ins.imm_offset]^=1
        reject(label,code)
    report=dict(status='PASS',new_native_bytes=288,DATA_sites=30,cases=len(all_cases),branches=12,
                branch_outcomes={hex(start+k):sorted(v) for k,v in outcomes.items()},code_controls=controls,
                scope='Stable-memory keyboard motion and toggle/reset only; original, placed and natural private execution from offset411 to699. Ordered writes, complete key array, motion/state, all GPRs and defined flags agree. Stack and ESI/EDI/EBP are preserved. Includes wrap/clamp extremes and index aliasing; no mouse calls, interrupt interleavings or full collect_input claim.')
    args.output.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))

if __name__=='__main__':main()

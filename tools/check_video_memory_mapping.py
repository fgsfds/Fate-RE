"""Exercise the video mapper's three full machine bodies with DPMI service stubs."""

import argparse
from collections import Counter
from dataclasses import dataclass
from hashlib import sha256
import json
from pathlib import Path
from struct import pack, pack_into, unpack

from unicorn import Uc, UcError, UC_ARCH_X86, UC_HOOK_CODE, UC_HOOK_MEM_WRITE, UC_MODE_32
from unicorn import x86_const as x86

import verify_c_leaf as v
from check_ripple_control import rename_external
from check_ripple_stack import mutate_public_byte
from check_start_hook import image
from le_fixups import read_le_fixups


ENTRY, SIZE, RAW_DELTA = 0x43B71, 411, 0x25600
PRIVATE, STACK, STOP = 0x400000, 0x4FF000, 0x4FFF00
FRAME = STACK - 44
DS, DATA_SIZE, MAPPED, GUARD = 0x80000, 0x28A300, 0x286B58, 16
DATA_SELECTOR, OTHER_SELECTOR, DF = 0x10, 0x18, 0x400
PUBLIC, OBJECT = "map_video_memory_", "vmapctx"
ALLOCATE, RIGHTS, MAP, SET_BASE, SET_LIMIT = (0x0000, 0x0009, 0x0800, 0x0007, 0x0008)
SERVICES = (ALLOCATE, RIGHTS, MAP, SET_BASE, SET_LIMIT)
PHYSICALS = (0, 0xA0000, 0x7FFFFFFF, 0x80000000, 0xE0000000, 0xFFFFFFFF)
LINEARS = (0, 0x1234FFFF, 0x7FFFFFFF, 0x80000000, 0xFFFF0000, 0xFFFFFFFF)
SELECTORS = (1, 8, 0xFFFF)
DIAGNOSTICS = {
    ALLOCATE: (0x195F, b"DPMI_allocSelector() failed!\n\0"),
    MAP: (0x197D, b"DPMI_mapPhysicalToLinear() failed!\n\0"),
    SET_BASE: (0x19A1, b"DPMI_setSelectorBase() failed!\n\0"),
    SET_LIMIT: (0x19C1, b"DPMI_setSelectorLimit() failed!\n\0"),
}
INT, PRINT, EXIT = "int386_", "printf_", "runtime_exit_"
TARGETS = {INT: 0x630B3, PRINT: 0x40BB4, EXIT: 0x60353}
CALL_OFFSETS = {
    INT: (0x22, 0x6F, 0xAF, 0x118, 0x169),
    PRINT: (0x39, 0xC6, 0x12F, 0x180),
    EXIT: (0x43, 0xD0, 0x139, 0x18A),
}
BRANCHES = {0x32: 0x48, 0xBF: 0xD5, 0x128: 0x13E, 0x179: 0x18F}
DATA_OFFSETS = {
    "_mapped_video_base": MAPPED,
    "_video_selector_allocation_error": DIAGNOSTICS[ALLOCATE][0],
    "_video_physical_mapping_error": DIAGNOSTICS[MAP][0],
    "_video_selector_base_error": DIAGNOSTICS[SET_BASE][0],
    "_video_selector_limit_error": DIAGNOSTICS[SET_LIMIT][0],
}
GPRS = (x86.UC_X86_REG_EAX, x86.UC_X86_REG_EBX, x86.UC_X86_REG_ECX,
        x86.UC_X86_REG_EDX, x86.UC_X86_REG_ESI, x86.UC_X86_REG_EDI,
        x86.UC_X86_REG_EBP)
EAX, EBX, ECX, EDX, ESI, EDI, EBP = GPRS


@dataclass(frozen=True)
class Program:
    name: str
    entry: int
    code: bytes


@dataclass(frozen=True)
class Case:
    physical: int
    linear: int
    selector: int
    rights_carry: int
    failure: int | None
    seed: int

    def inputs(self, service):
        high_physical, low_physical = divmod(self.physical, 1 << 16)
        high_linear, low_linear = divmod(self.linear, 1 << 16)
        # Register indices in the seven-dword INT386 record.
        return {
            ALLOCATE: {0: ALLOCATE, 2: 1},
            RIGHTS: {0: RIGHTS, 1: self.selector, 2: 0x8092},
            MAP: {0: MAP, 1: high_physical, 2: low_physical, 4: 0x003F, 5: 0xFFFF},
            SET_BASE: {0: SET_BASE, 1: self.selector, 2: high_linear, 3: low_linear},
            SET_LIMIT: {0: SET_LIMIT, 1: self.selector, 2: 0x003F, 3: 0xFFFF},
        }[service]

    def output(self, service):
        step = SERVICES.index(service)
        values = [0xA0108301 + self.seed * 0x08401100 + step * 0x00130205
                  + index * 0x0211070B for index in range(6)]
        if service == ALLOCATE:
            values[0] = (values[0] & 0xFFFF0000) | self.selector
        if service == MAP:
            high, low = divmod(self.linear, 1 << 16)
            values[1] = (values[1] & 0xFFFF0000) | high
            values[2] = (values[2] & 0xFFFF0000) | low
        carry = self.rights_carry if service == RIGHTS else int(service == self.failure)
        return pack("<7I", *values, carry)


def pattern(size, seed):
    period = bytes((seed + index * 73) & 0xFF for index in range(256))
    return (period * ((size + 255) // 256))[:size]


def check_control_flow(program):
    assert len(program.code) == SIZE
    for name, sites in CALL_OFFSETS.items():
        for offset in sites:
            assert program.code[offset] == 0xE8, (program.name, hex(offset))
            relative = unpack("<i", program.code[offset + 1:offset + 5])[0]
            assert program.entry + offset + 5 + relative == TARGETS[name]
    for offset, target in BRANCHES.items():
        assert program.code[offset] == 0x74
        displacement = unpack("<b", program.code[offset + 1:offset + 2])[0]
        assert offset + 2 + displacement == target


def bind_private(blob, data):
    alias = "map_video_memory_fixture_private_"
    assert alias not in v.LEAF_CODE_SLICES
    v.LEAF_CODE_SLICES[alias] = (PUBLIC, 0, SIZE, SIZE)
    branches = v.LEAF_SECTION_BRANCHES.pop(PUBLIC)
    try:
        code_refs = {}
        code, refs = v.bind_leaf_details(
            blob, alias, data, address=PRIVATE, functions=v.FUNCTION_ADDRESSES,
            absolute_code=v.CODE_OFFSETS, code_bindings=code_refs,
        )
        assert len(refs) == 6 and not code_refs
        for site, value in refs.items():
            assert code[site:site + 4] == pack("<I", value)
        return code
    finally:
        del v.LEAF_CODE_SLICES[alias]
        v.LEAF_SECTION_BRANCHES[PUBLIC] = branches


def programs(executable, memory, build):
    pointers = read_le_fixups(executable)["pointers"]
    assert len(pointers.between(ENTRY, ENTRY + SIZE)) == 6
    assert all(v.FUNCTION_ADDRESSES[name] == address for name, address in TARGETS.items())
    assert all(v.DATA_OFFSETS[name] == offset for name, offset in DATA_OFFSETS.items())
    layout = v.CONTROLLER_PREFIX_LAYOUT
    [metadata] = [row for row in layout["objects"] if row["object"] == OBJECT]
    [context] = metadata["contexts"]
    assert (context["public"], context["start"], context["size"]) == (PUBLIC, 0, SIZE)
    assert len(context["fixups"]) == 19
    metadata_calls = {int(site) - 1: spec[0] for site, spec in context["fixups"].items() if spec[1]}
    assert metadata_calls == {site: name for name, sites in CALL_OFFSETS.items() for site in sites}
    assert v.LEAF_SECTION_BRANCHES[PUBLIC] == (
        SIZE, SIZE, {site: (b"\x74", target, target) for site, target in BRANCHES.items()},
    )
    blob = (build / f"{OBJECT}.obj").read_bytes()
    phases = sorted((row for row in layout["phases"] if row["routine"] == "map_video_memory"),
                    key=lambda row: row["address"])
    assert len(phases) == 16
    data = dict(v.DATA_OFFSETS, **{name: DS + off for name, off in DATA_OFFSETS.items()})

    def bind_phase(phase, candidate, loaded=False):
        code_refs = {}
        code, refs = v.bind_leaf_details(
            candidate, phase["phase"], data if loaded else v.DATA_OFFSETS,
            address=phase["address"], functions=v.FUNCTION_ADDRESSES,
            absolute_code=v.CODE_OFFSETS, code_bindings=code_refs,
        )
        assert not code_refs
        return code, refs

    placed = bytearray()
    selected_le = 0
    compiler_offsets = set()
    for phase in phases:
        address, begin, end = (phase[key] for key in ("address", "begin", "end"))
        assert (phase["object"], phase["public"]) == (OBJECT, PUBLIC)
        assert address == ENTRY + len(placed)
        assert 0 <= begin < end <= SIZE and not compiler_offsets.intersection(range(begin, end))
        compiler_offsets.update(range(begin, end))
        canonical, refs = bind_phase(phase, blob)
        assert len(canonical) == end - begin and len(refs) == phase["le_sites"]
        raw = address + RAW_DELTA
        assert canonical == executable[raw:raw + len(canonical)]
        v.verify_leaf_relocations(canonical, refs, pointers, address)
        selected_le += len(refs)
        loaded, _ = bind_phase(phase, blob, loaded=True)
        placed.extend(loaded)
    assert len(placed) == SIZE and compiler_offsets == set(range(SIZE))
    assert selected_le == 6 and placed == memory[ENTRY:ENTRY + SIZE]

    all_programs = (
        Program("reference", ENTRY, memory[ENTRY:ENTRY + SIZE]),
        Program("placed", ENTRY, bytes(placed)),
        Program("private", PRIVATE, bind_private(blob, data)),
    )
    for program in all_programs:
        check_control_flow(program)

    first = phases[0]
    assert first["begin"] <= min(BRANCHES) < first["end"]

    def rejected(candidate, reason):
        try:
            bind_phase(first, candidate)
        except ValueError as exc:
            assert reason in str(exc).lower(), (reason, str(exc))
        else:
            raise AssertionError(f"Mutation escaped guard: {reason}")

    rejected(mutate_public_byte(blob, PUBLIC, SIZE - 1), "context")
    rejected(rename_external(blob, b"int386_", b"int387_"), "fixup")
    mapped_store = next(int(site) for site, spec in context["fixups"].items()
                        if spec[0] == "_mapped_video_base" and not spec[1])
    digest = v.LEAF_CONTEXT_SHA256.pop(PUBLIC)
    try:
        rejected(mutate_public_byte(blob, PUBLIC, mapped_store), "addend")
    finally:
        v.LEAF_CONTEXT_SHA256[PUBLIC] = digest

    branch_guard = v.LEAF_SECTION_BRANCHES[PUBLIC]
    public_size, placed_size, branches = branch_guard
    site = min(branches)
    opcode, compiled_target, placed_target = branches[site]
    try:
        v.LEAF_SECTION_BRANCHES[PUBLIC] = (
            public_size, placed_size, branches | {site: (opcode, compiled_target - 1, placed_target)},
        )
        rejected(blob, "compiler target")
        v.LEAF_SECTION_BRANCHES[PUBLIC] = (
            public_size, placed_size, branches | {site: (opcode, compiled_target, placed_target - 1)},
        )
        bad, _ = bind_phase(first, blob)
        at = first["address"] + RAW_DELTA
        assert bad != executable[at:at + len(bad)]
    finally:
        v.LEAF_SECTION_BRANCHES[PUBLIC] = branch_guard
    return all_programs, 5


def exercise(memory, template, program, case):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, 0x500000)
    cpu.mem_write(0, memory)
    cpu.mem_write(program.entry, program.code)
    cpu.mem_write(0x1000, pack("<4Q", 0, 0x00CF9B000000FFFF,
                               0x00CF93000000FFFF, 0x00CF93000000FFFF))
    cpu.reg_write(x86.UC_X86_REG_GDTR, (0, 0x1000, 31, 0))
    cpu.reg_write(x86.UC_X86_REG_CS, 8)
    for register in (x86.UC_X86_REG_DS, x86.UC_X86_REG_ES, x86.UC_X86_REG_SS):
        cpu.reg_write(register, DATA_SELECTOR)
    for register in (x86.UC_X86_REG_FS, x86.UC_X86_REG_GS):
        cpu.reg_write(register, OTHER_SELECTOR)
    cpu.reg_write(x86.UC_X86_REG_EFLAGS, 2)

    original_base = (case.linear + 0x1234567 + case.seed) & 0xFFFFFFFF
    data = bytearray(template)
    pack_into("<I", data, MAPPED, original_base)
    cpu.mem_write(DS - GUARD, b"\x5a" * GUARD + bytes(data) + b"\xa6" * GUARD)
    mapped = case.failure not in (ALLOCATE, MAP)
    if mapped:
        pack_into("<I", data, MAPPED, case.linear)

    cpu.mem_write(STACK - 256, b"\xa5" * 320)
    caller = pack("<I", STOP) + pattern(60, 0x51 + case.seed)
    cpu.mem_write(STACK, caller)
    cpu.reg_write(x86.UC_X86_REG_ESP, STACK)
    incoming = dict(zip(GPRS, (case.physical, 0x1B000011, 0x1C000022, 0x1D000033,
                               0x15000044, 0x16000055, 0x17000066)))
    for register, value in incoming.items():
        cpu.reg_write(register, value)
    saved = pack("<4I", *(incoming[register] for register in (EDI, ESI, ECX, EBX)))

    failed = case.failure is not None
    service_count = SERVICES.index(case.failure) + 1 if failed else len(SERVICES)
    expected_trace = (INT,) * service_count + ((PRINT, EXIT) if failed else ())
    int_returns = {program.entry + site + 5 for site in CALL_OFFSETS[INT]}
    normalization_sites = {site + 6 for site in int_returns}
    stubs = {addr: name for name, addr in TARGETS.items()}
    for address in stubs:
        cpu.mem_write(address, b"\xc3")
    stub_registers = (0xA1A11001 + case.seed, 0xB2B22002 + case.seed, 0xD4D44004 + case.seed)
    trace = []
    normalizations = []
    base_writes = []

    def reg(register):
        return cpu.reg_read(register)

    def read32(address):
        return unpack("<I", cpu.mem_read(address, 4))[0]

    def normalized():
        assert reg(x86.UC_X86_REG_ES) == DATA_SELECTOR
        assert not reg(x86.UC_X86_REG_EFLAGS) & DF

    def native_write(emu, access, address, width, value, _):
        if STACK - 128 <= address and address + width <= STACK:
            return
        assert mapped and (address, width) == (DS + MAPPED, 4), (
            "unexpected native write", hex(emu.reg_read(x86.UC_X86_REG_EIP)), hex(address), width,
        )
        base_writes.append(value & 0xFFFFFFFF)

    def visit(emu, address, instruction_size, _):
        if address in int_returns:
            assert reg(x86.UC_X86_REG_ES) == OTHER_SELECTOR
            assert reg(x86.UC_X86_REG_EFLAGS) & DF
        if address in normalization_sites:
            normalized()
            normalizations.append(address)

        name = stubs.get(address)
        if name is None:
            return
        assert len(trace) < len(expected_trace) and name == expected_trace[len(trace)], (
            trace, name, expected_trace,
        )
        normalized()
        sp = reg(x86.UC_X86_REG_ESP)
        stage = len(trace) if name == INT else tuple(DIAGNOSTICS).index(case.failure)
        assert read32(sp) == program.entry + CALL_OFFSETS[name][stage] + 5
        assert sp == FRAME - (8 if name == PRINT else 4), (name, hex(sp))
        trace.append(name)
        if name == INT:
            assert (reg(EAX), reg(EBX), reg(EDX)) == (0x31, FRAME, FRAME)
            assert reg(ECX) == (case.selector if stage else incoming[ECX])
            assert emu.mem_read(STACK - 16, 16) == saved
            service = SERVICES[stage]
            words = unpack("<14H", emu.mem_read(FRAME, 28))
            assert {index: words[index * 2] for index in case.inputs(service)} == case.inputs(service)
            expected_base = case.linear if service in (SET_BASE, SET_LIMIT) else original_base
            assert read32(DS + MAPPED) == expected_base
            emu.mem_write(FRAME, case.output(service))
            for register, value in zip((EAX, EBX, EDX), stub_registers):
                emu.reg_write(register, value)
            emu.reg_write(x86.UC_X86_REG_EFLAGS, reg(x86.UC_X86_REG_EFLAGS) | DF)
            emu.reg_write(x86.UC_X86_REG_ES, OTHER_SELECTOR)
        elif name == PRINT:
            offset, error = DIAGNOSTICS[case.failure]
            assert read32(sp + 4) == DS + offset
            assert emu.mem_read(DS + offset, len(error)) == error
            emu.reg_write(EAX, 0xF00D10A0 + case.seed)
        else:
            assert name == EXIT and reg(EAX) == 0
            emu.emu_stop()

    cpu.hook_add(UC_HOOK_MEM_WRITE, native_write)
    cpu.hook_add(UC_HOOK_CODE, visit)
    cpu.emu_start(program.entry, STOP, count=256)
    assert tuple(trace) == expected_trace and len(normalizations) == service_count
    normalized()
    assert reg(x86.UC_X86_REG_CS) == 8
    assert reg(x86.UC_X86_REG_DS) == reg(x86.UC_X86_REG_SS) == DATA_SELECTOR
    assert reg(x86.UC_X86_REG_FS) == reg(x86.UC_X86_REG_GS) == OTHER_SELECTOR
    if failed:
        assert (reg(x86.UC_X86_REG_EIP), reg(x86.UC_X86_REG_ESP)) == (TARGETS[EXIT], FRAME - 4)
        assert (reg(EAX), reg(EBX), reg(EDX)) == (0, stub_registers[1], stub_registers[2])
        assert reg(ECX) == (incoming[ECX] if case.failure == ALLOCATE else case.selector)
        assert reg(ESI) == (case.physical if case.failure == ALLOCATE else 0xFFFF)
        edi_at_exit = {ALLOCATE: incoming[EDI], MAP: 9, SET_BASE: 7, SET_LIMIT: 7}
        assert reg(EDI) == edi_at_exit[case.failure]
        assert reg(EBP) == incoming[EBP]
    else:
        assert (reg(x86.UC_X86_REG_EIP), reg(x86.UC_X86_REG_ESP)) == (STOP, STACK + 4)
        assert (reg(EAX), reg(EDX)) == (0, case.selector)
        assert all(reg(register) == incoming[register] for register in (EBX, ECX, ESI, EDI, EBP))
    assert cpu.mem_read(FRAME, 28) == case.output(SERVICES[service_count - 1])
    assert cpu.mem_read(STACK - 16, 16) == saved
    assert cpu.mem_read(STACK, len(caller)) == caller
    assert cpu.mem_read(STACK - 256, 128) == b"\xa5" * 128
    assert cpu.mem_read(DS - GUARD, DATA_SIZE + 2 * GUARD) == b"\x5a" * GUARD + bytes(data) + b"\xa6" * GUARD
    assert base_writes == ([case.linear] if mapped else [])
    return Counter({
        "interrupt_calls": service_count, "native_segment_normalizations": len(normalizations),
        "printf_calls": trace.count(PRINT), "exit_calls": trace.count(EXIT),
        "full_memory_checks": 1,
    })


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--exe", type=Path, required=True)
    parser.add_argument("--build", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    executable = args.exe.read_bytes()
    memory = image(executable)
    all_programs, mutation_controls = programs(executable, memory, args.build)
    counts, observed_carry, totals = Counter(), Counter(), Counter()
    for seed in (0, 1):
        data = bytearray(pattern(DATA_SIZE, 0x59 + seed))
        for offset, message in DIAGNOSTICS.values():
            assert memory[DS + offset:DS + offset + len(message)] == message
            data[offset:offset + len(message)] = message
        # Rotate linear addresses and selectors across the six physical inputs.
        # The second seed flips rights carry and permutes the paired outputs.
        for index, physical in enumerate(PHYSICALS):
            linear = LINEARS[(index + seed) % len(LINEARS)]
            selector = SELECTORS[(index + 2 * seed) % len(SELECTORS)]
            rights_carry = (index + seed) & 1
            for failure in (None, *DIAGNOSTICS):
                case = Case(physical, linear, selector, rights_carry, failure, seed)
                for program in all_programs:
                    try:
                        totals.update(exercise(memory, data, program, case))
                    except (AssertionError, UcError, ValueError) as exc:
                        raise AssertionError((program.name, case, str(exc))) from exc
                    label = "success" if failure is None else f"failure_{failure:04x}"
                    counts[f"{program.name}_{label}"] += 1
                    if failure != ALLOCATE:
                        observed_carry[f"rights_carry_{rights_carry}"] += 1
    report = {
        "status": "PASS", "cases": dict(counts), "total_cases": sum(counts.values()),
        "ignored_rights_carry_cases": dict(observed_carry), **totals,
        "mutation_controls": mutation_controls, "selected_bytes": SIZE,
        "selected_le_data_sites": 6, "selected_le_code_sites": 0,
        "native_c_bytes": SIZE - 30, "existing_inline_bytes": 30, "standalone_assembly_bytes": 0,
        "primitive_stubs": list(TARGETS),
        "fixture_sha256": sha256(Path(__file__).read_bytes()).hexdigest(),
    }
    args.output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report))


if __name__ == "__main__":
    main()

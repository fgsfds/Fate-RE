"""Verify the placed video DOS frame and both private Watcom transfer contexts."""

import argparse
from collections import Counter, defaultdict
from dataclasses import dataclass
import json
from pathlib import Path
from struct import calcsize, pack, pack_into, unpack

from unicorn import Uc, UcError, UC_ARCH_X86, UC_HOOK_CODE, UC_HOOK_MEM_WRITE, UC_MODE_32
from unicorn import x86_const as x86

import verify_c_leaf as v
from check_ripple_control import rename_external
from check_ripple_stack import mutate_public_byte
from check_start_hook import DS, image
from le_fixups import read_le_fixups


ENTRY, HANDOFF, END = 0x43A50, 0x43ACF, 0x43B28
RAW_DELTA, DATA_SIZE = 0x25600, 0x28A300
BIOS, BUFFER, DOS = 0x340000, 0x341000, 0x342000
PRIVATE, STACK, STOP = 0x400000, 0x4FF000, 0x4FFF00
DATA_SELECTOR, OTHER_SELECTOR, DF = 0x10, 0x18, 0x400
SIZE, ALLOCATION, REAL_SEGMENT, ERROR = 0x13FE8, 0x13FEC, 0x286B80, 0x1944
CALLBACK = 0x43A1D

INT, PRINT, EXIT, REGISTER, COPY, VBE = (
    "int386_", "printf_", "runtime_exit_", "main_prepare_", "_fmemcpy_",
    "dpmi_real_mode_far_call_",
)
TARGETS = dict(zip(
    (INT, PRINT, EXIT, REGISTER, COPY, VBE),
    (0x630B3, 0x40BB4, 0x60353, 0x40C0D, 0x63272, 0x438F9),
))
TAIL_RETURNS = {COPY: (0x43AF9, 0x43B20), VBE: (0x43B0B,)}
GPRS = (x86.UC_X86_REG_EAX, x86.UC_X86_REG_EBX, x86.UC_X86_REG_ECX,
        x86.UC_X86_REG_EDX, x86.UC_X86_REG_ESI, x86.UC_X86_REG_EDI,
        x86.UC_X86_REG_EBP)
EAX, EBX, ECX, EDX, ESI, EDI, EBP = GPRS
INT_POISON = (0x1A110001, 0x1B220002, 0x1D440004)
COPY_BX, COPY_CX, REGISTER_AX = 0xBC0F1234, 0xCC0F5678, 0xCBAC1234
GUARD = 16


@dataclass(frozen=True)
class Program:
    name: str
    entry: int
    code: bytes
    returns: dict
    saves: int
    prefix: bool = False
    result_in_edi: bool = False


def pattern(size, seed, step=73):
    period = bytes((seed + index * step) & 0xFF for index in range(256))
    return (period * ((size + 255) // 256))[:size]


def check_call(code, base, ret, name):
    after = ret - base
    assert code[after - 5:after - 4] == b"\xe8", (name, hex(ret))
    displacement = int.from_bytes(code[after - 4:after], "little", signed=True)
    assert ret + displacement == TARGETS[name], (name, hex(ret), displacement)


def metadata_returns(context, code, address, begin=0):
    returns = defaultdict(list)
    for offset, (name, relative, _) in context["fixups"].items():
        local = int(offset) - begin
        if relative and 0 <= local <= len(code) - 4:
            ret = address + local + 4
            check_call(code, address, ret, name)
            returns[name].append(ret)
    return {name: tuple(sorted(sites)) for name, sites in returns.items()}


def bind_private(blob, context, data, absolute_code):
    public, size = context["public"], context["size"]
    alias = public + "video_dos_fixture_private"
    assert alias not in v.LEAF_CODE_SLICES
    v.LEAF_CODE_SLICES[alias] = (public, 0, size, size)
    branches = v.LEAF_SECTION_BRANCHES.pop(public, None)
    try:
        code_refs = {}
        code, bindings = v.bind_leaf_details(
            blob, alias, data, address=PRIVATE, functions=v.FUNCTION_ADDRESSES,
            absolute_code=absolute_code, code_bindings=code_refs,
        )
        assert list(code_refs.values()) == [CALLBACK]
        for site, value in bindings.items():
            assert code[site:site + 4] == pack("<I", value)
        return code
    finally:
        del v.LEAF_CODE_SLICES[alias]
        if branches is not None:
            v.LEAF_SECTION_BRANCHES[public] = branches


def programs(executable, memory, build):
    pointers = read_le_fixups(executable)["pointers"]
    assert len(pointers.between(ENTRY, END)) == 9
    for name, address in TARGETS.items():
        assert v.FUNCTION_ADDRESSES[name] == address, (name, address)
    names = ("vdosio", "vbufret")
    layout = v.CONTROLLER_PREFIX_LAYOUT
    objects = {row["object"]: row for row in layout["objects"] if row["object"] in names}
    assert set(objects) == set(names)
    contexts = {name: row["contexts"][0] for name, row in objects.items()}
    assert [contexts[name]["size"] for name in names] == [232, 230]
    assert all(len(item["fixups"]) == 16 and item["start"] == 0
               for item in contexts.values())
    blobs = {name: (build / f"{name}.obj").read_bytes() for name in names}
    phases = sorted((row for row in layout["phases"]
                     if row["routine"] == "allocate_video_dos_memory"),
                    key=lambda row: row["address"])
    assert [(row["object"], row["begin"], row["end"], row["address"]) for row in phases] == [
        ("vbufret", 0, 2, ENTRY), ("vdosio", 2, 3, ENTRY + 2),
        ("vbufret", 4, 128, ENTRY + 3),
    ]
    data_addresses = {
        "_video_dos_buffer_size": SIZE, "_video_dos_allocation": ALLOCATION,
        "_video_dos_real_segment": REAL_SEGMENT, "_video_dos_allocation_error": ERROR,
    }
    assert all(v.DATA_OFFSETS[name] == offset for name, offset in data_addresses.items())
    data = dict(v.DATA_OFFSETS, **{name: DS + off for name, off in data_addresses.items()})
    assert v.CODE_OFFSETS["free_video_dos_memory_"] == CALLBACK - 0x10000
    code_addresses = dict(v.CODE_OFFSETS, free_video_dos_memory_=CALLBACK)

    def bind_phase(phase, blob, loaded=False):
        code_refs = {}
        code, refs = v.bind_leaf_details(
            blob, phase["phase"], data if loaded else v.DATA_OFFSETS,
            address=phase["address"], functions=v.FUNCTION_ADDRESSES,
            absolute_code=code_addresses if loaded else v.CODE_OFFSETS,
            code_bindings=code_refs,
        )
        return code, refs, code_refs

    loaded_prefix = bytearray()
    selected_returns = {}
    selected_le = selected_code_le = 0
    for phase in phases:
        name, address = phase["object"], phase["address"]
        assert address == ENTRY + len(loaded_prefix)
        canonical, refs, code_refs = bind_phase(phase, blobs[name])
        raw = address + RAW_DELTA
        assert canonical == executable[raw:raw + len(canonical)]
        v.verify_leaf_relocations(canonical, refs, pointers, address, code_bindings=code_refs)
        assert len(refs) == phase["le_sites"]
        selected_le += len(refs)
        selected_code_le += len(code_refs)
        loaded, _, _ = bind_phase(phase, blobs[name], loaded=True)
        selected_returns.update(metadata_returns(contexts[name], loaded, address, phase["begin"]))
        loaded_prefix.extend(loaded)
    assert (len(loaded_prefix), selected_le, selected_code_le) == (127, 6, 1)
    assert loaded_prefix == memory[ENTRY:HANDOFF]
    assert set(selected_returns) == {INT, PRINT, EXIT, REGISTER}

    placed = bytes(loaded_prefix) + memory[HANDOFF:END]
    for name, sites in TAIL_RETURNS.items():
        for ret in sites:
            check_call(placed, ENTRY, ret, name)
    all_programs = [
        Program("placed", ENTRY, placed, selected_returns | TAIL_RETURNS, 16),
        Program("prefix", ENTRY, bytes(loaded_prefix), selected_returns, 16, prefix=True),
    ]
    for name, saves in (("vdosio", 20), ("vbufret", 16)):
        private = bind_private(blobs[name], contexts[name], data, code_addresses)
        returns = metadata_returns(contexts[name], private, PRIVATE)
        assert set(returns) == set(TARGETS) and len(returns[COPY]) == 2
        all_programs.append(Program(name, PRIVATE, private, returns, saves,
                                    result_in_edi=name == "vbufret"))

    phase = phases[-1]
    public, blob = phase["public"], blobs[phase["object"]]
    context = contexts[phase["object"]]

    def rejected(bad_blob, reason):
        try:
            bind_phase(phase, bad_blob)
        except ValueError as exc:
            assert reason in str(exc).lower(), (reason, str(exc))
        else:
            raise AssertionError(f"Mutation escaped guard: {reason}")

    rejected(mutate_public_byte(blob, public, 2), "context")
    rejected(mutate_public_byte(blob, public, context["size"] - 1), "context")
    rejected(rename_external(blob, b"_fmemcpy_", b"_fmemcpY_"), "fixup")
    data_site = next(int(site) for site, spec in context["fixups"].items()
                     if int(site) >= phase["end"] and not spec[1])
    digest = v.LEAF_CONTEXT_SHA256.pop(public)
    try:
        rejected(mutate_public_byte(blob, public, data_site), "addend")
    finally:
        v.LEAF_CONTEXT_SHA256[public] = digest

    branch_guard = v.LEAF_SECTION_BRANCHES[public]
    public_size, placed_size, branches = branch_guard
    site = min(branches)
    opcode, compiled_target, placed_target = branches[site]
    try:
        v.LEAF_SECTION_BRANCHES[public] = (
            public_size, placed_size, branches | {site: (opcode, compiled_target - 1, placed_target)},
        )
        rejected(blob, "compiler target")
        v.LEAF_SECTION_BRANCHES[public] = (
            public_size, placed_size, branches | {site: (opcode, compiled_target, placed_target - 1)},
        )
        displaced, _, _ = bind_phase(phase, blob)
        assert displaced != executable[phase["address"] + RAW_DELTA:
                                       phase["address"] + RAW_DELTA + len(displaced)]
    finally:
        v.LEAF_SECTION_BRANCHES[public] = branch_guard
    return all_programs, 6


def exercise(memory, data_template, program, outcome, size, seed, length, selector, segment):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, 0x500000)
    cpu.mem_write(0, memory)
    cpu.mem_write(program.entry, program.code)
    cpu.mem_write(0x1000, pack("<QQQQ", 0, 0x00CF9B000000FFFF,
                               0x00CF93000000FFFF, 0x00CF93000000FFFF))
    cpu.reg_write(x86.UC_X86_REG_GDTR, (0, 0x1000, 31, 0))
    cpu.reg_write(x86.UC_X86_REG_CS, 8)
    for reg in (x86.UC_X86_REG_DS, x86.UC_X86_REG_ES, x86.UC_X86_REG_SS, x86.UC_X86_REG_FS):
        cpu.reg_write(reg, DATA_SELECTOR)
    cpu.reg_write(x86.UC_X86_REG_GS, OTHER_SELECTOR)
    cpu.reg_write(x86.UC_X86_REG_EFLAGS, 2)

    first = outcome != "reuse"
    failed = outcome == "failure"
    allocation = 0 if first else selector
    real_segment = 0xABCD8937 if first else segment
    data = bytearray(data_template)
    for offset, value in ((SIZE, size), (ALLOCATION, allocation), (REAL_SEGMENT, real_segment)):
        pack_into("<I", data, offset, value)
    data_guard_before, data_guard_after = b"\x5a" * GUARD, b"\xa6" * GUARD
    cpu.mem_write(DS - GUARD, data_guard_before + bytes(data) + data_guard_after)
    if first and not failed:
        pack_into("<I", data, ALLOCATION, selector)
        pack_into("<I", data, REAL_SEGMENT, segment)

    request = 0x4F00 if length == 512 else 0x4F01
    bios_input = pack("<7H", request, 0x85, seed + 1, 0xA001, 0x3F22, 0x5999, 0xCAFE)
    bios_output = pack("<7H", 0x4F, 0x1200 + seed, 0x4402, 0x5503, 0x6604, 0x7705, 0)
    input_bytes = pattern(length, 0x4B + seed)
    dos_initial = pattern(length, 0xD2 + seed)
    reply = bytes(value ^ ((index * 29 + request + seed) & 0xFF)
                  for index, value in enumerate(input_bytes))
    guard_before, guard_after = pattern(GUARD, 0x12 + seed), pattern(GUARD, 0x78 + seed)
    for location, content in ((BIOS, bios_input), (BUFFER, input_bytes), (DOS, dos_initial)):
        cpu.mem_write(location - GUARD, guard_before + content + guard_after)

    cpu.mem_write(STACK - 256, b"\xa5" * 320)
    caller = pack("<I", STOP) + pattern(60, 0x51 + seed)
    cpu.mem_write(STACK, caller)
    cpu.reg_write(x86.UC_X86_REG_ESP, STACK)
    incoming = dict(zip(GPRS, (BIOS, length, 0x19800000 + seed, BUFFER,
                               0x15000001, 0x16000012, 0x17000123)))
    for reg, value in incoming.items():
        cpu.reg_write(reg, value)

    frame = STACK - program.saves - 40
    expected_int = pack("<7I", 0xF12A0000 | segment, 0xF23B11E1, 0xF34C22E2,
                        0xF45D0000 | selector, 0xF56E44E4, 0xF67F55E5, int(failed))
    start_calls = (INT, PRINT, EXIT) if failed else ((INT, REGISTER) if first else ())
    transfer_calls = () if failed or program.prefix else (COPY, VBE, COPY)
    expected_trace = start_calls + transfer_calls
    trace = []
    normalizations = []
    int_return = program.returns[INT][0]
    stubs = {address: name for name, address in TARGETS.items()}
    for address, name in stubs.items():
        cpu.mem_write(address, b"\xc2\x04\x00" if name == COPY else b"\xc3")

    def reg(register):
        return cpu.reg_read(register)

    def read(fmt, location):
        return unpack(fmt, cpu.mem_read(location, calcsize(fmt)))[0]

    def normalized():
        assert not reg(x86.UC_X86_REG_EFLAGS) & DF
        assert reg(x86.UC_X86_REG_ES) == DATA_SELECTOR

    def native_write(emu, access, location, count, value, _):
        inside_stack = STACK - 128 <= location and location + count <= STACK
        valid_global = first and not failed and count == 4 and location in (
            DS + ALLOCATION, DS + REAL_SEGMENT,
        )
        assert inside_stack or valid_global or (location, count) == (BIOS + 10, 2), (
            "unexpected native write", hex(emu.reg_read(x86.UC_X86_REG_EIP)), hex(location), count,
        )

    def visit(emu, address, instruction_size, _):
        if address == int_return and first:
            assert reg(x86.UC_X86_REG_EFLAGS) & DF
            assert reg(x86.UC_X86_REG_ES) == OTHER_SELECTOR
        if address == int_return + 6 and first:
            normalized()
            normalizations.append(address)
        name = stubs.get(address)
        if name is None:
            return
        assert len(trace) < len(expected_trace) and name == expected_trace[len(trace)], (
            trace, name, expected_trace,
        )
        occurrence = trace.count(name)
        trace.append(name)
        sp = reg(x86.UC_X86_REG_ESP)
        assert read("<I", sp) == program.returns[name][occurrence]
        stack_argument = name in (PRINT, COPY)
        assert sp == frame - (8 if stack_argument else 4), (name, hex(sp), hex(frame))
        ax, bx, cx, dx = (reg(register) for register in (EAX, EBX, ECX, EDX))
        if name == INT:
            assert (ax, dx, bx) == (0x31, frame, frame)
            assert read("<H", frame) == 0x100
            assert read("<H", frame + 4) == ((size + 15) >> 4) & 0xFFFF
            emu.mem_write(frame, expected_int)
            for register, value in zip((EAX, EBX, EDX), INT_POISON):
                emu.reg_write(register, value)
            emu.reg_write(x86.UC_X86_REG_EFLAGS, reg(x86.UC_X86_REG_EFLAGS) | DF)
            emu.reg_write(x86.UC_X86_REG_ES, OTHER_SELECTOR)
        elif name == PRINT:
            normalized()
            error = b"DPMI_allocRealSeg failed!\n\0"
            assert read("<I", sp + 4) == DS + ERROR
            assert emu.mem_read(DS + ERROR, len(error)) == error
            emu.reg_write(EAX, 0xF00D10A0)
        elif name == EXIT:
            normalized()
            assert ax == 0
            emu.emu_stop()
        elif name == REGISTER:
            normalized()
            assert ax == CALLBACK
            assert read("<I", DS + ALLOCATION) == selector
            assert read("<I", DS + REAL_SEGMENT) == segment
            emu.reg_write(EAX, REGISTER_AX)
        elif name == COPY:
            normalized()
            expected = ((0, selector, BUFFER, DATA_SELECTOR) if occurrence == 0 else
                        (BUFFER, DATA_SELECTOR, 0, selector))
            assert (ax, dx & 0xFFFF, bx, cx & 0xFFFF) == expected
            assert read("<I", sp + 4) == length
            origin, destination = (BUFFER, DOS) if occurrence == 0 else (DOS, BUFFER)
            payload = bytes(emu.mem_read(origin, length))
            assert payload == (input_bytes if occurrence == 0 else reply)
            emu.mem_write(destination, payload)
            for register, value in ((EAX, ax), (EDX, 0xDEAD0000 | (dx & 0xFFFF)),
                                    (EBX, COPY_BX), (ECX, COPY_CX)):
                emu.reg_write(register, value)
        else:
            normalized()
            assert name == VBE and (ax, bx, cx, dx) == (0x10, BIOS, frame + 28, BIOS)
            assert emu.mem_read(BIOS, 14) == bios_input[:10] + b"\0\0" + bios_input[12:]
            assert read("<H", cx) == segment
            assert read("<H", cx + 8) == DATA_SELECTOR
            if program.entry == PRIVATE:
                assert read("<H", cx + 6) == 0
            assert emu.mem_read(DOS, length) == input_bytes
            emu.mem_write(cx, pack("<4H", 0xB170, 0xC280, 0xD390, 0xE4A0))
            emu.mem_write(BIOS, bios_output)
            emu.mem_write(DOS, reply)
            for index, register in enumerate((EAX, EBX, ECX, EDX)):
                emu.reg_write(register, 0xB1050000 + index)

    cpu.hook_add(UC_HOOK_MEM_WRITE, native_write)
    cpu.hook_add(UC_HOOK_CODE, visit)
    stop = HANDOFF if program.prefix else STOP
    cpu.emu_start(program.entry, stop, count=256)
    assert tuple(trace) == expected_trace
    assert len(normalizations) == int(first)
    normalized()
    assert reg(x86.UC_X86_REG_CS) == 8 and reg(x86.UC_X86_REG_GS) == OTHER_SELECTOR
    assert all(reg(register) == DATA_SELECTOR for register in
               (x86.UC_X86_REG_DS, x86.UC_X86_REG_SS, x86.UC_X86_REG_FS))

    if failed:
        assert reg(x86.UC_X86_REG_EIP) == TARGETS[EXIT]
        assert reg(x86.UC_X86_REG_ESP) == frame - 4
        assert cpu.mem_read(frame, 28) == expected_int
    elif program.prefix:
        assert (reg(x86.UC_X86_REG_EIP), reg(x86.UC_X86_REG_ESP)) == (HANDOFF, STACK - 56)
        assert (reg(ESI), reg(EDI), reg(EBP), reg(ECX)) == (BIOS, BUFFER, length, incoming[ECX])
        assert (reg(EAX), reg(EBX), reg(EDX)) == (
            (REGISTER_AX, INT_POISON[1], INT_POISON[2]) if first else (BIOS, length, BUFFER)
        )
        assert cpu.mem_read(STACK - 16, 16) == pack(
            "<4I", incoming[EBP], incoming[EDI], incoming[ESI], incoming[ECX],
        )
        assert cpu.mem_read(frame, 40) == (expected_int + b"\xa5" * 12 if first else b"\xa5" * 40)
    else:
        assert (reg(x86.UC_X86_REG_EIP), reg(x86.UC_X86_REG_ESP)) == (STOP, STACK + 4)
        assert (reg(EAX), reg(EBX), reg(EDX)) == (BUFFER, COPY_BX, 0xDEAD0010)
        assert all(reg(register) == incoming[register] for register in (ECX, ESI, EBP))
        assert reg(EDI) == (BUFFER if program.result_in_edi else incoming[EDI])
        assert read("<H", frame + 36) == DATA_SELECTOR

    completed = bool(transfer_calls)
    for location, content in (
        (BIOS, bios_output if completed else bios_input),
        (BUFFER, reply if completed else input_bytes),
        (DOS, reply if completed else dos_initial),
    ):
        expected = guard_before + content + guard_after
        assert cpu.mem_read(location - GUARD, len(expected)) == expected
    assert cpu.mem_read(STACK, len(caller)) == caller
    assert cpu.mem_read(STACK - 256, 128) == b"\xa5" * 128
    assert cpu.mem_read(DS - GUARD, DATA_SIZE + 2 * GUARD) == (
        data_guard_before + bytes(data) + data_guard_after
    )
    return len(normalizations)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--exe", type=Path, required=True)
    parser.add_argument("--build", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    executable = args.exe.read_bytes()
    memory = image(executable)
    all_programs, mutation_controls = programs(executable, memory, args.build)
    sizes = (0, 1, 15, 16, 17, 1024, 0xFFFF0)
    counts, domains = Counter(), Counter()
    normalizations = 0
    error = b"DPMI_allocRealSeg failed!\n\0"
    assert memory[DS + ERROR:DS + ERROR + len(error)] == error
    for seed in (0, 1):
        data = bytearray(pattern(DATA_SIZE, 0x59 + seed))
        data[ERROR:ERROR + len(error)] = error
        for program in all_programs:
            cases = [(kind, size) for size in sizes for kind in ("success", "failure")]
            cases.extend(("reuse", size) for size in (1, 1024))
            for index, (outcome, size) in enumerate(cases):
                length = 512 if (index // 2 + seed) & 1 else 256
                selector, segment = (1, 0xFFFF) if (index // 2 + seed) & 1 else (0xFFFF, 1)
                try:
                    normalizations += exercise(memory, data, program, outcome, size, seed,
                                               length, selector, segment)
                except (AssertionError, UcError, ValueError) as exc:
                    raise AssertionError((program.name, outcome, size, seed, length, str(exc))) from exc
                counts[f"{program.name}_{outcome}"] += 1
                domains[f"length_{length}"] += 1
    report = {
        "status": "PASS", "cases": dict(counts), "total_cases": sum(counts.values()),
        "length_cases": dict(domains), "normalization_cases": normalizations,
        "mutation_controls": mutation_controls, "selected_bytes": HANDOFF - ENTRY,
        "selected_le_sites": 6, "selected_code_le_sites": 1,
        "selected_inline_bytes": 6, "standalone_assembly_tail_bytes": END - HANDOFF,
        "whole_routine_le_sites": 9,
        "primitive_stubs": list(TARGETS),
    }
    args.output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report))


if __name__ == "__main__":
    main()

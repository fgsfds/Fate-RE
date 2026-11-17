"""Bounded behavioral comparisons; a behavioral PASS never qualifies exact code."""
from dataclasses import dataclass
from hashlib import sha256
import json
from pathlib import Path
from struct import pack

from unicorn import Uc, UcError, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE, UC_HOOK_MEM_WRITE
from unicorn import x86_const

from compare_exe import TARGET_SHA256
from le_fixups import read_le_fixups, pointer_range
from restoration_build import ROOT, write_json
from verification_diagnostics import code_mismatch
from verify_c_leaf import CODE_OFFSETS, bind_leaf_details, verify_leaf_relocations

REGISTERS = {name: getattr(x86_const, 'UC_X86_REG_' + name.upper())
             for name in ('eax', 'ebx', 'ecx', 'edx', 'esi', 'edi', 'ebp', 'esp', 'eflags')}
GUARD = b'\xa5' * 16


class BehaviorMismatch(AssertionError):
    pass


@dataclass(frozen=True)
class Region:
    name: str
    address: int
    size: int


@dataclass(frozen=True)
class Contract:
    entry: int
    stop: int
    stack: int
    cleanup: int
    preserved: tuple = ('ebp', 'esi', 'edi')
    results: tuple = ()
    stack_scratch: int = 4096
    flags_mask: int = 0
    instruction_limit: int = 100000


@dataclass(frozen=True)
class Observation:
    registers: dict
    memory: dict
    calls: tuple


class Machine:
    """Isolated 32-bit guest with explicit code, writable ranges, and ABI checks."""
    def __init__(self, contract, body, writable=(), *, code_address=None):
        self.contract = contract
        self.cpu = Uc(UC_ARCH_X86, UC_MODE_32)
        self.cpu.mem_map(0, 0x400000)
        self.writable = tuple(writable)
        if len({region.name for region in self.writable}) != len(self.writable):
            raise ValueError('Duplicate observable memory name')
        self.code = []
        self.stubs = {}
        self.calls = []
        self.add_code(contract.entry if code_address is None else code_address, body)
        self.write(contract.stop, b'\xcc')

    def write(self, address, payload):
        self.cpu.mem_write(address, bytes(payload))

    def read(self, address, size):
        return bytes(self.cpu.mem_read(address, size))

    def register(self, name):
        return self.cpu.reg_read(REGISTERS[name])

    def set_register(self, name, value):
        self.cpu.reg_write(REGISTERS[name], value & 0xffffffff)

    def add_code(self, address, body):
        if not body or len(body) > 0x10000 or address < 0x10000 or address + len(body) >= 0x400000:
            raise ValueError('Invalid or oversized guest code span')
        if any(address < end and start < address + len(body) for start, end in self.code):
            raise ValueError('Overlapping guest code spans')
        self.write(address, body)
        self.code.append((address, address + len(body)))

    def stub(self, address, callback):
        """Callback records arguments and returns only the registers its ABI changes."""
        self.add_code(address, b'\xc3')
        self.stubs[address] = callback

    def record(self, name, *arguments):
        self.calls.append((name, *arguments))

    def run(self, registers, stack_arguments=()):
        contract = self.contract
        if contract.cleanup != 4 * (len(stack_arguments) + 1):
            raise ValueError('Stack arguments do not match the ABI cleanup contract')
        self.write(contract.stack, pack('<' + 'I' * (len(stack_arguments) + 1),
                                       contract.stop, *(value & 0xffffffff for value in stack_arguments)))
        low_guard = contract.stack - contract.stack_scratch - len(GUARD)
        high_guard = contract.stack + contract.cleanup
        self.write(low_guard, GUARD)
        self.write(high_guard, GUARD)
        for name, value in registers.items():
            self.set_register(name, value)
        self.set_register('esp', contract.stack)
        saved = {name: self.register(name) for name in contract.preserved}

        def code_hook(_cpu, address, size, _user):
            if not any(start <= address and address + size <= end for start, end in self.code):
                raise BehaviorMismatch(f'execution escaped declared code at {address:#x}')
            if address in self.stubs:
                try:
                    changed = self.stubs[address](self) or {}
                except KeyError as error:
                    raise BehaviorMismatch(f'invalid external-call argument at {address:#x}: {error}') from error
                for name, value in changed.items():
                    self.set_register(name, value)

        def write_hook(_cpu, _access, address, size, _value, _user):
            # Scratch stack and consumed argument words may change; the saved
            # return address and caller-owned memory may not.
            stack_ok = (contract.stack - contract.stack_scratch <= address
                        and address + size <= contract.stack)
            arguments_ok = (contract.stack + 4 <= address
                            and address + size <= high_guard)
            data_ok = any(region.address <= address and address + size <= region.address + region.size
                          for region in self.writable)
            if not (stack_ok or arguments_ok or data_ok):
                raise BehaviorMismatch(f'write outside declared memory at {address:#x} ({size} bytes)')

        hooks = (self.cpu.hook_add(UC_HOOK_CODE, code_hook),
                 self.cpu.hook_add(UC_HOOK_MEM_WRITE, write_hook))
        try:
            self.cpu.emu_start(contract.entry, contract.stop, count=contract.instruction_limit,
                               timeout=500000)
        except UcError as error:
            raise BehaviorMismatch(f'guest execution failed: {error}') from error
        finally:
            for handle in hooks:
                self.cpu.hook_del(handle)
        ip = self.cpu.reg_read(x86_const.UC_X86_REG_EIP)
        if ip != contract.stop:
            raise BehaviorMismatch(f'routine did not return within its execution budget (EIP={ip:#x})')
        if self.register('esp') != high_guard:
            raise BehaviorMismatch(f'stack cleanup: expected {high_guard:#x}, '
                                   f'got {self.register("esp"):#x}')
        if self.read(low_guard, len(GUARD)) != GUARD or self.read(high_guard, len(GUARD)) != GUARD:
            raise BehaviorMismatch('stack guard changed')
        for name, expected in saved.items():
            if self.register(name) != expected:
                raise BehaviorMismatch(f'preserved register {name}: expected {expected:#x}, '
                                       f'got {self.register(name):#x}')
        results = {name: self.register(name) for name in contract.results}
        if contract.flags_mask:
            results['eflags'] = self.register('eflags') & contract.flags_mask
        return Observation(results,
                           {region.name: self.read(region.address, region.size) for region in self.writable},
                           tuple(self.calls))


def first_difference(expected, actual):
    for name in sorted(expected.registers.keys() | actual.registers.keys()):
        if expected.registers.get(name) != actual.registers.get(name):
            return f'register {name}: expected {expected.registers.get(name)}, got {actual.registers.get(name)}'
    for index in range(max(len(expected.calls), len(actual.calls))):
        left = expected.calls[index] if index < len(expected.calls) else None
        right = actual.calls[index] if index < len(actual.calls) else None
        if left != right:
            return f'call {index}: expected {left}, got {right}'
    for name in sorted(expected.memory.keys() | actual.memory.keys()):
        left, right = expected.memory.get(name), actual.memory.get(name)
        if left != right:
            if left is None or right is None:
                return f'observable memory region differs: {name}'
            index = next((i for i in range(min(len(left), len(right))) if left[i] != right[i]),
                         min(len(left), len(right)))
            return f'memory {name}+{index:#x}: expected {left[index:index+8].hex()}, got {right[index:index+8].hex()}'
    return None


def encode(value):
    if isinstance(value, bytes):
        return {'$bytes': value.hex()}
    if isinstance(value, (list, tuple)):
        return [encode(item) for item in value]
    if isinstance(value, dict):
        return {key: encode(item) for key, item in value.items()}
    return value


def decode(value):
    if isinstance(value, dict):
        if set(value) == {'$bytes'}:
            return bytes.fromhex(value['$bytes'])
        return {key: decode(item) for key, item in value.items()}
    if isinstance(value, list):
        return [decode(item) for item in value]
    return value


def replay_case(path, fixture):
    report = json.loads(Path(path).read_text(encoding='utf-8'))
    if report.get('schema') != 1 or report.get('fixture') != fixture:
        raise ValueError('Replay file belongs to another fixture or unsupported schema')
    return decode(report['case'])


def compare_cases(fixture, reference, candidate, cases, exercise, *, seed=None,
                  failure_output=None, check_reference=None, reuse_identical=False):
    """Stop at the first behavioral difference and save the precise replay input."""
    # Only callers that already passed exact acceptance opt in. Compare loaded
    # bodies, not object hashes or pre-relocation bytes (shared tails may move).
    identical = reuse_identical and reference == candidate
    count = 0
    for case in cases:
        count += 1
        phase = 'reference'
        try:
            expected = exercise(reference, case)
            if check_reference:
                check_reference(case, expected)
            phase = 'candidate'
            actual = expected if identical else exercise(candidate, case)
            difference = first_difference(expected, actual)
            if difference:
                raise BehaviorMismatch(difference)
        except (AssertionError, ValueError) as error:
            if failure_output:
                path = Path(failure_output)
                path.parent.mkdir(parents=True, exist_ok=True)
                write_json(path, dict(schema=1, fixture=fixture, seed=seed, case=encode(case),
                                      phase=phase, detail=str(error), case_index=count,
                                      reference_body_sha256=sha256(reference).hexdigest(),
                                      candidate_body_sha256=sha256(candidate).hexdigest(),
                                      inventory_eligible=False))
            raise BehaviorMismatch(f'{fixture}, case {count} ({case.get("name", "unnamed")}), '
                                   f'{phase}: {error}') from error
    if not count:
        raise ValueError('No behavioral cases selected')
    return count


def bind_bodies(executable, obj, symbol, address, size, offsets, functions, *,
                data_base=0x80000, behavior_only=False, execution_functions=None):
    """Exact mode keeps byte/LE gates; research mode only binds actual OMF fixups."""
    if sha256(executable).hexdigest() != TARGET_SHA256:
        raise ValueError('Reference is not the pinned October 1996 FATE.EXE')
    raw = address + 0x25600
    target = executable[raw:raw + size]
    code_refs = {}
    candidate, refs = bind_leaf_details(obj, symbol, offsets, address=address,
                                        functions=functions, absolute_code=CODE_OFFSETS,
                                        code_bindings=code_refs)
    pointers = read_le_fixups(executable)['pointers']
    if not behavior_only:
        if candidate != target:
            raise ValueError(code_mismatch(symbol, candidate, target, address))
        verify_leaf_relocations(candidate, refs, pointers, address, code_bindings=code_refs)
    reference = bytearray(target)
    for site, target_address in pointer_range(pointers, address, size).items():
        if site + 4 > len(reference):
            raise ValueError('Partial reference relocation at fixture boundary')
        value = target_address - 0x80000 + data_base if target_address >= 0x80000 else target_address
        reference[site:site+4] = value.to_bytes(4, 'little')
    loaded, _ = bind_leaf_details(
        obj, symbol, {name: data_base + value for name, value in offsets.items()},
        address=address, functions=execution_functions or functions,
        absolute_code={name: value + 0x10000 for name, value in CODE_OFFSETS.items()},
        code_bindings={})
    return bytes(reference), loaded, len(refs)


def add_arguments(parser):
    parser.add_argument('--behavior-only', action='store_true',
                        help='Compare behavior without qualifying exact bytes or LE sites')
    parser.add_argument('--seed', type=lambda value: int(value, 0), default=0xFACE)
    parser.add_argument('--random-cases', type=int, default=48)
    parser.add_argument('--case-file', type=Path, help='Replay one saved failing input')
    parser.add_argument('--failure-output', type=Path)
    parser.add_argument('--output', type=Path, help='Write an explicitly scoped result report')


def selected_cases(args, fixture, named, randomized):
    if not 0 <= args.random_cases <= 4096:
        raise ValueError('--random-cases must be between 0 and 4096')
    return ([replay_case(args.case_file, fixture)] if args.case_file else
            [*named, *randomized(args.random_cases, args.seed)])


def require_mutations_detected(fixture, reference, mutations, exercise):
    """A broken reference must fail, not accidentally count as a detected mutant."""
    detected = []
    for name, candidate, case in mutations:
        expected = exercise(reference, case)
        try:
            actual = exercise(candidate, case)
        except BehaviorMismatch:
            detected.append(name)
        else:
            if first_difference(expected, actual) is None:
                raise AssertionError(f'{fixture}: fixture missed mutation: {name}')
            detected.append(name)
    return detected


def finish(args, fixture, count, size, pointers):
    result = dict(fixture=fixture, status='passed', cases=count, seed=args.seed,
                  mode='behavior-only' if args.behavior_only else 'exact-and-behavior',
                  exact_verified=not args.behavior_only, inventory_eligible=False,
                  reference_sha256=TARGET_SHA256,
                  candidate_object_sha256=getattr(args, 'object_sha256', None),
                  candidate_bytes=size, candidate_absolute_fixups=pointers)
    if args.output:
        write_json(args.output, result)
    qualifier = 'BEHAVIOR ONLY; not eligible for exact coverage' if args.behavior_only else 'exact bytes/LE and behavior'
    print(f'PASS: {fixture}: {count} cases, {qualifier}')


def failure_path(args, fixture):
    return args.failure_output or ROOT / 'work/behavior-failures' / (fixture + '.json')

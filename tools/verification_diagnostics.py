"""Bounded byte/instruction and relocation diagnostics for exact comparisons."""
from itertools import zip_longest


def code_mismatch(symbol, actual, expected, address=0):
    first = next((i for i, (a, b) in enumerate(zip_longest(actual, expected))
                  if a != b), None)
    if first is None:
        return f'{symbol}: code matches'
    start, end = max(0, first - 8), first + 16
    lines = [f'Code mismatch: {symbol}; {len(actual)} generated vs {len(expected)} expected bytes; '
             f'first difference +{first:#x} ({address + first:#x})',
             f'  expected +{start:#x}: {expected[start:end].hex(" ")}',
             f'  generated +{start:#x}: {actual[start:end].hex(" ")}']
    try:
        from capstone import Cs, CS_ARCH_X86, CS_MODE_32
    except ImportError:
        return '\n'.join(lines)
    for label, code in (('expected', expected), ('generated', actual)):
        instructions = []
        for ins in Cs(CS_ARCH_X86, CS_MODE_32).disasm(code, address):
            instructions.append(ins)
            if ins.address >= address + first:
                break
        lines.append(f'  {label} instructions:')
        lines.extend(f'    {ins.address:#x}: {ins.mnemonic} {ins.op_str}'
                     for ins in instructions[-4:])
    return '\n'.join(lines)


def relocation_mismatch(actual, expected, limit=6):
    lines = []
    for site in sorted(actual.keys() | expected.keys()):
        if actual.get(site) == expected.get(site):
            continue
        def target(value):
            return 'absent' if value is None else hex(value)
        lines.append(f'+{site:#x}: expected {target(expected.get(site))}, '
                     f'actual {target(actual.get(site))}')
        if len(lines) == limit:
            break
    return '; '.join(lines)

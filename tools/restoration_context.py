"""Build bounded, reference-backed context for a single Fate CODE span."""
from hashlib import sha256
from pathlib import Path
import re

from compare_exe import TARGET_SHA256
from le_fixups import read_le_fixups
from restoration_build import ROOT, write_json

RAW_CODE_DELTA = 0x25600
IMAGE_BASE = 0x10000


def reference_span(context, selector):
    symbol = selector.rstrip('_')
    exact = [r for r in context['routines'] if r['symbol'].rstrip('_') == symbol]
    assembly = [r for r in context['assembly'] if r['symbol'].rstrip('_') == symbol]
    if len(exact) + len(assembly) != 1:
        raise ValueError('Reference context requires one unambiguous routine symbol')
    if exact:
        row = exact[0]
        return row['raw_offset'] - RAW_CODE_DELTA, row['bytes']
    row = assembly[0]
    return int(row['loaded_address'], 16), row['bytes']


def add_reference_context(context, selector, blob, export_dir=None, *, rea_span=False):
    try:
        from capstone import Cs, CS_ARCH_X86, CS_MODE_32
    except ImportError as error:
        raise ValueError('Reference context needs Capstone. Supply --dependencies.') from error

    address, size = reference_span(context, selector)
    start = address + RAW_CODE_DELTA
    end = address + size
    if address < IMAGE_BASE or size <= 0 or start + size > len(blob):
        raise ValueError('Routine span is outside the reference image')
    pointers = read_le_fixups(blob)['pointers'].between(address, end)
    body = blob[start:start + min(size, 1024)]
    decoded = list(Cs(CS_ARCH_X86, CS_MODE_32).disasm_lite(body, address, count=64))
    context['reference'] = dict(
        sha256=TARGET_SHA256, symbol=selector, address=hex(address),
        raw_offset=hex(start), bytes=size,
        decoded_bytes=decoded[-1][0] + decoded[-1][1] - address if decoded else 0,
        instructions=[dict(address=hex(pc), bytes=width, mnemonic=op, operands=args)
                      for pc, width, op, args in decoded],
        relocation_count=len(pointers),
        relocation_sample=[dict(site=hex(site), target=hex(target))
                           for site, target in pointers[:32]],
    )
    if export_dir is None:
        return

    from check_start_hook import image
    directory = Path(export_dir).resolve()
    if directory.parent != ROOT / 'work' or not re.fullmatch(r'[A-Za-z0-9_-]+', directory.name):
        raise ValueError('--ghidra-dir must be a named directory directly under work/')
    mapped = image(blob)
    if end > len(mapped):
        raise ValueError('Routine span is outside the mapped image')
    directory.mkdir(parents=False, exist_ok=False)
    filename = 'fate-mapped.bin'
    (directory / filename).write_bytes(mapped)
    context['ghidra'] = dict(image=filename, base='0x0', entry=hex(address),
                             span_bytes=size, language='x86:LE:32:default')
    if rea_span:
        # REA maps file offset zero at its raw import entry point.
        span = mapped[address:end]
        name = 'rea-span.bin'
        (directory / name).write_bytes(span)
        context['rea'] = dict(image=name, sha256=sha256(span).hexdigest(),
                              format='raw-binary', architecture='x86',
                              entry_point=hex(address), bytes=len(span))
    write_json(directory / 'context.json', context)

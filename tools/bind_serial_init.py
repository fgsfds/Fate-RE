"""Place only the serial initializer; discard its historical IPX context.

Both branch opcodes and the compiler-local shared epilogue are validated.
Only relative displacement operands change when that epilogue moves to the
original assembly IPX routine. No instruction is replaced or synthesized.
"""
from bind_melee_group import bind_switch_groups
from omf_fixups import read_fixups

BASE, SIZE, PREFIX = 0x41a46, 664, 16
CONTEXT_END, COMPILED_ENTRY, EPILOGUE = 944, 960, 938
DATA = {
    '_rmoffset32': 0x18fdc0,
    '_ipx_allocation_error': 0x18fe,
    '_ecbget': 0x18fde4,
    '_ecbput': 0x18fde0,
    '_ipxin': 0x18fdd4,
    '_ipxout': 0x18fdac,
    '_messin': 0x18fda0,
    '_messout': 0x18fd98,
    '_tempinbuf': 0x18fda4,
    '_tempoutbuf': 0x18fd9c,
    '_rmnethandler': 0x18fdb0,
    '_netinbufplc': 0x18fdb8,
    '_rmsegment16': 0x18fdec,
    '_netinbufend': 0x18fda8,
    '_netinbuf': 0x18fdb4,
    '_rmnetbuffer': 0x13e66,
    '_socket': 0x13e64,
    '_mycompaddr': 0x18fdc4,
    '_mypriority': 0x18fe0c,
    '_myconnectnum': 0x18fe30,
    '_netincnt': 0x186d38,
    '_netoutcnt_backing': 0x186e47,
    '_omessnum_backing': 0x18f6d6,
    '_omessleng_backing': 0x18f6f0,
    '_omessconnectindex_backing': 0x186cb0,
    '_comnum': 0x18fe10,
    '_comrateoption': 0x13cdf,
    '_comvect': 0x18fe04,
    '_incnt': 0x18fe00,
    '_inbufplc': 0x18fdbc,
    '_outcnt': 0x18fe14,
    '_inbufend': 0x18fdf0,
    '_outbufplc': 0x18fdd8,
    '_outbufend': 0x18fdd0,
    '_comport': 0x18fde8,
    '_comspeed': 0x18fe28,
    '_comtype': 0x18fdf8,
    '_comescape': 0x18fdfc,
    '_comreset': 0x18fe2c,
    '_comerror': 0x18fe1c,
    '_comresend': 0x18fdf4,
    '_syncbufleng': 0x18fe38,
}
CALLS = {
    'convalloc32_': 0x42fbb,
    'printf_': 0x40bb4,
    'memcpy_': 0x63245,
    'simulate_network_interrupt_': 0x42ffc,
    'netinitconnection_': 0x42319,
    'installbicomhandlers_': 0x430cc,
    'inp_': 0x6326a,
    '_disable_': 0x603dc,
    '_enable_': 0x60409,
}


def bind(blob, loaded=False):
    context_base = BASE - CONTEXT_END
    code, data_refs, code_refs, calls = bind_switch_groups(
        blob, base=context_base, loaded=loaded,
        tables=((0, 0, CONTEXT_END, 'ipx_compilation_context_'),
                (CONTEXT_END, PREFIX, None, 'initialize_serial_network_')),
        data_targets=DATA, call_targets=CALLS)
    code = bytearray(code)
    if len(code) != CONTEXT_END + SIZE:
        raise ValueError('Serial compiler group extent differs')
    if code[EPILOGUE:EPILOGUE + 6] != bytes.fromhex('5d5e5a595bc3'):
        raise ValueError('Serial shared epilogue differs')
    fields = {site for fix in read_fixups(blob) if fix.segment == 1
              for site in range(fix.offset, fix.offset + fix.width)}
    for site, opcode, width in ((COMPILED_ENTRY + 26, 0xeb, 1),
                                 (COMPILED_ENTRY + 643, 0xe9, 4)):
        end = site + 1 + width
        if code[site] != opcode or fields.intersection(range(site, end)):
            raise ValueError('Serial shared-return opcode/fixup differs')
        displacement = int.from_bytes(code[site + 1:end], 'little', signed=True)
        if end + displacement != EPILOGUE:
            raise ValueError('Serial shared-return target differs')
        code[site + 1:end] = (0x41a3f - (context_base + end)).to_bytes(
            width, 'little', signed=True)
    def selected(refs):
        return {site - CONTEXT_END: value for site, value in refs.items()
                if site >= CONTEXT_END}
    return (bytes(code[CONTEXT_END:]), selected(data_refs), selected(code_refs),
            selected(calls))

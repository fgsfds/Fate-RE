; Palette is dimmed.
BITS 32
ORG 0x365db

fade_level equ 0x12d14

palette_is_dimmed:
    cmp dword [fade_level], strict dword 0xff
    setnz al
    and eax, strict dword 0xff
    ret

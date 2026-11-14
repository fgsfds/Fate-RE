; Default DOS descriptor mode table and its DATA-relative pointer.
BITS 32
ORG 0x16ab4

descriptor_count:
    dd 20
default_modes:
    dd 1, 2, 2, 3, 2
    times 15 dd 0
descriptor_modes:
    dd default_modes

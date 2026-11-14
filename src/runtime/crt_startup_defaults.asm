; Initial stream-list pointer, CRT startup fields and shared callback.
BITS 32
ORG 0x14461

open_streams equ 0x2891e0
argument_initializer equ 0x63414
code_base equ 0x10000

    dd open_streams
    times 0x40 db 0
    dd argument_initializer - code_base
    times 0x65 db 0

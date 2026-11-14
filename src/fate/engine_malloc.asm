; Forward engine heap allocations to the Watcom runtime.
BITS 32
ORG 0x4478c

malloc equ 0x6126d

engine_malloc:
    jmp near malloc

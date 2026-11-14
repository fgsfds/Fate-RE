; Forward engine heap frees to the Watcom runtime.
BITS 32
ORG 0x44791

free equ 0x6170a

engine_free:
    jmp near free

; Reconstructed from FATE.EXE at logical code address 0x562e5.
; Produces the original 20 unrelocated bytes, not a runnable DOS executable.
; The two absolute operands require LE relocation in a complete executable.
BITS 32
randomseed equ 0x287e78             ; original DS-relative global offset

krand_:
    imul eax, dword [randomseed], 0x01a4e86d
    inc eax
    mov dword [randomseed], eax
    shr eax, 16
    ret

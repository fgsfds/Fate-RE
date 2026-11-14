; Allocate dos memory.
BITS 32
ORG 0x37659

int386 equ 0x630b3
frame_state_173f90 equ 0x173f90
frame_state_173fa0 equ 0x173fa0

allocate_dos_memory:
    push ebx
    sub esp, 0x1c
    mov dword [esp], 0x100
    movsx edx, ax
    add edx, 0x10
    mov eax, edx
    sar edx, byte 0x1f
    shl edx, byte 0x4
    db 0x1b, 0xc2 ; sbb eax, edx in the original register encoding
    sar eax, byte 0x4
    mov ebx, esp
    mov edx, esp
    mov [esp + 0x4], eax
    mov eax, 0x31
    call int386
    cmp dword [esp + 0x18], 0x0
    jnz short .branch_376b2
    mov eax, [esp]
    xor edx, edx
    mov [frame_state_173fa0], ax
    xor eax, eax
    mov [frame_state_173f90], dx
    mov ax, [esp]
    mov edx, ds
    shl eax, byte 0x4
    add esp, 0x1c
    pop ebx
    ret

.branch_376b2:
    xor edx, edx
    xor eax, eax
    add esp, 0x1c
    pop ebx
    ret

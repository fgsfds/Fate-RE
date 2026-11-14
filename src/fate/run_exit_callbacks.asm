; Run exit callbacks.
BITS 32
ORG 0x40bd6

frame_state_17ab1c equ 0x17ab1c
frame_state_17aba0 equ 0x17aba0

run_exit_callbacks:
    push ebx
    push edx
    sub esp, 0x4
    mov edx, 0x20
    mov ebx, [frame_state_17aba0]
    mov [frame_state_17aba0], edx
    mov edx, ebx
    shl edx, byte 0x2

.branch_40bf1:
    test edx, edx
    jz short .branch_40c07
    mov eax, [edx + frame_state_17ab1c]
    sub edx, 0x4
    mov [esp], eax
    dec ebx
    call dword near [esp]
    jmp short .branch_40bf1

.branch_40c07:
    add esp, 0x4
    pop edx
    pop ebx
    ret

; Register exit callback.
BITS 32
ORG 0x40c0d

atexit_hook equ 0x141ac
exit_dispatch_offset equ 0x30bd6
frame_state_17ab20 equ 0x17ab20
frame_state_17aba0 equ 0x17aba0

register_exit_callback:
    push ebx
    push ecx
    push edx
    mov ebx, eax
    mov edx, exit_dispatch_offset
    mov ecx, [frame_state_17aba0]
    mov [atexit_hook], edx
    cmp ecx, 0x20
    jnl short .branch_40c40
    mov eax, ecx
    lea edx, [ecx + 0x1]
    mov [nosplit ecx*4 + frame_state_17ab20], ebx
    mov [frame_state_17aba0], edx
    xor eax, ecx
    pop edx
    pop ecx
    pop ebx
    ret

.branch_40c40:
    mov eax, 0xffffffff
    pop edx
    pop ecx
    pop ebx
    ret

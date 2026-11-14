; Compute packed stereo attenuation from a world position.
BITS 32
ORG 0x34db6

listener_index equ 0x3cfa
player_y equ 0x5ad5c
player_x equ 0x5ad9c
absolute_long equ 0x602c3

audio_source_attenuation:
    push ebx
    mov ebx, edx
    movsx edx, word [listener_index]
    mov edx, [nosplit edx*4 + player_x]
    sub edx, eax
    mov eax, edx
    call absolute_long
    mov edx, eax
    movsx eax, word [listener_index]
    mov eax, [nosplit eax*4 + player_y]
    sub eax, ebx
    call absolute_long
    add eax, edx
    cmp eax, strict dword 0x600
    jnl short .branch_34df7
    mov eax, 0x7fff
    jmp short .branch_34e11

.branch_34df7:
    cmp eax, strict dword 0x21e2
    jng short .branch_34e05
    mov eax, 0x1f00
    jmp short .branch_34e11

.branch_34e05:
    mov edx, 0x9858
    shl eax, byte 0x2
    sub edx, eax
    mov eax, edx

.branch_34e11:
    cwde
    mov edx, eax
    shl edx, byte 0x10
    or eax, edx
    pop ebx
    ret

; Initialize key menu.
BITS 32
ORG 0x3a345

frame_state_13656 equ 0x13656
frame_state_13863 equ 0x13863
frame_state_1388d equ 0x1388d
frame_state_1741dc equ 0x1741dc
frame_state_1741e4 equ 0x1741e4
frame_state_1741f0 equ 0x1741f0

initialize_key_menu:
    push ebx
    push edx
    xor eax, eax

.branch_3a349:
    mov edx, eax
    shl edx, byte 0x2
    add edx, eax
    shl edx, byte 0x2
    mov ebx, frame_state_13656
    add edx, eax
    inc eax
    add ebx, edx
    mov [nosplit eax*4 + frame_state_1741f0], ebx
    cmp eax, 0x19
    jl short .branch_3a349
    xor eax, eax

.branch_3a36b:
    mov edx, eax
    shl edx, byte 0x2
    add edx, eax
    shl edx, byte 0x2
    mov ebx, frame_state_1388d
    add edx, eax
    inc eax
    add ebx, edx
    mov [nosplit eax*4 + frame_state_1741e4], ebx
    cmp eax, 0x3
    jl short .branch_3a36b
    xor eax, eax

.branch_3a38d:
    mov edx, eax
    shl edx, byte 0x2
    add edx, eax
    shl edx, byte 0x2
    mov ebx, frame_state_13863
    add edx, eax
    inc eax
    add ebx, edx
    mov [nosplit eax*4 + frame_state_1741dc], ebx
    cmp eax, 0x2
    jl short .branch_3a38d
    pop edx
    pop ebx
    ret

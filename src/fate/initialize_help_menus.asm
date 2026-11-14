; Initialize help menus.
BITS 32
ORG 0x3a6e8

frame_state_1390c equ 0x1390c
frame_state_13960 equ 0x13960
frame_state_1399f equ 0x1399f
frame_state_174568 equ 0x174568
frame_state_17457c equ 0x17457c
frame_state_17458c equ 0x17458c

initialize_help_menus:
    push ebx
    push edx
    xor eax, eax

.branch_3a6ec:
    mov edx, eax
    shl edx, byte 0x2
    add edx, eax
    shl edx, byte 0x2
    mov ebx, frame_state_1390c
    add edx, eax
    inc eax
    add ebx, edx
    mov [nosplit eax*4 + frame_state_174568], ebx
    cmp eax, 0x4
    jl short .branch_3a6ec
    xor eax, eax

.branch_3a70e:
    mov edx, eax
    shl edx, byte 0x2
    add edx, eax
    shl edx, byte 0x2
    mov ebx, frame_state_1399f
    add edx, eax
    inc eax
    add ebx, edx
    mov [nosplit eax*4 + frame_state_17457c], ebx
    cmp eax, 0x3
    jl short .branch_3a70e
    xor eax, eax

.branch_3a730:
    mov edx, eax
    shl edx, byte 0x2
    add edx, eax
    shl edx, byte 0x2
    mov ebx, frame_state_13960
    add edx, eax
    inc eax
    add ebx, edx
    mov [nosplit eax*4 + frame_state_17458c], ebx
    cmp eax, 0x1
    jl short .branch_3a730
    pop edx
    pop ebx
    ret

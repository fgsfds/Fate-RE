; Initialize game menus.
BITS 32
ORG 0x383d2

frame_state_12e18 equ 0x12e18
frame_state_12ec0 equ 0x12ec0
frame_state_12f68 equ 0x12f68
frame_state_13010 equ 0x13010
frame_state_130e4 equ 0x130e4
load_game_configuration equ 0x3818c
sub_3a345 equ 0x3a345
sub_3a6be equ 0x3a6be
sub_3a6e8 equ 0x3a6e8
sub_3a924 equ 0x3a924
sub_3ae44 equ 0x3ae44
sub_3af04 equ 0x3af04
sub_3b034 equ 0x3b034
frame_state_173fe4 equ 0x173fe4
frame_state_173fec equ 0x173fec
frame_state_17400c equ 0x17400c
frame_state_174024 equ 0x174024
frame_state_1740cc equ 0x1740cc

initialize_game_menus:
    push ebx
    push ecx
    push edx
    xor eax, eax

.branch_383d7:
    mov edx, eax
    shl edx, byte 0x2
    add edx, eax
    shl edx, byte 0x2
    lea ebx, [eax + edx]
    mov ecx, frame_state_12e18
    inc eax
    add ecx, ebx
    add ebx, frame_state_12ec0
    mov [nosplit eax*4 + frame_state_173fec], ecx
    mov [nosplit eax*4 + frame_state_174024], ebx
    cmp eax, 0x8
    jl short .branch_383d7
    xor eax, eax

.branch_38407:
    mov edx, eax
    shl edx, byte 0x2
    add edx, eax
    shl edx, byte 0x2
    mov ebx, frame_state_12f68
    add edx, eax
    inc eax
    add ebx, edx
    mov [nosplit eax*4 + frame_state_17400c], ebx
    cmp eax, 0x6
    jl short .branch_38407
    xor eax, eax

.branch_38429:
    mov edx, eax
    shl edx, byte 0x2
    add edx, eax
    shl edx, byte 0x2
    mov ebx, frame_state_13010
    add edx, eax
    inc eax
    add ebx, edx
    mov [nosplit eax*4 + frame_state_173fe4], ebx
    cmp eax, 0x2
    jl short .branch_38429
    xor eax, eax

.branch_3844b:
    mov edx, eax
    shl edx, byte 0x2
    add edx, eax
    shl edx, byte 0x2
    mov ebx, frame_state_130e4
    add edx, eax
    inc eax
    add ebx, edx
    mov [nosplit eax*4 + frame_state_1740cc], ebx
    cmp eax, 0x5
    jl short .branch_3844b
    call sub_3a345
    call sub_3a6be
    call sub_3ae44
    call sub_3a6e8
    call sub_3a924
    call sub_3b034
    call sub_3af04
    xor eax, eax
    call load_game_configuration
    pop edx
    pop ecx
    pop ebx
    ret

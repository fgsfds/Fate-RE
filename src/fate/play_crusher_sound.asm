; Play crusher sound.
BITS 32
ORG 0x404d6

frame_state_14e9 equ 0x14e9
report_error equ 0x26a03
play_sound equ 0x34f79
player_y equ 0x5ad5c
player_x equ 0x5ad9c

play_crusher_sound:
    push ebx
    push ecx
    push esi
    mov ebx, eax
    test eax, eax
    jnz short .branch_404e9
    mov eax, frame_state_14e9
    call report_error

.branch_404e9:
    cmp edx, 0x1
    mov esi, 0x4
    mov eax, [player_x]
    sub eax, [ebx + 0x29]
    test eax, eax
    jns short .branch_404ff
    neg eax

.branch_404ff:
    mov edx, eax
    mov ecx, [ebx + 0x2d]
    mov eax, [player_y]
    sub eax, ecx
    test eax, eax
    jns short .branch_40511
    neg eax

.branch_40511:
    add eax, edx
    cmp eax, strict dword 0x21e2
    jnl short .branch_4052b
    mov eax, [ebx + 0x2d]
    mov edx, [ebx + 0x29]
    xor ecx, ecx
    mov ebx, eax
    mov eax, esi
    call play_sound

.branch_4052b:
    pop esi
    pop ecx
    pop ebx
    ret

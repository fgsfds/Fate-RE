; Run settings menu.
BITS 32
ORG 0x39756

frame_state_c77 equ 0xc77
save_game_configuration equ 0x38291
run_menu_loop equ 0x3963b
sub_3a65c equ 0x3a65c
sub_3ade2 equ 0x3ade2
frame_state_1740cc equ 0x1740cc
frame_state_1740d0 equ 0x1740d0

    db 0x8b, 0xc0 ; original two-byte alignment

settings_dispatch:
    dd run_settings_menu.menu_case_39781 - 0x10000
    dd run_settings_menu.menu_case_397ca - 0x10000
    dd run_settings_menu.menu_case_39786 - 0x10000
    dd run_settings_menu.menu_case_3978d - 0x10000
    dd run_settings_menu.menu_case_397d1 - 0x10000

run_settings_menu:
    push ebx
    push ecx
    push edx
    mov ebx, 0x4
    mov edx, 0x1
    mov [frame_state_1740cc], ebx
    jmp short .branch_3978d
.menu_case_39781:
    call sub_3a65c

.branch_39786:
.menu_case_39786:
    xor eax, eax
    call save_game_configuration

.branch_3978d:
.menu_case_3978d:
    test edx, edx
    jz short .branch_397d5
    mov ebx, 0x820
    push strict dword frame_state_1740d0
    mov ecx, frame_state_c77
    mov edx, 0x5
    mov eax, frame_state_1740cc
    movsx ebx, bx
    call run_menu_loop
    mov edx, eax
    test eax, eax
    jz short .branch_3978d
    mov eax, [frame_state_1740cc]
    cmp eax, 0x4
    ja short .branch_3978d
    jmp dword near [cs:eax*4 + settings_dispatch - 0x10000]
.menu_case_397ca:
    call sub_3ade2
    jmp short .branch_39786
.menu_case_397d1:
    xor edx, edx
    jmp short .branch_3978d

.branch_397d5:
    mov eax, edx
    pop edx
    pop ecx
    pop ebx
    ret

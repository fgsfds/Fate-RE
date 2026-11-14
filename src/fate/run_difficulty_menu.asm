; Run difficulty menu.
BITS 32
ORG 0x3ae6b

frame_state_128b equ 0x128b
run_menu_loop equ 0x3963b
difficulty_divisor equ 0x7deec
frame_state_1745d0 equ 0x1745d0
frame_state_1745e0 equ 0x1745e0

    nop

difficulty_dispatch:
    dd run_difficulty_menu.menu_case_3aec1 - 0x10000
    dd run_difficulty_menu.menu_case_3aed6 - 0x10000
    dd run_difficulty_menu.menu_case_3aeeb - 0x10000
    dd run_difficulty_menu.menu_case_3af00 - 0x10000

run_difficulty_menu:
    push ebx
    push ecx
    push edx
    mov eax, 0x1

.branch_3ae84:
    test eax, eax
    jz near .branch_3aed2
    push strict dword frame_state_1745d0
    mov ecx, frame_state_128b
    mov ebx, 0x820
    mov edx, 0x4
    mov eax, frame_state_1745e0
    call run_menu_loop
    test eax, eax
    jz short .branch_3ae84
    mov edx, [frame_state_1745e0]
    cmp edx, 0x3
    ja short .branch_3ae84
    jmp dword near [cs:edx*4 + difficulty_dispatch - 0x10000]
.menu_case_3aec1:
    mov ecx, 0x4
    mov eax, 0x1
    mov [difficulty_divisor], cx

.branch_3aed2:
    pop edx
    pop ecx
    pop ebx
    ret
.menu_case_3aed6:
    mov ebx, 0x2
    mov eax, 0x2
    mov [difficulty_divisor], bx
    pop edx
    pop ecx
    pop ebx
    ret
.menu_case_3aeeb:
    mov edx, 0x1
    mov eax, 0x3
    mov [difficulty_divisor], dx
    pop edx
    pop ecx
    pop ebx
    ret
.menu_case_3af00:
    xor eax, eax
    jmp short .branch_3ae84

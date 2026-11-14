; Run help submenu.
BITS 32
ORG 0x3a871

frame_state_111b equ 0x111b
run_menu_loop equ 0x3963b
branch_3a86d equ 0x3a86d
frame_state_17457c equ 0x17457c
frame_state_174590 equ 0x174590

run_help_submenu:
    push ebx
    push ecx
    push edx
    mov eax, 0x1

.branch_3a879:
    cmp eax, 0x1
    jnz short branch_3a86d
    push strict dword frame_state_174590
    mov ecx, frame_state_111b
    mov ebx, 0x83e
    mov edx, eax
    mov eax, frame_state_17457c
    call run_menu_loop
    test eax, eax
    jz short .branch_3a879
    mov edx, [frame_state_17457c]
    test edx, edx
    jnz short .branch_3a879
    xor eax, eax
    jmp short .branch_3a879

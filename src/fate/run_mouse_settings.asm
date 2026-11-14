; Run mouse settings.
BITS 32
ORG 0x3ade2

frame_state_125b equ 0x125b
run_menu_loop equ 0x3963b
run_mouse_sensitivity_menu equ 0x3aaa9
run_mouse_button_menu equ 0x3abbc
frame_state_1745ac equ 0x1745ac
frame_state_1745bc equ 0x1745bc

run_mouse_settings:
    push ebx
    push ecx
    push edx
    mov edx, 0x1

.branch_3adea:
    test edx, edx
    jz short .branch_3ae3e
    mov ebx, 0x820
    push strict dword frame_state_1745bc
    mov ecx, frame_state_125b
    mov edx, 0x3
    mov eax, frame_state_1745ac
    movsx ebx, bx
    call run_menu_loop
    mov edx, eax
    test eax, eax
    jz short .branch_3adea
    mov eax, [frame_state_1745ac]
    cmp eax, 0x1
    jc short .branch_3ae28
    jna short .branch_3ae33
    cmp eax, 0x2
    jz short .branch_3ae3a
    jmp short .branch_3adea

.branch_3ae28:
    test eax, eax
    jnz short .branch_3adea
    call run_mouse_sensitivity_menu
    jmp short .branch_3adea

.branch_3ae33:
    call run_mouse_button_menu
    jmp short .branch_3adea

.branch_3ae3a:
    xor edx, edx
    jmp short .branch_3adea

.branch_3ae3e:
    mov eax, edx
    pop edx
    pop ecx
    pop ebx
    ret

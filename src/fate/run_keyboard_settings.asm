; Run keyboard settings.
BITS 32
ORG 0x3a65c

frame_state_10c7 equ 0x10c7
run_menu_loop equ 0x3963b
confirm_reset_key_bindings equ 0x3a443
run_key_binding_menu equ 0x3a492
frame_state_1741e8 equ 0x1741e8
frame_state_174260 equ 0x174260

run_keyboard_settings:
    push ebx
    push ecx
    push edx
    mov edx, 0x1

.branch_3a664:
    test edx, edx
    jz short .branch_3a6b8
    mov ebx, 0x820
    push strict dword frame_state_1741e8
    mov ecx, frame_state_10c7
    mov edx, 0x3
    mov eax, frame_state_174260
    movsx ebx, bx
    call run_menu_loop
    mov edx, eax
    test eax, eax
    jz short .branch_3a664
    mov eax, [frame_state_174260]
    cmp eax, 0x1
    jc short .branch_3a6a2
    jna short .branch_3a6ad
    cmp eax, 0x2
    jz short .branch_3a6b4
    jmp short .branch_3a664

.branch_3a6a2:
    test eax, eax
    jnz short .branch_3a664
    call run_key_binding_menu
    jmp short .branch_3a664

.branch_3a6ad:
    call confirm_reset_key_bindings
    jmp short .branch_3a664

.branch_3a6b4:
    xor edx, edx
    jmp short .branch_3a664

.branch_3a6b8:
    mov eax, edx
    pop edx
    pop ecx
    pop ebx
    ret

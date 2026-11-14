; Confirm reset key bindings.
BITS 32
ORG 0x3a443

frame_state_1086 equ 0x1086
run_menu_loop equ 0x3963b
reset_key_bindings equ 0x3a42c
frame_state_1741e0 equ 0x1741e0
frame_state_174258 equ 0x174258

confirm_reset_key_bindings:
    push ebx
    push ecx
    push edx
    mov eax, 0x1

.branch_3a44b:
    test eax, eax
    jz short .branch_3a48e
    mov ebx, 0x834
    push strict dword frame_state_1741e0
    mov ecx, frame_state_1086
    mov edx, 0x2
    mov eax, frame_state_174258
    movsx ebx, bx
    call run_menu_loop
    test eax, eax
    jz short .branch_3a44b
    mov edx, [frame_state_174258]
    test edx, edx
    jna short .branch_3a485
    cmp edx, 0x1
    jz short .branch_3a48a
    jmp short .branch_3a44b

.branch_3a485:
    call reset_key_bindings

.branch_3a48a:
    xor eax, eax
    jmp short .branch_3a44b

.branch_3a48e:
    pop edx
    pop ecx
    pop ebx
    ret

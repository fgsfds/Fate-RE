; Confirm menu action.
BITS 32
ORG 0x3a0ce

confirm_menu_title equ 0xd65
run_menu_loop equ 0x3963b
frame_state_173fe8 equ 0x173fe8
frame_state_1740e4 equ 0x1740e4

confirm_menu_action:
    push ebx
    push ecx
    push edx
    push esi
    mov eax, 0x1
    xor esi, esi
    jmp short .branch_3a0e2

.branch_3a0db:
    mov esi, 0x1

.branch_3a0e0:
    xor eax, eax

.branch_3a0e2:
    test eax, eax
    jz short .branch_3a120
    mov ebx, 0x820
    push strict dword frame_state_173fe8
    mov ecx, confirm_menu_title
    mov edx, 0x2
    mov eax, frame_state_1740e4
    movsx ebx, bx
    call run_menu_loop
    test eax, eax
    jz short .branch_3a0e2
    mov edx, [frame_state_1740e4]
    test edx, edx
    jna short .branch_3a0db
    cmp edx, 0x1
    jz short .branch_3a11c
    jmp short .branch_3a0e2

.branch_3a11c:
    xor esi, esi
    jmp short .branch_3a0e0

.branch_3a120:
    mov eax, esi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

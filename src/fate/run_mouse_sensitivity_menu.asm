; Run mouse sensitivity menu.
BITS 32
ORG 0x3aaa9

frame_state_120e equ 0x120e
frame_state_1220 equ 0x1220
frame_state_1224 equ 0x1224
scale_x equ 0x13a81
scale_y equ 0x13a85
run_menu_loop equ 0x3963b
truncate_x87 equ 0x60304
frame_state_1745b0 equ 0x1745b0
frame_state_1745b4 equ 0x1745b4
frame_state_1745c8 equ 0x1745c8

run_mouse_sensitivity_menu:
    push ebx
    push ecx
    push edx
    sub esp, 0x8
    fld dword [scale_x]
    fmul dword [frame_state_1220]
    call truncate_x87
    fistp dword [esp + 0x4]
    mov ebx, [frame_state_1745b0]
    mov eax, [esp + 0x4]
    mov [ebx + 0x7], eax
    mov eax, [frame_state_1745b0]
    mov dword [eax + 0xb], 0x10
    fld dword [scale_y]
    fmul dword [frame_state_1220]
    call truncate_x87
    fistp dword [esp + 0x4]
    mov ebx, [frame_state_1745b4]
    mov eax, [esp + 0x4]
    mov [ebx + 0x7], eax
    mov eax, [frame_state_1745b4]
    mov edx, 0x1
    mov dword [eax + 0xb], 0x10

.branch_3ab10:
    test edx, edx
    jz near .branch_3abb3
    mov ebx, 0x820
    push strict dword frame_state_1745b0
    mov ecx, frame_state_120e
    mov edx, 0x3
    mov eax, frame_state_1745c8
    movsx ebx, bx
    call run_menu_loop
    mov edx, eax
    test eax, eax
    jz short .branch_3ab10
    mov eax, [frame_state_1745b0]
    cmp dword [eax + 0x7], 0x1
    jnl short .branch_3ab51
    mov dword [eax + 0x7], 0x1

.branch_3ab51:
    mov eax, [frame_state_1745b4]
    cmp dword [eax + 0x7], 0x1
    jnl short .branch_3ab63
    mov dword [eax + 0x7], 0x1

.branch_3ab63:
    mov eax, [frame_state_1745b0]
    fild dword [eax + 0x7]
    fdiv qword [frame_state_1224]
    fstp dword [esp]
    mov eax, [esp]
    mov [scale_x], eax
    mov eax, [frame_state_1745b4]
    fild dword [eax + 0x7]
    fdiv qword [frame_state_1224]
    fstp dword [esp]
    mov eax, [esp]
    mov [scale_y], eax
    mov eax, [frame_state_1745c8]
    cmp eax, 0x1
    jna near .branch_3ab10
    cmp eax, 0x2
    jnz near .branch_3ab10
    xor edx, edx
    jmp near .branch_3ab10

.branch_3abb3:
    mov eax, edx
    add esp, 0x8
    pop edx
    pop ecx
    pop ebx
    ret

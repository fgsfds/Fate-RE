; Run control limits menu.
BITS 32
ORG 0x3b05b

frame_state_130c equ 0x130c
strafe_limit equ 0x13b9f
strafe_step equ 0x13ba3
run_menu_loop equ 0x3963b
frame_state_174604 equ 0x174604
frame_state_174608 equ 0x174608
frame_state_17460c equ 0x17460c

run_control_limits_menu:
    push ebx
    push ecx
    push edx
    push esi
    mov ebx, 0x1
    mov edx, [strafe_limit]
    add edx, ebx
    mov eax, edx
    sar edx, byte 0x1f
    shl edx, byte 0x4
    db 0x1b, 0xc2 ; sbb eax, edx in the original register encoding
    sar eax, byte 0x4
    mov edx, eax
    mov eax, [frame_state_174608]
    mov [eax + 0x7], edx
    mov eax, [frame_state_174608]
    mov dword [eax + 0xb], 0x10
    mov eax, [frame_state_17460c]
    mov edx, [strafe_step]
    mov [eax + 0x7], edx
    mov eax, [frame_state_17460c]
    mov dword [eax + 0xb], 0x10

.branch_3b0a9:
    test ebx, ebx
    jz near .branch_3b144
    mov ebx, 0x821
    push strict dword frame_state_174608
    mov ecx, frame_state_130c
    mov edx, 0x3
    mov eax, frame_state_174604
    movsx ebx, bx
    call run_menu_loop
    mov ebx, eax
    test eax, eax
    jz short .branch_3b0a9
    mov eax, [frame_state_174608]
    cmp dword [eax + 0x7], 0x3
    jnl short .branch_3b0ea
    mov dword [eax + 0x7], 0x3

.branch_3b0ea:
    mov eax, [frame_state_17460c]
    cmp dword [eax + 0x7], 0x3
    jnl short .branch_3b0fc
    mov dword [eax + 0x7], 0x3

.branch_3b0fc:
    mov eax, [frame_state_174608]
    mov eax, [eax + 0x7]
    shl eax, byte 0x4
    mov [strafe_limit], eax
    mov esi, [strafe_limit]
    dec esi
    mov eax, [frame_state_17460c]
    mov [strafe_limit], esi
    mov eax, [eax + 0x7]
    mov [strafe_step], eax
    mov eax, [frame_state_174604]
    cmp eax, 0x1
    jna near .branch_3b0a9
    cmp eax, 0x2
    jnz near .branch_3b0a9
    xor ebx, ebx
    jmp near .branch_3b0a9

.branch_3b144:
    mov eax, ebx
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

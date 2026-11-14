; Prepare and submit an IPX packet to the DOS driver.
BITS 32
ORG 0x41d59

frame_state_13e64 equ 0x13e64
simulate_network_interrupt equ 0x42ffc
memcpy equ 0x63245
frame_state_186d88 equ 0x186d88
frame_state_18fd98 equ 0x18fd98
frame_state_18fdac equ 0x18fdac
frame_state_18fdc0 equ 0x18fdc0
frame_state_18fde0 equ 0x18fde0
frame_state_18fdec equ 0x18fdec

send_ipx_packet:
    push ebx
    push ecx
    sub esp, 0x4
    mov ecx, eax
    mov [esp], dx
    mov eax, 0x7fff
    mov edx, [frame_state_18fde0]

.branch_41d6f:
    cmp byte [edx + 0x8], 0x0
    jz short .branch_41d7c
    test eax, eax
    jng short .branch_41d7c
    dec eax
    jmp short .branch_41d6f

.branch_41d7c:
    xor eax, eax
    jmp short .branch_41d8b

.branch_41d80:
    mov edx, [frame_state_18fdac]
    mov byte [edx + eax], 0x0
    inc eax

.branch_41d8b:
    cmp eax, 0x1e
    jl short .branch_41d80
    xor eax, eax
    jmp short .branch_41d9f

.branch_41d94:
    mov edx, [frame_state_18fde0]
    mov byte [edx + eax], 0x0
    inc eax

.branch_41d9f:
    cmp eax, 0x30
    jl short .branch_41d94
    mov eax, [frame_state_18fdac]
    mov byte [eax + 0x5], 0x4
    test cx, cx
    jnl short .branch_41e23
    mov ebx, 0x4
    mov eax, [frame_state_18fdac]
    mov edx, frame_state_186d88
    add eax, 0x6
    call memcpy
    mov eax, [frame_state_18fdac]
    mov byte [eax + 0xa], 0xff
    mov eax, [frame_state_18fdac]
    mov byte [eax + 0xb], 0xff
    mov eax, [frame_state_18fdac]
    mov byte [eax + 0xc], 0xff
    mov eax, [frame_state_18fdac]
    mov byte [eax + 0xd], 0xff
    mov eax, [frame_state_18fdac]
    mov byte [eax + 0xe], 0xff
    mov eax, [frame_state_18fdac]
    mov byte [eax + 0xf], 0xff
    mov eax, [frame_state_18fdac]
    mov dl, [frame_state_13e64]
    mov [eax + 0x10], dl
    movsx eax, word [frame_state_13e64]
    sar eax, byte 0x8
    mov dl, al
    mov eax, [frame_state_18fdac]
    mov [eax + 0x11], dl
    jmp short .branch_41e49

.branch_41e23:
    movsx edx, cx
    mov eax, edx
    shl eax, byte 0x2
    sub eax, edx
    mov edx, frame_state_186d88
    shl eax, byte 0x2
    add edx, eax
    mov eax, [frame_state_18fdac]
    mov ebx, 0xc
    add eax, 0x6
    call memcpy

.branch_41e49:
    mov eax, [frame_state_18fde0]
    mov dl, [frame_state_13e64]
    mov [eax + 0xa], dl
    movsx eax, word [frame_state_13e64]
    sar eax, byte 0x8
    mov dl, al
    mov eax, [frame_state_18fde0]
    mov [eax + 0xb], dl
    test cx, cx
    jnl short .branch_41ea8
    mov eax, [frame_state_18fde0]
    mov byte [eax + 0x1c], 0xff
    mov eax, [frame_state_18fde0]
    mov byte [eax + 0x1d], 0xff
    mov eax, [frame_state_18fde0]
    mov byte [eax + 0x1e], 0xff
    mov eax, [frame_state_18fde0]
    mov byte [eax + 0x1f], 0xff
    mov eax, [frame_state_18fde0]
    mov byte [eax + 0x20], 0xff
    mov eax, [frame_state_18fde0]
    mov byte [eax + 0x21], 0xff
    jmp short .branch_41ecf

.branch_41ea8:
    movsx edx, cx
    mov eax, edx
    shl eax, byte 0x2
    sub eax, edx
    shl eax, byte 0x2
    add eax, frame_state_186d88
    lea edx, [eax + 0x4]
    mov eax, [frame_state_18fde0]
    mov ebx, 0x6
    add eax, 0x1c
    call memcpy

.branch_41ecf:
    mov eax, [frame_state_18fde0]
    mov byte [eax + 0x22], 0x2
    mov eax, [frame_state_18fde0]
    mov byte [eax + 0x23], 0x0
    mov dl, [frame_state_18fdac]
    mov bh, [frame_state_18fdc0]
    mov eax, [frame_state_18fde0]
    sub dl, bh
    mov [eax + 0x24], dl
    mov eax, [frame_state_18fdac]
    sub eax, [frame_state_18fdc0]
    sar eax, byte 0x8
    mov dl, al
    mov eax, [frame_state_18fde0]
    mov [eax + 0x25], dl
    mov eax, [frame_state_18fde0]
    mov dl, [frame_state_18fdec]
    mov [eax + 0x26], dl
    mov eax, [frame_state_18fdec]
    sar eax, byte 0x8
    mov dl, al
    mov eax, [frame_state_18fde0]
    mov [eax + 0x27], dl
    mov eax, [frame_state_18fde0]
    mov byte [eax + 0x28], 0x1e
    mov eax, [frame_state_18fde0]
    mov byte [eax + 0x29], 0x0
    mov dl, [frame_state_18fd98]
    mov cl, [frame_state_18fdc0]
    mov eax, [frame_state_18fde0]
    sub dl, cl
    mov [eax + 0x2a], dl
    mov eax, [frame_state_18fd98]
    sub eax, [frame_state_18fdc0]
    sar eax, byte 0x8
    mov dl, al
    mov eax, [frame_state_18fde0]
    mov [eax + 0x2b], dl
    mov eax, [frame_state_18fde0]
    mov dl, [frame_state_18fdec]
    mov [eax + 0x2c], dl
    mov edx, [frame_state_18fdec]
    mov eax, [frame_state_18fde0]
    sar edx, byte 0x8
    mov [eax + 0x2d], dl
    mov eax, [frame_state_18fde0]
    mov dl, [esp]
    mov [eax + 0x2e], dl
    movsx eax, word [esp]
    sar eax, byte 0x8
    mov dl, al
    mov eax, [frame_state_18fde0]
    mov [eax + 0x2f], dl
    push strict byte 0x0
    mov ecx, [frame_state_18fde0]
    push ecx
    mov ebx, 0x3
    mov eax, 0x7a
    push strict byte 0x0
    xor edx, edx
    xor ecx, ecx
    call simulate_network_interrupt
    add esp, 0x4
    pop ecx
    pop ebx
    ret

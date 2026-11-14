; Check the shorter wall list for a portal linking the two sectors.
BITS 32
ORG 0x2f3ce

wall_next_sector equ 0x2310ac
sectors equ 0x27c3a0
sector_wall_count equ 0x27c3a2

sectors_share_portal:
    push ebx
    push ecx
    push esi
    push edi
    sub esp, 0x4
    mov edi, eax
    mov esi, edx
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x2
    movsx ecx, si
    add ebx, edx
    mov edx, ecx
    shl ebx, byte 0x3
    shl edx, byte 0x2
    mov ax, [ebx + sector_wall_count]
    add edx, ecx
    mov [esp], eax
    shl edx, byte 0x3
    mov ecx, [esp]
    mov ax, [edx + sector_wall_count]
    cmp ax, cx
    jng short .branch_2f43b
    mov eax, ecx
    mov bx, [ebx + sectors]
    dec eax
    movsx ecx, bx
    jmp short .branch_2f434

.branch_2f41b:
    movsx edx, ax
    add edx, ecx
    shl edx, byte 0x5
    cmp si, [edx + wall_next_sector]
    jnz short .branch_2f433

.branch_2f42c:
    mov edx, 0x1
    jmp short .branch_2f461

.branch_2f433:
    dec eax

.branch_2f434:
    test ax, ax
    jnl short .branch_2f41b
    jmp short .branch_2f45f

.branch_2f43b:
    mov bx, [edx + sectors]
    dec eax
    movsx ecx, bx
    jmp short .branch_2f45a

.branch_2f448:
    movsx edx, ax
    add edx, ecx
    shl edx, byte 0x5
    cmp di, [edx + wall_next_sector]
    jz short .branch_2f42c
    dec eax

.branch_2f45a:
    test ax, ax
    jnl short .branch_2f448

.branch_2f45f:
    xor edx, edx

.branch_2f461:
    mov eax, edx
    add esp, 0x4
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

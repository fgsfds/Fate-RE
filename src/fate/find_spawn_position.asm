; Search for a usable spawn position and resolve wall clipping.
BITS 32
ORG 0x2e5fc

inside equ 0x4c88f
pushmove equ 0x53edd
krand equ 0x562e5
walls equ 0x2310a0
engine_2310a4 equ 0x2310a4
sectors equ 0x27c3a0
sector_wall_count equ 0x27c3a2
ceil_base equ 0x27c3a4
floor_base equ 0x27c3a8
floor_flags equ 0x27c3ae
sector_lotag equ 0x27c3c2
sector_hitag equ 0x27c3c4
numsectors equ 0x289154

find_spawn_position:
    push ecx
    push esi
    push edi
    push ebp
    sub esp, 0x1c
    push eax
    push edx
    push ebx
    mov dword [esp + 0x18], 0x100
    jmp near .branch_2e7e4

.branch_2e613:
    mov dx, [numsectors]
    movsx ebx, dx
    call krand
    imul ebx
    shrd eax, edx, byte 0x10
    movsx edx, ax
    mov [esp + 0x20], eax
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    shl eax, byte 0x3
    mov edx, [eax + ceil_base]
    mov ecx, [eax + floor_base]
    add edx, strict dword 0x800
    cmp edx, ecx
    jnl short .branch_2e613
    mov dx, [eax + sector_hitag]
    xor dh, dh
    movsx ecx, dx
    movsx edx, word [eax + sector_lotag]
    or edx, ecx
    jnz short .branch_2e613
    mov dx, [eax + floor_flags]
    xor dh, dh
    and dl, 0x1
    movsx edx, dx
    test edx, edx
    jnz short .branch_2e613
    mov dx, [eax + sectors]
    mov bx, [eax + sector_wall_count]
    mov [esp + 0x24], edx
    add edx, ebx
    mov ecx, [esp + 0x24]
    mov [esp + 0x1c], edx
    cmp dx, cx
    jng near .branch_2e7e0
    mov ecx, 0x7fffffff
    xor esi, esi
    mov ebx, [esp + 0x24]
    mov [esp + 0x14], esi
    mov [esp + 0x10], esi
    mov esi, 0x80000000
    mov edi, ecx
    mov ebp, esi
    jmp short .branch_2e719

.branch_2e6bc:
    movsx edx, bx
    shl edx, byte 0x5
    mov eax, [edx + walls]
    add [esp + 0x14], eax
    mov eax, [edx + engine_2310a4]
    add [esp + 0x10], eax
    mov eax, [edx + walls]
    cmp ecx, eax
    jng short .branch_2e6e2
    mov ecx, eax

.branch_2e6e2:
    movsx eax, bx
    shl eax, byte 0x5
    mov edx, [eax + walls]
    cmp esi, edx
    jnl short .branch_2e6f4
    mov esi, edx

.branch_2e6f4:
    movsx eax, bx
    shl eax, byte 0x5
    mov edx, [eax + engine_2310a4]
    cmp edi, edx
    jng short .branch_2e706
    mov edi, edx

.branch_2e706:
    movsx eax, bx
    shl eax, byte 0x5
    mov edx, [eax + engine_2310a4]
    cmp ebp, edx
    jnl short .branch_2e718
    mov ebp, edx

.branch_2e718:
    inc ebx

.branch_2e719:
    mov eax, [esp + 0x1c]
    cmp bx, ax
    jl short .branch_2e6bc
    sub esi, ecx
    cmp esi, strict dword 0x100
    jng near .branch_2e7e0
    sub ebp, edi
    cmp ebp, strict dword 0x100
    jng near .branch_2e7e0
    movsx ebx, ax
    movsx eax, word [esp + 0x24]
    sub ebx, eax
    mov eax, [esp + 0x14]
    mov edx, eax
    sar edx, byte 0x1f
    idiv ebx
    mov [esp + 0x14], eax
    mov eax, [esp + 0x10]
    mov edx, eax
    sar edx, byte 0x1f
    idiv ebx
    movsx ebx, word [esp + 0x20]
    mov [esp + 0x10], eax
    mov edx, eax
    mov eax, [esp + 0x14]
    call inside
    test eax, eax
    jz short .branch_2e7e0
    movsx edx, word [esp + 0x20]
    push strict byte 0x0
    mov eax, edx
    push strict dword 0x400
    shl eax, byte 0x2
    lea ecx, [esp + 0x28]
    add eax, edx
    push strict dword 0x400
    lea ebx, [esp + 0x18]
    mov eax, [nosplit eax*8 + floor_base]
    push strict dword 0x80
    sub eax, strict dword 0x2000
    lea edx, [esp + 0x20]
    mov [esp + 0x1c], eax
    lea eax, [esp + 0x24]
    call pushmove
    test eax, eax
    jl short .branch_2e7e0
    mov edx, [esp + 0x8]
    mov eax, [esp + 0x14]
    mov [edx], eax
    mov edx, [esp + 0x4]
    mov eax, [esp + 0x10]
    mov [edx], eax
    mov edx, [esp]
    mov eax, [esp + 0x20]
    mov [edx], ax
    jmp short .branch_2e7ef

.branch_2e7e0:
    dec dword [esp + 0x18]

.branch_2e7e4:
    cmp dword [esp + 0x18], 0x0
    jnl near .branch_2e613

.branch_2e7ef:
    add esp, 0x28
    pop ebp
    pop edi
    pop esi
    pop ecx
    ret

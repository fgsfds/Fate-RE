; Flatten sprite.
BITS 32
ORG 0x40991

bad_sprite_sector_error equ 0x1710
report_error equ 0x26a03
tilesizy equ 0x1f4020
sprite equ 0x2040a0
sectors equ 0x27c3a0
numsectors equ 0x289154

flatten_sprite:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    cwde
    imul eax, eax, 0x2c
    mov edx, sprite
    add edx, eax
    mov bx, [edx + 0x18]
    test bx, bx
    jl short .branch_409b4
    cmp bx, [numsectors]
    jl short .branch_409be

.branch_409b4:
    mov eax, bad_sprite_sector_error
    call report_error

.branch_409be:
    movsx ebx, word [edx + 0x18]
    mov eax, ebx
    shl eax, byte 0x2
    add eax, ebx
    movsx ebx, word [edx + 0xe]
    movsx ecx, word [nosplit ebx*2 + tilesizy]
    xor ebx, ebx
    mov bl, [edx + 0x15]
    imul ecx, ebx
    mov bx, [edx + 0xc]
    xor bh, bh
    shl eax, byte 0x3
    and bl, 0x80
    add eax, sectors
    movsx ebx, bx
    add ecx, ecx
    test ebx, ebx
    jnz short .branch_40a18
    mov ebx, [edx + 0x8]
    mov ecx, [eax + 0x8]
    cmp ebx, ecx
    jz short .branch_40a41
    mov esi, [eax + 0x4]
    lea ebx, [ecx + esi]
    sar ebx, 1
    mov [edx + 0x8], ebx
    mov edi, [eax + 0x8]
    cmp ebx, edi
    jnl short .branch_40a41
    mov [edx + 0x8], edi
    jmp short .branch_40a41

.branch_40a18:
    mov ebx, [eax + 0x8]
    mov esi, [edx + 0x8]
    sub ebx, strict dword 0xc00
    cmp ebx, esi
    jg short .branch_40a41
    mov ebx, [eax + 0x8]
    add ebx, [eax + 0x4]
    sar ebx, 1
    mov [edx + 0x8], ebx
    mov ebp, [eax + 0x8]
    cmp ebx, ebp
    jnl short .branch_40a41
    mov eax, ebp
    sub eax, ecx
    mov [edx + 0x8], eax

.branch_40a41:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

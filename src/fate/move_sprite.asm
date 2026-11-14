; Move a sprite through collision geometry and report the collision.
BITS 32
ORG 0x339b9

change_sprite_sector equ 0x50bc3
clipmove equ 0x5291f
get_z_range equ 0x562f9
ceiling_z equ 0x770a4
floor_z equ 0x770a8
floor_hit equ 0x770b0
ceiling_hit equ 0x770b4
tilesizy equ 0x1f4020
sprite equ 0x2040a0

move_sprite:
    push esi
    push edi
    push ebp
    sub esp, 0xc
    push eax
    push ecx
    cwde
    imul eax, eax, 0x2c
    mov esi, sprite
    add esi, eax
    mov ax, [esi + 0xc]
    xor ah, ah
    and al, 0x80
    cwde
    test eax, eax
    jnz short .branch_339f5
    movsx eax, word [esi + 0xe]
    movsx ecx, word [nosplit eax*2 + tilesizy]
    xor eax, eax
    mov al, [esi + 0x15]
    mov ebp, eax
    imul ebp, ecx
    add ebp, ebp
    neg ebp
    jmp short .branch_339f7

.branch_339f5:
    xor ebp, ebp

.branch_339f7:
    mov ax, [esi + 0x18]
    mov [esp + 0x10], eax
    mov eax, [esi + 0x8]
    add eax, ebp
    mov [esp + 0x8], eax
    xor eax, eax
    mov al, [esp + 0x2c]
    push eax
    mov ecx, [esp + 0x2c]
    push ecx
    xor eax, eax
    mov edi, [esp + 0x2c]
    mov al, [esi + 0x12]
    push edi
    shl eax, byte 0x2
    push eax
    push ebx
    lea ecx, [esp + 0x24]
    push edx
    lea edx, [esi + 0x4]
    lea ebx, [esp + 0x20]
    mov eax, esi
    call clipmove
    mov edx, [esp + 0x10]
    mov edi, eax
    test dx, dx
    jnl short .branch_33a46
    mov edi, 0xffffffff

.branch_33a46:
    mov eax, [esp + 0x10]
    cmp ax, [esi + 0x18]
    jz short .branch_33a62
    test ax, ax
    jl short .branch_33a62
    movsx edx, ax
    movsx eax, word [esp + 0x4]
    call change_sprite_sector

.branch_33a62:
    mov ax, [esi + 0xc]
    mov [esp + 0xc], eax
    and al, 0xfe
    mov [esi + 0xc], ax
    xor eax, eax
    mov al, [esp + 0x2c]
    push eax
    xor eax, eax
    mov al, [esi + 0x12]
    shl eax, byte 0x2
    push eax
    push strict dword floor_hit
    push strict dword ceiling_hit
    movsx ecx, word [esi + 0x18]
    push strict dword floor_z
    mov ebx, [esi + 0x8]
    mov edx, [esi + 0x4]
    push strict dword ceiling_z
    dec ebx
    mov eax, [esi]
    call get_z_range
    mov eax, [esp + 0xc]
    mov [esi + 0xc], ax
    mov eax, [esi + 0x8]
    mov edx, [esp]
    add eax, ebp
    add edx, eax
    mov [esp + 0x8], edx
    mov eax, edx
    cmp eax, [ceiling_z]
    jng short .branch_33ace
    cmp eax, [ceiling_hit]
    jng short .branch_33adf

.branch_33ace:
    test di, di
    jnz short .branch_33ae4
    movsx eax, word [esp + 0x10]
    add eax, strict dword 0x4000
    jmp short .branch_33ae7

.branch_33adf:
    sub eax, ebp
    mov [esi + 0x8], eax

.branch_33ae4:
    movsx eax, di

.branch_33ae7:
    add esp, 0x14
    pop ebp
    pop edi
    pop esi
    ret word 0xc

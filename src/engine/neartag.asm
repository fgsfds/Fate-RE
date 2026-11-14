; Trace a direction for tagged walls, sectors, and sprites.
BITS 32
ORG 0x51fc1

sintable equ 0x2300a0
clipsectorlist equ 0x195f50
sector equ 0x27c3a0
wall equ 0x2310a0
headspritesect equ 0x28891e
sprite equ 0x2040a0
tilesizy equ 0x1f4020
picanm equ 0x1ed3a0
tilesizx equ 0x1f2020
nextspritesect equ 0x1f9ca0
lintersect equ 0x5261d

neartag_:
    push esi
    push edi
    push ebp
    sub esp, 0x5c
    mov edi, dword [esp + 0x80]
    mov dword [esp + 0x40], eax
    mov dword [esp + 0x28], edx
    mov dword [esp + 0x20], ebx
    mov eax, dword [esp + 0x70]
    mov word [eax], 0xffff
    mov eax, dword [esp + 0x74]
    mov word [eax], 0xffff
    mov eax, dword [esp + 0x78]
    mov word [eax], 0xffff
    mov eax, dword [esp + 0x7c]
    mov dword [eax], 0
    test cx, cx
    jl near .restore_stack
    xor eax, eax
    mov al, byte [esp + 0x84]
    cmp eax, 1
    jl near .restore_stack
    cmp eax, 3
    jg near .restore_stack
    movsx esi, word [esp + 0x6c]
    lea eax, [esi + 0xa00]
    and eax, 0x7ff
    mov ax, word [nosplit eax*2 + sintable]
    mov ebx, edi
    cwde
    imul ebx
    shrd eax, edx, 0xe
    mov edx, dword [esp + 0x40]
    mov dword [esp + 0x3c], eax
    add edx, eax
    lea eax, [esi + 0x800]
    and eax, 0x7ff
    mov ax, word [nosplit eax*2 + sintable]
    cwde
    mov dword [esp + 0x34], edx
    imul ebx
    shrd eax, edx, 0xe
    mov edx, dword [esp + 0x28]
    mov dword [esp + 0xc], eax
    mov word [clipsectorlist], cx
    xor ebx, edi
    add edx, eax
    mov dword [esp + 0x2c], ebx
    mov dword [esp + 0x30], edx
    xor edx, edx
    mov ebx, 1
    mov dword [esp + 0x1c], edx
    xor edx, edx
    mov dword [esp + 0x44], ebx
    mov dword [esp + 0x4c], edx

.process_sector:
    movsx eax, word [esp + 0x4c]
    mov ax, word [nosplit eax*2 + clipsectorlist]
    movsx edx, ax
    mov dword [esp + 0x54], eax
    mov eax, edx
    shl eax, 2
    add eax, edx
    mov dx, word [eax*8 + sector]
    mov ax, word [eax*8 + 0x27c3a2]
    add eax, edx
    dec eax
    mov dword [esp + 0x48], eax
    movsx eax, dx
    mov ebp, eax
    shl ebp, 5
    mov dword [esp + 0x24], eax
    add ebp, wall
    jmp near .test_wall

.process_wall:
    movsx eax, word [ebp + 8]
    mov edx, dword [ebp]
    xor ecx, ecx
    shl eax, 5
    mov dword [esp + 0x10], edx
    add eax, wall
    mov word [esp + 0x50], cx
    mov edx, dword [ebp + 4]
    mov edi, dword [eax]
    mov esi, dword [eax + 4]
    mov ax, word [ebp + 0xc]
    mov dword [esp + 0x38], edx
    mov dword [esp + 0x58], eax
    test ax, ax
    jl short .branch_1b1
    mov al, byte [esp + 0x84]
    and al, 1
    and eax, 0xff
    je short .branch_185
    movsx edx, word [esp + 0x58]
    mov eax, edx
    shl eax, 2
    add eax, edx
    cmp word [eax*8 + 0x27c3c2], 0
    je short .branch_185
    mov word [esp + 0x50], 1

.branch_185:
    mov al, byte [esp + 0x84]
    and al, 2
    and eax, 0xff
    je short .branch_1b1
    movsx edx, word [esp + 0x58]
    mov eax, edx
    shl eax, 2
    add eax, edx
    cmp word [eax*8 + 0x27c3c4], 0
    je short .branch_1b1
    or byte [esp + 0x50], 1

.branch_1b1:
    mov al, byte [esp + 0x84]
    and al, 1
    and eax, 0xff
    je short .branch_1cd
    cmp word [ebp + 0x1a], 0
    je short .branch_1cd
    or byte [esp + 0x50], 2

.branch_1cd:
    mov al, byte [esp + 0x84]
    and al, 2
    and eax, 0xff
    je short .branch_1e9
    cmp word [ebp + 0x1c], 0
    je short .branch_1e9
    or byte [esp + 0x50], 2

.branch_1e9:
    cmp word [esp + 0x50], 0
    jne short .branch_1fd
    cmp word [esp + 0x58], 0
    jl near .advance_wall

.branch_1fd:
    mov eax, dword [esp + 0x10]
    mov edx, dword [esp + 0x40]
    mov ebx, dword [esp + 0x28]
    sub eax, edx
    mov edx, esi
    sub edx, ebx
    mov ebx, eax
    imul ebx, edx
    mov ecx, dword [esp + 0x40]
    mov edx, edi
    mov eax, dword [esp + 0x38]
    sub edx, ecx
    sub eax, dword [esp + 0x28]
    imul eax, edx
    cmp ebx, eax
    jl near .advance_wall
    mov eax, esp
    push eax
    lea eax, [esp + 8]
    push eax
    lea eax, [esp + 0x10]
    push eax
    push esi
    push edi
    mov esi, dword [esp + 0x4c]
    push esi
    mov edi, dword [esp + 0x28]
    push edi
    mov eax, dword [esp + 0x48]
    mov edx, dword [esp + 0x4c]
    push eax
    mov ecx, dword [esp + 0x54]
    mov ebx, dword [esp + 0x40]
    push edx
    mov eax, dword [esp + 0x64]
    mov edx, dword [esp + 0x4c]
    call lintersect
    cmp eax, 1
    jne near .advance_wall
    mov esi, dword [esp + 0x50]
    test si, si
    je near .branch_31c
    mov eax, esi
    xor ah, ah
    and al, 1
    cwde
    test eax, eax
    je short .branch_293
    mov edx, dword [esp + 0x70]
    mov eax, dword [esp + 0x58]
    mov word [edx], ax

.branch_293:
    mov eax, dword [esp + 0x50]
    xor ah, ah
    and al, 2
    cwde
    test eax, eax
    je short .branch_2ab
    mov edx, dword [esp + 0x74]
    mov eax, dword [esp + 0x24]
    mov word [edx], ax

.branch_2ab:
    movsx edx, word [esp + 0x6c]
    lea eax, [edx + 0x800]
    mov esi, dword [esp + 4]
    and eax, 0x7ff
    mov ebx, dword [esp + 0x28]
    mov ecx, dword [esp + 0x40]
    mov di, word [nosplit eax*2 + sintable]
    lea eax, [edx + 0xa00]
    sub esi, ebx
    and eax, 0x7ff
    movsx edi, di
    mov dx, word [nosplit eax*2 + sintable]
    mov eax, dword [esp + 8]
    movsx ebx, dx
    sub eax, ecx
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0xe
    mov edx, dword [esp + 0x7c]
    mov dword [edx], eax
    mov eax, dword [esp + 8]
    mov dword [esp + 0x34], eax
    mov eax, dword [esp + 4]
    mov dword [esp + 0x30], eax
    mov eax, dword [esp]
    mov dword [esp + 0x2c], eax

.branch_31c:
    cmp word [esp + 0x58], 0
    jl short .advance_wall
    movsx eax, word [esp + 0x44]
    mov ebx, dword [esp + 0x58]
    jmp short .branch_339

.find_queued_sector:
    cmp bx, word [nosplit eax*2 + clipsectorlist]
    je short .branch_33e

.branch_339:
    dec eax
    test eax, eax
    jge short .find_queued_sector

.branch_33e:
    test eax, eax
    jge short .advance_wall
    movsx eax, word [esp + 0x44]
    mov ecx, dword [esp + 0x44]
    mov edx, dword [esp + 0x58]
    inc ecx
    mov word [nosplit eax*2 + clipsectorlist], dx
    mov dword [esp + 0x44], ecx

.advance_wall:
    mov ecx, dword [esp + 0x24]
    inc ecx
    add ebp, 0x20
    mov dword [esp + 0x24], ecx

.test_wall:
    movsx eax, word [esp + 0x48]
    cmp eax, dword [esp + 0x24]
    jge near .process_wall
    movsx eax, word [esp + 0x54]
    movsx eax, word [nosplit eax*2 + headspritesect]
    jmp near .test_sprite

.process_sprite:
    imul esi, esi, 0x2c
    xor ebx, ebx
    mov al, byte [esp + 0x84]
    mov word [esp + 0x50], bx
    and al, 1
    add esi, sprite
    and eax, 0xff
    je short .branch_3b7
    cmp word [esi + 0x26], 0
    je short .branch_3b7
    mov word [esp + 0x50], 1

.branch_3b7:
    mov al, byte [esp + 0x84]
    and al, 2
    and eax, 0xff
    je short .test_sprite_tags
    cmp word [esi + 0x28], 0
    je short .test_sprite_tags
    or byte [esp + 0x50], 1

.test_sprite_tags:
    cmp word [esp + 0x50], 0
    je near .advance_sprite
    mov eax, dword [esi]
    mov dword [esp + 0x10], eax
    mov eax, dword [esi + 4]
    mov dword [esp + 0x38], eax
    mov eax, dword [esi + 8]
    mov ebp, dword [esp + 0x40]
    mov dword [esp + 0x18], eax
    mov eax, dword [esp + 0x10]
    mov edx, dword [esp + 0x3c]
    sub eax, ebp
    imul eax, edx
    mov ebx, dword [esp + 0x28]
    mov edx, dword [esp + 0x38]
    mov ecx, dword [esp + 0xc]
    sub edx, ebx
    imul edx, ecx
    lea edi, [eax + edx]
    test edi, edi
    jle near .advance_sprite
    mov eax, dword [esp + 0x3c]
    imul eax, eax
    mov ebp, ecx
    imul ebp, ecx
    add ebp, eax
    je near .advance_sprite
    mov eax, dword [esp + 0x1c]
    mov ecx, ebp
    mov ebx, edi
    imul ebx
    idiv ecx
    mov edx, dword [esp + 0x20]
    add edx, eax
    mov dword [esp], edx
    movsx eax, word [esi + 0xe]
    movsx edx, word [nosplit eax*2 + tilesizy]
    xor eax, eax
    mov al, byte [esi + 0x15]
    imul eax, edx
    mov dx, word [esi + 0xc]
    xor dh, dh
    and dl, 0x80
    movsx edx, dx
    test edx, edx
    je short .branch_47a
    mov ebx, dword [esp + 0x18]
    lea edx, [eax + eax]
    add ebx, edx
    mov dword [esp + 0x18], ebx

.branch_47a:
    movsx edx, word [esi + 0xe]
    shl edx, 2
    test byte [edx + picanm+2], 0xff
    je short .branch_4b1
    mov edx, dword [edx + picanm]
    sar edx, 0x10
    xor ebx, ebx
    and edx, 0xff
    mov bl, byte [esi + 0x15]
    movsx edx, dl
    imul edx, ebx
    mov ecx, dword [esp + 0x18]
    shl edx, 2
    sub ecx, edx
    mov dword [esp + 0x18], ecx

.branch_4b1:
    mov edx, dword [esp]
    mov ebx, dword [esp + 0x18]
    cmp edx, ebx
    jg near .advance_sprite
    shl eax, 2
    mov edx, ebx
    mov ecx, dword [esp]
    sub edx, eax
    cmp edx, ecx
    jg near .advance_sprite
    mov eax, dword [esp + 0x38]
    mov edx, dword [esp + 0x28]
    mov ebx, dword [esp + 0x3c]
    sub eax, edx
    imul eax, ebx
    mov ecx, dword [esp + 0x40]
    mov edx, dword [esp + 0x10]
    sub edx, ecx
    imul edx, dword [esp + 0xc]
    sub eax, edx
    mov ecx, ebp
    mov ebx, eax
    mov eax, dword [esp + 0x3c]
    imul ebx
    idiv ecx
    mov dword [esp + 0x14], eax
    mov eax, dword [esp + 0xc]
    imul ebx
    idiv ecx
    imul eax, eax
    mov ebx, dword [esp + 0x14]
    imul ebx, ebx
    add ebx, eax
    movsx eax, word [esi + 0xe]
    movsx edx, word [nosplit eax*2 + tilesizx]
    xor eax, eax
    mov al, byte [esi + 0x14]
    imul eax, edx
    imul eax, eax
    sar eax, 7
    cmp ebx, eax
    jg near .advance_sprite
    mov eax, dword [esp + 0x3c]
    mov ebx, edi
    imul ebx
    idiv ecx
    mov edx, dword [esp + 0x40]
    add edx, eax
    mov eax, dword [esp + 0xc]
    mov dword [esp + 8], edx
    imul ebx
    idiv ecx
    mov edx, dword [esp + 0x28]
    mov esi, dword [esp + 0x40]
    add edx, eax
    mov eax, dword [esp + 8]
    mov edi, dword [esp + 0x28]
    sub eax, esi
    mov dword [esp + 4], edx
    test eax, eax
    jns short .branch_574
    neg eax

.branch_574:
    mov edx, eax
    mov eax, dword [esp + 4]
    sub eax, edi
    test eax, eax
    jns short .branch_582
    neg eax

.branch_582:
    lea ebx, [edx + eax]
    mov eax, dword [esp + 0x34]
    sub eax, esi
    test eax, eax
    jns short .branch_591
    neg eax

.branch_591:
    mov edx, eax
    mov eax, dword [esp + 0x30]
    sub eax, edi
    test eax, eax
    jns short .branch_59f
    neg eax

.branch_59f:
    add eax, edx
    cmp ebx, eax
    jge short .advance_sprite
    mov edx, dword [esp + 0x78]
    mov eax, dword [esp + 0x24]
    mov word [edx], ax
    movsx edx, word [esp + 0x6c]
    lea eax, [edx + 0x800]
    and eax, 0x7ff
    mov ebx, dword [esp + 0x40]
    mov ebp, dword [esp + 4]
    mov si, word [nosplit eax*2 + sintable]
    lea eax, [edx + 0xa00]
    sub ebp, edi
    and eax, 0x7ff
    movsx edi, si
    mov dx, word [nosplit eax*2 + sintable]
    mov eax, dword [esp + 8]
    mov esi, ebp
    sub eax, ebx
    movsx ebx, dx
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0xe
    mov edx, dword [esp + 0x7c]
    mov dword [edx], eax
    mov eax, dword [esp + 8]
    mov dword [esp + 0x34], eax
    mov eax, dword [esp + 4]
    mov dword [esp + 0x30], eax
    mov eax, dword [esp]
    mov dword [esp + 0x2c], eax

.advance_sprite:
    mov eax, dword [esp + 0x24]
    movsx eax, word [nosplit eax*2 + nextspritesect]

.test_sprite:
    mov dword [esp + 0x24], eax
    mov esi, dword [esp + 0x24]
    test esi, esi
    jge near .process_sprite
    mov eax, dword [esp + 0x4c]
    inc eax
    mov edx, dword [esp + 0x44]
    mov dword [esp + 0x4c], eax
    cmp ax, dx
    jl near .process_sector

.restore_stack:
    xor eax, eax
    add esp, 0x5c
    pop ebp
    pop edi
    pop esi
    ret 0x1c

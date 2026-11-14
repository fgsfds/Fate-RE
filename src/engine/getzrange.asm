; Find the nearest floor and ceiling around a movement position.
BITS 32
ORG 0x562f9

clipsectorlist equ 0x195f50
clipsectnum equ 0x28912e
sector equ 0x27c3a0
wall equ 0x2310a0
editstatus equ 0x14185
headspritesect equ 0x28891e
sprite equ 0x2040a0
tilesizy equ 0x1f4020
picanm equ 0x1ed3a0
sintable equ 0x2300a0
tilesizx equ 0x1f2020
nextspritesect equ 0x1f9ca0
getzsofslope equ 0x5e07a
clipinsideboxline equ 0x4c1b2
clipmove_return equ 0x52c82

getzrange_:
    push esi
    push edi
    push ebp
    sub esp, 0x7c
    push eax
    push edx
    push ebx
    mov esi, ecx
    test cx, cx
    jge short .branch_049
    mov eax, dword [esp + 0x98]
    mov dword [eax], 0x80000000
    mov eax, dword [esp + 0x9c]
    mov dword [eax], 0xffffffff
    mov eax, dword [esp + 0xa0]
    mov dword [eax], 0x7fffffff
    mov eax, dword [esp + 0xa4]
    mov dword [eax], 0xffffffff
    jmp near .restore_stack

.branch_049:
    mov eax, dword [esp + 0xa8]
    add eax, 0x401
    mov dword [esp + 0x78], eax
    mov eax, dword [esp + 8]
    mov edx, dword [esp + 0x78]
    sub eax, edx
    mov dword [esp + 0x4c], eax
    mov eax, dword [esp + 4]
    mov ebp, dword [esp + 0xa0]
    sub eax, edx
    mov ebx, dword [esp + 4]
    mov dword [esp + 0x58], eax
    mov eax, dword [esp + 8]
    movsx edi, cx
    add eax, edx
    mov ecx, dword [esp + 0x98]
    mov dword [esp + 0x50], eax
    mov eax, dword [esp + 4]
    push ebp
    add eax, edx
    mov edx, dword [esp + 0xc]
    mov dword [esp + 0x58], eax
    mov eax, edi
    call getzsofslope
    mov eax, dword [esp + 0x9c]
    add edi, 0x4000
    mov edx, dword [esp + 0xa4]
    mov dword [eax], edi
    mov eax, edi
    mov dword [edx], edi
    mov edx, 1
    xor eax, edi
    mov word [clipsectorlist], si
    mov dword [esp + 0x44], eax
    mov word [clipsectnum], dx

.branch_0d9:
    mov eax, dword [esp + 0x44]
    movsx edx, word [nosplit eax*2 + clipsectorlist]
    mov eax, edx
    shl eax, 2
    add eax, edx
    shl eax, 3
    add eax, sector
    movsx edx, word [eax]
    movsx eax, word [eax + 2]
    lea ebx, [edx + eax]
    mov ebp, wall
    mov dword [esp + 0x68], edx
    shl edx, 5
    mov dword [esp + 0x48], ebx
    add ebp, edx
    jmp near .branch_3ff

.branch_115:
    movsx eax, word [ebp + 0xc]
    mov dword [esp + 0x74], eax
    test eax, eax
    jl near .branch_3f3
    movsx eax, word [ebp + 8]
    mov esi, wall
    shl eax, 5
    add esi, eax
    mov edx, dword [esp + 0x4c]
    mov eax, dword [ebp]
    mov edi, dword [esi]
    mov dword [esp + 0x70], eax
    cmp eax, edx
    jge short .branch_14c
    cmp edi, edx
    jl near .branch_3f3

.branch_14c:
    mov eax, dword [esp + 0x70]
    mov ecx, dword [esp + 0x50]
    cmp eax, ecx
    jle short .branch_160
    cmp edi, ecx
    jg near .branch_3f3

.branch_160:
    mov edx, dword [esp + 0x58]
    mov ecx, dword [ebp + 4]
    mov esi, dword [esi + 4]
    cmp ecx, edx
    jge short .branch_176
    cmp esi, edx
    jl near .branch_3f3

.branch_176:
    mov eax, dword [esp + 0x54]
    cmp ecx, eax
    jle short .branch_186
    cmp esi, eax
    jg near .branch_3f3

.branch_186:
    mov ebx, dword [esp + 0x70]
    mov edx, edi
    mov eax, esi
    sub edx, ebx
    mov ebx, dword [esp + 8]
    sub eax, ecx
    sub ebx, dword [esp + 0x70]
    mov dword [esp + 0x5c], eax
    imul ebx, dword [esp + 0x5c]
    mov eax, dword [esp + 4]
    sub eax, ecx
    imul eax, edx
    cmp eax, ebx
    jl near .branch_3f3
    test edx, edx
    jle short .branch_1be
    mov eax, dword [esp + 0x58]
    jmp short .branch_1c2

.branch_1be:
    mov eax, dword [esp + 0x54]

.branch_1c2:
    mov ebx, edx
    sub eax, ecx
    imul ebx, eax
    mov dword [esp + 0x3c], ebx
    cmp dword [esp + 0x5c], 0
    jle short .branch_1da
    mov eax, dword [esp + 0x50]
    jmp short .branch_1de

.branch_1da:
    mov eax, dword [esp + 0x4c]

.branch_1de:
    sub eax, dword [esp + 0x70]
    mov ebx, dword [esp + 0x5c]
    imul ebx, eax
    mov dword [esp + 0x6c], ebx
    mov eax, dword [esp + 0x3c]
    cmp eax, dword [esp + 0x6c]
    jge near .branch_3f3
    cmp byte [esp + 0xac], 0
    jne short .branch_216
    mov ax, word [ebp + 0xe]
    xor ah, ah
    and al, 1
    cwde
    test eax, eax
    jne near .branch_3f3

.branch_216:
    xor eax, eax
    mov al, byte [esp + 0xac]
    cmp eax, 1
    jne short .branch_235
    mov ax, word [ebp + 0xe]
    xor ah, ah
    and al, 0x40
    cwde
    test eax, eax
    jne near .branch_3f3

.branch_235:
    mov eax, dword [esp + 0x74]
    mov dword [esp + 0x40], eax
    mov ebx, dword [esp + 0x40]
    shl eax, 2
    add eax, ebx
    shl eax, 3
    mov bx, word [editstatus]
    add eax, sector
    test bx, bx
    jne short .branch_2a7
    mov bx, word [eax + 0xc]
    xor bh, bh
    and bl, 1
    movsx ebx, bx
    test ebx, ebx
    jne short .branch_284
    mov ebx, dword [eax + 4]
    add ebx, 0x300
    mov dword [esp + 0x40], ebx
    mov ebx, dword [esp]
    cmp ebx, dword [esp + 0x40]
    jle near .branch_3f3

.branch_284:
    mov bx, word [eax + 0xe]
    xor bh, bh
    and bl, 1
    movsx ebx, bx
    test ebx, ebx
    jne short .branch_2a7
    mov eax, dword [eax + 8]
    mov ebx, dword [esp]
    sub eax, 0x300
    cmp eax, ebx
    jle near .branch_3f3

.branch_2a7:
    movsx eax, word [clipsectnum]
    dec eax
    mov ebx, dword [esp + 0x74]
    mov dword [esp + 0x78], eax
    jmp short .branch_2c9

.branch_2b9:
    movsx eax, word [nosplit eax*2 + clipsectorlist]
    cmp eax, ebx
    je short .branch_2d1
    dec dword [esp + 0x78]

.branch_2c9:
    mov eax, dword [esp + 0x78]
    test eax, eax
    jge short .branch_2b9

.branch_2d1:
    cmp dword [esp + 0x78], 0
    jge short .branch_300
    mov ax, word [clipsectnum]
    mov dword [esp + 0x80], eax
    cwde
    mov ebx, dword [esp + 0x74]
    mov word [nosplit eax*2 + clipsectorlist], bx
    mov eax, dword [esp + 0x80]
    inc eax
    mov word [clipsectnum], ax

.branch_300:
    mov eax, dword [esp + 0x4c]
    mov ebx, dword [esp + 0x70]
    add eax, 0x400
    cmp eax, ebx
    jle short .branch_319
    cmp edi, eax
    jl near .branch_3f3

.branch_319:
    mov eax, dword [esp + 0x50]
    mov ebx, dword [esp + 0x70]
    sub eax, 0x400
    cmp eax, ebx
    jge short .branch_332
    cmp edi, eax
    jg near .branch_3f3

.branch_332:
    mov eax, dword [esp + 0x58]
    add eax, 0x400
    cmp ecx, eax
    jge short .branch_347
    cmp esi, eax
    jl near .branch_3f3

.branch_347:
    mov eax, dword [esp + 0x54]
    sub eax, 0x400
    cmp ecx, eax
    jle short .branch_35c
    cmp esi, eax
    jg near .branch_3f3

.branch_35c:
    mov eax, edx
    shl eax, 0xa
    test edx, edx
    jle short .branch_36b
    add dword [esp + 0x3c], eax
    jmp short .branch_36f

.branch_36b:
    sub dword [esp + 0x3c], eax

.branch_36f:
    mov eax, dword [esp + 0x5c]
    mov edi, dword [esp + 0x5c]
    shl eax, 0xa
    test edi, edi
    jle short .branch_384
    sub dword [esp + 0x6c], eax
    jmp short .branch_388

.branch_384:
    add dword [esp + 0x6c], eax

.branch_388:
    mov eax, dword [esp + 0x3c]
    cmp eax, dword [esp + 0x6c]
    jge short .branch_3f3
    lea eax, [esp + 0x28]
    lea ecx, [esp + 0x2c]
    mov ebx, dword [esp + 4]
    mov edx, dword [esp + 8]
    push eax
    movsx eax, word [esp + 0x78]
    call getzsofslope
    mov edx, dword [esp + 0x98]
    mov eax, dword [esp + 0x2c]
    cmp eax, dword [edx]
    jle short .branch_3d0
    mov dword [edx], eax
    mov eax, dword [esp + 0x74]
    mov edx, dword [esp + 0x9c]
    add eax, 0x4000
    mov dword [edx], eax

.branch_3d0:
    mov edx, dword [esp + 0xa0]
    mov eax, dword [esp + 0x28]
    cmp eax, dword [edx]
    jge short .branch_3f3
    mov dword [edx], eax
    mov eax, dword [esp + 0x74]
    mov edx, dword [esp + 0xa4]
    add eax, 0x4000
    mov dword [edx], eax

.branch_3f3:
    mov eax, dword [esp + 0x68]
    inc eax
    add ebp, 0x20
    mov dword [esp + 0x68], eax

.branch_3ff:
    mov eax, dword [esp + 0x68]
    cmp eax, dword [esp + 0x48]
    jl near .branch_115
    mov ebx, dword [esp + 0x44]
    inc ebx
    movsx eax, word [clipsectnum]
    mov dword [esp + 0x44], ebx
    cmp eax, ebx
    jg near .branch_0d9
    xor esi, esi
    mov dword [esp + 0x78], esi
    jmp near .test_sprite_sector

.get_sprite_head:
    movsx eax, word [nosplit edx*2 + clipsectorlist]
    movsx eax, word [nosplit eax*2 + headspritesect]
    jmp near .branch_b64

.process_sprite:
    imul ebp, ebx, 0x2c
    add ebp, sprite
    mov ax, word [ebp + 0xc]
    mov dl, byte [esp + 0xac]
    mov dword [esp + 0x7c], eax
    test dl, dl
    jne short .branch_46a
    xor ah, ah
    and al, 1
    cwde
    test eax, eax
    jne short .branch_48e

.branch_46a:
    xor eax, eax
    mov al, byte [esp + 0xac]
    cmp eax, 1
    jne near .advance_sprite
    mov eax, dword [esp + 0x7c]
    xor al, al
    and ah, 1
    cwde
    test eax, eax
    je near .advance_sprite

.branch_48e:
    mov ebx, dword [esp + 0x7c]
    mov eax, dword [ebp]
    mov ecx, dword [ebp + 4]
    xor dh, dh
    xor bh, bh
    mov dword [esp + 0x70], eax
    and bl, 0x30
    mov byte [esp + 0x84], dh
    cmp bx, 0x10
    jb short .branch_4c5
    jbe near .branch_59f
    cmp bx, 0x20
    je near .branch_723
    jmp near .branch_afa

.branch_4c5:
    test bx, bx
    jne near .branch_afa
    xor eax, eax
    mov al, byte [ebp + 0x12]
    mov esi, dword [esp + 0xa8]
    shl eax, 2
    add eax, esi
    inc eax
    mov edi, dword [esp + 8]
    mov dword [esp + 0x74], eax
    mov eax, dword [esp + 0x70]
    sub eax, edi
    mov edx, dword [esp + 0x74]
    test eax, eax
    jns short .branch_4f8
    neg eax

.branch_4f8:
    cmp eax, edx
    jg near .branch_afa
    mov ebx, dword [esp + 4]
    mov eax, ecx
    sub eax, ebx
    test eax, eax
    jns short .branch_50e
    neg eax

.branch_50e:
    cmp eax, edx
    jg near .branch_afa
    mov eax, dword [ebp + 8]
    mov dword [esp + 0x2c], eax
    movsx eax, word [ebp + 0xe]
    movsx edx, word [nosplit eax*2 + tilesizy]
    xor eax, eax
    mov al, byte [ebp + 0x15]
    imul eax, edx
    add eax, eax
    mov dword [esp + 0x74], eax
    mov eax, dword [esp + 0x7c]
    xor ah, ah
    and al, 0x80
    cwde
    test eax, eax
    je short .branch_54c
    mov eax, dword [esp + 0x74]
    add dword [esp + 0x2c], eax

.branch_54c:
    movsx eax, word [ebp + 0xe]
    shl eax, 2
    test byte [eax + picanm+2], 0xff
    je short .branch_582
    mov eax, dword [eax + picanm]
    sar eax, 0x10
    xor edx, edx
    and eax, 0xff
    mov dl, byte [ebp + 0x15]
    movsx eax, al
    imul eax, edx
    mov edi, dword [esp + 0x2c]
    shl eax, 2
    sub edi, eax
    mov dword [esp + 0x2c], edi

.branch_582:
    mov eax, dword [esp + 0x74]
    mov edx, dword [esp + 0x2c]
    add eax, eax
    sub edx, eax
    mov dword [esp + 0x28], edx
    mov byte [esp + 0x84], 1
    jmp near .branch_afa

.branch_59f:
    movsx ebx, word [ebp + 0xe]
    mov eax, dword [ebx*4 + picanm]
    sar eax, 8
    and eax, 0xff
    movsx edx, al
    movsx eax, byte [ebp + 0x16]
    add eax, edx
    mov edx, dword [esp + 0x7c]
    xor dh, dh
    and dl, 4
    movsx edx, dx
    test edx, edx
    jle short .branch_5cd
    neg eax

.branch_5cd:
    movsx edx, word [ebp + 0x1c]
    mov dword [esp + 0x74], edx
    xor edx, edx
    mov dl, byte [ebp + 0x14]
    mov dword [esp + 0x30], edx
    mov edx, dword [esp + 0x74]
    and edx, 0x7ff
    mov esi, dword [esp + 0x30]
    movsx edx, word [nosplit edx*2 + sintable]
    imul esi, edx
    mov edx, dword [esp + 0x74]
    add edx, 0x600
    and edx, 0x7ff
    mov dword [esp + 0x3c], esi
    mov esi, dword [esp + 0x30]
    movsx edx, word [nosplit edx*2 + sintable]
    imul esi, edx
    movsx edx, word [nosplit ebx*2 + tilesizx]
    mov dword [esp + 0x30], edx
    sar edx, 1
    mov edi, dword [esp + 0x70]
    add edx, eax
    mov eax, dword [esp + 0x3c]
    mov ebx, edx
    mov dword [esp + 0x74], edx
    imul ebx
    shrd eax, edx, 0x10
    mov ebx, dword [esp + 0x30]
    sub edi, eax
    mov eax, dword [esp + 0x3c]
    mov dword [esp + 0x70], edi
    imul ebx
    shrd eax, edx, 0x10
    mov ebx, dword [esp + 0x74]
    add edi, eax
    mov eax, esi
    imul ebx
    shrd eax, edx, 0x10
    mov ebx, dword [esp + 0x30]
    sub ecx, eax
    mov eax, esi
    mov dword [esp + 0x6c], esi
    imul ebx
    shrd eax, edx, 0x10
    lea esi, [ecx + eax]
    mov eax, dword [esp + 0xa8]
    inc eax
    push eax
    push esi
    mov ebx, dword [esp + 0x78]
    push edi
    mov edx, dword [esp + 0x10]
    mov eax, dword [esp + 0x14]
    call clipinsideboxline
    test eax, eax
    je near .branch_afa
    mov eax, dword [ebp + 8]
    mov dword [esp + 0x2c], eax
    movsx eax, word [ebp + 0xe]
    movsx edx, word [nosplit eax*2 + tilesizy]
    xor eax, eax
    mov al, byte [ebp + 0x15]
    imul eax, edx
    add eax, eax
    mov dword [esp + 0x74], eax
    mov eax, dword [esp + 0x7c]
    xor ah, ah
    and al, 0x80
    cwde
    test eax, eax
    je short .branch_6cf
    mov eax, dword [esp + 0x74]
    add dword [esp + 0x2c], eax

.branch_6cf:
    movsx eax, word [ebp + 0xe]
    shl eax, 2
    test byte [eax + picanm+2], 0xff
    je short .branch_705
    mov eax, dword [eax + picanm]
    sar eax, 0x10
    and eax, 0xff
    movsx edx, al
    xor eax, eax
    mov al, byte [ebp + 0x15]
    imul eax, edx
    mov ebx, dword [esp + 0x2c]
    shl eax, 2
    sub ebx, eax
    mov dword [esp + 0x2c], ebx

.branch_705:
    mov eax, dword [esp + 0x74]
    mov edx, dword [esp + 0x2c]
    add eax, eax
    mov ch, 1
    sub edx, eax
    mov byte [esp + 0x84], ch
    mov dword [esp + 0x28], edx
    jmp near .branch_afa

.branch_723:
    mov eax, dword [ebp + 8]
    mov dword [esp + 0x2c], eax
    mov dword [esp + 0x28], eax
    mov eax, dword [esp + 0x7c]
    xor ah, ah
    and al, 0x40
    cwde
    test eax, eax
    je short .branch_76a
    mov eax, dword [esp + 0x7c]
    xor ah, ah
    and al, 8
    cwde
    test eax, eax
    sete al
    mov edi, dword [esp + 0x2c]
    mov edx, eax
    mov eax, dword [esp]
    and edx, 0xff
    cmp eax, edi
    setg al
    and eax, 0xff
    cmp eax, edx
    je near .advance_sprite

.branch_76a:
    movsx ebx, word [ebp + 0xe]
    mov eax, dword [ebx*4 + picanm]
    sar eax, 8
    mov edx, dword [ebx*4 + picanm]
    and eax, 0xff
    sar edx, 0x10
    mov dword [esp + 0x40], eax
    and edx, 0xff
    mov al, byte [esp + 0x40]
    mov dword [esp + 0x40], edx
    movsx esi, al
    movsx eax, byte [ebp + 0x16]
    mov dl, byte [esp + 0x40]
    add eax, esi
    movsx esi, dl
    movsx edx, byte [ebp + 0x17]
    add edx, esi
    mov esi, dword [esp + 0x7c]
    and esi, 4
    movsx esi, si
    test esi, esi
    jle short .branch_7bf
    neg eax

.branch_7bf:
    mov esi, dword [esp + 0x7c]
    and esi, 8
    movsx esi, si
    test esi, esi
    jle short .branch_7cf
    neg edx

.branch_7cf:
    movsx esi, word [ebp + 0x1c]
    mov dword [esp + 0x24], esi
    add esi, 0x200
    and esi, 0x7ff
    movsx esi, word [nosplit esi*2 + sintable]
    mov dword [esp + 0x20], esi
    mov esi, dword [esp + 0x24]
    movsx esi, word [nosplit esi*2 + sintable]
    mov dword [esp + 0x1c], esi
    movsx esi, word [nosplit ebx*2 + tilesizx]
    movsx ebx, word [nosplit ebx*2 + tilesizy]
    mov dword [esp + 0x14], ebx
    xor ebx, ebx
    mov bl, byte [ebp + 0x15]
    mov dword [esp + 0x18], esi
    mov dword [esp + 0xc], ebx
    mov ebx, dword [esp + 0x18]
    sar ebx, 1
    movzx esi, byte [ebp + 0x14]
    add eax, ebx
    mov ebx, esi
    imul ebx, eax
    mov eax, dword [esp + 0x14]
    sar eax, 1
    add eax, edx
    mov edx, dword [esp + 0xc]
    imul edx, eax
    mov dword [esp + 0x10], esi
    mov esi, dword [esp + 0x20]
    mov dword [esp + 0x3c], ebx
    mov eax, dword [esp + 0x1c]
    mov edi, edx
    mov dword [esp + 0x6c], edx
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0x10
    mov edx, dword [esp + 8]
    mov ebx, dword [esp + 0x70]
    mov esi, dword [esp + 0x20]
    mov edi, dword [esp + 0x3c]
    sub eax, edx
    neg esi
    add ebx, eax
    mov eax, dword [esp + 0x1c]
    mov dword [esp + 0x70], ebx
    mov ebx, dword [esp + 0x6c]
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0x10
    sub eax, dword [esp + 4]
    mov edi, dword [esp + 0x10]
    add ecx, eax
    mov eax, dword [esp + 0x18]
    imul eax, edi
    mov dword [esp + 0x30], eax
    mov ebx, eax
    mov eax, dword [esp + 0x1c]
    mov edi, dword [esp + 0x70]
    imul ebx
    shrd eax, edx, 0x10
    sub edi, eax
    mov eax, dword [esp + 0x20]
    imul ebx
    shrd eax, edx, 0x10
    mov edx, dword [esp + 0xc]
    lea esi, [ecx + eax]
    mov eax, dword [esp + 0x14]
    imul eax, edx
    mov dword [esp + 0x30], eax
    mov ebx, eax
    mov eax, dword [esp + 0x20]
    imul ebx
    shrd eax, edx, 0x10
    mov ebx, eax
    mov dword [esp + 0x74], eax
    neg ebx
    mov dword [esp + 0x74], ebx
    lea eax, [ebx + edi]
    mov dword [esp + 0x34], eax
    mov eax, dword [esp + 0x70]
    add eax, ebx
    mov ebx, dword [esp + 0x30]
    mov dword [esp + 0x60], eax
    mov eax, dword [esp + 0x1c]
    imul ebx
    shrd eax, edx, 0x10
    mov ebx, eax
    mov dword [esp + 0x74], eax
    neg ebx
    mov dword [esp + 0x74], ebx
    lea eax, [ebx + esi]
    mov dword [esp + 0x64], eax
    lea eax, [ebx + ecx]
    mov dword [esp + 0x38], eax
    mov eax, dword [esp + 0xa8]
    add eax, 4
    mov dword [esp + 0x40], eax
    movsx eax, word [ebp + 0x1c]
    add eax, 0x100
    and eax, 0x7ff
    mov ax, word [nosplit eax*2 + sintable]
    mov ebx, dword [esp + 0x40]
    cwde
    imul ebx
    shrd eax, edx, 0xe
    mov dword [esp + 0x40], eax
    movsx eax, word [ebp + 0x1c]
    sub eax, 0x100
    and eax, 0x7ff
    mov ax, word [nosplit eax*2 + sintable]
    cwde
    mov ebp, dword [esp + 0x70]
    imul ebx
    shrd eax, edx, 0xe
    mov edx, dword [esp + 0x40]
    mov ebx, dword [esp + 0x34]
    sub edi, eax
    add ecx, eax
    add ebp, edx
    sub ebx, edx
    add esi, edx
    mov dword [esp + 0x70], ebp
    mov dword [esp + 0x34], ebx
    mov ebp, dword [esp + 0x60]
    mov ebx, dword [esp + 0x64]
    add ebp, eax
    sub ebx, eax
    mov dword [esp + 0x60], ebp
    mov dword [esp + 0x64], ebx
    mov ebp, dword [esp + 0x38]
    mov eax, ecx
    sub ebp, edx
    xor eax, esi
    mov dword [esp + 0x38], ebp
    test eax, eax
    jge short .branch_a03
    mov eax, dword [esp + 0x70]
    xor eax, edi
    test eax, eax
    jge short .branch_9f4
    mov eax, dword [esp + 0x70]
    imul eax, esi
    mov edx, edi
    imul edx, ecx
    cmp eax, edx
    setl al
    mov ah, al
    cmp ecx, esi
    setl al
    mov bh, byte [esp + 0x84]
    xor al, ah
    xor bh, al
    mov byte [esp + 0x84], bh
    jmp short .branch_a03

.branch_9f4:
    cmp dword [esp + 0x70], 0
    jl short .branch_a03
    xor byte [esp + 0x84], 1

.branch_a03:
    mov eax, dword [esp + 0x64]
    xor eax, esi
    test eax, eax
    jge short .branch_a48
    mov eax, dword [esp + 0x34]
    xor eax, edi
    test eax, eax
    jge short .branch_a3c
    mov edx, dword [esp + 0x64]
    imul edi, edx
    mov eax, dword [esp + 0x34]
    imul eax, esi
    cmp edi, eax
    setl al
    mov ah, al
    cmp esi, edx
    setl al
    xor al, ah
    xor byte [esp + 0x84], al
    jmp short .branch_a48

.branch_a3c:
    test edi, edi
    jl short .branch_a48
    xor byte [esp + 0x84], 1

.branch_a48:
    mov eax, dword [esp + 0x64]
    mov esi, dword [esp + 0x38]
    xor eax, esi
    test eax, eax
    jge short .branch_aa3
    mov eax, dword [esp + 0x34]
    mov edi, dword [esp + 0x60]
    xor eax, edi
    test eax, eax
    jge short .branch_a94
    mov eax, dword [esp + 0x34]
    imul eax, esi
    mov ebx, dword [esp + 0x64]
    mov edx, edi
    imul edx, ebx
    cmp eax, edx
    setl al
    mov ah, al
    cmp ebx, esi
    setl al
    mov dh, byte [esp + 0x84]
    xor al, ah
    xor dh, al
    mov byte [esp + 0x84], dh
    jmp short .branch_aa3

.branch_a94:
    cmp dword [esp + 0x34], 0
    jl short .branch_aa3
    xor byte [esp + 0x84], 1

.branch_aa3:
    mov eax, dword [esp + 0x38]
    xor eax, ecx
    test eax, eax
    jge short .branch_afa
    mov eax, dword [esp + 0x60]
    mov edi, dword [esp + 0x70]
    xor eax, edi
    test eax, eax
    jge short .branch_aeb
    mov edx, dword [esp + 0x60]
    imul edx, ecx
    mov ebx, dword [esp + 0x38]
    mov eax, edi
    imul eax, ebx
    cmp edx, eax
    setl al
    mov ah, al
    cmp ecx, ebx
    setg al
    mov bh, byte [esp + 0x84]
    xor al, ah
    xor bh, al
    mov byte [esp + 0x84], bh
    jmp short .branch_afa

.branch_aeb:
    cmp dword [esp + 0x60], 0
    jl short .branch_afa
    xor byte [esp + 0x84], 1

.branch_afa:
    cmp byte [esp + 0x84], 0
    je short .advance_sprite
    mov eax, dword [esp]
    mov ebp, dword [esp + 0x2c]
    cmp eax, ebp
    jle short .branch_b2e
    mov edx, dword [esp + 0x98]
    cmp ebp, dword [edx]
    jle short .branch_b2e
    mov eax, dword [esp + 0x68]
    mov dword [edx], ebp
    mov edx, dword [esp + 0x9c]
    add eax, 0xc000
    mov dword [edx], eax

.branch_b2e:
    mov eax, dword [esp]
    mov ecx, dword [esp + 0x28]
    cmp eax, ecx
    jge short .advance_sprite
    mov edx, dword [esp + 0xa0]
    cmp ecx, dword [edx]
    jge short .advance_sprite
    mov eax, dword [esp + 0x68]
    mov dword [edx], ecx
    mov edx, dword [esp + 0xa4]
    add eax, 0xc000
    mov dword [edx], eax

.advance_sprite:
    mov eax, dword [esp + 0x68]
    movsx eax, word [nosplit eax*2 + nextspritesect]

.branch_b64:
    mov dword [esp + 0x68], eax
    mov ebx, dword [esp + 0x68]
    test ebx, ebx
    jge near .process_sprite
    inc dword [esp + 0x78]

.test_sprite_sector:
    mov edx, dword [esp + 0x78]
    movsx eax, word [clipsectnum]
    cmp eax, edx
    jg near .get_sprite_head

.restore_stack:
    add esp, 0x88
    jmp clipmove_return

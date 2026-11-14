; Trace a 3D ray against sector planes, walls, and sprites.
BITS 32
ORG 0x50f15

sqrtable equ 0x1dfa60
clipsectorlist equ 0x195f50
sector equ 0x27c3a0
wall equ 0x2310a0
headspritesect equ 0x28891e
sprite equ 0x2040a0
tilesizy equ 0x1f4020
picanm equ 0x1ed3a0
sintable equ 0x2300a0
tilesizx equ 0x1f2020
nextspritesect equ 0x1f9ca0
inside equ 0x4c88f
rintersect equ 0x5272c
getzsofslope equ 0x5e07a

hitscan_:
    push esi
    push edi
    push ebp
    sub esp, 0x74
    push eax
    push edx
    push ebx
    mov eax, dword [esp + 0x9c]
    mov word [eax], 0xffff
    test cx, cx
    jge short .initialize_outputs
    mov eax, 0xffffffff
    jmp near .restore_stack

.initialize_outputs:
    mov eax, dword [esp + 0xa8]
    xor edx, edx
    mov dword [eax], 0x1fffffff
    mov eax, dword [esp + 0xac]
    mov ebx, 1
    mov dword [esp + 0x7c], edx
    mov dword [eax], 0x1fffffff
    mov dword [esp + 0x78], ebx
    mov word [clipsectorlist], cx

.process_sector:
    movsx eax, word [esp + 0x7c]
    mov ax, word [nosplit eax*2 + clipsectorlist]
    movsx edx, ax
    mov dword [esp + 0x74], eax
    mov eax, edx
    shl eax, 2
    add eax, edx
    mov edx, sector
    shl eax, 3
    add edx, eax
    mov dword [esp + 0x40], edx
    mov eax, dword [esp + 0x40]
    mov ax, word [eax + 0xc]
    xor ah, ah
    and al, 2
    mov edx, 0x3fffffff
    cwde
    mov dword [esp + 0x6c], edx
    test eax, eax
    je near .branch_242
    mov eax, dword [esp + 0x40]
    movsx eax, word [eax]
    mov edx, wall
    shl eax, 5
    add edx, eax
    movsx eax, word [edx + 8]
    mov dword [esp + 0x58], edx
    shl eax, 5
    mov ebx, dword [esp + 0x58]
    add eax, wall
    mov edi, dword [ebx]
    mov edx, dword [eax]
    mov ebx, dword [ebx + 4]
    mov eax, dword [eax + 4]
    sub eax, ebx
    sub edx, edi
    mov dword [esp + 0x50], eax
    mov eax, edx
    imul eax, edx
    mov dword [esp + 0x54], edx
    mov edx, dword [esp + 0x50]
    imul edx, edx
    add eax, edx
    test eax, eax
    jns short .branch_0ea
    neg eax

.branch_0ea:
    bsr ecx, eax
    cmp cl, 0xb
    jge short .branch_0fc
    movzx eax, word [nosplit eax*2 + sqrtable]
    jmp short .branch_110

.branch_0fc:
    sub cl, 9
    and cl, 0xfe
    sar eax, cl
    movzx eax, word [nosplit eax*2 + sqrtable]
    sar cl, 1
    shl eax, cl

.branch_110:
    sar eax, 0xa
    test eax, eax
    je near .branch_108f
    mov edx, dword [esp + 0x40]
    mov dx, word [edx + 0x12]
    mov ebx, eax
    movsx eax, dx
    mov edx, eax
    sar edx, 0x11
    shl eax, 0xf
    idiv ebx
    mov edx, dword [esp + 0x54]
    imul edx, eax
    mov dword [esp + 0x54], edx
    mov edx, dword [esp + 0x50]
    imul edx, eax
    mov edi, dword [esp + 0x90]
    mov ebx, dword [esp + 0x94]
    mov eax, dword [esp + 0x98]
    mov ecx, edx
    shl eax, 8
    neg ecx
    mov dword [esp + 0x34], eax
    mov esi, ecx
    mov eax, dword [esp + 0x54]
    mov dword [esp + 0x50], edx
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0xf
    mov edx, dword [esp + 0x34]
    sub edx, eax
    mov dword [esp + 0x3c], edx
    je near .branch_2ab
    mov eax, dword [esp + 0x40]
    mov edx, dword [esp]
    mov eax, dword [eax + 4]
    sub eax, edx
    shl eax, 8
    mov dword [esp + 0x34], eax
    mov eax, dword [esp + 0x58]
    mov edi, dword [esp + 8]
    mov ebx, dword [eax]
    mov esi, dword [eax + 4]
    sub edi, ebx
    mov ebx, dword [esp + 4]
    mov eax, dword [esp + 0x54]
    sub ebx, esi
    mov esi, ecx
    mov ecx, dword [esp + 0x34]
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0xf
    add ecx, eax
    mov eax, ecx
    sar eax, 1
    test eax, eax
    jns short .branch_1da
    neg eax

.branch_1da:
    mov edx, eax
    mov eax, dword [esp + 0x3c]
    test eax, eax
    jns short .branch_1e6
    neg eax

.branch_1e6:
    cmp edx, eax
    jge near .branch_2ab
    mov ebx, dword [esp + 0x3c]
    mov eax, ecx
    mov edx, eax
    sar edx, 2
    shl eax, 0x1e
    idiv ebx
    mov ebx, eax
    mov eax, dword [esp + 0x90]
    imul ebx
    shrd eax, edx, 0x1e
    mov edx, dword [esp + 8]
    mov ebp, dword [esp + 4]
    add edx, eax
    mov eax, dword [esp + 0x94]
    mov dword [esp + 0x6c], edx
    imul ebx
    shrd eax, edx, 0x1e
    add ebp, eax
    mov eax, dword [esp + 0x98]
    imul ebx
    shrd eax, edx, 0x1e
    mov edx, dword [esp]
    add edx, eax
    mov dword [esp + 0x5c], edx
    jmp short .branch_2ab

.branch_242:
    mov ebx, dword [esp + 0x98]
    test ebx, ebx
    jge short .branch_2ab
    mov edx, dword [esp + 0x40]
    mov eax, dword [esp]
    mov ecx, dword [edx + 4]
    cmp eax, ecx
    jl short .branch_2ab
    mov dword [esp + 0x5c], ecx
    sub ecx, eax
    mov eax, ecx
    mov edx, ebx
    sar eax, 1
    neg edx
    test eax, eax
    jns short .branch_26f
    neg eax

.branch_26f:
    cmp eax, edx
    jge short .branch_2ab
    mov eax, ecx
    mov edx, eax
    sar edx, 2
    shl eax, 0x1e
    idiv ebx
    mov ebx, eax
    mov eax, dword [esp + 0x90]
    imul ebx
    shrd eax, edx, 0x1e
    mov edx, dword [esp + 8]
    mov ebp, dword [esp + 4]
    add edx, eax
    mov eax, dword [esp + 0x94]
    mov dword [esp + 0x6c], edx
    imul ebx
    shrd eax, edx, 0x1e
    add ebp, eax

.branch_2ab:
    mov eax, dword [esp + 0x6c]
    mov edi, dword [esp + 8]
    sub eax, edi
    mov ebx, dword [esp + 4]
    test eax, eax
    jns short .branch_2bf
    neg eax

.branch_2bf:
    mov edx, eax
    mov eax, ebp
    sub eax, ebx
    test eax, eax
    jns short .branch_2cb
    neg eax

.branch_2cb:
    lea ebx, [edx + eax]
    mov eax, dword [esp + 0xa8]
    mov eax, dword [eax]
    sub eax, edi
    test eax, eax
    jns short .branch_2df
    neg eax

.branch_2df:
    mov edx, eax
    mov eax, dword [esp + 0xac]
    mov esi, dword [esp + 4]
    mov eax, dword [eax]
    sub eax, esi
    test eax, eax
    jns short .branch_2f6
    neg eax

.branch_2f6:
    add eax, edx
    cmp ebx, eax
    jge short .branch_359
    movsx ebx, word [esp + 0x74]
    mov eax, dword [esp + 0x6c]
    mov edx, ebp
    call inside
    test eax, eax
    je short .branch_359
    mov edx, dword [esp + 0x9c]
    mov eax, dword [esp + 0x74]
    mov word [edx], ax
    mov eax, dword [esp + 0xa0]
    mov word [eax], 0xffff
    mov eax, dword [esp + 0xa4]
    mov edx, dword [esp + 0xa8]
    mov word [eax], 0xffff
    mov eax, dword [esp + 0x6c]
    mov dword [edx], eax
    mov eax, dword [esp + 0xac]
    mov edx, dword [esp + 0xb0]
    mov dword [eax], ebp
    mov eax, dword [esp + 0x5c]
    mov dword [edx], eax

.branch_359:
    mov eax, dword [esp + 0x40]
    mov ax, word [eax + 0xe]
    xor ah, ah
    and al, 2
    mov edi, 0x3fffffff
    cwde
    mov dword [esp + 0x6c], edi
    test eax, eax
    je near .branch_518
    mov eax, dword [esp + 0x40]
    movsx eax, word [eax]
    mov edx, wall
    shl eax, 5
    add edx, eax
    movsx eax, word [edx + 8]
    mov dword [esp + 0x58], edx
    shl eax, 5
    mov ebx, dword [esp + 0x58]
    add eax, wall
    mov ecx, dword [ebx]
    mov edx, dword [eax]
    sub edx, ecx
    mov dword [esp + 0x54], edx
    imul edx, edx
    mov esi, dword [ebx + 4]
    mov eax, dword [eax + 4]
    sub eax, esi
    mov dword [esp + 0x50], eax
    imul eax, eax
    add eax, edx
    test eax, eax
    jns short .branch_3c0
    neg eax

.branch_3c0:
    bsr ecx, eax
    cmp cl, 0xb
    jge short .branch_3d2
    movzx eax, word [nosplit eax*2 + sqrtable]
    jmp short .branch_3e6

.branch_3d2:
    sub cl, 9
    and cl, 0xfe
    sar eax, cl
    movzx eax, word [nosplit eax*2 + sqrtable]
    sar cl, 1
    shl eax, cl

.branch_3e6:
    sar eax, 0xa
    test eax, eax
    je near .branch_108f
    mov edx, dword [esp + 0x40]
    mov dx, word [edx + 0x1a]
    mov ebx, eax
    movsx eax, dx
    mov edx, eax
    sar edx, 0x11
    shl eax, 0xf
    idiv ebx
    mov edx, dword [esp + 0x54]
    imul edx, eax
    mov dword [esp + 0x54], edx
    mov edx, dword [esp + 0x50]
    imul edx, eax
    mov edi, dword [esp + 0x90]
    mov ebx, dword [esp + 0x94]
    mov eax, dword [esp + 0x98]
    mov ecx, edx
    shl eax, 8
    neg ecx
    mov dword [esp + 0x34], eax
    mov esi, ecx
    mov eax, dword [esp + 0x54]
    mov dword [esp + 0x50], edx
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0xf
    mov edx, dword [esp + 0x34]
    sub edx, eax
    mov dword [esp + 0x3c], edx
    je near .branch_587
    mov eax, dword [esp + 0x40]
    mov edi, dword [esp]
    mov eax, dword [eax + 8]
    sub eax, edi
    shl eax, 8
    mov dword [esp + 0x34], eax
    mov eax, dword [esp + 0x58]
    mov ebx, dword [esp + 4]
    mov edi, dword [esp + 8]
    mov edx, dword [eax]
    mov esi, dword [eax + 4]
    mov eax, dword [esp + 0x54]
    sub edi, edx
    sub ebx, esi
    mov esi, ecx
    mov ecx, dword [esp + 0x34]
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0xf
    add ecx, eax
    mov eax, ecx
    sar eax, 1
    test eax, eax
    jns short .branch_4b0
    neg eax

.branch_4b0:
    mov edx, eax
    mov eax, dword [esp + 0x3c]
    test eax, eax
    jns short .branch_4bc
    neg eax

.branch_4bc:
    cmp edx, eax
    jge near .branch_587
    mov ebx, dword [esp + 0x3c]
    mov eax, ecx
    mov edx, eax
    sar edx, 2
    shl eax, 0x1e
    idiv ebx
    mov ebx, eax
    mov eax, dword [esp + 0x90]
    imul ebx
    shrd eax, edx, 0x1e
    mov edx, dword [esp + 8]
    mov ebp, dword [esp + 4]
    add edx, eax
    mov eax, dword [esp + 0x94]
    mov dword [esp + 0x6c], edx
    imul ebx
    shrd eax, edx, 0x1e
    add ebp, eax
    mov eax, dword [esp + 0x98]
    imul ebx
    shrd eax, edx, 0x1e
    mov edx, dword [esp]
    add edx, eax
    mov dword [esp + 0x5c], edx
    jmp short .branch_587

.branch_518:
    cmp dword [esp + 0x98], 0
    jle short .branch_587
    mov edx, dword [esp + 0x40]
    mov eax, dword [esp]
    mov ebx, dword [edx + 8]
    cmp eax, ebx
    jg short .branch_587
    mov ecx, ebx
    sub ecx, eax
    mov eax, ecx
    mov edi, dword [esp + 0x98]
    sar eax, 1
    mov dword [esp + 0x5c], ebx
    test eax, eax
    jns short .branch_549
    neg eax

.branch_549:
    cmp eax, edi
    jge short .branch_587
    mov ebx, edi
    mov eax, ecx
    mov edx, eax
    sar edx, 2
    shl eax, 0x1e
    idiv ebx
    mov ebx, eax
    mov eax, dword [esp + 0x90]
    imul ebx
    shrd eax, edx, 0x1e
    mov edx, dword [esp + 8]
    mov ebp, dword [esp + 4]
    add edx, eax
    mov eax, dword [esp + 0x94]
    mov dword [esp + 0x6c], edx
    imul ebx
    shrd eax, edx, 0x1e
    add ebp, eax

.branch_587:
    mov eax, dword [esp + 0x6c]
    mov edi, dword [esp + 8]
    sub eax, edi
    mov ebx, dword [esp + 4]
    test eax, eax
    jns short .branch_59b
    neg eax

.branch_59b:
    mov edx, eax
    mov eax, ebp
    sub eax, ebx
    test eax, eax
    jns short .branch_5a7
    neg eax

.branch_5a7:
    lea ebx, [edx + eax]
    mov eax, dword [esp + 0xa8]
    mov eax, dword [eax]
    sub eax, edi
    test eax, eax
    jns short .branch_5bb
    neg eax

.branch_5bb:
    mov edx, eax
    mov eax, dword [esp + 0xac]
    mov esi, dword [esp + 4]
    mov eax, dword [eax]
    sub eax, esi
    test eax, eax
    jns short .branch_5d2
    neg eax

.branch_5d2:
    add eax, edx
    cmp ebx, eax
    jge short .branch_635
    movsx ebx, word [esp + 0x74]
    mov eax, dword [esp + 0x6c]
    mov edx, ebp
    call inside
    test eax, eax
    je short .branch_635
    mov edx, dword [esp + 0x9c]
    mov eax, dword [esp + 0x74]
    mov word [edx], ax
    mov eax, dword [esp + 0xa0]
    mov word [eax], 0xffff
    mov eax, dword [esp + 0xa4]
    mov edx, dword [esp + 0xa8]
    mov word [eax], 0xffff
    mov eax, dword [esp + 0x6c]
    mov dword [edx], eax
    mov eax, dword [esp + 0xac]
    mov edx, dword [esp + 0xb0]
    mov dword [eax], ebp
    mov eax, dword [esp + 0x5c]
    mov dword [edx], eax

.branch_635:
    mov eax, dword [esp + 0x40]
    mov edx, dword [esp + 0x40]
    mov ax, word [eax]
    mov dx, word [edx + 2]
    add edx, eax
    mov dword [esp + 0x70], edx
    cwde
    mov edx, wall
    mov dword [esp + 0x64], eax
    shl eax, 5
    add edx, eax
    mov dword [esp + 0x58], edx
    jmp near .branch_839

.branch_662:
    mov eax, dword [esp + 0x58]
    movsx eax, word [eax + 8]
    mov edi, wall
    shl eax, 5
    add edi, eax
    mov eax, dword [esp + 0x58]
    mov eax, dword [eax]
    mov ebx, dword [esp + 4]
    mov dword [esp + 0x6c], eax
    mov eax, dword [edi]
    mov edx, dword [esp + 0x6c]
    mov dword [esp + 0x68], eax
    mov eax, dword [esp + 8]
    mov edi, dword [edi + 4]
    sub edx, eax
    mov eax, edi
    sub eax, ebx
    mov ebx, edx
    imul ebx, eax
    mov ebp, dword [esp + 0x58]
    mov ecx, dword [esp + 8]
    mov esi, dword [esp + 4]
    mov ebp, dword [ebp + 4]
    mov edx, dword [esp + 0x68]
    mov eax, ebp
    sub edx, ecx
    sub eax, esi
    imul eax, edx
    cmp ebx, eax
    jl near .branch_825
    lea eax, [esp + 0x28]
    push eax
    lea eax, [esp + 0x30]
    push eax
    lea eax, [esp + 0x38]
    push eax
    push edi
    mov edi, dword [esp + 0x78]
    push edi
    push ebp
    mov eax, dword [esp + 0x84]
    push eax
    mov edx, dword [esp + 0xb4]
    mov ebx, dword [esp + 0xb0]
    push edx
    mov ecx, dword [esp + 0xb0]
    mov eax, dword [esp + 0x28]
    push ebx
    mov edx, esi
    mov ebx, dword [esp + 0x24]
    call rintersect
    test eax, eax
    je near .branch_825
    mov eax, dword [esp + 0x30]
    mov ecx, dword [esp + 8]
    sub eax, ecx
    test eax, eax
    jns short .branch_71e
    neg eax

.branch_71e:
    mov edx, eax
    mov eax, dword [esp + 0x2c]
    sub eax, esi
    test eax, eax
    jns short .branch_72c
    neg eax

.branch_72c:
    lea ebx, [edx + eax]
    mov eax, dword [esp + 0xa8]
    mov eax, dword [eax]
    sub eax, ecx
    test eax, eax
    jns short .branch_740
    neg eax

.branch_740:
    mov edx, eax
    mov eax, dword [esp + 0xac]
    mov eax, dword [eax]
    sub eax, esi
    test eax, eax
    jns short .branch_753
    neg eax

.branch_753:
    add eax, edx
    cmp ebx, eax
    jge near .branch_825
    mov edi, dword [esp + 0x58]
    mov di, word [edi + 0xc]
    test di, di
    jl short .branch_77b
    mov eax, dword [esp + 0x58]
    mov ax, word [eax + 0xe]
    xor ah, ah
    and al, 0x40
    cwde
    test eax, eax
    je short .branch_7cc

.branch_77b:
    mov edx, dword [esp + 0x9c]
    mov eax, dword [esp + 0x74]
    mov word [edx], ax
    mov edx, dword [esp + 0xa0]
    mov eax, dword [esp + 0x64]
    mov word [edx], ax
    mov eax, dword [esp + 0xa4]
    mov word [eax], 0xffff
    mov edx, dword [esp + 0xa8]
    mov eax, dword [esp + 0x30]
    mov dword [edx], eax
    mov edx, dword [esp + 0xac]
    mov eax, dword [esp + 0x2c]
    mov dword [edx], eax
    mov edx, dword [esp + 0xb0]
    mov eax, dword [esp + 0x28]
    mov dword [edx], eax
    jmp short .branch_825

.branch_7cc:
    lea eax, [esp + 0x20]
    lea ecx, [esp + 0x24]
    mov ebx, dword [esp + 0x2c]
    mov edx, dword [esp + 0x30]
    push eax
    movsx eax, di
    call getzsofslope
    mov eax, dword [esp + 0x28]
    cmp eax, dword [esp + 0x24]
    jle short .branch_77b
    cmp eax, dword [esp + 0x20]
    jge short .branch_77b
    movsx eax, word [esp + 0x78]
    jmp short .branch_806

.branch_7fc:
    cmp di, word [nosplit eax*2 + clipsectorlist]
    je short .branch_80b

.branch_806:
    dec eax
    test eax, eax
    jge short .branch_7fc

.branch_80b:
    test eax, eax
    jge short .branch_825
    mov ebx, dword [esp + 0x78]
    movsx eax, word [esp + 0x78]
    inc ebx
    mov word [nosplit eax*2 + clipsectorlist], di
    mov dword [esp + 0x78], ebx

.branch_825:
    mov esi, dword [esp + 0x64]
    mov edi, dword [esp + 0x58]
    inc esi
    add edi, 0x20
    mov dword [esp + 0x64], esi
    mov dword [esp + 0x58], edi

.branch_839:
    movsx eax, word [esp + 0x70]
    cmp eax, dword [esp + 0x64]
    jg near .branch_662
    movsx eax, word [esp + 0x74]
    movsx eax, word [nosplit eax*2 + headspritesect]
    jmp near .update_sprite_index

.process_sprite:
    imul esi, ebx, 0x2c
    add esi, sprite
    movsx eax, word [esi + 0xc]
    mov dword [esp + 0x60], eax
    test byte [esp + 0x61], 1
    je near .test_sprite
    mov eax, dword [esi]
    mov dword [esp + 0x6c], eax
    mov eax, dword [esi + 8]
    mov dword [esp + 0x5c], eax
    mov eax, dword [esp + 0x60]
    and eax, 0x30
    mov ebp, dword [esi + 4]
    cmp eax, 0x10
    jb short .branch_8a6
    jbe near .branch_a91
    cmp eax, 0x20
    je near .branch_cbf
    jmp near .test_sprite

.branch_8a6:
    test eax, eax
    jne near .test_sprite
    mov eax, dword [esp + 0x6c]
    mov ebx, dword [esp + 8]
    mov edx, dword [esp + 0x90]
    sub eax, ebx
    imul edx, eax
    mov ecx, dword [esp + 4]
    mov eax, ebp
    mov edi, dword [esp + 0x94]
    sub eax, ecx
    imul eax, edi
    add edx, eax
    mov dword [esp + 0x38], edx
    test edx, edx
    jle near .test_sprite
    imul edi, edi
    mov eax, dword [esp + 0x90]
    imul eax, eax
    add edi, eax
    je near .test_sprite
    mov eax, dword [esp + 0x98]
    mov ecx, edi
    mov ebx, edx
    imul ebx
    idiv ecx
    mov edx, dword [esp]
    add edx, eax
    mov dword [esp + 0x28], edx
    movsx eax, word [esi + 0xe]
    movsx edx, word [nosplit eax*2 + tilesizy]
    xor eax, eax
    mov al, byte [esi + 0x15]
    mov ecx, eax
    imul ecx, edx
    mov dh, byte [esp + 0x60]
    shl ecx, 2
    test dh, 0x80
    je short .branch_93f
    mov eax, ecx
    mov edx, dword [esp + 0x5c]
    sar eax, 1
    add edx, eax
    mov dword [esp + 0x5c], edx

.branch_93f:
    movsx eax, word [esi + 0xe]
    shl eax, 2
    test byte [eax + picanm+2], 0xff
    je short .branch_975
    mov eax, dword [eax + picanm]
    sar eax, 0x10
    and eax, 0xff
    movsx edx, al
    xor eax, eax
    mov al, byte [esi + 0x15]
    imul eax, edx
    mov ebx, dword [esp + 0x5c]
    shl eax, 2
    sub ebx, eax
    mov dword [esp + 0x5c], ebx

.branch_975:
    mov eax, dword [esp + 0x28]
    mov edx, dword [esp + 0x5c]
    cmp eax, edx
    jg near .test_sprite
    mov eax, edx
    mov ebx, dword [esp + 0x28]
    sub eax, ecx
    cmp eax, ebx
    jg near .test_sprite
    mov ecx, dword [esp + 4]
    mov edx, ebp
    mov eax, dword [esp + 0x90]
    sub edx, ecx
    imul edx, eax
    mov ebx, dword [esp + 8]
    mov eax, dword [esp + 0x6c]
    mov ecx, dword [esp + 0x94]
    sub eax, ebx
    imul eax, ecx
    mov ecx, edi
    sub edx, eax
    mov eax, dword [esp + 0x90]
    mov ebx, edx
    imul ebx
    idiv ecx
    mov dword [esp + 0x34], eax
    mov eax, dword [esp + 0x94]
    imul ebx
    idiv ecx
    imul eax, eax
    mov edx, dword [esp + 0x34]
    imul edx, edx
    xor ecx, edi
    add edx, eax
    movsx eax, word [esi + 0xe]
    mov cl, byte [esi + 0x14]
    movsx eax, word [nosplit eax*2 + tilesizx]
    imul ecx, eax
    imul ecx, ecx
    sar ecx, 7
    cmp edx, ecx
    jg near .test_sprite
    mov ebx, dword [esp + 0x38]
    mov eax, dword [esp + 0x90]
    mov ecx, edi
    imul ebx
    idiv ecx
    mov edx, dword [esp + 8]
    add edx, eax
    mov eax, dword [esp + 0x94]
    mov dword [esp + 0x30], edx
    imul ebx
    idiv ecx
    mov edx, dword [esp + 4]
    mov ecx, dword [esp + 8]
    add edx, eax
    mov eax, dword [esp + 0x30]
    mov esi, dword [esp + 4]
    sub eax, ecx
    mov dword [esp + 0x2c], edx
    test eax, eax
    jns short .branch_a4d
    neg eax

.branch_a4d:
    mov edx, eax
    mov eax, dword [esp + 0x2c]
    sub eax, esi
    test eax, eax
    jns short .branch_a5b
    neg eax

.branch_a5b:
    lea ebx, [edx + eax]
    mov eax, dword [esp + 0xa8]
    mov eax, dword [eax]
    sub eax, ecx
    test eax, eax
    jns short .branch_a6f
    neg eax

.branch_a6f:
    mov edx, eax
    mov eax, dword [esp + 0xac]
    mov eax, dword [eax]
    sub eax, esi
    test eax, eax
    jns short .branch_a82
    neg eax

.branch_a82:
    add eax, edx
    cmp ebx, eax
    jg near .test_sprite
    jmp near .advance_sprite

.branch_a91:
    movsx eax, word [esi + 0xe]
    mov dword [esp + 0x4c], eax
    mov eax, dword [eax*4 + picanm]
    sar eax, 8
    and eax, 0xff
    movsx edx, al
    movsx eax, byte [esi + 0x16]
    add eax, edx
    mov edx, dword [esp + 0x60]
    and edx, 4
    test edx, edx
    jle short .branch_abe
    neg eax

.branch_abe:
    movsx ecx, word [esi + 0x1c]
    mov edx, ecx
    and edx, 0x7ff
    movzx edi, byte [esi + 0x14]
    movsx edx, word [nosplit edx*2 + sintable]
    imul edx, edi
    mov dword [esp + 0x54], edx
    lea edx, [ecx + 0x600]
    and edx, 0x7ff
    movsx edx, word [nosplit edx*2 + sintable]
    imul edx, edi
    mov edi, dword [esp + 0x4c]
    movsx edi, word [nosplit edi*2 + tilesizx]
    mov ecx, edi
    sar ecx, 1
    add ecx, eax
    mov eax, dword [esp + 0x54]
    mov ebx, ecx
    mov dword [esp + 0x50], edx
    imul ebx
    shrd eax, edx, 0x10
    mov edx, dword [esp + 0x6c]
    mov ebx, edi
    sub edx, eax
    mov eax, dword [esp + 0x54]
    mov dword [esp + 0x6c], edx
    imul ebx
    shrd eax, edx, 0x10
    mov edx, dword [esp + 0x6c]
    mov ebx, ecx
    add edx, eax
    mov eax, dword [esp + 0x50]
    mov dword [esp + 0x68], edx
    imul ebx
    shrd eax, edx, 0x10
    mov ebx, edi
    sub ebp, eax
    mov eax, dword [esp + 0x50]
    imul ebx
    shrd eax, edx, 0x10
    mov bh, byte [esp + 0x60]
    lea edi, [eax + ebp]
    test bh, 0x40
    je short .branch_b8a
    mov ebx, dword [esp + 0x6c]
    mov ecx, dword [esp + 8]
    mov edx, dword [esp + 4]
    mov eax, edi
    sub ebx, ecx
    sub eax, edx
    imul ebx, eax
    mov edx, dword [esp + 0x68]
    sub edx, ecx
    mov ecx, dword [esp + 4]
    mov eax, ebp
    sub eax, ecx
    imul eax, edx
    cmp ebx, eax
    jl near .test_sprite

.branch_b8a:
    lea eax, [esp + 0x28]
    push eax
    lea eax, [esp + 0x30]
    push eax
    lea eax, [esp + 0x38]
    push eax
    push edi
    mov edi, dword [esp + 0x78]
    push edi
    push ebp
    mov eax, dword [esp + 0x84]
    push eax
    mov edx, dword [esp + 0xb4]
    mov ebx, dword [esp + 0xb0]
    push edx
    mov ecx, dword [esp + 0xb0]
    mov eax, dword [esp + 0x28]
    push ebx
    mov edx, dword [esp + 0x28]
    mov ebx, dword [esp + 0x24]
    call rintersect
    test eax, eax
    je near .test_sprite
    mov eax, dword [esp + 0x30]
    sub eax, dword [esp + 8]
    mov edi, dword [esp + 4]
    test eax, eax
    jns short .branch_bea
    neg eax

.branch_bea:
    mov edx, eax
    mov eax, dword [esp + 0x2c]
    sub eax, edi
    test eax, eax
    jns short .branch_bf8
    neg eax

.branch_bf8:
    lea ecx, [edx + eax]
    mov eax, dword [esp + 0xa8]
    mov edx, dword [esp + 8]
    mov eax, dword [eax]
    sub eax, edx
    test eax, eax
    jns short .branch_c10
    neg eax

.branch_c10:
    mov edx, eax
    mov eax, dword [esp + 0xac]
    mov eax, dword [eax]
    sub eax, edi
    test eax, eax
    jns short .branch_c23
    neg eax

.branch_c23:
    add eax, edx
    cmp ecx, eax
    jg near .test_sprite
    movsx eax, word [esi + 0xe]
    movsx edx, word [nosplit eax*2 + tilesizy]
    xor eax, eax
    mov al, byte [esi + 0x15]
    mov ecx, eax
    imul ecx, edx
    mov al, byte [esp + 0x60]
    shl ecx, 2
    test al, 0x80
    je short .branch_c5d
    mov eax, ecx
    mov edx, dword [esi + 8]
    sar eax, 1
    add edx, eax
    mov dword [esp + 0x24], edx
    jmp short .branch_c64

.branch_c5d:
    mov eax, dword [esi + 8]
    mov dword [esp + 0x24], eax

.branch_c64:
    movsx eax, word [esi + 0xe]
    shl eax, 2
    test byte [eax + picanm+2], 0xff
    je short .branch_c9a
    mov eax, dword [eax + picanm]
    sar eax, 0x10
    and eax, 0xff
    movsx edx, al
    xor eax, eax
    mov al, byte [esi + 0x15]
    imul eax, edx
    mov esi, dword [esp + 0x24]
    shl eax, 2
    sub esi, eax
    mov dword [esp + 0x24], esi

.branch_c9a:
    mov eax, dword [esp + 0x28]
    mov edi, dword [esp + 0x24]
    cmp eax, edi
    jge near .test_sprite
    mov eax, edi
    mov edx, dword [esp + 0x28]
    sub eax, ecx
    cmp eax, edx
    jge near .test_sprite
    jmp near .advance_sprite

.branch_cbf:
    mov edi, dword [esp + 0x98]
    test edi, edi
    je near .test_sprite
    mov eax, dword [esp + 0x5c]
    mov edx, dword [esp]
    mov dword [esp + 0x28], eax
    sub eax, edx
    xor eax, edi
    test eax, eax
    jl near .test_sprite
    test byte [esp + 0x60], 0x40
    je short .branch_d15
    mov eax, dword [esp]
    cmp eax, dword [esp + 0x5c]
    setg al
    mov edx, eax
    mov bl, byte [esp + 0x60]
    and edx, 0xff
    test bl, 8
    sete al
    and eax, 0xff
    cmp edx, eax
    je near .test_sprite

.branch_d15:
    mov eax, dword [esp + 0x28]
    mov edi, dword [esp]
    mov ecx, dword [esp + 0x98]
    mov ebx, dword [esp + 0x90]
    sub eax, edi
    imul ebx
    idiv ecx
    mov edx, dword [esp + 8]
    add edx, eax
    mov eax, dword [esp + 0x28]
    mov ebx, dword [esp + 0x94]
    sub eax, edi
    mov dword [esp + 0x30], edx
    imul ebx
    idiv ecx
    mov edx, dword [esp + 4]
    mov ebx, dword [esp + 8]
    add edx, eax
    mov eax, dword [esp + 0x30]
    mov ecx, dword [esp + 4]
    sub eax, ebx
    mov dword [esp + 0x2c], edx
    test eax, eax
    jns short .branch_d69
    neg eax

.branch_d69:
    mov edx, eax
    mov eax, dword [esp + 0x2c]
    sub eax, ecx
    test eax, eax
    jns short .branch_d77
    neg eax

.branch_d77:
    lea ecx, [edx + eax]
    mov eax, dword [esp + 0xa8]
    mov eax, dword [eax]
    sub eax, ebx
    test eax, eax
    jns short .branch_d8b
    neg eax

.branch_d8b:
    mov edx, eax
    mov eax, dword [esp + 0xac]
    mov ebx, dword [esp + 4]
    mov eax, dword [eax]
    sub eax, ebx
    test eax, eax
    jns short .branch_da2
    neg eax

.branch_da2:
    add eax, edx
    cmp ecx, eax
    jg near .test_sprite
    movsx eax, word [esi + 0xe]
    mov dword [esp + 0x4c], eax
    mov ecx, eax
    mov eax, dword [eax*4 + picanm]
    sar eax, 8
    and eax, 0xff
    movsx edx, al
    movsx eax, byte [esi + 0x16]
    add eax, edx
    mov edx, dword [ecx*4 + picanm]
    sar edx, 0x10
    and edx, 0xff
    movsx ebx, byte [esi + 0x17]
    movsx edx, dl
    add edx, ebx
    mov ebx, dword [esp + 0x60]
    and ebx, 4
    test ebx, ebx
    jle short .branch_df4
    neg eax

.branch_df4:
    mov ebx, dword [esp + 0x60]
    and ebx, 8
    test ebx, ebx
    jle short .branch_e01
    neg edx

.branch_e01:
    movsx edi, word [esi + 0x1c]
    lea ecx, [edi + 0x200]
    movsx ebx, word [nosplit edi*2 + sintable]
    mov edi, dword [esp + 0x4c]
    mov dword [esp + 0x1c], ebx
    movsx ebx, word [nosplit edi*2 + tilesizx]
    mov dword [esp + 0x18], ebx
    xor ebx, ebx
    mov bl, byte [esi + 0x14]
    mov dword [esp + 0x10], ebx
    movsx ebx, word [nosplit edi*2 + tilesizy]
    mov dword [esp + 0x14], ebx
    xor ebx, ebx
    mov bl, byte [esi + 0x15]
    mov esi, dword [esp + 0x18]
    mov dword [esp + 0xc], ebx
    sar esi, 1
    mov ebx, dword [esp + 0x10]
    add eax, esi
    imul ebx, eax
    mov eax, dword [esp + 0x14]
    sar eax, 1
    add eax, edx
    mov edx, dword [esp + 0xc]
    imul edx, eax
    and ecx, 0x7ff
    add ecx, ecx
    movsx ecx, word [ecx + sintable]
    mov esi, ecx
    mov dword [esp + 0x54], ebx
    mov eax, dword [esp + 0x1c]
    mov edi, edx
    mov dword [esp + 0x50], edx
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0x10
    mov esi, dword [esp + 0x30]
    mov edi, dword [esp + 0x6c]
    mov ebx, dword [esp + 0x50]
    sub eax, esi
    mov esi, ecx
    add edi, eax
    mov eax, dword [esp + 0x1c]
    mov dword [esp + 0x6c], edi
    neg esi
    mov edi, dword [esp + 0x54]
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0x10
    mov esi, dword [esp + 0x18]
    mov ebx, dword [esp + 0x10]
    imul ebx, esi
    sub eax, dword [esp + 0x2c]
    add ebp, eax
    mov eax, dword [esp + 0x1c]
    imul ebx
    shrd eax, edx, 0x10
    mov edx, dword [esp + 0x6c]
    sub edx, eax
    mov eax, ecx
    mov dword [esp + 0x68], edx
    imul ebx
    shrd eax, edx, 0x10
    mov ebx, dword [esp + 0x14]
    lea edi, [eax + ebp]
    imul ebx, dword [esp + 0xc]
    mov eax, ecx
    imul ebx
    shrd eax, edx, 0x10
    mov ecx, eax
    mov eax, dword [esp + 0x68]
    neg ecx
    add eax, ecx
    mov dword [esp + 0x48], eax
    mov eax, dword [esp + 0x6c]
    add eax, ecx
    mov dword [esp + 0x44], eax
    mov eax, dword [esp + 0x1c]
    imul ebx
    shrd eax, edx, 0x10
    mov ecx, eax
    neg ecx
    mov edx, ebp
    lea esi, [edi + ecx]
    xor al, al
    xor edx, edi
    add ecx, ebp
    test edx, edx
    jge short .branch_f67
    mov edx, dword [esp + 0x6c]
    xor edx, dword [esp + 0x68]
    test edx, edx
    jge short .branch_f5e
    mov ebx, dword [esp + 0x6c]
    imul ebx, edi
    mov edx, dword [esp + 0x68]
    imul edx, ebp
    cmp ebx, edx
    setl ah
    cmp ebp, edi
    setl al
    xor al, ah
    jmp short .branch_f67

.branch_f5e:
    cmp dword [esp + 0x6c], 0
    jl short .branch_f67
    mov al, 1

.branch_f67:
    mov edx, edi
    xor edx, esi
    test edx, edx
    jge short .branch_fa2
    mov edx, dword [esp + 0x68]
    mov ebx, dword [esp + 0x48]
    xor edx, ebx
    test edx, edx
    jge short .branch_f99
    imul ebx, edi
    mov edx, dword [esp + 0x68]
    imul edx, esi
    cmp edx, ebx
    setl ah
    mov dl, ah
    cmp edi, esi
    setl ah
    xor ah, dl
    xor al, ah
    jmp short .branch_fa2

.branch_f99:
    cmp dword [esp + 0x68], 0
    jl short .branch_fa2
    xor al, 1

.branch_fa2:
    mov edx, esi
    xor edx, ecx
    test edx, edx
    jge short .branch_fdf
    mov edx, dword [esp + 0x48]
    mov edi, dword [esp + 0x44]
    xor edx, edi
    test edx, edx
    jge short .branch_fd6
    mov edx, dword [esp + 0x48]
    imul edx, ecx
    mov ebx, edi
    imul ebx, esi
    cmp edx, ebx
    setl ah
    mov dl, ah
    cmp esi, ecx
    setl ah
    xor ah, dl
    xor al, ah
    jmp short .branch_fdf

.branch_fd6:
    cmp dword [esp + 0x48], 0
    jl short .branch_fdf
    xor al, 1

.branch_fdf:
    mov edx, ecx
    xor edx, ebp
    test edx, edx
    jge short .branch_101c
    mov edx, dword [esp + 0x44]
    mov ebx, dword [esp + 0x6c]
    xor edx, ebx
    test edx, edx
    jge short .branch_1013
    mov esi, dword [esp + 0x44]
    imul esi, ebp
    mov edx, ebx
    imul edx, ecx
    cmp esi, edx
    setl ah
    mov dl, ah
    cmp ecx, ebp
    setl ah
    xor ah, dl
    xor al, ah
    jmp short .branch_101c

.branch_1013:
    cmp dword [esp + 0x44], 0
    jl short .branch_101c
    xor al, 1

.branch_101c:
    test al, al
    je short .test_sprite

.advance_sprite:
    mov edx, dword [esp + 0x9c]
    mov eax, dword [esp + 0x74]
    mov word [edx], ax
    mov eax, dword [esp + 0xa0]
    mov edx, dword [esp + 0xa4]
    mov word [eax], 0xffff
    mov eax, dword [esp + 0x64]
    mov word [edx], ax
    mov edx, dword [esp + 0xa8]
    mov eax, dword [esp + 0x30]
    mov dword [edx], eax
    mov edx, dword [esp + 0xac]
    mov eax, dword [esp + 0x2c]
    mov dword [edx], eax
    mov edx, dword [esp + 0xb0]
    mov eax, dword [esp + 0x28]
    mov dword [edx], eax

.test_sprite:
    mov eax, dword [esp + 0x64]
    movsx eax, word [nosplit eax*2 + nextspritesect]

.update_sprite_index:
    mov dword [esp + 0x64], eax
    mov ebx, dword [esp + 0x64]
    test ebx, ebx
    jge near .process_sprite
    inc dword [esp + 0x7c]

.branch_108f:
    mov eax, dword [esp + 0x7c]
    cmp ax, word [esp + 0x78]
    jl near .process_sector
    xor eax, eax

.restore_stack:
    add esp, 0x80

; Shared return also used by visibility and segment intersection.
hitscan_return:
    pop ebp
    pop edi
    pop esi
    ret 0x24

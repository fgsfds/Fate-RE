; Clip linked automap polygons to the screen window.
BITS 32
ORG 0x5b230

rx1 equ 0x1cd160
ry1 equ 0x1d1160
rx2 equ 0x1cb160
ry2 equ 0x1cf160
window_left equ 0x286b9c
window_top equ 0x286b94
window_right equ 0x286b98
window_bottom equ 0x286b90
engine_1c5160 equ 0x1c5160
engine_1c3160 equ 0x1c3160
engine_1d8560 equ 0x1d8560
engine_1c315c equ 0x1c315c
engine_1c515c equ 0x1c515c
ceiling_sprite_restore equ 0x50347

clippoly_:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    sub esp, 0x50
    push eax
    push edx
    mov eax, dword [window_left]
    mov dword [esp + 0x20], eax
    mov eax, dword [window_top]
    mov edx, dword [esp + 0x20]
    mov dword [esp + 0x1c], eax
    shl edx, 0x10
    mov ebx, dword [esp + 0x1c]
    mov eax, dword [window_right]
    mov dword [esp + 0x20], edx
    inc eax
    shl ebx, 0x10
    mov dword [esp + 0x24], eax
    mov dword [esp + 0x1c], ebx
    mov eax, dword [window_bottom]
    mov ecx, dword [esp + 0x24]
    inc eax
    shl ecx, 0x10
    mov dword [esp + 0x18], eax
    mov esi, eax
    mov dword [esp + 0x24], ecx
    shl esi, 0x10
    mov ah, byte [esp]
    mov dword [esp + 0x18], esi
    test ah, 0xa
    je near .branch_6e9
    xor edi, edi
    xor ebx, ebx
    mov dword [esp + 0x50], edi
    mov dword [esp + 0x28], edi
    mov dword [esp + 0x4c], edi

.branch_076:
    mov ebp, dword [esp + 0x20]
    sub ebp, dword [ebx*4 + rx1]

.branch_081:
    mov edx, ebx
    mov ecx, 0xffffffff
    shl edx, 2
    mov esi, ebp
    mov edi, dword [edx + engine_1c5160]
    mov ebp, dword [esp + 0x20]
    mov dword [edx + engine_1c5160], ecx
    sub ebp, dword [edi*4 + rx1]
    test esi, esi
    jge short .branch_0d4
    mov ecx, dword [esp + 0x50]
    mov eax, dword [edx + rx1]
    mov dword [ecx*4 + rx2], eax
    mov eax, dword [edx + ry1]
    mov dword [ecx*4 + ry2], eax
    lea eax, [ecx + 1]
    mov dword [esp + 0x50], eax
    mov dword [ecx*4 + engine_1c3160], eax

.branch_0d4:
    mov eax, esi
    xor eax, ebp
    test eax, eax
    jge near .branch_192
    mov eax, esi
    sub eax, ebp
    shl ebx, 2
    mov dword [esp + 0x10], eax
    mov eax, edi
    mov dword [esp + 0x54], ebx
    shl eax, 2
    mov ebx, dword [ebx + rx1]
    mov dword [esp + 0x14], eax
    mov eax, dword [eax + rx1]
    mov ecx, dword [esp + 0x10]
    sub eax, ebx
    mov ebx, esi
    imul ebx
    idiv ecx
    mov edx, dword [esp + 0x54]
    mov ecx, dword [edx + rx1]
    mov edx, dword [esp + 0x50]
    shl edx, 2
    add eax, ecx
    mov dword [esp + 0xc], edx
    mov dword [edx + rx2], eax
    mov edx, dword [esp + 0x14]
    mov eax, dword [esp + 0x54]
    mov edx, dword [edx + ry1]
    mov ebx, dword [eax + ry1]
    mov eax, edx
    mov ecx, dword [esp + 0x10]
    sub eax, ebx
    mov ebx, esi
    imul ebx
    idiv ecx
    mov edx, dword [esp + 0x54]
    mov ecx, dword [edx + ry1]
    mov edx, dword [esp + 0xc]
    add eax, ecx
    mov dword [edx + ry2], eax
    test esi, esi
    jge short .branch_180
    mov eax, dword [esp + 0x4c]
    mov edx, dword [esp + 0x50]
    lea esi, [eax + 1]
    mov word [nosplit eax*2 + engine_1d8560], dx
    mov dword [esp + 0x4c], esi

.branch_180:
    mov edx, dword [esp + 0x50]
    lea eax, [edx + 1]
    mov dword [esp + 0x50], eax
    mov dword [edx*4 + engine_1c3160], eax

.branch_192:
    mov eax, dword [edi*4 + engine_1c5160]
    mov ebx, edi
    test eax, eax
    jge near .branch_081
    mov eax, dword [esp + 0x28]
    mov edx, dword [esp + 0x50]
    add eax, 3
    cmp eax, edx
    jg short .branch_1c5
    mov eax, edx
    mov edx, dword [esp + 0x28]
    mov dword [esp + 0x28], eax
    mov dword [eax*4 + engine_1c315c], edx
    jmp short .branch_1cd

.branch_1c5:
    mov eax, dword [esp + 0x28]
    mov dword [esp + 0x50], eax

.branch_1cd:
    mov ebx, 1
    mov ecx, dword [esp + 4]

.branch_1d6:
    cmp ebx, ecx
    jge short .branch_1e7
    cmp dword [ebx*4 + engine_1c5160], 0
    jge short .branch_1e7
    inc ebx
    jmp short .branch_1d6

.branch_1e7:
    cmp ebx, dword [esp + 4]
    jl near .branch_076
    cmp dword [esp + 0x50], 2
    jg short .branch_1ff

.branch_1f8:
    xor esi, esi
    jmp near .branch_d7d

.branch_1ff:
    mov ebx, 1
    jmp near .branch_39e

.branch_209:
    xor edi, edi
    jmp near .branch_395

.branch_210:
    lea eax, [ebx + ebx]
    lea ecx, [edi + edi]
    mov dword [esp + 0x2c], eax
    mov dword [esp + 0x48], ecx
    movsx edx, word [eax + engine_1d8560]
    movsx ecx, word [ecx + engine_1d8560]
    mov eax, dword [edx*4 + engine_1c3160]
    mov esi, dword [ecx*4 + engine_1c3160]
    shl eax, 2
    mov dword [esp + 8], esi
    mov dword [esp + 0x14], eax
    mov esi, dword [edx*4 + rx2]
    mov ebp, dword [eax + rx2]
    mov eax, esi
    sub eax, ebp
    test eax, eax
    jns short .branch_25c
    neg eax

.branch_25c:
    mov ebp, eax
    mov eax, dword [esp + 0x14]
    mov esi, dword [edx*4 + ry2]
    sub esi, dword [eax + ry2]
    mov eax, esi
    test eax, eax
    jns short .branch_277
    neg eax

.branch_277:
    lea esi, [eax + ebp]
    mov eax, dword [ecx*4 + rx2]
    mov ebp, dword [esp + 8]
    mov dword [esp + 0x54], eax
    mov eax, dword [ebp*4 + rx2]
    sub dword [esp + 0x54], eax
    mov eax, dword [esp + 0x54]
    test eax, eax
    jns short .branch_29e
    neg eax

.branch_29e:
    mov dword [esp + 0x10], eax
    mov eax, dword [ecx*4 + ry2]
    mov dword [esp + 0x54], eax
    mov eax, dword [ebp*4 + ry2]
    sub dword [esp + 0x54], eax
    mov eax, dword [esp + 0x54]
    test eax, eax
    jns short .branch_2c2
    neg eax

.branch_2c2:
    mov dword [esp + 0xc], eax
    mov eax, dword [esp + 0x10]
    add eax, dword [esp + 0xc]
    add esi, eax
    mov eax, dword [edx*4 + rx2]
    mov dword [esp + 0x54], eax
    mov eax, dword [ebp*4 + rx2]
    sub dword [esp + 0x54], eax
    mov eax, dword [esp + 0x54]
    test eax, eax
    jns short .branch_2f0
    neg eax

.branch_2f0:
    mov dword [esp + 0xc], eax
    mov edx, dword [edx*4 + ry2]
    mov eax, dword [ebp*4 + ry2]
    sub edx, eax
    mov eax, edx
    mov ebp, dword [esp + 0xc]
    test eax, eax
    jns short .branch_310
    neg eax

.branch_310:
    add ebp, eax
    mov eax, dword [ecx*4 + rx2]
    mov dword [esp + 0x54], eax
    mov eax, dword [esp + 0x14]
    mov edx, dword [esp + 0x54]
    mov eax, dword [eax + rx2]
    sub edx, eax
    mov eax, edx
    test eax, eax
    jns short .branch_335
    neg eax

.branch_335:
    mov edx, eax
    mov eax, dword [ecx*4 + ry2]
    mov dword [esp + 0x54], eax
    mov eax, dword [esp + 0x14]
    mov ecx, dword [esp + 0x54]
    mov eax, dword [eax + ry2]
    sub ecx, eax
    mov eax, ecx
    test eax, eax
    jns short .branch_35a
    neg eax

.branch_35a:
    add eax, edx
    add ebp, eax
    cmp ebp, esi
    jge short .branch_394
    mov ecx, dword [esp + 0x48]
    mov edx, dword [esp + 0x2c]
    movsx ecx, word [ecx + engine_1d8560]
    movsx edx, word [edx + engine_1d8560]
    mov eax, dword [ecx*4 + engine_1c3160]
    mov esi, dword [edx*4 + engine_1c3160]
    mov dword [edx*4 + engine_1c3160], eax
    mov dword [ecx*4 + engine_1c3160], esi

.branch_394:
    inc edi

.branch_395:
    cmp edi, ebx
    jl near .branch_210
    inc ebx

.branch_39e:
    cmp ebx, dword [esp + 0x4c]
    jl near .branch_209
    xor edx, edx
    xor ebx, ebx
    mov dword [esp + 4], edx
    mov dword [esp + 0x28], edx
    mov dword [esp + 0x4c], edx

.branch_3b8:
    mov ebp, dword [esp + 0x1c]
    sub ebp, dword [ebx*4 + ry2]

.branch_3c3:
    mov ecx, ebx
    shl ecx, 2
    mov eax, 0xffffffff
    mov edi, dword [ecx + engine_1c3160]
    mov esi, ebp
    mov ebp, dword [esp + 0x1c]
    mov edx, dword [edi*4 + ry2]
    mov dword [ecx + engine_1c3160], eax
    sub ebp, edx
    test esi, esi
    jge short .branch_418
    mov edx, dword [esp + 4]
    mov eax, dword [ecx + rx2]
    mov dword [edx*4 + rx1], eax
    mov eax, dword [ecx + ry2]
    mov dword [edx*4 + ry1], eax
    lea eax, [edx + 1]
    mov dword [esp + 4], eax
    mov dword [edx*4 + engine_1c5160], eax

.branch_418:
    mov eax, esi
    xor eax, ebp
    test eax, eax
    jge near .branch_4d6
    mov eax, esi
    sub eax, ebp
    shl ebx, 2
    mov dword [esp + 0x10], eax
    mov eax, edi
    mov dword [esp + 0x54], ebx
    shl eax, 2
    mov ebx, dword [ebx + rx2]
    mov dword [esp + 0x14], eax
    mov eax, dword [eax + rx2]
    mov ecx, dword [esp + 0x10]
    sub eax, ebx
    mov ebx, esi
    imul ebx
    idiv ecx
    mov edx, dword [esp + 0x54]
    mov ecx, dword [edx + rx2]
    mov edx, dword [esp + 4]
    shl edx, 2
    add eax, ecx
    mov dword [esp + 0xc], edx
    mov dword [edx + rx1], eax
    mov edx, dword [esp + 0x14]
    mov eax, dword [esp + 0x54]
    mov edx, dword [edx + ry2]
    mov ebx, dword [eax + ry2]
    mov eax, edx
    mov ecx, dword [esp + 0x10]
    sub eax, ebx
    mov ebx, esi
    imul ebx
    idiv ecx
    mov edx, dword [esp + 0x54]
    mov ecx, dword [edx + ry2]
    mov edx, dword [esp + 0xc]
    add eax, ecx
    mov dword [edx + ry1], eax
    test esi, esi
    jge short .branch_4c4
    mov eax, dword [esp + 0x4c]
    mov edx, dword [esp + 4]
    lea esi, [eax + 1]
    mov word [nosplit eax*2 + engine_1d8560], dx
    mov dword [esp + 0x4c], esi

.branch_4c4:
    mov edx, dword [esp + 4]
    lea eax, [edx + 1]
    mov dword [esp + 4], eax
    mov dword [edx*4 + engine_1c5160], eax

.branch_4d6:
    mov eax, dword [edi*4 + engine_1c3160]
    mov ebx, edi
    test eax, eax
    jge near .branch_3c3
    mov eax, dword [esp + 0x28]
    mov edx, dword [esp + 4]
    add eax, 3
    cmp eax, edx
    jg short .branch_509
    mov eax, edx
    mov edx, dword [esp + 0x28]
    mov dword [esp + 0x28], eax
    mov dword [eax*4 + engine_1c515c], edx
    jmp short .branch_511

.branch_509:
    mov eax, dword [esp + 0x28]
    mov dword [esp + 4], eax

.branch_511:
    mov ebx, 1
    mov ecx, dword [esp + 0x50]

.branch_51a:
    cmp ebx, ecx
    jge short .branch_52b
    cmp dword [ebx*4 + engine_1c3160], 0
    jge short .branch_52b
    inc ebx
    jmp short .branch_51a

.branch_52b:
    cmp ebx, dword [esp + 0x50]
    jl near .branch_3b8
    cmp dword [esp + 4], 2
    jle near .branch_1f8
    mov ebx, 1
    jmp near .branch_6df

.branch_54a:
    xor edi, edi
    jmp near .branch_6d6

.branch_551:
    lea eax, [ebx + ebx]
    lea ecx, [edi + edi]
    mov dword [esp + 0x38], eax
    mov dword [esp + 0x3c], ecx
    movsx edx, word [eax + engine_1d8560]
    movsx ecx, word [ecx + engine_1d8560]
    mov eax, dword [edx*4 + engine_1c5160]
    mov esi, dword [ecx*4 + engine_1c5160]
    shl eax, 2
    mov dword [esp + 8], esi
    mov dword [esp + 0x14], eax
    mov esi, dword [edx*4 + rx1]
    mov ebp, dword [eax + rx1]
    mov eax, esi
    sub eax, ebp
    test eax, eax
    jns short .branch_59d
    neg eax

.branch_59d:
    mov ebp, eax
    mov eax, dword [esp + 0x14]
    mov esi, dword [edx*4 + ry1]
    sub esi, dword [eax + ry1]
    mov eax, esi
    test eax, eax
    jns short .branch_5b8
    neg eax

.branch_5b8:
    lea esi, [eax + ebp]
    mov eax, dword [ecx*4 + rx1]
    mov ebp, dword [esp + 8]
    mov dword [esp + 0x54], eax
    mov eax, dword [ebp*4 + rx1]
    sub dword [esp + 0x54], eax
    mov eax, dword [esp + 0x54]
    test eax, eax
    jns short .branch_5df
    neg eax

.branch_5df:
    mov dword [esp + 0x10], eax
    mov eax, dword [ecx*4 + ry1]
    mov dword [esp + 0x54], eax
    mov eax, dword [ebp*4 + ry1]
    sub dword [esp + 0x54], eax
    mov eax, dword [esp + 0x54]
    test eax, eax
    jns short .branch_603
    neg eax

.branch_603:
    mov dword [esp + 0xc], eax
    mov eax, dword [esp + 0x10]
    add eax, dword [esp + 0xc]
    add esi, eax
    mov eax, dword [edx*4 + rx1]
    mov dword [esp + 0x54], eax
    mov eax, dword [ebp*4 + rx1]
    sub dword [esp + 0x54], eax
    mov eax, dword [esp + 0x54]
    test eax, eax
    jns short .branch_631
    neg eax

.branch_631:
    mov dword [esp + 0xc], eax
    mov edx, dword [edx*4 + ry1]
    mov eax, dword [ebp*4 + ry1]
    sub edx, eax
    mov eax, edx
    mov ebp, dword [esp + 0xc]
    test eax, eax
    jns short .branch_651
    neg eax

.branch_651:
    add ebp, eax
    mov eax, dword [ecx*4 + rx1]
    mov dword [esp + 0x54], eax
    mov eax, dword [esp + 0x14]
    mov edx, dword [esp + 0x54]
    mov eax, dword [eax + rx1]
    sub edx, eax
    mov eax, edx
    test eax, eax
    jns short .branch_676
    neg eax

.branch_676:
    mov edx, eax
    mov eax, dword [ecx*4 + ry1]
    mov dword [esp + 0x54], eax
    mov eax, dword [esp + 0x14]
    mov ecx, dword [esp + 0x54]
    mov eax, dword [eax + ry1]
    sub ecx, eax
    mov eax, ecx
    test eax, eax
    jns short .branch_69b
    neg eax

.branch_69b:
    add eax, edx
    add ebp, eax
    cmp ebp, esi
    jge short .branch_6d5
    mov ecx, dword [esp + 0x3c]
    mov edx, dword [esp + 0x38]
    movsx ecx, word [ecx + engine_1d8560]
    movsx edx, word [edx + engine_1d8560]
    mov eax, dword [ecx*4 + engine_1c5160]
    mov esi, dword [edx*4 + engine_1c5160]
    mov dword [edx*4 + engine_1c5160], eax
    mov dword [ecx*4 + engine_1c5160], esi

.branch_6d5:
    inc edi

.branch_6d6:
    cmp edi, ebx
    jl near .branch_551
    inc ebx

.branch_6df:
    cmp ebx, dword [esp + 0x4c]
    jl near .branch_54a

.branch_6e9:
    test byte [esp], 5
    je near .branch_d79
    xor esi, esi
    xor ebx, ebx
    mov dword [esp + 0x50], esi
    mov dword [esp + 0x28], esi
    mov dword [esp + 0x4c], esi

.branch_703:
    mov eax, dword [esp + 0x24]
    mov ebp, dword [ebx*4 + rx1]
    sub ebp, eax

.branch_710:
    mov ecx, ebx
    shl ecx, 2
    mov edx, 0xffffffff
    mov edi, dword [ecx + engine_1c5160]
    mov eax, dword [esp + 0x24]
    mov esi, ebp
    mov ebp, dword [edi*4 + rx1]
    mov dword [ecx + engine_1c5160], edx
    sub ebp, eax
    test esi, esi
    jge short .branch_765
    mov edx, dword [esp + 0x50]
    mov eax, dword [ecx + rx1]
    mov dword [edx*4 + rx2], eax
    mov eax, dword [ecx + ry1]
    mov dword [edx*4 + ry2], eax
    lea eax, [edx + 1]
    mov dword [esp + 0x50], eax
    mov dword [edx*4 + engine_1c3160], eax

.branch_765:
    mov eax, esi
    xor eax, ebp
    test eax, eax
    jge near .branch_823
    mov eax, esi
    sub eax, ebp
    shl ebx, 2
    mov dword [esp + 0x10], eax
    mov eax, edi
    mov dword [esp + 0x54], ebx
    shl eax, 2
    mov ebx, dword [ebx + rx1]
    mov dword [esp + 0x14], eax
    mov eax, dword [eax + rx1]
    mov ecx, dword [esp + 0x10]
    sub eax, ebx
    mov ebx, esi
    imul ebx
    idiv ecx
    mov edx, dword [esp + 0x54]
    mov ecx, dword [edx + rx1]
    mov edx, dword [esp + 0x50]
    shl edx, 2
    add eax, ecx
    mov dword [esp + 0xc], edx
    mov dword [edx + rx2], eax
    mov edx, dword [esp + 0x14]
    mov eax, dword [esp + 0x54]
    mov edx, dword [edx + ry1]
    mov ebx, dword [eax + ry1]
    mov eax, edx
    mov ecx, dword [esp + 0x10]
    sub eax, ebx
    mov ebx, esi
    imul ebx
    idiv ecx
    mov edx, dword [esp + 0x54]
    mov ecx, dword [edx + ry1]
    mov edx, dword [esp + 0xc]
    add eax, ecx
    mov dword [edx + ry2], eax
    test esi, esi
    jge short .branch_811
    mov eax, dword [esp + 0x4c]
    mov edx, dword [esp + 0x50]
    lea esi, [eax + 1]
    mov word [nosplit eax*2 + engine_1d8560], dx
    mov dword [esp + 0x4c], esi

.branch_811:
    mov edx, dword [esp + 0x50]
    lea eax, [edx + 1]
    mov dword [esp + 0x50], eax
    mov dword [edx*4 + engine_1c3160], eax

.branch_823:
    mov eax, dword [edi*4 + engine_1c5160]
    mov ebx, edi
    test eax, eax
    jge near .branch_710
    mov eax, dword [esp + 0x28]
    mov edx, dword [esp + 0x50]
    add eax, 3
    cmp eax, edx
    jg short .branch_856
    mov eax, edx
    mov edx, dword [esp + 0x28]
    mov dword [esp + 0x28], eax
    mov dword [eax*4 + engine_1c315c], edx
    jmp short .branch_85e

.branch_856:
    mov eax, dword [esp + 0x28]
    mov dword [esp + 0x50], eax

.branch_85e:
    mov ebx, 1
    mov ecx, dword [esp + 4]

.branch_867:
    cmp ebx, ecx
    jge short .branch_878
    cmp dword [ebx*4 + engine_1c5160], 0
    jge short .branch_878
    inc ebx
    jmp short .branch_867

.branch_878:
    cmp ebx, dword [esp + 4]
    jl near .branch_703
    cmp dword [esp + 0x50], 2
    jle near .branch_1f8
    mov ebx, 1
    jmp near .branch_a2c

.branch_897:
    xor edi, edi
    jmp near .branch_a23

.branch_89e:
    lea eax, [ebx + ebx]
    lea edx, [edi + edi]
    mov dword [esp + 0x44], eax
    mov dword [esp + 0x34], edx
    movsx ecx, word [eax + engine_1d8560]
    movsx edx, word [edx + engine_1d8560]
    mov eax, dword [ecx*4 + engine_1c3160]
    mov esi, dword [edx*4 + engine_1c3160]
    shl eax, 2
    mov dword [esp + 8], esi
    mov dword [esp + 0x14], eax
    mov esi, dword [ecx*4 + rx2]
    mov ebp, dword [eax + rx2]
    mov eax, esi
    sub eax, ebp
    test eax, eax
    jns short .branch_8ea
    neg eax

.branch_8ea:
    mov ebp, eax
    mov eax, dword [esp + 0x14]
    mov esi, dword [ecx*4 + ry2]
    sub esi, dword [eax + ry2]
    mov eax, esi
    test eax, eax
    jns short .branch_905
    neg eax

.branch_905:
    lea esi, [eax + ebp]
    mov eax, dword [edx*4 + rx2]
    mov ebp, dword [esp + 8]
    mov dword [esp + 0x54], eax
    mov eax, dword [ebp*4 + rx2]
    sub dword [esp + 0x54], eax
    mov eax, dword [esp + 0x54]
    test eax, eax
    jns short .branch_92c
    neg eax

.branch_92c:
    mov dword [esp + 0x10], eax
    mov eax, dword [edx*4 + ry2]
    mov dword [esp + 0x54], eax
    mov eax, dword [ebp*4 + ry2]
    sub dword [esp + 0x54], eax
    mov eax, dword [esp + 0x54]
    test eax, eax
    jns short .branch_950
    neg eax

.branch_950:
    mov dword [esp + 0xc], eax
    mov eax, dword [esp + 0x10]
    add eax, dword [esp + 0xc]
    add esi, eax
    mov eax, dword [ecx*4 + rx2]
    mov dword [esp + 0x54], eax
    mov eax, dword [ebp*4 + rx2]
    sub dword [esp + 0x54], eax
    mov eax, dword [esp + 0x54]
    test eax, eax
    jns short .branch_97e
    neg eax

.branch_97e:
    mov dword [esp + 0xc], eax
    mov ecx, dword [ecx*4 + ry2]
    mov eax, dword [ebp*4 + ry2]
    sub ecx, eax
    mov eax, ecx
    mov ebp, dword [esp + 0xc]
    test eax, eax
    jns short .branch_99e
    neg eax

.branch_99e:
    add ebp, eax
    mov eax, dword [edx*4 + rx2]
    mov dword [esp + 0x54], eax
    mov eax, dword [esp + 0x14]
    mov ecx, dword [esp + 0x54]
    mov eax, dword [eax + rx2]
    sub ecx, eax
    mov eax, ecx
    test eax, eax
    jns short .branch_9c3
    neg eax

.branch_9c3:
    mov ecx, eax
    mov eax, dword [edx*4 + ry2]
    mov dword [esp + 0x54], eax
    mov eax, dword [esp + 0x14]
    mov edx, dword [esp + 0x54]
    mov eax, dword [eax + ry2]
    sub edx, eax
    mov eax, edx
    test eax, eax
    jns short .branch_9e8
    neg eax

.branch_9e8:
    add eax, ecx
    add ebp, eax
    cmp ebp, esi
    jge short .branch_a22
    mov edx, dword [esp + 0x34]
    mov ecx, dword [esp + 0x44]
    movsx edx, word [edx + engine_1d8560]
    movsx ecx, word [ecx + engine_1d8560]
    mov eax, dword [edx*4 + engine_1c3160]
    mov esi, dword [ecx*4 + engine_1c3160]
    mov dword [ecx*4 + engine_1c3160], eax
    mov dword [edx*4 + engine_1c3160], esi

.branch_a22:
    inc edi

.branch_a23:
    cmp edi, ebx
    jl near .branch_89e
    inc ebx

.branch_a2c:
    cmp ebx, dword [esp + 0x4c]
    jl near .branch_897
    xor edx, edx
    xor ebx, ebx
    mov dword [esp + 4], edx
    mov dword [esp + 0x28], edx
    mov dword [esp + 0x4c], edx

.branch_a46:
    mov ecx, dword [esp + 0x18]
    mov ebp, dword [ebx*4 + ry2]
    sub ebp, ecx

.branch_a53:
    mov ecx, ebx
    mov esi, 0xffffffff
    shl ecx, 2
    mov eax, dword [esp + 0x18]
    mov edi, dword [ecx + engine_1c3160]
    mov dword [ecx + engine_1c3160], esi
    mov esi, ebp
    mov ebp, dword [edi*4 + ry2]
    sub ebp, eax
    test esi, esi
    jge short .branch_aa8
    mov edx, dword [esp + 4]
    mov eax, dword [ecx + rx2]
    mov dword [edx*4 + rx1], eax
    mov eax, dword [ecx + ry2]
    mov dword [edx*4 + ry1], eax
    lea eax, [edx + 1]
    mov dword [esp + 4], eax
    mov dword [edx*4 + engine_1c5160], eax

.branch_aa8:
    mov eax, esi
    xor eax, ebp
    test eax, eax
    jge near .branch_b66
    mov eax, esi
    sub eax, ebp
    shl ebx, 2
    mov dword [esp + 0x14], eax
    mov eax, edi
    mov dword [esp + 0xc], ebx
    shl eax, 2
    mov ebx, dword [ebx + rx2]
    mov dword [esp + 0x54], eax
    mov eax, dword [eax + rx2]
    mov ecx, dword [esp + 0x14]
    sub eax, ebx
    mov ebx, esi
    imul ebx
    idiv ecx
    mov edx, dword [esp + 0xc]
    mov ecx, dword [edx + rx2]
    mov edx, dword [esp + 4]
    shl edx, 2
    add eax, ecx
    mov dword [esp + 0x10], edx
    mov dword [edx + rx1], eax
    mov edx, dword [esp + 0x54]
    mov eax, dword [esp + 0xc]
    mov edx, dword [edx + ry2]
    mov ebx, dword [eax + ry2]
    mov eax, edx
    mov ecx, dword [esp + 0x14]
    sub eax, ebx
    mov ebx, esi
    imul ebx
    idiv ecx
    mov edx, dword [esp + 0xc]
    mov ecx, dword [edx + ry2]
    mov edx, dword [esp + 0x10]
    add eax, ecx
    mov dword [edx + ry1], eax
    test esi, esi
    jge short .branch_b54
    mov eax, dword [esp + 0x4c]
    mov edx, dword [esp + 4]
    lea esi, [eax + 1]
    mov word [nosplit eax*2 + engine_1d8560], dx
    mov dword [esp + 0x4c], esi

.branch_b54:
    mov edx, dword [esp + 4]
    lea eax, [edx + 1]
    mov dword [esp + 4], eax
    mov dword [edx*4 + engine_1c5160], eax

.branch_b66:
    mov eax, dword [edi*4 + engine_1c3160]
    mov ebx, edi
    test eax, eax
    jge near .branch_a53
    mov eax, dword [esp + 0x28]
    mov edx, dword [esp + 4]
    add eax, 3
    cmp eax, edx
    jg short .branch_b99
    mov eax, edx
    mov edx, dword [esp + 0x28]
    mov dword [esp + 0x28], eax
    mov dword [eax*4 + engine_1c515c], edx
    jmp short .branch_ba1

.branch_b99:
    mov eax, dword [esp + 0x28]
    mov dword [esp + 4], eax

.branch_ba1:
    mov ebx, 1
    mov ecx, dword [esp + 0x50]

.branch_baa:
    cmp ebx, ecx
    jge short .branch_bbb
    cmp dword [ebx*4 + engine_1c3160], 0
    jge short .branch_bbb
    inc ebx
    jmp short .branch_baa

.branch_bbb:
    cmp ebx, dword [esp + 0x50]
    jl near .branch_a46
    cmp dword [esp + 4], 2
    jle near .branch_1f8
    mov ebx, 1
    jmp near .branch_d6f

.branch_bda:
    xor edi, edi
    jmp near .branch_d66

.branch_be1:
    lea eax, [ebx + ebx]
    lea ecx, [edi + edi]
    mov dword [esp + 0x40], eax
    mov dword [esp + 0x30], ecx
    movsx edx, word [eax + engine_1d8560]
    movsx ecx, word [ecx + engine_1d8560]
    mov eax, dword [edx*4 + engine_1c5160]
    mov esi, dword [ecx*4 + engine_1c5160]
    shl eax, 2
    mov dword [esp + 8], esi
    mov dword [esp + 0x10], eax
    mov esi, dword [edx*4 + rx1]
    mov ebp, dword [eax + rx1]
    mov eax, esi
    sub eax, ebp
    test eax, eax
    jns short .branch_c2d
    neg eax

.branch_c2d:
    mov ebp, eax
    mov eax, dword [esp + 0x10]
    mov esi, dword [edx*4 + ry1]
    sub esi, dword [eax + ry1]
    mov eax, esi
    test eax, eax
    jns short .branch_c48
    neg eax

.branch_c48:
    lea esi, [eax + ebp]
    mov eax, dword [ecx*4 + rx1]
    mov ebp, dword [esp + 8]
    mov dword [esp + 0x54], eax
    mov eax, dword [ebp*4 + rx1]
    sub dword [esp + 0x54], eax
    mov eax, dword [esp + 0x54]
    test eax, eax
    jns short .branch_c6f
    neg eax

.branch_c6f:
    mov dword [esp + 0x14], eax
    mov eax, dword [ecx*4 + ry1]
    mov dword [esp + 0x54], eax
    mov eax, dword [ebp*4 + ry1]
    sub dword [esp + 0x54], eax
    mov eax, dword [esp + 0x54]
    test eax, eax
    jns short .branch_c93
    neg eax

.branch_c93:
    mov dword [esp + 0x54], eax
    mov eax, dword [esp + 0x14]
    add eax, dword [esp + 0x54]
    add esi, eax
    mov eax, dword [edx*4 + rx1]
    mov dword [esp + 0x54], eax
    mov eax, dword [ebp*4 + rx1]
    sub dword [esp + 0x54], eax
    mov eax, dword [esp + 0x54]
    test eax, eax
    jns short .branch_cc1
    neg eax

.branch_cc1:
    mov dword [esp + 0x54], eax
    mov edx, dword [edx*4 + ry1]
    mov eax, dword [ebp*4 + ry1]
    sub edx, eax
    mov eax, edx
    mov ebp, dword [esp + 0x54]
    test eax, eax
    jns short .branch_ce1
    neg eax

.branch_ce1:
    add ebp, eax
    mov eax, dword [ecx*4 + rx1]
    mov dword [esp + 0x54], eax
    mov eax, dword [esp + 0x10]
    mov edx, dword [esp + 0x54]
    mov eax, dword [eax + rx1]
    sub edx, eax
    mov eax, edx
    test eax, eax
    jns short .branch_d06
    neg eax

.branch_d06:
    mov edx, eax
    mov eax, dword [ecx*4 + ry1]
    mov dword [esp + 0x54], eax
    mov eax, dword [esp + 0x10]
    mov ecx, dword [esp + 0x54]
    mov eax, dword [eax + ry1]
    sub ecx, eax
    mov eax, ecx
    test eax, eax
    jns short .branch_d2b
    neg eax

.branch_d2b:
    add eax, edx
    add ebp, eax
    cmp ebp, esi
    jge short .branch_d65
    mov ecx, dword [esp + 0x30]
    mov edx, dword [esp + 0x40]
    movsx ecx, word [ecx + engine_1d8560]
    movsx edx, word [edx + engine_1d8560]
    mov eax, dword [ecx*4 + engine_1c5160]
    mov esi, dword [edx*4 + engine_1c5160]
    mov dword [edx*4 + engine_1c5160], eax
    mov dword [ecx*4 + engine_1c5160], esi

.branch_d65:
    inc edi

.branch_d66:
    cmp edi, ebx
    jl near .branch_be1
    inc ebx

.branch_d6f:
    cmp ebx, dword [esp + 0x4c]
    jl near .branch_bda

.branch_d79:
    mov esi, dword [esp + 4]

.branch_d7d:
    mov eax, esi
    add esp, 0x58
    jmp near ceiling_sprite_restore

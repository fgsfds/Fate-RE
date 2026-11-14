; Order and draw masked walls and sprites after the opaque room pass.
BITS 32
ORG 0x4cc8a

xdimen equ 0x140b5
tsprite equ 0x2710a0
maskwall equ 0x19b6e0
maskwall_count equ 0x28914c
scan_wall equ 0x1c2160
wall equ 0x2310a0
globalposz equ 0x286ad8
engine_14004 equ 0x14004
engine_287e84 equ 0x287e84
engine_286ad0 equ 0x286ad0
engine_286ad4 equ 0x286ad4
engine_2710a4 equ 0x2710a4
engine_286ac8 equ 0x286ac8
engine_286af8 equ 0x286af8
engine_19c6e0 equ 0x19c6e0
engine_2710ac equ 0x2710ac
engine_19d6e0 equ 0x19d6e0
engine_27c048 equ 0x27c048
engine_19b6de equ 0x19b6de
engine_1c5160 equ 0x1c5160
engine_1c3160 equ 0x1c3160
engine_2710be equ 0x2710be
spritewallfront equ 0x45527
drawsprite equ 0x4d6ca
drawmaskwall equ 0x4d193
transmaskvline2_return equ 0x4b026

drawmasks_:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 0x20
    cmp dword [engine_14004], 0
    jle short .branch_01d
    mov eax, 2
    mov edx, 0x3c4
    out dx, al

.branch_01d:
    mov eax, dword [engine_287e84]
    dec eax
    mov dword [esp + 0x10], eax
    jmp near .branch_147

.branch_02c:
    imul ecx, ebx, 0x2c
    mov edi, dword [engine_286ad0]
    mov eax, dword [ecx + tsprite]
    sub eax, edi
    mov ebp, dword [engine_286ad4]
    mov dword [esp + 8], eax
    mov eax, dword [ecx + engine_2710a4]
    mov ebx, dword [engine_286ac8]
    sub eax, ebp
    mov edi, dword [engine_286af8]
    mov dword [esp + 4], eax
    mov esi, eax
    mov eax, dword [esp + 8]
    mov ebp, dword [esp + 0x10]
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 6
    shl ebp, 2
    mov dword [esp + 0xc], eax
    mov dword [esp], eax
    cmp eax, 0x400
    jle short .branch_0cb
    mov esi, dword [esp + 8]
    mov eax, dword [esp + 4]
    mov edi, dword [engine_286af8]
    mov ebx, dword [engine_286ac8]
    neg esi
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 6
    mov ebx, dword [xdimen]
    mov esi, dword [esp + 0xc]
    shl ebx, 7
    mov ecx, esi
    add eax, esi
    imul ebx
    idiv ecx
    mov dword [ebp + engine_19c6e0], eax
    jmp short .branch_135

.branch_0cb:
    mov ax, word [ecx + engine_2710ac]
    xor ah, ah
    and al, 0x30
    cwde
    test eax, eax
    jne short .branch_135
    mov edx, dword [engine_287e84]
    dec edx
    mov eax, dword [esp + 0x10]
    mov dword [engine_287e84], edx
    cmp eax, edx
    je short .branch_143
    imul esi, edx, 0x2c
    mov edi, tsprite
    add edi, ecx
    mov ecx, 0x2c
    add esi, tsprite
    test cl, 1
    je short .branch_10b
    movsb

.branch_10b:
    shr ecx, 2
    jae short .branch_112
    movsw

.branch_112:
    rep movsd
    mov eax, dword [engine_287e84]
    mov edx, dword [eax*4 + engine_19c6e0]
    mov eax, dword [eax*4 + engine_19d6e0]
    mov dword [ebp + engine_19c6e0], edx
    mov dword [ebp + engine_19d6e0], eax
    jmp short .branch_143

.branch_135:
    mov eax, dword [esp + 0x10]
    mov edx, dword [esp]
    mov dword [eax*4 + engine_19d6e0], edx

.branch_143:
    dec dword [esp + 0x10]

.branch_147:
    mov ebx, dword [esp + 0x10]
    test ebx, ebx
    jge near .branch_02c
    mov eax, dword [engine_287e84]
    mov ecx, engine_27c048
    sar eax, 1
    mov dword [esp + 0x14], ecx
    mov dword [esp + 0x18], eax
    jmp near .branch_332

.branch_16c:
    xor eax, eax
    mov dword [esp + 0x10], eax
    jmp near .branch_313

.branch_177:
    mov ebp, ecx
    jmp near .branch_307

.branch_17e:
    mov eax, dword [esp + 0x18]
    add eax, ebp
    mov ecx, dword [ebp*4 + engine_19d6e0]
    sub ecx, dword [eax*4 + engine_19d6e0]
    test ecx, ecx
    jl near .branch_30f
    imul ebx, ebp, 0x2c
    imul eax, eax, 0x2c
    mov edx, tsprite
    add ebx, tsprite
    add edx, eax
    test ecx, ecx
    jne near .branch_277
    movsx ecx, word [ebx + 0x1a]
    movsx eax, word [edx + 0x1a]
    sub ecx, eax
    test ecx, ecx
    jl near .branch_30f
    jne near .branch_277
    mov ax, word [ebx + 0xc]
    xor ah, ah
    and al, 0x30
    cwde
    cmp eax, 0x20
    jne short .branch_228
    mov edi, dword [globalposz]
    mov eax, dword [edx + 8]
    sub eax, edi
    mov dword [esp + 0x1c], eax
    mov ax, word [edx + 0xc]
    xor ah, ah
    and al, 0x30
    mov ecx, dword [ebx + 8]
    cwde
    sub ecx, edi
    cmp eax, 0x20
    je short .branch_205
    sub dword [esp + 0x1c], 0x100

.branch_205:
    cmp ecx, dword [esp + 0x1c]
    setl al
    mov esi, eax
    and esi, 0xff
    test ecx, ecx
    setl al
    and eax, 0xff
    cmp eax, esi
    jne near .branch_30f
    jmp short .branch_277

.branch_228:
    mov ax, word [edx + 0xc]
    xor ah, ah
    and al, 0x30
    cwde
    cmp eax, 0x20
    jne short .branch_277
    mov ecx, dword [globalposz]
    mov eax, dword [ebx + 8]
    sub eax, ecx
    lea ecx, [eax - 0x100]
    mov esi, dword [globalposz]
    mov eax, dword [edx + 8]
    sub eax, esi
    mov dword [esp + 0x1c], eax
    mov esi, eax
    cmp ecx, eax
    setg al
    mov ecx, eax
    and ecx, 0xff
    test esi, esi
    setl al
    and eax, 0xff
    cmp eax, ecx
    je near .branch_30f

.branch_277:
    mov ecx, 0x2c
    mov edi, dword [esp + 0x14]
    mov esi, ebx
    test cl, 1
    je short .branch_288
    movsb

.branch_288:
    shr ecx, 2
    jae short .branch_28f
    movsw

.branch_28f:
    rep movsd
    mov ecx, 0x2c
    mov edi, ebx
    mov esi, edx
    test cl, 1
    je short .branch_2a0
    movsb

.branch_2a0:
    shr ecx, 2
    jae short .branch_2a7
    movsw

.branch_2a7:
    rep movsd
    mov ecx, 0x2c
    mov esi, dword [esp + 0x14]
    mov ebx, dword [esp + 0x18]
    mov edi, edx
    add ebx, ebp
    test cl, 1
    je short .branch_2c0
    movsb

.branch_2c0:
    shr ecx, 2
    jae short .branch_2c7
    movsw

.branch_2c7:
    rep movsd
    mov edi, dword [esp + 0x18]
    mov ecx, dword [ebx*4 + engine_19c6e0]
    mov eax, dword [ebp*4 + engine_19c6e0]
    mov dword [ebp*4 + engine_19c6e0], ecx
    mov ecx, dword [ebx*4 + engine_19d6e0]
    mov dword [ebx*4 + engine_19c6e0], eax
    mov eax, dword [ebp*4 + engine_19d6e0]
    mov dword [ebp*4 + engine_19d6e0], ecx
    sub ebp, edi
    mov dword [ebx*4 + engine_19d6e0], eax

.branch_307:
    test ebp, ebp
    jge near .branch_17e

.branch_30f:
    inc dword [esp + 0x10]

.branch_313:
    mov ebx, dword [esp + 0x18]
    mov eax, dword [engine_287e84]
    mov ecx, dword [esp + 0x10]
    sub eax, ebx
    cmp eax, ecx
    jg near .branch_177
    mov esi, ebx
    sar esi, 1
    mov dword [esp + 0x18], esi

.branch_332:
    cmp dword [esp + 0x18], 0
    jg near .branch_16c

.branch_33d:
    cmp dword [engine_287e84], 0
    jle near .branch_4cc
    mov dx, word [maskwall_count]
    test dx, dx
    jle near .branch_4cc
    mov eax, dword [engine_287e84]
    dec eax
    imul eax, eax, 0x2c
    movsx ecx, dx
    movsx ecx, word [nosplit ecx*2 + engine_19b6de]
    movsx edx, word [nosplit ecx*2 + scan_wall]
    add eax, tsprite
    call spritewallfront
    test eax, eax
    jne short .branch_39a
    mov edi, dword [engine_287e84]
    dec edi
    mov eax, edi
    mov dword [engine_287e84], edi
    call drawsprite
    jmp short .branch_33d

.branch_39a:
    mov ebx, 0xffffffff
    mov eax, dword [engine_287e84]
    xor esi, esi
    mov dword [esp + 0x1c], ebx
    sub eax, 2
    mov dword [esp + 0x18], esi
    mov dword [esp + 0x10], eax
    jmp short .branch_419

.branch_3b7:
    mov eax, ecx
    mov edx, dword [edx*4 + engine_19c6e0]
    shl eax, 2
    sar edx, 8
    cmp edx, dword [eax + engine_1c5160]
    jl short .branch_415
    cmp edx, dword [eax + engine_1c3160]
    jg short .branch_415
    mov ebp, dword [esp + 0x10]
    imul ebx, ebp, 0x2c
    mov eax, tsprite
    movsx edx, word [nosplit ecx*2 + scan_wall]
    add eax, ebx
    call spritewallfront
    test eax, eax
    jne short .branch_415
    mov eax, ebp
    mov esi, 0xffffffff
    call drawsprite
    mov eax, dword [esp + 0x18]
    mov dword [esp + 0x1c], ebp
    inc eax
    mov word [ebx + engine_2710be], si
    mov dword [esp + 0x18], eax

.branch_415:
    dec dword [esp + 0x10]

.branch_419:
    mov edx, dword [esp + 0x10]
    test edx, edx
    jge short .branch_3b7
    mov ebx, dword [esp + 0x1c]
    test ebx, ebx
    jl near .branch_4b4
    mov dword [esp + 0x10], ebx
    jmp short .branch_498

.branch_433:
    imul eax, eax, 0x2c
    cmp word [eax + engine_2710be], 0
    jl short .branch_494
    mov edx, dword [esp + 0x10]
    mov edi, dword [esp + 0x1c]
    cmp edx, edi
    jle short .branch_490
    mov ebp, edi
    imul edi, edi, 0x2c
    mov esi, tsprite
    mov ecx, 0x2c
    add esi, eax
    add edi, tsprite
    test cl, 1
    je short .branch_469
    movsb

.branch_469:
    shr ecx, 2
    jae short .branch_470
    movsw

.branch_470:
    rep movsd
    mov eax, ebp
    mov ebx, dword [edx*4 + engine_19c6e0]
    mov edx, dword [edx*4 + engine_19d6e0]
    mov dword [eax*4 + engine_19c6e0], ebx
    mov dword [eax*4 + engine_19d6e0], edx

.branch_490:
    inc dword [esp + 0x1c]

.branch_494:
    inc dword [esp + 0x10]

.branch_498:
    mov eax, dword [esp + 0x10]
    mov ebx, dword [engine_287e84]
    cmp eax, ebx
    jl short .branch_433
    mov eax, dword [esp + 0x18]
    mov ecx, ebx
    sub ecx, eax
    mov dword [engine_287e84], ecx

.branch_4b4:
    mov ax, word [maskwall_count]
    dec eax
    mov word [maskwall_count], ax
    cwde
    call drawmaskwall
    jmp near .branch_33d

.branch_4cc:
    mov ebp, dword [engine_287e84]
    test ebp, ebp
    jle short .branch_4e5
    lea eax, [ebp - 1]
    mov dword [engine_287e84], eax
    call drawsprite
    jmp short .branch_4cc

.branch_4e5:
    mov bx, word [maskwall_count]
    test bx, bx
    jle near transmaskvline2_return
    mov ecx, ebx
    dec ecx
    movsx eax, cx
    mov word [maskwall_count], cx
    call drawmaskwall
    jmp short .branch_4e5

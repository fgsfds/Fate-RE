; Clip a masked portal wall and dispatch its masked or translucent raster.
BITS 32
ORG 0x4d193

sector equ 0x27c3a0
wall equ 0x2310a0
picanm equ 0x1ed3a0
picsiz equ 0x1e5fe0
pow2long equ 0x14031
move_tile_heights equ 0x1f4020
dwall equ 0x1a63e0
globalpal equ 0x286adc
globalpicnum equ 0x289144
globalshade equ 0x286a88
globalxpanning equ 0x286abc
globalyscale equ 0x286ab4
globalzd equ 0x286a8c
globvis equ 0x286ab8
lwall equ 0x199150
swall equ 0x1a18e0
uwall equ 0x19aa60
globalorientation equ 0x286a84
globalypanning equ 0x286ac0
maskwall equ 0x19b6e0
scan_sector equ 0x1dbde0
scan_wall equ 0x1c2160
xb2 equ 0x1c3160
xb1 equ 0x1c5160
engine_1a3e60 equ 0x1a3e60
engine_19f360 equ 0x19f360
engine_286a9c equ 0x286a9c
engine_289146 equ 0x289146
engine_286ad8 equ 0x286ad8
engine_286a85 equ 0x286a85
engine_140b1 equ 0x140b1
engine_1d5560 equ 0x1d5560
engine_1db5e0 equ 0x1db5e0
engine_1da560 equ 0x1da560
engine_1a8960 equ 0x1a8960
engine_28912a equ 0x28912a
engine_14187 equ 0x14187
engine_2863cc equ 0x2863cc
engine_289124 equ 0x289124
engine_289128 equ 0x289128
engine_289122 equ 0x289122
wallmost equ 0x5e824
prepwall equ 0x4751e
animateoffs equ 0x50758
wallfront equ 0x45313
maskwallscan equ 0x49190
settransreverse equ 0x74450
settransnormal equ 0x743d0
transmaskwallscan equ 0x49dd1
transmaskvline_restore equ 0x4abbe

drawmaskwall_:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 0x14
    movsx ebp, ax
    movsx ebp, word [nosplit ebp*2 + maskwall]
    movsx eax, word [nosplit ebp*2 + scan_sector]
    mov dword [esp + 8], eax
    mov edx, eax
    shl eax, 2
    movsx edi, word [nosplit ebp*2 + scan_wall]
    add eax, edx
    mov edx, sector
    shl eax, 3
    shl edi, 5
    add edx, eax
    add edi, wall
    mov dword [esp + 0xc], edx
    movsx edx, word [edi + 0xc]
    mov eax, edx
    shl eax, 2
    add eax, edx
    shl eax, 3
    mov ebx, dword [esp + 0xc]
    add eax, sector
    mov ecx, dword [ebx + 4]
    mov edx, dword [eax + 4]
    cmp edx, ecx
    jg short .branch_069
    mov edx, ecx

.branch_069:
    mov ebx, dword [esp + 0xc]
    mov dword [esp], edx
    mov edx, dword [eax + 8]
    mov esi, dword [ebx + 8]
    cmp edx, esi
    jge short .branch_07e
    mov eax, edx
    jmp short .branch_080

.branch_07e:
    mov eax, esi

.branch_080:
    mov ebx, dword [esp + 8]
    mov dword [esp + 4], eax
    mov edx, ebp
    xor ecx, ecx
    mov eax, uwall
    call wallmost
    mov eax, engine_1a3e60
    mov edx, ebp
    movsx ebx, word [edi + 0xc]
    xor ecx, ecx
    call wallmost
    mov eax, dword [ebp*4 + xb1]
    jmp short .branch_0cc

.branch_0b1:
    lea edx, [eax + eax]
    mov bx, word [edx + engine_1a3e60]
    cmp bx, word [edx + uwall]
    jle short .branch_0cb
    mov word [edx + uwall], bx

.branch_0cb:
    inc eax

.branch_0cc:
    mov esi, ebp
    shl esi, 2
    cmp eax, dword [esi + xb2]
    jle short .branch_0b1
    mov ecx, 1
    mov ebx, dword [esp + 8]
    mov eax, dwall
    mov edx, ebp
    call wallmost
    mov ecx, 1
    mov eax, engine_19f360
    mov edx, ebp
    movsx ebx, word [edi + 0xc]
    call wallmost
    mov eax, dword [esi + xb1]
    jmp short .branch_126

.branch_10b:
    lea edx, [eax + eax]
    mov bx, word [edx + engine_19f360]
    cmp bx, word [edx + dwall]
    jge short .branch_125
    mov word [edx + dwall], bx

.branch_125:
    inc eax

.branch_126:
    cmp eax, dword [ebp*4 + xb2]
    jle short .branch_10b
    mov edx, edi
    mov eax, ebp
    call prepwall
    movsx eax, word [edi + 0xe]
    mov dword [globalorientation], eax
    mov ax, word [edi + 0x12]
    mov word [globalpicnum], ax
    cwde
    test eax, 0xfffff000
    je short .branch_15c
    xor esi, esi
    mov word [globalpicnum], si

.branch_15c:
    xor eax, eax
    mov al, byte [edi + 0x18]
    mov dword [globalxpanning], eax
    xor eax, eax
    mov al, byte [edi + 0x19]
    mov dword [globalypanning], eax
    movsx eax, word [globalpicnum]
    test byte [eax*4 + picanm], 0xc0
    je short .branch_19b
    movsx edx, word [nosplit ebp*2 + scan_wall]
    add edx, 0x4000
    call animateoffs
    add word [globalpicnum], ax

.branch_19b:
    movsx eax, byte [edi + 0x14]
    mov dword [globalshade], eax
    mov eax, dword [engine_286a9c]
    mov dword [globvis], eax
    mov eax, dword [esp + 0xc]
    mov bh, byte [eax + 0x20]
    test bh, bh
    je short .branch_1d1
    mov al, bh
    add al, 0x10
    xor ebx, ebx
    mov bl, al
    mov eax, dword [globvis]
    imul ebx
    shrd eax, edx, 4
    mov dword [globvis], eax

.branch_1d1:
    xor eax, eax
    mov al, byte [edi + 0x15]
    mov dword [globalpal], eax
    movsx eax, word [globalpicnum]
    xor edx, edx
    mov dl, byte [eax + picsiz]
    sar edx, 4
    mov word [engine_289146], dx
    movsx edx, word [nosplit eax*2 + move_tile_heights]
    movsx eax, word [engine_289146]
    cmp edx, dword [eax*4 + pow2long]
    je short .branch_213
    inc word [engine_289146]

.branch_213:
    mov eax, 0x20
    mov cx, word [engine_289146]
    sub eax, ecx
    mov word [engine_289146], ax
    movsx ecx, word [engine_289146]
    xor eax, eax
    sub ecx, 0x13
    mov al, byte [edi + 0x17]
    shl eax, cl
    mov cl, byte [globalorientation]
    mov dword [globalyscale], eax
    test cl, 4
    jne short .branch_25d
    mov edx, dword [esp]
    mov eax, dword [engine_286ad8]
    mov ebx, dword [globalyscale]
    sub eax, edx
    imul eax, ebx
    jmp short .branch_271

.branch_25d:
    mov esi, dword [esp + 4]
    mov eax, dword [engine_286ad8]
    mov edi, dword [globalyscale]
    sub eax, esi
    imul eax, edi

.branch_271:
    shl eax, 8
    mov dword [globalzd], eax
    mov eax, dword [globalypanning]
    mov ecx, dword [globalzd]
    shl eax, 0x18
    add ecx, eax
    mov dword [globalzd], ecx
    test byte [engine_286a85], 1
    je short .branch_2b4
    mov esi, dword [globalyscale]
    mov edi, dword [globalzd]
    neg esi
    neg edi
    mov dword [globalyscale], esi
    mov dword [globalzd], edi

.branch_2b4:
    mov eax, dword [engine_140b1]
    dec eax
    mov dword [esp + 0x10], eax
    jmp near .branch_452

.branch_2c3:
    mov esi, dword [eax*4 + engine_1d5560]
    mov ecx, esi
    shl ecx, 2
    mov edx, dword [ebx + xb2]
    cmp edx, dword [ecx + xb1]
    jl near .branch_44e
    mov eax, dword [ecx + xb2]
    cmp eax, dword [ebx + xb1]
    jl near .branch_44e
    mov edx, ebp
    mov eax, esi
    call wallfront
    test eax, eax
    jne near .branch_44e
    mov eax, dword [ecx + xb1]
    mov edx, dword [ebx + xb1]
    cmp eax, edx
    jg short .branch_316
    mov eax, edx

.branch_316:
    mov ecx, esi
    mov edx, ebp
    shl ecx, 2
    shl edx, 2
    mov ebx, dword [ecx + xb2]
    mov edi, dword [edx + xb2]
    cmp ebx, edi
    jge short .branch_334
    mov ecx, ebx
    jmp short .branch_336

.branch_334:
    mov ecx, edi

.branch_336:
    mov edx, dword [esp + 0x10]
    mov dl, byte [edx + engine_1db5e0]
    mov edi, ecx
    cmp dl, 1
    jb short .branch_367
    mov ecx, dword [esp + 0x10]
    shl esi, 2
    add ecx, ecx
    cmp dl, 1
    jbe near .branch_3e6
    cmp dl, 2
    je near .branch_41b
    jmp near .branch_44e

.branch_367:
    test dl, dl
    jne near .branch_44e
    cmp eax, ecx
    jg near .branch_44e
    mov edx, ebp
    shl edx, 2
    cmp eax, dword [edx + xb1]
    jne short .branch_390
    cmp ecx, dword [edx + xb2]
    je near .branch_52f

.branch_390:
    mov ecx, edi
    sub ecx, eax
    mov edi, dwall
    add ecx, ecx
    add eax, eax
    add ecx, 2
    add edi, eax
    xor eax, eax
    cmp ecx, 4
    jae short .branch_3b6
    test cl, 1
    je short .branch_3af
    stosb

.branch_3af:
    shr ecx, 1
    db 0xf3                       ; REP precedes the operand-size prefix
    stosw
    jmp short .branch_3e1

.branch_3b6:
    test edi, 1
    je short .branch_3c0
    stosb
    dec ecx

.branch_3c0:
    test edi, 2
    je short .branch_3cd
    stosw
    sub ecx, 2

.branch_3cd:
    mov ebx, ecx
    shr ecx, 2
    rep stosd
    test bl, 2
    je short .branch_3db
    stosw

.branch_3db:
    test bl, 1
    je short .branch_3e1
    stosb

.branch_3e1:
    jmp near .branch_44e

.branch_3e6:
    movsx ecx, word [ecx + engine_1da560]
    sub ecx, dword [esi + xb1]
    jmp short .branch_415

.branch_3f5:
    lea ebx, [ecx + eax]
    add ebx, ebx
    mov si, word [ebx + engine_1a8960]
    lea edx, [eax + eax]
    cmp si, word [edx + uwall]
    jle short .branch_414
    mov word [edx + uwall], si

.branch_414:
    inc eax

.branch_415:
    cmp eax, edi
    jle short .branch_3f5
    jmp short .branch_44e

.branch_41b:
    movsx ecx, word [ecx + engine_1da560]
    sub ecx, dword [esi + xb1]
    jmp short .branch_44a

.branch_42a:
    lea edx, [ecx + eax]
    add edx, edx
    mov si, word [edx + engine_1a8960]
    lea ebx, [eax + eax]
    cmp si, word [ebx + dwall]
    jge short .branch_449
    mov word [ebx + dwall], si

.branch_449:
    inc eax

.branch_44a:
    cmp eax, edi
    jle short .branch_42a

.branch_44e:
    dec dword [esp + 0x10]

.branch_452:
    mov ebx, ebp
    mov eax, dword [esp + 0x10]
    shl ebx, 2
    test eax, eax
    jge near .branch_2c3
    movsx eax, word [engine_28912a]
    cmp eax, 1
    jl short .branch_4d1
    mov eax, dword [engine_14187]
    cmp eax, dword [ebx + xb1]
    jl short .branch_4d1
    cmp eax, dword [ebx + xb2]
    jg short .branch_4d1
    add eax, eax
    mov esi, dword [engine_2863cc]
    movsx edx, word [eax + uwall]
    cmp edx, esi
    jg short .branch_4d1
    movsx eax, word [eax + dwall]
    cmp eax, esi
    jl short .branch_4d1
    mov eax, dword [esp + 8]
    mov word [engine_289124], ax
    mov ax, word [nosplit ebp*2 + scan_wall]
    mov edi, 4
    mov word [engine_289128], ax
    mov eax, 1
    mov word [engine_289122], di
    mov word [engine_28912a], ax

.branch_4d1:
    mov al, byte [globalorientation]
    test al, 0x80
    jne short .branch_503
    push lwall
    mov ecx, dwall
    mov ebx, uwall
    push swall
    mov edx, dword [ebp*4 + xb2]
    mov eax, dword [ebp*4 + xb1]
    call maskwallscan
    jmp short .branch_52f

.branch_503:
    test al, 0x80
    je short .branch_51c
    test byte [engine_286a85], 2
    je short .branch_517
    call settransreverse
    jmp short .branch_51c

.branch_517:
    call settransnormal

.branch_51c:
    mov edx, dword [ebp*4 + xb2]
    mov eax, dword [ebp*4 + xb1]
    call transmaskwallscan

.branch_52f:
    add esp, 0x14
    jmp near transmaskvline_restore

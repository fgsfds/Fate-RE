; Project face, wall, and floor sprites and dispatch the corresponding raster paths.
BITS 32
ORG 0x4d6ca

sector equ 0x27c3a0
wall equ 0x2310a0
picanm equ 0x1ed3a0
picsiz equ 0x1e5fe0
pow2long equ 0x14031
tilesizx equ 0x1f2020
move_tile_heights equ 0x1f4020
walock equ 0x1f8ca0
waloff equ 0x1ffca0
pow2char equ 0x14029
startdmost equ 0x1f8020
startumost equ 0x1f13a0
dwall equ 0x1a63e0
globalhoriz equ 0x286ae4
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
windowx1 equ 0x286b9c
windowy1 equ 0x286b94
xdimen equ 0x140b5
sprite_visibility equ 0x1ecfa0
globalbufplc equ 0x286a90
globalorientation equ 0x286a84
globalx1 equ 0x286a80
globalx2 equ 0x286a4c
globaly1 equ 0x286a50
globaly2 equ 0x286a58
globalypanning equ 0x286ac0
reciptable equ 0x1d3160
sintable equ 0x2300a0
tsprite equ 0x2710a0
sprite_screen_x equ 0x19c6e0
sprite_depth equ 0x19d6e0
globalposx equ 0x286ad0
globalposy equ 0x286ad4
globalposz equ 0x286ad8
engine_286b00 equ 0x286b00
engine_286bac equ 0x286bac
engine_1a63de equ 0x1a63de
engine_140b1 equ 0x140b1
engine_1d5560 equ 0x1d5560
engine_1c5160 equ 0x1c5160
engine_1c3160 equ 0x1c3160
engine_1c9160 equ 0x1c9160
engine_1c7160 equ 0x1c7160
engine_1c2160 equ 0x1c2160
engine_1db5e0 equ 0x1db5e0
engine_1da560 equ 0x1da560
engine_1a8960 equ 0x1a8960
engine_28912a equ 0x28912a
engine_14187 equ 0x14187
engine_2863cc equ 0x2863cc
engine_289124 equ 0x289124
engine_289122 equ 0x289122
engine_289128 equ 0x289128
engine_286a9c equ 0x286a9c
engine_289146 equ 0x289146
engine_286b14 equ 0x286b14
engine_2891d8 equ 0x2891d8
engine_286af8 equ 0x286af8
engine_286ac8 equ 0x286ac8
engine_286b08 equ 0x286b08
engine_1c715c equ 0x1c715c
engine_1cb15c equ 0x1cb15c
engine_1c515c equ 0x1c515c
engine_1c915c equ 0x1c915c
engine_286b20 equ 0x286b20
engine_199148 equ 0x199148
engine_199144 equ 0x199144
engine_19913c equ 0x19913c
engine_19914c equ 0x19914c
engine_1cf15c equ 0x1cf15c
engine_1d315c equ 0x1d315c
engine_1cd15c equ 0x1cd15c
engine_1d115c equ 0x1d115c
engine_2310a8 equ 0x2310a8
engine_2310a4 equ 0x2310a4
engine_2310ac equ 0x2310ac
engine_199130 equ 0x199130
engine_1990b0 equ 0x1990b0
engine_289148 equ 0x289148
engine_199134 equ 0x199134
engine_1990b4 equ 0x1990b4
engine_199138 equ 0x199138
engine_1990b8 equ 0x1990b8
engine_1990bc equ 0x1990bc
engine_287e7c equ 0x287e7c
engine_199110 equ 0x199110
engine_199114 equ 0x199114
engine_199118 equ 0x199118
engine_19911c equ 0x19911c
engine_199050 equ 0x199050
engine_199070 equ 0x199070
engine_199090 equ 0x199090
engine_286af4 equ 0x286af4
engine_1990d0 equ 0x1990d0
engine_1990f0 equ 0x1990f0
engine_1ecda0 equ 0x1ecda0
engine_286a98 equ 0x286a98
animateoffs equ 0x50758
settransreverse equ 0x74450
settransnormal equ 0x743d0
spritewallfront equ 0x45527
maskwallscan equ 0x49190
transmaskwallscan equ 0x49dd1
owallmost equ 0x5e350
loadtile equ 0x4bb0d
msethlineshift equ 0x74a50
tsethlineshift equ 0x74bc0
ceilspritescan equ 0x50271
transmaskvline_restore equ 0x4abbe

drawsprite_:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 0xc8
    mov ebx, eax
    imul eax, eax, 0x2c
    mov edx, tsprite
    add edx, eax
    mov eax, ebx
    mov dword [esp + 0x6c], edx
    mov edx, dword [eax*4 + sprite_screen_x]
    mov eax, dword [eax*4 + sprite_depth]
    mov dword [esp + 0x68], eax
    mov eax, dword [esp + 0x6c]
    mov ax, word [eax + 0xe]
    mov dword [esp + 0xa4], edx
    mov dword [esp + 0xbc], eax
    mov eax, dword [esp + 0x6c]
    movsx ebx, word [esp + 0xbc]
    mov ax, word [eax + 0x1e]
    mov dl, byte [ebx*4 + picanm]
    mov dword [esp + 0xc0], eax
    test dl, 0xc0
    je short .branch_080
    movsx edx, ax
    add edx, 0x8000
    mov eax, ebx
    call animateoffs
    add dword [esp + 0xbc], eax

.branch_080:
    movsx eax, word [esp + 0xbc]
    add eax, eax
    cmp word [eax + tilesizx], 0
    jle near .branch_2b9c
    cmp word [eax + move_tile_heights], 0
    jle near .branch_2b9c
    cmp word [esp + 0xc0], 0
    jl near .branch_2b9c
    mov eax, dword [esp + 0x6c]
    cmp byte [eax + 0x14], 0
    jbe near .branch_2b9c
    cmp byte [eax + 0x15], 0
    jbe near .branch_2b9c
    movsx eax, word [eax + 0x18]
    mov dword [esp + 0x98], eax
    mov edx, eax
    shl eax, 2
    add eax, edx
    mov edx, sector
    shl eax, 3
    add edx, eax
    mov eax, dword [esp + 0x6c]
    mov dword [esp + 0xa0], edx
    movsx eax, word [eax + 0xc]
    mov edx, dword [esp + 0x6c]
    mov dword [esp + 0x64], eax
    xor eax, eax
    mov al, byte [edx + 0x11]
    mov dword [globalpal], eax
    movsx eax, byte [edx + 0x10]
    mov bh, byte [esp + 0x64]
    mov dword [globalshade], eax
    test bh, 2
    je short .branch_12f
    test byte [esp + 0x65], 2
    je short .branch_12a
    call settransreverse
    jmp short .branch_12f

.branch_12a:
    call settransnormal

.branch_12f:
    movsx eax, word [esp + 0xbc]
    mov edx, dword [eax*4 + picanm]
    sar edx, 8
    and edx, 0xff
    mov eax, dword [eax*4 + picanm]
    movsx ebx, dl
    mov edx, dword [esp + 0x6c]
    sar eax, 0x10
    movsx edx, byte [edx + 0x16]
    and eax, 0xff
    lea ebp, [ebx + edx]
    movsx edx, al
    mov eax, dword [esp + 0x6c]
    movsx eax, byte [eax + 0x17]
    add edx, eax
    mov ch, byte [esp + 0x64]
    mov dword [esp + 0xb0], edx
    test ch, 0x30
    je short .branch_191
    mov eax, dword [esp + 0x64]
    and eax, 0x30
    cmp eax, 0x30
    jne near .branch_a69

.branch_191:
    mov edi, dword [esp + 0x68]
    cmp edi, 0x400
    jle near .branch_2b9c
    mov eax, dword [engine_286b00]
    mov ebx, edi
    mov edx, eax
    sar edx, 0xd
    shl eax, 0x13
    idiv ebx
    mov edx, dword [esp + 0x6c]
    mov esi, eax
    xor eax, eax
    mov al, byte [edx + 0x14]
    mov ebx, dword [engine_286bac]
    shl eax, 0x10
    movsx ecx, word [esp + 0xbc]
    imul ebx
    shrd eax, edx, 0x10
    mov edi, eax
    movsx eax, word [nosplit ecx*2 + tilesizx]
    mov dword [esp + 0x60], eax
    movsx eax, word [nosplit ecx*2 + move_tile_heights]
    mov ebx, edi
    mov dword [esp + 0x9c], eax
    imul ebx, dword [esp + 0x60]
    mov eax, esi
    imul ebx
    shrd eax, edx, 0x1e
    mov dword [esp + 0x88], eax
    mov dword [esp + 0xa8], eax
    mov eax, dword [esp + 0x6c]
    xor ebx, ebx
    mov edx, dword [esp + 0x9c]
    mov bl, byte [eax + 0x15]
    imul ebx, edx
    mov eax, esi
    imul ebx
    shrd eax, edx, 0xe
    mov edx, eax
    mov dword [esp + 0x94], eax
    movsx eax, word [nosplit ecx*2 + tilesizx]
    mov ebx, dword [esp + 0x88]
    sar eax, 0xb
    cmp eax, ebx
    jge near .branch_2b9c
    mov eax, edx
    mov ecx, dword [esp + 0x9c]
    sar eax, 1
    cmp eax, ecx
    jle near .branch_2b9c
    mov eax, ebx
    mov edx, dword [esp + 0xa4]
    sar eax, 1
    sub edx, eax
    mov cl, byte [esp + 0x60]
    mov dword [esp + 0x5c], edx
    test cl, 1
    je short .branch_287
    mov ebx, edi
    mov eax, esi
    imul ebx
    shrd eax, edx, 0x1f
    add dword [esp + 0x5c], eax

.branch_287:
    mov ebx, edi
    imul ebx, ebp
    mov eax, esi
    mov ch, byte [esp + 0x64]
    imul ebx
    shrd eax, edx, 0x1e
    test ch, 4
    jne short .branch_2a3
    sub dword [esp + 0x5c], eax
    jmp short .branch_2a7

.branch_2a3:
    add dword [esp + 0x5c], eax

.branch_2a7:
    mov eax, dword [esp + 0x6c]
    mov edi, dword [globalposz]
    mov eax, dword [eax + 8]
    mov ebx, esi
    sub eax, edi
    imul ebx
    shrd eax, edx, 0x10
    mov ecx, eax
    mov eax, dword [esp + 0x6c]
    xor ebx, esi
    mov ebp, dword [esp + 0xb0]
    mov bl, byte [eax + 0x15]
    imul ebx, ebp
    mov eax, esi
    imul ebx
    shrd eax, edx, 0xe
    sub ecx, eax
    mov eax, dword [globalhoriz]
    mov edx, dword [esp + 0x94]
    shl eax, 8
    sub eax, edx
    mov dword [esp + 0x58], ecx
    lea ebx, [ecx + eax]
    mov al, byte [esp + 0x64]
    mov dword [esp + 0x58], ebx
    test al, 0x80
    je short .branch_332
    mov eax, edx
    sar eax, 1
    lea ecx, [ebx + eax]
    mov ah, byte [esp + 0x9c]
    mov dword [esp + 0x58], ecx
    test ah, 1
    je short .branch_332
    mov eax, dword [esp + 0x6c]
    xor ebx, ebx
    mov al, byte [eax + 0x15]
    mov bl, al
    mov eax, esi
    imul ebx
    shrd eax, edx, 0xf
    lea edi, [ecx + eax]
    mov dword [esp + 0x58], edi

.branch_332:
    mov eax, dword [esp + 0x5c]
    add eax, dword [esp + 0xa8]
    dec eax
    mov edx, dword [esp + 0x94]
    mov dword [esp + 0x54], eax
    mov eax, dword [esp + 0x58]
    add eax, edx
    dec eax
    mov edx, dword [esp + 0x58]
    mov dword [esp + 0x50], eax
    or dl, 0xff
    or al, 0xff
    cmp edx, eax
    jge near .branch_2b9c
    mov eax, dword [esp + 0x5c]
    sar eax, 8
    inc eax
    mov dword [esp + 0x4c], eax
    test eax, eax
    jge short .branch_37b
    xor ecx, ecx
    mov dword [esp + 0x4c], ecx

.branch_37b:
    mov eax, dword [esp + 0x54]
    sar eax, 8
    mov edi, dword [xdimen]
    mov dword [esp + 0x48], eax
    cmp eax, edi
    jl short .branch_397
    lea eax, [edi - 1]
    mov dword [esp + 0x48], eax

.branch_397:
    mov eax, dword [esp + 0x4c]
    cmp eax, dword [esp + 0x48]
    jg near .branch_2b9c
    mov ebx, dword [esp + 0x94]
    mov edx, dword [esp + 0x9c]
    xor eax, eax
    idiv ebx
    mov eax, dword [esp + 0xa0]
    mov ax, word [eax + 0xc]
    xor ah, ah
    and al, 3
    cwde
    test eax, eax
    jne short .branch_3f0
    mov ebx, dword [esp + 0xa0]
    mov edx, dword [globalposz]
    mov ebx, dword [ebx + 4]
    mov eax, esi
    sub ebx, edx
    imul ebx
    shrd eax, edx, 0x18
    add eax, dword [globalhoriz]
    lea ecx, [eax - 1]
    jmp short .branch_3f2

.branch_3f0:
    xor ecx, ecx

.branch_3f2:
    mov eax, dword [esp + 0xa0]
    mov ax, word [eax + 0xe]
    xor ah, ah
    and al, 3
    cwde
    test eax, eax
    jne short .branch_42b
    mov ebx, dword [esp + 0xa0]
    mov edi, dword [globalposz]
    mov ebx, dword [ebx + 8]
    mov eax, esi
    sub ebx, edi
    imul ebx
    shrd eax, edx, 0x18
    add eax, dword [globalhoriz]
    lea esi, [eax + 1]
    jmp short .branch_430

.branch_42b:
    mov esi, 0x7fffffff

.branch_430:
    mov eax, dword [esp + 0x58]
    sar eax, 8
    cmp eax, ecx
    jle short .branch_43d
    mov ecx, eax

.branch_43d:
    mov eax, dword [esp + 0x50]
    sar eax, 8
    cmp eax, esi
    jge short .branch_44a
    mov esi, eax

.branch_44a:
    cmp ecx, 0xffff8000
    jge short .branch_457
    mov ecx, 0xffff8000

.branch_457:
    cmp esi, 0x7fff
    jle short .branch_464
    mov esi, 0x7fff

.branch_464:
    cmp ecx, esi
    jge near .branch_2b9c
    mov edi, dword [esp + 0x4c]
    mov dl, byte [esp + 0x64]
    shl edi, 8
    test dl, 4
    jne short .branch_4a6
    mov ebx, dword [esp + 0xa8]
    mov eax, dword [esp + 0x60]
    mov edx, eax
    sar edx, 8
    shl eax, 0x18
    idiv ebx
    mov ebx, dword [esp + 0x5c]
    mov edx, edi
    mov dword [esp + 0x8c], eax
    sub edx, ebx
    mov ebx, eax
    mov eax, edx
    jmp short .branch_4da

.branch_4a6:
    mov ebx, dword [esp + 0xa8]
    mov eax, dword [esp + 0x60]
    mov edx, eax
    sar edx, 8
    shl eax, 0x18
    idiv ebx
    mov dword [esp + 0x8c], eax
    neg eax
    mov edx, dword [esp + 0x54]
    mov dword [esp + 0x8c], eax
    mov eax, edi
    mov ebx, dword [esp + 0x8c]
    sub eax, edx

.branch_4da:
    imul ebx
    shrd eax, edx, 8
    mov dword [esp + 0x84], eax
    mov eax, dword [esp + 0x64]
    and eax, 8
    test eax, eax
    mov ebp, dword [esp + 0x4c]
    mov edi, dword [esp + 0x48]
    mov ebx, dword [windowy1]
    jmp short .branch_549

.branch_500:
    mov eax, dword [windowx1]
    add eax, ebp
    movsx edx, word [nosplit eax*2 + startumost]
    sub edx, dword [windowy1]
    movsx eax, cx
    cmp edx, eax
    jle short .branch_51e
    mov eax, edx

.branch_51e:
    mov word [nosplit ebp*2 + uwall], ax
    mov eax, dword [windowx1]
    add eax, ebp
    movsx edx, word [nosplit eax*2 + startdmost]
    movsx eax, si
    sub edx, ebx
    cmp edx, eax
    jge short .branch_540
    mov eax, edx

.branch_540:
    inc ebp
    mov word [nosplit ebp*2 + engine_1a63de], ax

.branch_549:
    cmp ebp, edi
    jle short .branch_500
    mov eax, dword [engine_140b1]
    dec eax
    mov dword [esp + 0x3c], eax
    jmp near .branch_74e

.branch_55c:
    mov eax, dword [ecx*4 + engine_1d5560]
    mov dword [esp + 0x38], eax
    shl eax, 2
    mov esi, dword [esp + 0x48]
    cmp esi, dword [eax + engine_1c5160]
    jl near .branch_74a
    mov edi, dword [esp + 0x4c]
    cmp edi, dword [eax + engine_1c3160]
    jg near .branch_74a
    mov edx, dword [esp + 0x68]
    cmp edx, dword [eax + engine_1c9160]
    jg short .branch_5a2
    cmp edx, dword [eax + engine_1c7160]
    jle near .branch_74a

.branch_5a2:
    mov edx, dword [esp + 0x38]
    mov eax, dword [esp + 0x6c]
    movsx edx, word [nosplit edx*2 + engine_1c2160]
    call spritewallfront
    test eax, eax
    je short .branch_5de
    mov eax, dword [esp + 0x38]
    shl eax, 2
    mov edx, dword [esp + 0x68]
    cmp edx, dword [eax + engine_1c9160]
    jle near .branch_74a
    cmp edx, dword [eax + engine_1c7160]
    jle near .branch_74a

.branch_5de:
    mov eax, dword [esp + 0x38]
    shl eax, 2
    mov edi, dword [esp + 0x4c]
    mov edx, dword [eax + engine_1c5160]
    cmp edx, edi
    jle short .branch_5f7
    mov eax, edx
    jmp short .branch_5f9

.branch_5f7:
    mov eax, edi

.branch_5f9:
    mov dword [esp + 0x44], eax
    mov eax, dword [esp + 0x38]
    shl eax, 2
    mov ebp, dword [esp + 0x48]
    mov edx, dword [eax + engine_1c3160]
    cmp edx, ebp
    jge short .branch_616
    mov eax, edx
    jmp short .branch_618

.branch_616:
    mov eax, ebp

.branch_618:
    mov edx, dword [esp + 0x3c]
    mov dl, byte [edx + engine_1db5e0]
    mov dword [esp + 0x40], eax
    cmp dl, 1
    jb short .branch_64f
    mov ebp, dword [esp + 0x38]
    mov eax, dword [esp + 0x3c]
    shl ebp, 2
    add eax, eax
    cmp dl, 1
    jbe near .branch_6d0
    cmp dl, 2
    je near .branch_70e
    jmp near .branch_74a

.branch_64f:
    test dl, dl
    jne near .branch_74a
    mov ecx, dword [esp + 0x44]
    cmp eax, ecx
    jl near .branch_74a
    cmp ecx, dword [esp + 0x4c]
    jne short .branch_673
    cmp eax, dword [esp + 0x48]
    je near .branch_2b9c

.branch_673:
    mov ecx, dword [esp + 0x40]
    mov ebp, dword [esp + 0x44]
    sub ecx, ebp
    xor eax, eax
    add ecx, ecx
    lea edi, [ebp + ebp]
    add ecx, 2
    add edi, dwall
    cmp ecx, 4
    jae short .branch_6a0
    test cl, 1
    je short .branch_699
    stosb

.branch_699:
    shr ecx, 1
    db 0xf3                       ; REP precedes the operand-size prefix
    stosw
    jmp short .branch_6cb

.branch_6a0:
    test edi, 1
    je short .branch_6aa
    stosb
    dec ecx

.branch_6aa:
    test edi, 2
    je short .branch_6b7
    stosw
    sub ecx, 2

.branch_6b7:
    mov ebx, ecx
    shr ecx, 2
    rep stosd
    test bl, 2
    je short .branch_6c5
    stosw

.branch_6c5:
    test bl, 1
    je short .branch_6cb
    stosb

.branch_6cb:
    jmp near .branch_74a

.branch_6d0:
    movsx eax, word [eax + engine_1da560]
    mov ebx, dword [ebp + engine_1c5160]
    mov ebp, dword [esp + 0x44]
    sub eax, ebx
    jmp short .branch_706

.branch_6e5:
    lea ebx, [eax + ebp]
    add ebx, ebx
    lea edx, [ebp + ebp]
    mov si, word [ebx + engine_1a8960]
    cmp si, word [edx + uwall]
    jle short .branch_705
    mov word [edx + uwall], si

.branch_705:
    inc ebp

.branch_706:
    cmp ebp, dword [esp + 0x40]
    jle short .branch_6e5
    jmp short .branch_74a

.branch_70e:
    movsx eax, word [eax + engine_1da560]
    mov edx, dword [ebp + engine_1c5160]
    mov ebp, dword [esp + 0x44]
    sub eax, edx
    jmp short .branch_744

.branch_723:
    lea ebx, [eax + ebp]
    add ebx, ebx
    lea edx, [ebp + ebp]
    mov si, word [ebx + engine_1a8960]
    cmp si, word [edx + dwall]
    jge short .branch_743
    mov word [edx + dwall], si

.branch_743:
    inc ebp

.branch_744:
    cmp ebp, dword [esp + 0x40]
    jle short .branch_723

.branch_74a:
    dec dword [esp + 0x3c]

.branch_74e:
    mov ecx, dword [esp + 0x3c]
    test ecx, ecx
    jge near .branch_55c
    mov eax, dword [esp + 0x48]
    mov dx, word [nosplit eax*2 + uwall]
    cmp dx, word [nosplit eax*2 + dwall]
    jl short .branch_79b
    mov ebp, dword [esp + 0x4c]
    mov eax, dword [esp + 0x48]
    jmp short .branch_78d

.branch_77a:
    mov dx, word [nosplit ebp*2 + uwall]
    cmp dx, word [nosplit ebp*2 + dwall]
    jl short .branch_791
    inc ebp

.branch_78d:
    cmp ebp, eax
    jl short .branch_77a

.branch_791:
    cmp ebp, dword [esp + 0x48]
    je near .branch_2b9c

.branch_79b:
    movsx eax, word [engine_28912a]
    cmp eax, 1
    jl short .branch_80b
    mov ebx, dword [esp + 0x4c]
    mov eax, dword [engine_14187]
    cmp eax, ebx
    jl short .branch_80b
    cmp eax, dword [esp + 0x48]
    jg short .branch_80b
    lea edx, [eax + eax]
    mov esi, dword [engine_2863cc]
    movsx eax, word [edx + uwall]
    cmp eax, esi
    jg short .branch_80b
    movsx eax, word [edx + dwall]
    cmp eax, esi
    jle short .branch_80b
    mov eax, dword [esp + 0x98]
    mov esi, 3
    mov edi, 1
    mov word [engine_289124], ax
    mov word [engine_289122], si
    mov eax, dword [esp + 0xc0]
    mov word [engine_28912a], di
    mov word [engine_289128], ax

.branch_80b:
    mov eax, dword [esp + 0x6c]
    xor edx, edx
    mov ebp, dword [esp + 0xb0]
    mov dl, byte [eax + 0x15]
    imul ebp, edx
    mov eax, dword [eax + 8]
    shl ebp, 2
    sub eax, ebp
    mov bl, byte [esp + 0x64]
    mov ebp, eax
    test bl, 0x80
    je short .branch_850
    mov eax, dword [esp + 0x9c]
    imul eax, edx
    add eax, eax
    mov bh, byte [esp + 0x9c]
    add ebp, eax
    test bh, 1
    je short .branch_850
    lea eax, [edx + edx]
    add ebp, eax

.branch_850:
    mov edx, dword [esp + 0x6c]
    xor eax, eax
    mov al, byte [edx + 0x15]
    imul eax, dword [esp + 0x9c]
    shl eax, 2
    mov edx, ebp
    xor ebx, ebx
    sub edx, eax
    mov eax, dword [esp + 0xbc]
    mov dword [globalorientation], ebx
    mov word [globalpicnum], ax
    cwde
    mov dword [esp + 0x34], edx
    test eax, 0xfffff000
    je short .branch_891
    xor eax, eax
    mov word [globalpicnum], ax

.branch_891:
    mov eax, dword [engine_286a9c]
    xor ecx, ecx
    mov dword [globvis], eax
    mov eax, dword [esp + 0xa0]
    mov dword [globalxpanning], ecx
    mov dword [globalypanning], ecx
    mov cl, byte [eax + 0x20]
    test cl, cl
    je short .branch_8cf
    mov al, cl
    xor ebx, ebx
    add al, 0x10
    mov bl, al
    mov eax, dword [globvis]
    imul ebx
    shrd eax, edx, 4
    mov dword [globvis], eax

.branch_8cf:
    movsx eax, word [globalpicnum]
    xor edx, edx
    mov dl, byte [eax + picsiz]
    sar edx, 4
    mov word [engine_289146], dx
    movsx edx, word [nosplit eax*2 + move_tile_heights]
    movsx eax, word [engine_289146]
    cmp edx, dword [eax*4 + pow2long]
    je short .branch_907
    inc word [engine_289146]

.branch_907:
    mov eax, 0x20
    mov bx, word [engine_289146]
    sub eax, ebx
    mov word [engine_289146], ax
    movsx ecx, ax
    mov eax, dword [esp + 0x6c]
    xor ebx, ebx
    mov al, byte [eax + 0x15]
    sub ecx, 0x13
    mov bl, al
    mov eax, 0x200
    mov edx, eax
    shl eax, cl
    neg cl
    sar edx, cl
    idiv ebx
    mov ebx, dword [esp + 0x34]
    mov edx, eax
    mov dword [globalyscale], eax
    mov eax, dword [globalposz]
    sub eax, ebx
    imul eax, edx
    shl eax, 8
    mov dword [globalzd], eax
    mov eax, dword [esp + 0x64]
    and eax, 8
    test eax, eax
    jle short .branch_97f
    mov ecx, edx
    mov eax, dword [globalposz]
    neg ecx
    sub eax, ebp
    imul eax, ecx
    shl eax, 8
    mov dword [globalyscale], ecx
    mov dword [globalzd], eax

.branch_97f:
    mov ebp, dword [esp + 0x48]
    mov edi, dword [esp + 0x4c]
    mov esi, dword [esp + 0x8c]
    mov eax, edi
    sub ebp, edi
    shl eax, 2
    inc ebp
    mov dword [esp + 0x70], eax
    mov eax, lwall
    mov edx, dword [esp + 0x70]
    mov ecx, ebp
    add eax, edx
    mov edx, dword [esp + 0x84]
    mov ebx, ecx
    shr ecx, 1
    je short .branch_9d3

.branch_9b4:
    lea edi, [edx + esi]
    sar edx, 0x10
    mov dword [eax], edx
    lea edx, [edi + esi]
    sar edi, 0x10
    mov dword [eax + 4], edi
    add eax, 8
    dec ecx
    jne short .branch_9b4
    test ebx, 1
    je short .branch_9d8

.branch_9d3:
    sar edx, 0x10
    mov dword [eax], edx

.branch_9d8:
    mov eax, dword [esp + 0x68]
    mov ebx, dword [engine_286b14]
    mov edi, swall
    imul ebx
    shrd eax, edx, 0x13
    mov ebx, dword [esp + 0x70]
    mov ecx, ebp
    add edi, ebx
    rep stosd
    test byte [esp + 0x64], 2
    jne short .branch_a21
    push lwall
    mov ecx, dwall
    mov ebx, uwall
    push swall
    mov edx, dword [esp + 0x50]
    mov eax, dword [esp + 0x54]
    call maskwallscan
    jmp short .branch_a2e

.branch_a21:
    mov edx, dword [esp + 0x48]
    mov eax, dword [esp + 0x4c]
    call transmaskwallscan

.branch_a2e:
    xor eax, eax
    mov al, byte [engine_2891d8]
    cmp eax, 1
    jne near .branch_2b9c
    mov edx, dword [esp + 0xc0]
    xor dh, dh
    and dl, 7
    movsx eax, word [esp + 0xc0]
    movsx edx, dx
    sar eax, 3
    mov dl, byte [edx + pow2char]
    or byte [eax + sprite_visibility], dl
    jmp near .branch_2b9c

.branch_a69:
    cmp eax, 0x10
    jne near .branch_18a5
    mov eax, dword [esp + 0x64]
    and eax, 4
    test eax, eax
    jle short .branch_a7f
    neg ebp

.branch_a7f:
    mov eax, dword [esp + 0x64]
    and eax, 8
    test eax, eax
    jle short .branch_a91
    neg dword [esp + 0xb0]

.branch_a91:
    movsx eax, word [esp + 0xbc]
    mov ebx, dword [esp + 0x6c]
    movsx edx, word [nosplit eax*2 + tilesizx]
    xor ecx, ecx
    mov dword [esp + 0x60], edx
    mov edx, dword [esp + 0x6c]
    movsx eax, word [nosplit eax*2 + move_tile_heights]
    movsx edx, word [edx + 0x1c]
    mov dword [esp + 0x9c], eax
    lea eax, [edx + 0x1000]
    mov cl, byte [ebx + 0x14]
    and eax, 0x7ff
    mov edi, ecx
    movsx eax, word [nosplit eax*2 + sintable]
    imul edi, eax
    lea eax, [edx + 0xe00]
    and eax, 0x7ff
    movsx eax, word [nosplit eax*2 + sintable]
    imul ecx, eax
    mov eax, dword [esp + 0x60]
    sar eax, 1
    mov esi, dword [globalposx]
    add ebp, eax
    mov eax, dword [ebx]
    sub eax, esi
    mov ebx, ebp
    mov esi, eax
    mov eax, edi
    imul ebx
    shrd eax, edx, 0x10
    mov ebx, dword [esp + 0x60]
    sub esi, eax
    mov eax, edi
    mov dword [esp + 0x5c], esi
    imul ebx
    shrd eax, edx, 0x10
    mov edi, dword [globalposy]
    lea edx, [esi + eax]
    mov ebx, ebp
    mov esi, dword [esp + 0x6c]
    mov dword [esp + 0x54], edx
    mov eax, ecx
    mov esi, dword [esi + 4]
    imul ebx
    shrd eax, edx, 0x10
    sub esi, edi
    mov ebx, dword [esp + 0x60]
    sub esi, eax
    mov eax, ecx
    mov dword [esp + 0x58], esi
    imul ebx
    shrd eax, edx, 0x10
    mov edi, dword [engine_286af8]
    mov ebx, dword [engine_286ac8]
    lea edx, [esi + eax]
    mov eax, dword [esp + 0x5c]
    mov dword [esp + 0x50], edx
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 6
    mov esi, dword [esp + 0x50]
    mov edi, dword [engine_286af8]
    mov ebx, dword [engine_286ac8]
    mov ecx, eax
    mov dword [esp + 0x2c], eax
    mov eax, dword [esp + 0x54]
    mov dword [esp + 0x3c], ebp
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 6
    mov dword [esp + 0x24], eax
    test ecx, ecx
    jg short .branch_bb8
    test eax, eax
    jle near .branch_2b9c

.branch_bb8:
    mov esi, dword [esp + 0x5c]
    mov eax, dword [esp + 0x58]
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
    mov esi, dword [esp + 0x54]
    mov edi, dword [engine_286af8]
    mov ebx, dword [engine_286ac8]
    mov ecx, eax
    mov dword [esp + 0x30], eax
    mov eax, dword [esp + 0x50]
    neg esi
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 6
    mov edx, dword [esp + 0x5c]
    mov ebx, dword [esp + 0x58]
    mov esi, dword [esp + 0x54]
    mov ebp, eax
    mov dword [esp + 0x28], eax
    mov eax, dword [globalposx]
    mov edi, dword [esp + 0x50]
    add edx, eax
    mov eax, dword [globalposy]
    mov dword [esp + 0x5c], edx
    add ebx, eax
    xor dh, dh
    mov eax, dword [globalposx]
    mov dword [esp + 0x58], ebx
    mov ebx, dword [esp + 0x24]
    add esi, eax
    mov eax, dword [globalposy]
    mov dword [esp + 0x54], esi
    add edi, eax
    mov esi, ebp
    mov dword [esp + 0x50], edi
    neg esi
    mov eax, ecx
    mov edi, dword [esp + 0x2c]
    mov byte [esp + 0xc4], dh
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    test edx, edx
    jl short .branch_ccc
    test byte [esp + 0x64], 0x40
    jne near .branch_2b9c
    mov eax, dword [esp + 0x24]
    mov dword [esp + 0x3c], edi
    mov dword [esp + 0x2c], eax
    mov eax, dword [esp + 0x5c]
    mov dword [esp + 0x3c], eax
    mov eax, dword [esp + 0x54]
    mov bh, 1
    mov dword [esp + 0x5c], eax
    mov eax, dword [esp + 0x3c]
    mov dword [esp + 0x30], ebp
    mov dword [esp + 0x54], eax
    mov eax, dword [esp + 0x58]
    mov dword [esp + 0x28], ecx
    mov dword [esp + 0x3c], eax
    mov eax, dword [esp + 0x50]
    mov dword [esp + 0x24], edi
    mov dword [esp + 0x58], eax
    mov eax, dword [esp + 0x3c]
    mov byte [esp + 0xc4], bh
    mov dword [esp + 0x50], eax

.branch_ccc:
    mov eax, dword [esp + 0x2c]
    mov ebp, dword [esp + 0x30]
    neg eax
    cmp eax, ebp
    jg short .branch_d3a
    mov ebx, dword [esp + 0x2c]
    cmp ebp, ebx
    jg near .branch_2b9c
    test ebx, ebx
    je near .branch_2b9c
    mov ecx, dword [esp + 0x2c]
    mov ebx, dword [engine_286b08]
    mov eax, ebp
    imul ebx
    idiv ecx
    mov edx, dword [engine_286b08]
    add eax, edx
    mov dword [engine_1c715c], eax
    test ebp, ebp
    jl short .branch_d18
    lea edi, [eax + 1]
    mov dword [engine_1c715c], edi

.branch_d18:
    mov eax, dword [engine_1c715c]
    mov ebp, dword [xdimen]
    cmp eax, ebp
    jl short .branch_d2f
    lea eax, [ebp - 1]
    mov dword [engine_1c715c], eax

.branch_d2f:
    mov eax, dword [esp + 0x2c]
    mov dword [engine_1cb15c], eax
    jmp short .branch_d8f

.branch_d3a:
    mov eax, dword [esp + 0x24]
    mov edx, dword [esp + 0x28]
    neg eax
    cmp eax, edx
    jg near .branch_2b9c
    mov eax, dword [esp + 0x2c]
    mov ecx, dword [esp + 0x24]
    sub eax, ecx
    xor ebx, ebx
    add eax, ebp
    mov dword [engine_1c715c], ebx
    sub eax, edx
    mov dword [esp + 0x3c], eax
    je near .branch_2b9c
    mov eax, dword [esp + 0x2c]
    mov edx, dword [esp + 0x2c]
    lea ebx, [eax + ebp]
    mov eax, ecx
    mov ecx, dword [esp + 0x3c]
    sub eax, edx
    imul ebx
    idiv ecx
    mov edx, dword [esp + 0x2c]
    add edx, eax
    mov dword [engine_1cb15c], edx

.branch_d8f:
    mov eax, dword [esp + 0x28]
    mov edx, dword [esp + 0x24]
    cmp eax, edx
    jg short .branch_e02
    mov eax, edx
    mov ebx, dword [esp + 0x28]
    neg eax
    cmp eax, ebx
    jg near .branch_2b9c
    test edx, edx
    je near .branch_2b9c
    mov eax, dword [esp + 0x28]
    mov ebx, dword [engine_286b08]
    mov ecx, edx
    imul ebx
    idiv ecx
    add eax, dword [engine_286b08]
    dec eax
    mov edi, dword [esp + 0x28]
    mov dword [engine_1c515c], eax
    test edi, edi
    jl short .branch_de0
    lea ebp, [eax + 1]
    mov dword [engine_1c515c], ebp

.branch_de0:
    mov eax, dword [engine_1c515c]
    mov edx, dword [xdimen]
    cmp eax, edx
    jl short .branch_df7
    lea eax, [edx - 1]
    mov dword [engine_1c515c], eax

.branch_df7:
    mov eax, dword [esp + 0x24]
    mov dword [engine_1c915c], eax
    jmp short .branch_e53

.branch_e02:
    mov eax, dword [esp + 0x30]
    mov ebx, dword [esp + 0x2c]
    cmp eax, ebx
    jg near .branch_2b9c
    mov eax, dword [xdimen]
    dec eax
    mov ecx, dword [esp + 0x30]
    mov dword [engine_1c515c], eax
    mov eax, dword [esp + 0x28]
    sub eax, ecx
    add eax, ebx
    sub eax, edx
    mov dword [esp + 0x3c], eax
    je near .branch_2b9c
    mov eax, edx
    sub ebx, ecx
    mov edx, dword [esp + 0x2c]
    mov ecx, dword [esp + 0x3c]
    sub eax, edx
    imul ebx
    idiv ecx
    mov edx, dword [esp + 0x2c]
    add edx, eax
    mov dword [engine_1c915c], edx

.branch_e53:
    cmp dword [engine_1cb15c], 0x100
    jl near .branch_2b9c
    cmp dword [engine_1c915c], 0x100
    jl near .branch_2b9c
    mov eax, dword [engine_1c715c]
    cmp eax, dword [engine_1c515c]
    jg near .branch_2b9c
    mov ebx, dword [esp + 0x60]
    mov eax, dword [esp + 0x2c]
    imul ebx
    shrd eax, edx, 0xa
    mov ebx, dword [xdimen]
    mov dword [esp + 0xb4], eax
    mov edi, eax
    mov eax, dword [esp + 0x30]
    imul ebx
    shrd eax, edx, 0xa
    mov ebp, dword [engine_286b08]
    mov ecx, eax
    mov eax, dword [engine_1c715c]
    mov ebx, dword [esp + 0x2c]
    sub eax, ebp
    imul ebx
    shrd eax, edx, 9
    sub ecx, eax
    imul ecx, dword [esp + 0x60]
    neg edi
    mov eax, dword [esp + 0x24]
    sar ecx, 3
    sub eax, ebx
    mov dword [esp + 0x20], ecx
    sar eax, 8
    mov ecx, dword [esp + 0x28]
    mov dword [esp + 0xb8], eax
    mov eax, dword [esp + 0x30]
    mov ebx, dword [xdimen]
    sub eax, ecx
    mov dword [esp + 0xb4], edi
    imul ebx
    shrd eax, edx, 0xb
    mov esi, dword [engine_286b08]
    mov edi, eax
    mov eax, dword [engine_1c715c]
    mov ebx, dword [esp + 0xb8]
    sub eax, esi
    imul ebx
    shrd eax, edx, 2
    add edi, eax
    mov eax, dword [engine_1c515c]
    add eax, 3
    mov dword [esp + 0x38], eax
    mov eax, edi
    mov dword [engine_286b20], eax
    fild dword [engine_286b20]
    add eax, eax
    fstp dword [engine_286b20]
    sbb ebx, ebx
    mov eax, dword [engine_286b20]
    mov ecx, eax
    and eax, 0x7ff000
    shr eax, 0xa
    sub ecx, 0x3f800000
    shr ecx, 0x17
    mov eax, dword [eax + reciptable]
    sar eax, cl
    xor eax, ebx
    mov ebx, eax
    mov eax, dword [esp + 0x20]
    imul ebx
    shrd eax, edx, 0x14
    mov esi, eax
    mov edx, eax
    mov eax, dword [engine_1c715c]
    sar edx, 8
    lea ebp, [eax + 4]
    mov dword [eax*4 + lwall], edx
    jmp near .branch_1033

.branch_f8b:
    mov eax, dword [esp + 0xb4]
    mov ebx, dword [esp + 0xb8]
    mov edx, dword [esp + 0x20]
    add edi, ebx
    add edx, eax
    mov eax, edi
    mov dword [engine_286b20], eax
    fild dword [engine_286b20]
    add eax, eax
    fstp dword [engine_286b20]
    sbb ebx, ebx
    mov eax, dword [engine_286b20]
    mov ecx, eax
    and eax, 0x7ff000
    shr eax, 0xa
    sub ecx, 0x3f800000
    shr ecx, 0x17
    mov eax, dword [eax + reciptable]
    sar eax, cl
    xor eax, ebx
    mov ebx, eax
    mov eax, edx
    mov dword [esp + 0x20], edx
    imul ebx
    shrd eax, edx, 0x14
    mov ebx, eax
    sar ebx, 8
    mov dword [esp], esi
    mov dword [ebp*4 + lwall], ebx
    mov ebx, dword [esp]
    add ebx, eax
    mov ecx, ebx
    sar ecx, 1
    sar ebx, 9
    mov dword [esp + 0x3c], ecx
    mov dword [ebp*4 + engine_199148], ebx
    mov ebx, ecx
    add ebx, dword [esp]
    sar ebx, 9
    mov dword [ebp*4 + engine_199144], ebx
    mov ebx, dword [esp + 0x3c]
    mov esi, eax
    lea edx, [eax + ebx]
    add ebp, 4
    sar edx, 9
    mov dword [ebp*4 + engine_19913c], edx

.branch_1033:
    cmp ebp, dword [esp + 0x38]
    jle near .branch_f8b
    mov eax, dword [engine_1c715c]
    shl eax, 2
    cmp dword [eax + lwall], 0
    jge short .branch_1056
    xor ebx, ebx
    mov dword [eax + lwall], ebx

.branch_1056:
    mov edx, dword [engine_1c515c]
    shl edx, 2
    mov ecx, dword [esp + 0x60]
    cmp ecx, dword [edx + lwall]
    jg short .branch_1074
    lea eax, [ecx - 1]
    mov dword [edx + lwall], eax

.branch_1074:
    mov eax, dword [esp + 0x64]
    and eax, 4
    test eax, eax
    setg al
    mov edx, eax
    xor eax, eax
    and edx, 0xff
    mov al, byte [esp + 0xc4]
    xor eax, edx
    test eax, eax
    jle short .branch_10c7
    mov eax, dword [esp + 0x60]
    mov ebp, dword [engine_1c715c]
    dec eax
    mov ecx, dword [engine_1c515c]
    mov dword [esp + 0x38], eax
    jmp short .branch_10c3

.branch_10ae:
    mov edx, dword [esp + 0x38]
    mov esi, dword [ebp*4 + lwall]
    inc ebp
    sub edx, esi
    mov dword [ebp*4 + engine_19914c], edx

.branch_10c3:
    cmp ebp, ecx
    jle short .branch_10ae

.branch_10c7:
    mov eax, dword [esp + 0x30]
    mov dword [engine_1cf15c], eax
    mov eax, dword [esp + 0x2c]
    mov dword [engine_1d315c], eax
    mov eax, dword [esp + 0x28]
    mov dword [engine_1cd15c], eax
    mov eax, dword [esp + 0x24]
    mov ebx, dword [engine_1cb15c]
    mov dword [engine_1d115c], eax
    mov eax, dword [engine_286b00]
    mov edx, eax
    sar edx, 0xd
    shl eax, 0x13
    idiv ebx
    mov ebx, dword [engine_1c915c]
    mov ecx, eax
    mov esi, eax
    mov eax, dword [engine_286b00]
    mov edx, eax
    sar edx, 0xd
    shl eax, 0x13
    idiv ebx
    mov ebx, dword [engine_1c515c]
    mov edi, dword [engine_1c715c]
    mov edx, eax
    sub ebx, edi
    sub edx, ecx
    inc ebx
    mov eax, edx
    sar edx, 0x1f
    idiv ebx
    mov edi, eax
    mov eax, dword [esp + 0x6c]
    xor edx, edx
    mov dl, byte [eax + 0x15]
    mov eax, dword [esp + 0xb0]
    imul eax, edx
    mov ebp, dword [esp + 0x6c]
    mov ebp, dword [ebp + 8]
    shl eax, 2
    mov bl, byte [esp + 0x64]
    sub ebp, eax
    test bl, 0x80
    je short .branch_117c
    mov eax, dword [esp + 0x9c]
    imul eax, edx
    add eax, eax
    mov bh, byte [esp + 0x9c]
    add ebp, eax
    test bh, 1
    je short .branch_117c
    lea eax, [edx + edx]
    add ebp, eax

.branch_117c:
    mov edx, dword [esp + 0x6c]
    xor eax, eax
    mov al, byte [edx + 0x15]
    imul eax, dword [esp + 0x9c]
    shl eax, 2
    mov edx, ebp
    xor ebx, ebx
    sub edx, eax
    mov eax, dword [esp + 0xbc]
    mov dword [globalorientation], ebx
    mov word [globalpicnum], ax
    cwde
    mov dword [esp + 0x34], edx
    test eax, 0xfffff000
    je short .branch_11bd
    xor eax, eax
    mov word [globalpicnum], ax

.branch_11bd:
    mov eax, dword [engine_286a9c]
    xor ecx, ecx
    mov dword [globvis], eax
    mov eax, dword [esp + 0xa0]
    mov dword [globalxpanning], ecx
    mov dword [globalypanning], ecx
    mov cl, byte [eax + 0x20]
    test cl, cl
    je short .branch_11fb
    mov al, cl
    xor ebx, ebx
    add al, 0x10
    mov bl, al
    mov eax, dword [globvis]
    imul ebx
    shrd eax, edx, 4
    mov dword [globvis], eax

.branch_11fb:
    movsx eax, word [globalpicnum]
    xor edx, edx
    mov dl, byte [eax + picsiz]
    sar edx, 4
    mov word [engine_289146], dx
    movsx edx, word [nosplit eax*2 + move_tile_heights]
    movsx eax, word [engine_289146]
    cmp edx, dword [eax*4 + pow2long]
    je short .branch_1233
    inc word [engine_289146]

.branch_1233:
    mov eax, 0x20
    mov bx, word [engine_289146]
    sub eax, ebx
    mov word [engine_289146], ax
    movsx ecx, ax
    mov eax, dword [esp + 0x6c]
    xor ebx, ebx
    mov al, byte [eax + 0x15]
    sub ecx, 0x13
    mov bl, al
    mov eax, 0x200
    mov edx, eax
    shl eax, cl
    neg cl
    sar edx, cl
    idiv ebx
    mov ecx, dword [esp + 0x34]
    mov edx, eax
    mov dword [globalyscale], eax
    mov eax, dword [globalposz]
    sub eax, ecx
    imul eax, edx
    shl eax, 8
    mov dword [globalzd], eax
    mov eax, dword [esp + 0x64]
    and eax, 8
    test eax, eax
    jle short .branch_12b0
    mov eax, edx
    neg eax
    mov dword [globalyscale], eax
    mov eax, dword [globalposz]
    mov edx, dword [globalyscale]
    sub eax, ebp
    imul eax, edx
    shl eax, 8
    mov dword [globalzd], eax

.branch_12b0:
    mov eax, dword [esp + 0xa0]
    mov ax, word [eax + 0xc]
    xor ah, ah
    and al, 1
    cwde
    test eax, eax
    jne short .branch_12da
    mov edx, dword [esp + 0xa0]
    mov eax, dword [esp + 0x34]
    mov ebx, dword [edx + 4]
    cmp eax, ebx
    jge short .branch_12da
    mov dword [esp + 0x34], ebx

.branch_12da:
    mov eax, dword [esp + 0xa0]
    mov ax, word [eax + 0xe]
    xor ah, ah
    and al, 1
    cwde
    test eax, eax
    jne short .branch_12fe
    mov eax, dword [esp + 0xa0]
    mov ecx, dword [eax + 8]
    cmp ebp, ecx
    jle short .branch_12fe
    mov ebp, ecx

.branch_12fe:
    mov ebx, dword [esp + 0x34]
    mov eax, dword [globalposz]
    mov edx, 0x7ff
    sub ebx, eax
    mov eax, uwall
    call owallmost
    mov edx, dword [globalposz]
    mov ebx, ebp
    mov eax, dwall
    sub ebx, edx
    mov edx, 0x7ff
    call owallmost
    mov eax, dword [engine_1c715c]
    mov dword [esp + 0x3c], eax
    jmp short .branch_138e

.branch_133c:
    mov eax, esi
    mov dword [engine_286b20], eax
    fild dword [engine_286b20]
    add eax, eax
    fstp dword [engine_286b20]
    sbb ebx, ebx
    mov eax, dword [engine_286b20]
    mov ecx, eax
    and eax, 0x7ff000
    shr eax, 0xa
    sub ecx, 0x3f800000
    shr ecx, 0x17
    mov eax, dword [eax + reciptable]
    sar eax, cl
    xor eax, ebx
    mov edx, eax
    add esi, edi
    mov eax, dword [esp + 0x3c]
    shl edx, 2
    lea ecx, [eax + 1]
    mov dword [eax*4 + swall], edx
    mov dword [esp + 0x3c], ecx

.branch_138e:
    mov eax, dword [esp + 0x3c]
    cmp eax, dword [engine_1c515c]
    jle short .branch_133c
    mov eax, dword [engine_140b1]
    dec eax
    mov dword [esp + 0x3c], eax
    jmp near .branch_17e3

.branch_13a9:
    mov eax, dword [ecx*4 + engine_1d5560]
    mov dword [esp + 0x38], eax
    shl eax, 2
    mov ebx, dword [engine_1c515c]
    cmp ebx, dword [eax + engine_1c5160]
    jl near .branch_17df
    mov ecx, dword [engine_1c715c]
    cmp ecx, dword [eax + engine_1c3160]
    jg near .branch_17df
    mov edx, dword [eax + engine_1c5160]
    mov dword [esp + 0x44], edx
    mov edx, dword [eax + engine_1c3160]
    mov esi, dword [eax + engine_1c7160]
    mov dword [esp + 0x40], edx
    mov edx, dword [eax + engine_1c9160]
    cmp edx, esi
    jge short .branch_1403
    mov eax, edx
    jmp short .branch_1405

.branch_1403:
    mov eax, esi

.branch_1405:
    mov edx, dword [engine_1cb15c]
    mov edi, dword [engine_1c915c]
    cmp edx, edi
    jg short .branch_1417
    mov edx, edi

.branch_1417:
    cmp edx, eax
    jle near .branch_17df
    mov eax, dword [esp + 0x38]
    shl eax, 2
    mov edx, dword [eax + engine_1c9160]
    mov ebp, dword [eax + engine_1c7160]
    cmp edx, ebp
    jle short .branch_143a
    mov eax, edx
    jmp short .branch_143c

.branch_143a:
    mov eax, ebp

.branch_143c:
    mov edx, dword [engine_1cb15c]
    mov ebx, dword [engine_1c915c]
    cmp edx, ebx
    jl short .branch_144e
    mov edx, ebx

.branch_144e:
    cmp edx, eax
    jle short .branch_145c

.branch_1452:
    mov ebp, 0x80000000
    jmp near .branch_1678

.branch_145c:
    mov eax, dword [esp + 0x38]
    movsx eax, word [nosplit eax*2 + engine_1c2160]
    shl eax, 5
    mov edx, dword [eax + wall]
    movsx ebp, word [eax + engine_2310a8]
    mov dword [esp + 0x30], edx
    mov edx, dword [eax + engine_2310a4]
    shl ebp, 5
    mov dword [esp + 0x2c], edx
    mov edx, dword [ebp + wall]
    mov ebx, dword [esp + 0x58]
    mov dword [esp + 0x28], edx
    mov edx, dword [ebp + engine_2310a4]
    mov ecx, dword [esp + 0x30]
    mov dword [esp + 0x24], edx
    mov edx, dword [esp + 0x28]
    mov esi, dword [esp + 0x2c]
    sub edx, ecx
    sub ebx, esi
    mov ecx, edx
    imul ecx, ebx
    mov edi, dword [esp + 0x2c]
    mov ebp, dword [esp + 0x30]
    mov esi, dword [esp + 0x24]
    mov ebx, dword [esp + 0x5c]
    sub esi, edi
    sub ebx, ebp
    imul ebx, esi
    sub ecx, ebx
    mov ebx, dword [esp + 0x50]
    sub ebx, edi
    imul ebx, edx
    mov ebp, dword [esp + 0x54]
    sub ebp, dword [esp + 0x30]
    imul ebp, esi
    sub ebx, ebp
    mov ebp, ebx
    mov ebx, ecx
    xor ebx, ebp
    mov dword [esp + 0x34], ecx
    test ebx, ebx
    jl short .branch_14fa
    add ebp, ecx
    jmp near .branch_1678

.branch_14fa:
    mov ebx, dword [esp + 0x54]
    mov ebp, dword [esp + 0x5c]
    mov ecx, dword [esp + 0x2c]
    mov edi, dword [esp + 0x58]
    sub ebx, ebp
    sub ecx, edi
    mov edi, ebx
    imul edi, ecx
    mov ebp, dword [esp + 0x58]
    mov ecx, dword [esp + 0x50]
    mov dword [esp + 0x70], edi
    mov edi, dword [esp + 0x30]
    sub ecx, ebp
    sub edi, dword [esp + 0x5c]
    imul edi, ecx
    mov ebp, dword [esp + 0x70]
    sub ebp, edi
    mov edi, dword [esp + 0x24]
    mov dword [esp + 0x34], ebp
    sub edi, dword [esp + 0x58]
    imul ebx, edi
    mov ebp, dword [esp + 0x5c]
    mov edi, dword [esp + 0x28]
    sub edi, ebp
    imul ecx, edi
    mov ebp, ebx
    mov ebx, dword [esp + 0x34]
    sub ebp, ecx
    xor ebx, ebp
    test ebx, ebx
    jl short .branch_1567
    add ebp, dword [esp + 0x34]
    neg ebp
    jmp near .branch_1678

.branch_1567:
    mov ebx, dword [esp + 0x6c]
    mov ecx, dword [esp + 0x2c]
    mov ebx, dword [ebx + 4]
    sub ebx, ecx
    mov ecx, edx
    imul ecx, ebx
    mov ebx, dword [esp + 0x6c]
    mov edi, dword [esp + 0x30]
    mov ebx, dword [ebx]
    sub ebx, edi
    imul ebx, esi
    cmp ecx, ebx
    jne short .branch_15a6
    mov edx, dword [esp + 0x6c]
    mov ax, word [eax + engine_2310ac]
    cmp ax, word [edx + 0x18]
    je near .branch_1452
    jmp near .branch_1673

.branch_15a6:
    mov ebx, dword [globalposx]
    mov eax, edi
    mov edi, dword [esp + 0x34]
    sub eax, ebx
    mov ebx, dword [esp + 0x34]
    sub edi, ebp
    mov dword [esp + 0x70], eax
    mov ecx, edi
    mov eax, edx
    mov ebp, dword [esp + 0x70]
    imul ebx
    idiv ecx
    mov ecx, dword [globalposy]
    add ebp, eax
    mov eax, dword [esp + 0x2c]
    sub eax, ecx
    mov dword [esp + 0x70], eax
    mov ecx, edi
    mov eax, esi
    imul ebx
    idiv ecx
    mov edx, dword [esp + 0x70]
    mov edi, dword [engine_286af8]
    add edx, eax
    mov ebx, dword [engine_286ac8]
    mov esi, edx
    mov eax, ebp
    mov dword [esp + 4], edx
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0xe
    mov ecx, eax
    test eax, eax
    jle short .branch_1673
    mov eax, dword [esp + 4]
    mov edi, dword [engine_286af8]
    mov esi, ebp
    mov ebx, dword [engine_286ac8]
    neg esi
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0xe
    mov ebx, dword [engine_286b08]
    mov esi, eax
    imul ebx
    idiv ecx
    mov ebp, dword [engine_286b08]
    add ebp, eax
    test esi, esi
    jl short .branch_164f
    inc ebp

.branch_164f:
    cmp dword [esp + 0x34], 0
    jge short .branch_1662
    cmp ebp, dword [esp + 0x44]
    jle short .branch_166c
    mov dword [esp + 0x44], ebp
    jmp short .branch_166c

.branch_1662:
    cmp ebp, dword [esp + 0x40]
    jge short .branch_166c
    mov dword [esp + 0x40], ebp

.branch_166c:
    mov ebp, 0x80000001
    jmp short .branch_1678

.branch_1673:
    mov ebp, 0x7fffffff

.branch_1678:
    test ebp, ebp
    jge near .branch_17df
    mov eax, dword [esp + 0x44]
    mov ecx, dword [engine_1c715c]
    cmp eax, ecx
    jge short .branch_1692
    mov dword [esp + 0x44], ecx

.branch_1692:
    mov eax, dword [esp + 0x40]
    mov esi, dword [engine_1c515c]
    cmp eax, esi
    jle short .branch_16a4
    mov dword [esp + 0x40], esi

.branch_16a4:
    mov edx, dword [esp + 0x3c]
    mov dl, byte [edx + engine_1db5e0]
    cmp dl, 1
    jb short .branch_16d7
    mov eax, dword [esp + 0x38]
    mov ebp, dword [esp + 0x3c]
    shl eax, 2
    add ebp, ebp
    cmp dl, 1
    jbe near .branch_175f
    cmp dl, 2
    je near .branch_179f
    jmp near .branch_17df

.branch_16d7:
    test dl, dl
    jne near .branch_17df
    mov eax, dword [esp + 0x44]
    mov edx, dword [esp + 0x40]
    cmp eax, edx
    jg near .branch_17df
    cmp eax, dword [engine_1c715c]
    jne short .branch_1703
    cmp edx, dword [engine_1c515c]
    je near .branch_2b9c

.branch_1703:
    mov eax, dword [esp + 0x40]
    mov esi, dword [esp + 0x44]
    sub eax, esi
    add eax, eax
    lea edi, [esi + esi]
    lea ecx, [eax + 2]
    add edi, dwall
    xor eax, eax
    cmp ecx, 4
    jae short .branch_172f
    test cl, 1
    je short .branch_1728
    stosb

.branch_1728:
    shr ecx, 1
    db 0xf3                       ; REP precedes the operand-size prefix
    stosw
    jmp short .branch_175a

.branch_172f:
    test edi, 1
    je short .branch_1739
    stosb
    dec ecx

.branch_1739:
    test edi, 2
    je short .branch_1746
    stosw
    sub ecx, 2

.branch_1746:
    mov ebx, ecx
    shr ecx, 2
    rep stosd
    test bl, 2
    je short .branch_1754
    stosw

.branch_1754:
    test bl, 1
    je short .branch_175a
    stosb

.branch_175a:
    jmp near .branch_17df

.branch_175f:
    movsx edx, word [ebp + engine_1da560]
    mov ebp, dword [eax + engine_1c5160]
    mov eax, edx
    sub eax, ebp
    mov ebp, dword [esp + 0x44]
    jmp short .branch_1797

.branch_1776:
    lea ebx, [eax + ebp]
    add ebx, ebx
    lea edx, [ebp + ebp]
    mov si, word [ebx + engine_1a8960]
    cmp si, word [edx + uwall]
    jle short .branch_1796
    mov word [edx + uwall], si

.branch_1796:
    inc ebp

.branch_1797:
    cmp ebp, dword [esp + 0x40]
    jle short .branch_1776
    jmp short .branch_17df

.branch_179f:
    movsx edx, word [ebp + engine_1da560]
    mov edi, dword [eax + engine_1c5160]
    mov eax, edx
    mov ebp, dword [esp + 0x44]
    sub eax, edi
    mov edi, dword [esp + 0x40]
    jmp short .branch_17db

.branch_17ba:
    lea ebx, [eax + ebp]
    add ebx, ebx
    lea edx, [ebp + ebp]
    mov si, word [ebx + engine_1a8960]
    cmp si, word [edx + dwall]
    jge short .branch_17da
    mov word [edx + dwall], si

.branch_17da:
    inc ebp

.branch_17db:
    cmp ebp, edi
    jle short .branch_17ba

.branch_17df:
    dec dword [esp + 0x3c]

.branch_17e3:
    mov ecx, dword [esp + 0x3c]
    test ecx, ecx
    jge near .branch_13a9
    movsx eax, word [engine_28912a]
    cmp eax, 1
    jl short .branch_1860
    mov eax, dword [engine_14187]
    cmp eax, dword [engine_1c715c]
    jl short .branch_1860
    cmp eax, dword [engine_1c515c]
    jg short .branch_1860
    lea edx, [eax + eax]
    mov ebp, dword [engine_2863cc]
    movsx eax, word [edx + uwall]
    cmp eax, ebp
    jg short .branch_1860
    movsx eax, word [edx + dwall]
    cmp eax, ebp
    jl short .branch_1860
    mov eax, dword [esp + 0x98]
    mov word [engine_289124], ax
    mov eax, dword [esp + 0xc0]
    mov edx, 1
    mov word [engine_289128], ax
    mov eax, 3
    mov word [engine_28912a], dx
    mov word [engine_289122], ax

.branch_1860:
    test byte [esp + 0x64], 2
    jne short .branch_1890
    push lwall
    mov ecx, dwall
    mov ebx, uwall
    push swall
    mov edx, dword [engine_1c515c]
    mov eax, dword [engine_1c715c]
    call maskwallscan
    jmp near .branch_2b9c

.branch_1890:
    mov edx, dword [engine_1c515c]
    mov eax, dword [engine_1c715c]
    call transmaskwallscan
    jmp near .branch_2b9c

.branch_18a5:
    cmp eax, 0x20
    jne near .branch_2b9c
    test ch, 0x40
    je short .branch_18dd
    mov edx, dword [esp + 0x6c]
    mov eax, dword [globalposz]
    cmp eax, dword [edx + 8]
    setg al
    mov edx, eax
    and edx, 0xff
    test ch, 8
    sete al
    and eax, 0xff
    cmp edx, eax
    je near .branch_2b9c

.branch_18dd:
    mov eax, dword [esp + 0x64]
    and eax, 4
    test eax, eax
    jle short .branch_18ea
    neg ebp

.branch_18ea:
    mov eax, dword [esp + 0x64]
    and eax, 8
    test eax, eax
    jle short .branch_18fc
    neg dword [esp + 0xb0]

.branch_18fc:
    movsx eax, word [esp + 0xbc]
    mov ecx, dword [esp + 0x6c]
    movsx edx, word [nosplit eax*2 + tilesizx]
    movsx eax, word [nosplit eax*2 + move_tile_heights]
    mov esi, dword [globalposx]
    mov dword [esp + 0x9c], eax
    mov eax, dword [esp + 0x6c]
    mov edi, dword [globalposy]
    mov ecx, dword [ecx + 4]
    mov eax, dword [eax]
    sub ecx, edi
    sub eax, esi
    mov edi, ecx
    mov dword [esp + 0x1c], eax
    mov esi, dword [engine_286af8]
    mov ebx, dword [esp + 0x1c]
    mov eax, dword [engine_286ac8]
    mov dword [esp + 0x60], edx
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0xa
    mov edi, dword [esp + 0x1c]
    mov esi, dword [engine_286af8]
    mov dword [engine_199130], eax
    mov ebx, ecx
    mov eax, dword [engine_286ac8]
    neg esi
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0xa
    mov edx, dword [esp + 0x6c]
    mov dword [engine_1990b0], eax
    movsx edx, word [edx + 0x1c]
    movsx eax, word [engine_289148]
    add edx, 0x800
    sub edx, eax
    and edx, 0x7ff
    mov dword [esp + 0x3c], edx
    lea eax, [edx + 0x200]
    and eax, 0x7ff
    movsx eax, word [nosplit eax*2 + sintable]
    mov dword [esp + 0x90], eax
    movsx eax, word [nosplit edx*2 + sintable]
    mov dword [esp + 0x80], eax
    mov eax, dword [esp + 0x60]
    sar eax, 1
    mov ebx, dword [esp + 0x6c]
    lea edx, [eax + ebp]
    xor eax, eax
    mov al, byte [ebx + 0x14]
    imul edx, eax
    xor ecx, ecx
    mov eax, dword [esp + 0x9c]
    mov ebp, dword [esp + 0xb0]
    sar eax, 1
    mov cl, byte [ebx + 0x15]
    add eax, ebp
    imul ecx, eax
    mov esi, dword [esp + 0x90]
    mov ebx, edx
    mov eax, dword [esp + 0x80]
    mov edi, ecx
    mov dword [esp + 0x1c], edx
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0xc
    mov esi, dword [esp + 0x90]
    mov edi, dword [esp + 0x1c]
    mov edx, dword [engine_199130]
    mov ebx, ecx
    neg esi
    add edx, eax
    mov eax, dword [esp + 0x80]
    mov dword [engine_199130], edx
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0xc
    mov ebx, dword [engine_1990b0]
    add ebx, eax
    mov edx, dword [esp + 0x6c]
    mov dword [engine_1990b0], ebx
    xor eax, eax
    mov al, byte [edx + 0x14]
    mov edx, dword [esp + 0x60]
    imul edx, eax
    mov eax, dword [esp + 0x6c]
    xor ecx, ecx
    mov ebx, edx
    mov cl, byte [eax + 0x15]
    mov eax, dword [esp + 0x80]
    mov dword [esp + 0x1c], edx
    imul ebx
    shrd eax, edx, 0xc
    mov edx, dword [engine_199130]
    sub edx, eax
    mov esi, dword [esp + 0x9c]
    mov dword [engine_199134], edx
    imul ecx, esi
    mov eax, dword [esp + 0x90]
    imul ebx
    shrd eax, edx, 0xc
    mov edx, dword [engine_1990b0]
    add eax, edx
    mov ebx, ecx
    mov dword [engine_1990b4], eax
    mov eax, dword [esp + 0x90]
    imul ebx
    shrd eax, edx, 0xc
    mov dword [esp + 0x1c], eax
    mov edi, eax
    mov eax, dword [esp + 0x80]
    neg edi
    imul ebx
    shrd eax, edx, 0xc
    mov ecx, eax
    mov eax, dword [engine_199134]
    add eax, edi
    neg ecx
    mov dword [engine_199138], eax
    mov eax, dword [engine_1990b4]
    add eax, ecx
    mov dword [engine_1990b8], eax
    mov eax, dword [engine_199130]
    add eax, edi
    mov dword [engine_19913c], eax
    mov eax, dword [engine_1990b0]
    add ecx, eax
    mov eax, dword [esp + 0x6c]
    mov dword [engine_1990bc], ecx
    mov ecx, dword [globalposz]
    mov eax, dword [eax + 8]
    mov ebx, dword [engine_287e7c]
    sub eax, ecx
    mov ecx, 0x14000
    mov dword [esp + 0x1c], edi
    imul ebx
    idiv ecx
    mov dword [engine_199110], eax
    test eax, eax
    je near .branch_2b9c
    mov dl, byte [esp + 0x64]
    mov dword [engine_199114], eax
    mov dword [engine_199118], eax
    mov dword [engine_19911c], eax
    test dl, 4
    jne short .branch_1b7b
    mov ebp, 1
    xor esi, esi
    mov dword [esp + 0x34], ebp
    mov ebp, 3
    jmp short .branch_1b8b

.branch_1b7b:
    mov esi, 1
    xor edi, edi
    mov ebp, 2
    mov dword [esp + 0x34], edi

.branch_1b8b:
    shl esi, 2
    mov eax, dword [esi + engine_1990b0]
    shl eax, 0xc
    mov dword [globalxpanning], eax
    mov eax, dword [esi + engine_199130]
    shl eax, 0xc
    mov dword [globalypanning], eax
    mov eax, dword [esi + engine_199110]
    shl eax, 0xc
    mov dword [globalzd], eax
    mov eax, dword [esp + 0x34]
    mov dword [esp + 0xac], esi
    mov ecx, dword [esi + engine_199130]
    mov edx, dword [eax*4 + engine_199130]
    mov esi, dword [esi + engine_1990b0]
    sub edx, ecx
    mov ecx, dword [eax*4 + engine_1990b0]
    mov ebx, edx
    sub ecx, esi
    mov eax, edx
    mov edi, ecx
    mov esi, ecx
    mov dword [esp + 0x1c], edx
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 8
    mov esi, eax
    mov eax, dword [esp + 0x1c]
    test eax, eax
    jns short .branch_1c08
    neg eax

.branch_1c08:
    sar eax, 0xd
    cmp eax, esi
    jge near .branch_2b9c
    mov eax, ecx
    test eax, eax
    jns short .branch_1c1b
    neg eax

.branch_1c1b:
    sar eax, 0xd
    cmp eax, esi
    jge near .branch_2b9c
    mov eax, dword [esp + 0x1c]
    mov ebx, esi
    mov edx, eax
    sar edx, 0xe
    shl eax, 0x12
    idiv ebx
    mov dword [globalx1], eax
    mov eax, ecx
    mov edx, eax
    sar edx, 0xe
    shl eax, 0x12
    idiv ebx
    mov edx, dword [esp + 0xac]
    mov dword [globalx2], eax
    mov ecx, dword [ebp*4 + engine_1990b0]
    mov eax, dword [ebp*4 + engine_199130]
    mov edi, dword [edx + engine_199130]
    mov ebp, dword [edx + engine_1990b0]
    sub eax, edi
    sub ecx, ebp
    mov ebx, eax
    mov edi, ecx
    mov esi, ecx
    mov dword [esp + 0x1c], eax
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 8
    mov esi, eax
    mov eax, dword [esp + 0x1c]
    test eax, eax
    jns short .branch_1c96
    neg eax

.branch_1c96:
    sar eax, 0xd
    cmp eax, esi
    jge near .branch_2b9c
    mov eax, ecx
    test eax, eax
    jns short .branch_1ca9
    neg eax

.branch_1ca9:
    sar eax, 0xd
    cmp eax, esi
    jge near .branch_2b9c
    mov eax, dword [esp + 0x1c]
    mov ebx, esi
    mov edx, eax
    sar edx, 0xe
    shl eax, 0x12
    idiv ebx
    mov dword [globaly1], eax
    mov eax, ecx
    mov edx, eax
    sar edx, 0xe
    shl eax, 0x12
    idiv ebx
    mov dword [globaly2], eax
    cmp dword [engine_199110], 0
    jge short .branch_1d1b
    mov eax, dword [engine_1990b4]
    mov dword [esp + 0x3c], eax
    mov eax, dword [engine_1990bc]
    mov dword [engine_1990b4], eax
    mov eax, dword [esp + 0x3c]
    mov dword [engine_1990bc], eax
    mov eax, dword [engine_199134]
    mov dword [esp + 0x3c], eax
    mov eax, dword [engine_19913c]
    mov dword [engine_199134], eax
    mov eax, dword [esp + 0x3c]
    mov dword [engine_19913c], eax

.branch_1d1b:
    mov ebp, 4
    mov ecx, dword [engine_1990b0]
    mov edx, dword [engine_199130]
    xor edi, edi
    xor esi, esi
    add ecx, edx
    jmp near .branch_1e80

.branch_1d37:
    lea eax, [esi + 1]
    mov dword [esp], eax
    cmp ebp, eax
    jne short .branch_1d46
    xor edx, edx
    mov dword [esp], edx

.branch_1d46:
    mov edx, dword [esp]
    mov eax, ecx
    mov ecx, dword [edx*4 + engine_1990b0]
    add ecx, dword [edx*4 + engine_199130]
    test eax, eax
    jl short .branch_1da4
    mov edx, esi
    shl edx, 2
    mov dword [esp + 0x74], edx
    mov edx, edi
    shl edx, 2
    mov dword [esp + 0x70], edx
    mov edx, dword [esp + 0x74]
    mov ebx, dword [esp + 0x70]
    mov edx, dword [edx + engine_1990b0]
    mov dword [ebx + engine_199050], edx
    mov edx, dword [esp + 0x74]
    mov edx, dword [edx + engine_199110]
    mov dword [ebx + engine_199070], edx
    mov edx, dword [esp + 0x74]
    mov edx, dword [edx + engine_199130]
    inc edi
    mov dword [ebx + engine_199090], edx

.branch_1da4:
    mov edx, eax
    xor edx, ecx
    test edx, edx
    jge near .branch_1e7f
    mov ebx, eax
    sub ebx, ecx
    mov edx, eax
    sar edx, 2
    shl eax, 0x1e
    idiv ebx
    mov dword [esp + 0x7c], eax
    mov eax, esi
    shl eax, 2
    mov dword [esp + 0x78], eax
    mov eax, dword [esp]
    mov edx, dword [esp + 0x78]
    shl eax, 2
    mov ebx, dword [edx + engine_1990b0]
    mov dword [esp + 0x74], eax
    mov eax, dword [eax + engine_1990b0]
    sub eax, ebx
    mov ebx, eax
    mov eax, dword [esp + 0x7c]
    imul ebx
    shrd eax, edx, 0x1e
    mov edx, dword [esp + 0x78]
    mov ebx, dword [edx + engine_1990b0]
    mov edx, edi
    shl edx, 2
    add eax, ebx
    mov dword [edx + engine_199050], eax
    mov eax, dword [esp + 0x74]
    mov dword [esp + 0x70], edx
    mov edx, dword [esp + 0x78]
    mov eax, dword [eax + engine_199110]
    mov ebx, dword [edx + engine_199110]
    sub eax, ebx
    mov ebx, eax
    mov eax, dword [esp + 0x7c]
    imul ebx
    shrd eax, edx, 0x1e
    mov edx, dword [esp + 0x78]
    mov ebx, dword [edx + engine_199110]
    mov edx, dword [esp + 0x70]
    add eax, ebx
    mov dword [edx + engine_199070], eax
    mov eax, dword [esp + 0x74]
    mov edx, dword [esp + 0x78]
    mov eax, dword [eax + engine_199130]
    mov ebx, dword [edx + engine_199130]
    sub eax, ebx
    mov ebx, eax
    mov eax, dword [esp + 0x7c]
    imul ebx
    shrd eax, edx, 0x1e
    mov edx, dword [esp + 0x78]
    mov ebx, dword [edx + engine_199130]
    mov edx, dword [esp + 0x70]
    add eax, ebx
    inc edi
    mov dword [edx + engine_199090], eax

.branch_1e7f:
    inc esi

.branch_1e80:
    cmp esi, ebp
    jl near .branch_1d37
    cmp edi, 2
    jle near .branch_2b9c
    mov ecx, dword [engine_199050]
    mov esi, dword [engine_199090]
    xor ebp, ebp
    sub ecx, esi
    xor esi, esi
    jmp near .branch_1ff1

.branch_1ea8:
    lea eax, [esi + 1]
    mov dword [esp], eax
    cmp edi, eax
    jne short .branch_1eb7
    xor edx, edx
    mov dword [esp], edx

.branch_1eb7:
    mov edx, dword [esp]
    mov eax, ecx
    mov ecx, dword [edx*4 + engine_199050]
    sub ecx, dword [edx*4 + engine_199090]
    test eax, eax
    jg short .branch_1f15
    mov edx, esi
    shl edx, 2
    mov dword [esp + 0x74], edx
    mov edx, ebp
    shl edx, 2
    mov dword [esp + 0x70], edx
    mov edx, dword [esp + 0x74]
    mov ebx, dword [esp + 0x70]
    mov edx, dword [edx + engine_199050]
    mov dword [ebx + engine_1990b0], edx
    mov edx, dword [esp + 0x74]
    mov edx, dword [edx + engine_199070]
    mov dword [ebx + engine_199110], edx
    mov edx, dword [esp + 0x74]
    mov edx, dword [edx + engine_199090]
    inc ebp
    mov dword [ebx + engine_199130], edx

.branch_1f15:
    mov edx, eax
    xor edx, ecx
    test edx, edx
    jge near .branch_1ff0
    mov ebx, eax
    sub ebx, ecx
    mov edx, eax
    sar edx, 2
    shl eax, 0x1e
    idiv ebx
    mov dword [esp + 0x7c], eax
    mov eax, esi
    shl eax, 2
    mov dword [esp + 0x78], eax
    mov eax, dword [esp]
    mov edx, dword [esp + 0x78]
    shl eax, 2
    mov ebx, dword [edx + engine_199050]
    mov dword [esp + 0x74], eax
    mov eax, dword [eax + engine_199050]
    sub eax, ebx
    mov ebx, eax
    mov eax, dword [esp + 0x7c]
    imul ebx
    shrd eax, edx, 0x1e
    mov edx, dword [esp + 0x78]
    mov ebx, dword [edx + engine_199050]
    mov edx, ebp
    shl edx, 2
    add eax, ebx
    mov dword [edx + engine_1990b0], eax
    mov eax, dword [esp + 0x74]
    mov dword [esp + 0x70], edx
    mov edx, dword [esp + 0x78]
    mov eax, dword [eax + engine_199070]
    mov ebx, dword [edx + engine_199070]
    sub eax, ebx
    mov ebx, eax
    mov eax, dword [esp + 0x7c]
    imul ebx
    shrd eax, edx, 0x1e
    mov edx, dword [esp + 0x78]
    mov ebx, dword [edx + engine_199070]
    mov edx, dword [esp + 0x70]
    add eax, ebx
    mov dword [edx + engine_199110], eax
    mov eax, dword [esp + 0x74]
    mov edx, dword [esp + 0x78]
    mov eax, dword [eax + engine_199090]
    mov ebx, dword [edx + engine_199090]
    sub eax, ebx
    mov ebx, eax
    mov eax, dword [esp + 0x7c]
    imul ebx
    shrd eax, edx, 0x1e
    mov edx, dword [esp + 0x78]
    mov ebx, dword [edx + engine_199090]
    mov edx, dword [esp + 0x70]
    add eax, ebx
    inc ebp
    mov dword [edx + engine_199130], eax

.branch_1ff0:
    inc esi

.branch_1ff1:
    cmp esi, edi
    jl near .branch_1ea8
    cmp ebp, 2
    jle near .branch_2b9c
    mov eax, dword [engine_199110]
    mov ecx, dword [engine_286b08]
    imul ecx, eax
    mov esi, dword [globalhoriz]
    mov eax, dword [engine_199130]
    imul eax, esi
    xor edi, edi
    add ecx, eax
    xor esi, esi
    jmp near .branch_2185

.branch_2029:
    lea eax, [esi + 1]
    mov dword [esp], eax
    cmp ebp, eax
    jne short .branch_2038
    xor edx, edx
    mov dword [esp], edx

.branch_2038:
    mov edx, dword [esp]
    mov eax, ecx
    mov ecx, dword [engine_286b08]
    mov ebx, dword [edx*4 + engine_199110]
    imul ebx, ecx
    mov edx, dword [edx*4 + engine_199130]
    imul edx, dword [globalhoriz]
    lea ecx, [ebx + edx]
    test eax, eax
    jl short .branch_20a9
    mov edx, esi
    shl edx, 2
    mov dword [esp + 0x74], edx
    mov edx, edi
    shl edx, 2
    mov dword [esp + 0x70], edx
    mov edx, dword [esp + 0x74]
    mov ebx, dword [esp + 0x70]
    mov edx, dword [edx + engine_1990b0]
    mov dword [ebx + engine_199050], edx
    mov edx, dword [esp + 0x74]
    mov edx, dword [edx + engine_199110]
    mov dword [ebx + engine_199070], edx
    mov edx, dword [esp + 0x74]
    mov edx, dword [edx + engine_199130]
    inc edi
    mov dword [ebx + engine_199090], edx

.branch_20a9:
    mov edx, eax
    xor edx, ecx
    test edx, edx
    jge near .branch_2184
    mov ebx, eax
    sub ebx, ecx
    mov edx, eax
    sar edx, 2
    shl eax, 0x1e
    idiv ebx
    mov dword [esp + 0x7c], eax
    mov eax, esi
    shl eax, 2
    mov dword [esp + 0x78], eax
    mov eax, dword [esp]
    mov edx, dword [esp + 0x78]
    shl eax, 2
    mov ebx, dword [edx + engine_1990b0]
    mov dword [esp + 0x74], eax
    mov eax, dword [eax + engine_1990b0]
    sub eax, ebx
    mov ebx, eax
    mov eax, dword [esp + 0x7c]
    imul ebx
    shrd eax, edx, 0x1e
    mov edx, dword [esp + 0x78]
    mov ebx, dword [edx + engine_1990b0]
    mov edx, edi
    shl edx, 2
    add eax, ebx
    mov dword [edx + engine_199050], eax
    mov eax, dword [esp + 0x74]
    mov dword [esp + 0x70], edx
    mov edx, dword [esp + 0x78]
    mov eax, dword [eax + engine_199110]
    mov ebx, dword [edx + engine_199110]
    sub eax, ebx
    mov ebx, eax
    mov eax, dword [esp + 0x7c]
    imul ebx
    shrd eax, edx, 0x1e
    mov edx, dword [esp + 0x78]
    mov ebx, dword [edx + engine_199110]
    mov edx, dword [esp + 0x70]
    add eax, ebx
    mov dword [edx + engine_199070], eax
    mov eax, dword [esp + 0x74]
    mov edx, dword [esp + 0x78]
    mov eax, dword [eax + engine_199130]
    mov ebx, dword [edx + engine_199130]
    sub eax, ebx
    mov ebx, eax
    mov eax, dword [esp + 0x7c]
    imul ebx
    shrd eax, edx, 0x1e
    mov edx, dword [esp + 0x78]
    mov ebx, dword [edx + engine_199130]
    mov edx, dword [esp + 0x70]
    add eax, ebx
    inc edi
    mov dword [edx + engine_199090], eax

.branch_2184:
    inc esi

.branch_2185:
    cmp esi, ebp
    jl near .branch_2029
    cmp edi, 2
    jle near .branch_2b9c
    mov eax, dword [globalhoriz]
    sub eax, dword [engine_286af4]
    mov ecx, dword [engine_199090]
    imul ecx, eax
    mov esi, dword [engine_286b08]
    mov eax, dword [engine_199070]
    imul eax, esi
    xor ebp, ebp
    add ecx, eax
    xor esi, esi
    jmp near .branch_2325

.branch_21c3:
    lea eax, [esi + 1]
    mov dword [esp], eax
    cmp edi, eax
    jne short .branch_21d2
    xor ebx, ebx
    mov dword [esp], ebx

.branch_21d2:
    mov ebx, dword [globalhoriz]
    mov eax, ecx
    mov ecx, dword [engine_286af4]
    mov edx, dword [esp]
    sub ebx, ecx
    imul ebx, dword [edx*4 + engine_199090]
    mov edx, dword [edx*4 + engine_199070]
    imul edx, dword [engine_286b08]
    lea ecx, [edx + ebx]
    test eax, eax
    jg short .branch_2249
    mov edx, esi
    shl edx, 2
    mov dword [esp + 0x74], edx
    mov edx, ebp
    shl edx, 2
    mov dword [esp + 0x70], edx
    mov edx, dword [esp + 0x74]
    mov ebx, dword [esp + 0x70]
    mov edx, dword [edx + engine_199050]
    mov dword [ebx + engine_1990b0], edx
    mov edx, dword [esp + 0x74]
    mov edx, dword [edx + engine_199070]
    mov dword [ebx + engine_199110], edx
    mov edx, dword [esp + 0x74]
    mov edx, dword [edx + engine_199090]
    inc ebp
    mov dword [ebx + engine_199130], edx

.branch_2249:
    mov edx, eax
    xor edx, ecx
    test edx, edx
    jge near .branch_2324
    mov ebx, eax
    sub ebx, ecx
    mov edx, eax
    sar edx, 2
    shl eax, 0x1e
    idiv ebx
    mov dword [esp + 0x70], eax
    mov eax, esi
    shl eax, 2
    mov dword [esp + 0x74], eax
    mov eax, dword [esp]
    mov edx, dword [esp + 0x74]
    shl eax, 2
    mov ebx, dword [edx + engine_199050]
    mov dword [esp + 0x78], eax
    mov eax, dword [eax + engine_199050]
    sub eax, ebx
    mov ebx, eax
    mov eax, dword [esp + 0x70]
    imul ebx
    shrd eax, edx, 0x1e
    mov edx, dword [esp + 0x74]
    mov ebx, dword [edx + engine_199050]
    mov edx, ebp
    shl edx, 2
    add eax, ebx
    mov dword [edx + engine_1990b0], eax
    mov eax, dword [esp + 0x78]
    mov dword [esp + 0x7c], edx
    mov edx, dword [esp + 0x74]
    mov eax, dword [eax + engine_199070]
    mov ebx, dword [edx + engine_199070]
    sub eax, ebx
    mov ebx, eax
    mov eax, dword [esp + 0x70]
    imul ebx
    shrd eax, edx, 0x1e
    mov edx, dword [esp + 0x74]
    mov ebx, dword [edx + engine_199070]
    mov edx, dword [esp + 0x7c]
    add eax, ebx
    mov dword [edx + engine_199110], eax
    mov eax, dword [esp + 0x78]
    mov edx, dword [esp + 0x74]
    mov eax, dword [eax + engine_199090]
    mov ebx, dword [edx + engine_199090]
    sub eax, ebx
    mov ebx, eax
    mov eax, dword [esp + 0x70]
    imul ebx
    shrd eax, edx, 0x1e
    mov edx, dword [esp + 0x74]
    mov ebx, dword [edx + engine_199090]
    mov edx, dword [esp + 0x7c]
    add eax, ebx
    inc ebp
    mov dword [edx + engine_199130], eax

.branch_2324:
    inc esi

.branch_2325:
    cmp esi, edi
    jl near .branch_21c3
    cmp ebp, 2
    jle near .branch_2b9c
    mov ecx, 0xffffffff
    mov esi, 0x7fffffff
    mov eax, 0x80000000
    mov dword [esp + 0x18], ecx
    mov dword [esp + 0x14], esi
    mov dword [esp + 0x10], ecx
    mov dword [esp + 0xc], eax
    xor esi, esi
    jmp near .branch_2443

.branch_235c:
    mov edi, esi
    mov ebx, dword [xdimen]
    shl edi, 2
    shl ebx, 0xf
    mov ecx, dword [edi + engine_199130]
    mov eax, dword [edi + engine_1990b0]
    imul ebx
    idiv ecx
    mov ebx, dword [xdimen]
    shl ebx, 0xf
    add eax, ebx
    mov ecx, dword [edi + engine_199130]
    mov dword [edi + engine_1990d0], eax
    mov eax, dword [edi + engine_199110]
    imul ebx
    idiv ecx
    mov edx, dword [globalhoriz]
    shl edx, 0x10
    add eax, edx
    mov ecx, dword [edi + engine_1990d0]
    mov dword [edi + engine_1990f0], eax
    test ecx, ecx
    jge short .branch_23be
    xor eax, eax
    mov dword [edi + engine_1990d0], eax

.branch_23be:
    mov eax, esi
    mov edx, dword [xdimen]
    shl eax, 2
    shl edx, 0x10
    cmp edx, dword [eax + engine_1990d0]
    jge short .branch_23da
    mov dword [eax + engine_1990d0], edx

.branch_23da:
    mov eax, esi
    shl eax, 2
    cmp dword [eax + engine_1990f0], 0
    jge short .branch_23f0
    xor edi, edi
    mov dword [eax + engine_1990f0], edi

.branch_23f0:
    mov eax, esi
    mov edx, dword [engine_286af4]
    shl eax, 2
    shl edx, 0x10
    cmp edx, dword [eax + engine_1990f0]
    jge short .branch_240c
    mov dword [eax + engine_1990f0], edx

.branch_240c:
    mov eax, esi
    shl eax, 2
    mov ecx, dword [esp + 0x14]
    mov edx, dword [eax + engine_1990d0]
    cmp edx, ecx
    jge short .branch_2427
    mov dword [esp + 0x14], edx
    mov dword [esp + 0x18], esi

.branch_2427:
    mov eax, esi
    shl eax, 2
    mov edi, dword [esp + 0xc]
    mov edx, dword [eax + engine_1990d0]
    cmp edx, edi
    jle short .branch_2442
    mov dword [esp + 0xc], edx
    mov dword [esp + 0x10], esi

.branch_2442:
    inc esi

.branch_2443:
    cmp esi, ebp
    jl near .branch_235c
    mov esi, dword [esp + 0x18]
    jmp near .branch_2540

.branch_2454:
    lea eax, [esi + 1]
    mov dword [esp], eax
    cmp ebp, eax
    jne short .branch_2463
    xor ebx, ebx
    mov dword [esp], ebx

.branch_2463:
    mov eax, dword [esp]
    shl eax, 2
    shl esi, 2
    mov edx, dword [eax + engine_1990d0]
    mov edi, dword [esi + engine_1990d0]
    add edx, 0xffff
    add edi, 0xffff
    sar edx, 0x10
    sar edi, 0x10
    mov dword [esp + 8], edx
    cmp edi, edx
    jge near .branch_253d
    mov edx, dword [eax + engine_1990d0]
    mov ebx, dword [esi + engine_1990d0]
    mov ecx, dword [esi + engine_1990f0]
    sub edx, ebx
    mov eax, dword [eax + engine_1990f0]
    mov ebx, edx
    sub eax, ecx
    mov edx, eax
    sar edx, 0x10
    shl eax, 0x10
    idiv ebx
    mov ecx, eax
    mov eax, edi
    mov edx, dword [esi + engine_1990d0]
    shl eax, 0x10
    mov ebx, ecx
    sub eax, edx
    imul ebx
    shrd eax, edx, 0x10
    mov edx, dword [esi + engine_1990f0]
    add edx, eax
    mov eax, dword [esp + 8]
    sub eax, edi
    lea ebx, [edi + edi]
    mov esi, ecx
    add ebx, uwall
    mov ecx, eax
    mov eax, ebx
    mov dword [esp + 4], edx
    test ecx, ecx
    je short .branch_253d
    test al, 2
    je short .branch_250e
    mov ebx, edx
    sar ebx, 0x10
    mov word [eax], bx
    add edx, esi
    add eax, 2
    dec ecx
    je short .branch_253d

.branch_250e:
    sub ecx, 2
    jb short .branch_2535

.branch_2513:
    mov ebx, edx
    add edx, esi
    sar ebx, 0x10
    mov edi, edx
    and edi, 0xffff0000
    add edx, esi
    add ebx, edi
    mov dword [eax], ebx
    add eax, 4
    sub ecx, 2
    jae short .branch_2513
    test cl, 1
    je short .branch_253d

.branch_2535:
    mov ebx, edx
    sar ebx, 0x10
    mov word [eax], bx

.branch_253d:
    mov esi, dword [esp]

.branch_2540:
    cmp esi, dword [esp + 0x10]
    jne near .branch_2454
    jmp near .branch_262f

.branch_254f:
    lea eax, [esi + 1]
    mov dword [esp], eax
    cmp ebp, eax
    jne short .branch_255e
    xor edi, edi
    mov dword [esp], edi

.branch_255e:
    mov ecx, dword [esp]
    shl esi, 2
    shl ecx, 2
    mov eax, dword [esi + engine_1990d0]
    mov edi, dword [ecx + engine_1990d0]
    add eax, 0xffff
    add edi, 0xffff
    sar eax, 0x10
    sar edi, 0x10
    mov dword [esp + 8], eax
    cmp edi, eax
    jge near .branch_262c
    mov ebx, dword [ecx + engine_1990d0]
    mov edx, dword [esi + engine_1990d0]
    mov eax, dword [ecx + engine_1990f0]
    sub ebx, edx
    sub eax, dword [esi + engine_1990f0]
    mov edx, eax
    sar edx, 0x10
    shl eax, 0x10
    idiv ebx
    mov esi, eax
    mov eax, edi
    mov ebx, dword [ecx + engine_1990d0]
    shl eax, 0x10
    sub eax, ebx
    mov ebx, esi
    imul ebx
    shrd eax, edx, 0x10
    mov edx, dword [ecx + engine_1990f0]
    mov ecx, dword [esp + 8]
    add edx, eax
    sub ecx, edi
    lea eax, [edi + edi]
    add eax, dwall
    mov dword [esp + 4], edx
    test ecx, ecx
    je short .branch_262c
    test al, 2
    je short .branch_25fd
    mov ebx, edx
    sar ebx, 0x10
    mov word [eax], bx
    add edx, esi
    add eax, 2
    dec ecx
    je short .branch_262c

.branch_25fd:
    sub ecx, 2
    jb short .branch_2624

.branch_2602:
    mov ebx, edx
    add edx, esi
    sar ebx, 0x10
    mov edi, edx
    and edi, 0xffff0000
    add edx, esi
    add ebx, edi
    mov dword [eax], ebx
    add eax, 4
    sub ecx, 2
    jae short .branch_2602
    test cl, 1
    je short .branch_262c

.branch_2624:
    mov ebx, edx
    sar ebx, 0x10
    mov word [eax], bx

.branch_262c:
    mov esi, dword [esp]

.branch_262f:
    cmp esi, dword [esp + 0x18]
    jne near .branch_254f
    mov eax, dword [esp + 0x14]
    add eax, 0xffff
    sar eax, 0x10
    mov dword [esp + 0x4c], eax
    mov eax, dword [esp + 0xc]
    add eax, 0xffff
    mov edi, dword [windowy1]
    sar eax, 0x10
    mov esi, dword [windowy1]
    mov dword [esp + 0x48], eax
    mov ebp, dword [esp + 0x4c]
    mov ecx, dword [esp + 0x48]
    jmp short .branch_26bf

.branch_266f:
    mov eax, dword [windowx1]
    add eax, ebp
    movsx edx, word [nosplit eax*2 + startumost]
    movsx eax, word [nosplit ebp*2 + uwall]
    sub edx, esi
    cmp eax, edx
    jg short .branch_268e
    mov eax, edx

.branch_268e:
    mov edx, dword [windowx1]
    add edx, ebp
    mov word [nosplit ebp*2 + uwall], ax
    movsx edx, word [nosplit edx*2 + startdmost]
    movsx eax, word [nosplit ebp*2 + dwall]
    sub edx, edi
    cmp eax, edx
    jge short .branch_26b6
    mov edx, eax

.branch_26b6:
    inc ebp
    mov word [nosplit ebp*2 + engine_1a63de], dx

.branch_26bf:
    cmp ebp, ecx
    jle short .branch_266f
    mov eax, dword [engine_140b1]
    dec eax
    mov dword [esp + 0x3c], eax
    jmp near .branch_294d

.branch_26d2:
    mov eax, dword [ecx*4 + engine_1d5560]
    mov dword [esp + 0x38], eax
    shl eax, 2
    mov ecx, dword [esp + 0x48]
    cmp ecx, dword [eax + engine_1c5160]
    jl near .branch_2949
    mov esi, dword [esp + 0x4c]
    cmp esi, dword [eax + engine_1c3160]
    jg near .branch_2949
    mov edx, dword [esp + 0x68]
    cmp edx, dword [eax + engine_1c9160]
    jg short .branch_2718
    cmp edx, dword [eax + engine_1c7160]
    jle near .branch_2949

.branch_2718:
    mov ebp, dword [esp + 0x38]
    movsx ebp, word [nosplit ebp*2 + engine_1c2160]
    shl ebp, 5
    mov eax, dword [ebp + wall]
    mov dword [esp + 0x30], eax
    mov eax, dword [ebp + engine_2310a4]
    movsx ebp, word [ebp + engine_2310a8]
    shl ebp, 5
    mov dword [esp + 0x2c], eax
    mov eax, dword [ebp + wall]
    mov dword [esp + 0x28], eax
    mov eax, dword [ebp + engine_2310a4]
    mov ebx, dword [esp + 0x30]
    mov dword [esp + 0x24], eax
    mov eax, dword [esp + 0x6c]
    mov edx, dword [esp + 0x2c]
    mov ebp, dword [esp + 0x28]
    mov eax, dword [eax + 4]
    sub ebp, ebx
    sub eax, edx
    imul ebp, eax
    mov edx, dword [esp + 0x6c]
    mov esi, dword [esp + 0x2c]
    mov edx, dword [edx]
    mov eax, dword [esp + 0x24]
    sub edx, ebx
    sub eax, esi
    imul eax, edx
    sub ebp, eax
    mov eax, dword [esp + 0x38]
    shl eax, 2
    mov edx, dword [esp + 0x68]
    cmp edx, dword [eax + engine_1c9160]
    jle short .branch_27aa
    cmp edx, dword [eax + engine_1c7160]
    jle short .branch_27aa
    mov ebp, 0xffffffff

.branch_27aa:
    test ebp, ebp
    jl short .branch_27d8
    jne near .branch_2949
    mov eax, dword [esp + 0x38]
    movsx eax, word [nosplit eax*2 + engine_1c2160]
    mov edx, dword [esp + 0x6c]
    shl eax, 5
    mov bx, word [edx + 0x18]
    cmp bx, word [eax + engine_2310ac]
    jne near .branch_2949

.branch_27d8:
    mov eax, dword [esp + 0x38]
    shl eax, 2
    mov ecx, dword [esp + 0x4c]
    mov edx, dword [eax + engine_1c5160]
    cmp edx, ecx
    jle short .branch_27f1
    mov eax, edx
    jmp short .branch_27f3

.branch_27f1:
    mov eax, ecx

.branch_27f3:
    mov dword [esp + 0x44], eax
    mov eax, dword [esp + 0x38]
    shl eax, 2
    mov esi, dword [esp + 0x48]
    mov edx, dword [eax + engine_1c3160]
    cmp edx, esi
    jge short .branch_2810
    mov eax, edx
    jmp short .branch_2812

.branch_2810:
    mov eax, esi

.branch_2812:
    mov edx, dword [esp + 0x3c]
    mov dl, byte [edx + engine_1db5e0]
    mov dword [esp + 0x40], eax
    cmp dl, 1
    jb short .branch_2849
    mov eax, dword [esp + 0x38]
    mov ebp, dword [esp + 0x3c]
    shl eax, 2
    add ebp, ebp
    cmp dl, 1
    jbe near .branch_28c9
    cmp dl, 2
    je near .branch_2909
    jmp near .branch_2949

.branch_2849:
    test dl, dl
    jne near .branch_2949
    mov edx, dword [esp + 0x44]
    cmp eax, edx
    jl near .branch_2949
    cmp edx, dword [esp + 0x4c]
    jne short .branch_286d
    cmp eax, dword [esp + 0x48]
    je near .branch_2b9c

.branch_286d:
    mov ecx, dword [esp + 0x40]
    mov esi, dword [esp + 0x44]
    sub ecx, esi
    xor eax, eax
    add ecx, ecx
    lea edi, [esi + esi]
    add ecx, 2
    add edi, dwall
    cmp ecx, 4
    jae short .branch_2899
    test cl, 1
    je short .branch_2892
    stosb

.branch_2892:
    shr ecx, 1
    db 0xf3                       ; REP precedes the operand-size prefix
    stosw
    jmp short .branch_28c4

.branch_2899:
    test edi, 1
    je short .branch_28a3
    stosb
    dec ecx

.branch_28a3:
    test edi, 2
    je short .branch_28b0
    stosw
    sub ecx, 2

.branch_28b0:
    mov ebx, ecx
    shr ecx, 2
    rep stosd
    test bl, 2
    je short .branch_28be
    stosw

.branch_28be:
    test bl, 1
    je short .branch_28c4
    stosb

.branch_28c4:
    jmp near .branch_2949

.branch_28c9:
    movsx edx, word [ebp + engine_1da560]
    mov ebp, dword [eax + engine_1c5160]
    mov eax, edx
    sub eax, ebp
    mov ebp, dword [esp + 0x44]
    jmp short .branch_2901

.branch_28e0:
    lea ebx, [eax + ebp]
    add ebx, ebx
    lea edx, [ebp + ebp]
    mov si, word [ebx + engine_1a8960]
    cmp si, word [edx + uwall]
    jle short .branch_2900
    mov word [edx + uwall], si

.branch_2900:
    inc ebp

.branch_2901:
    cmp ebp, dword [esp + 0x40]
    jle short .branch_28e0
    jmp short .branch_2949

.branch_2909:
    movsx edx, word [ebp + engine_1da560]
    mov edi, dword [eax + engine_1c5160]
    mov eax, edx
    mov ebp, dword [esp + 0x44]
    sub eax, edi
    mov edi, dword [esp + 0x40]
    jmp short .branch_2945

.branch_2924:
    lea edx, [eax + ebp]
    add edx, edx
    lea ebx, [ebp + ebp]
    mov si, word [edx + engine_1a8960]
    cmp si, word [ebx + dwall]
    jge short .branch_2944
    mov word [ebx + dwall], si

.branch_2944:
    inc ebp

.branch_2945:
    cmp ebp, edi
    jle short .branch_2924

.branch_2949:
    dec dword [esp + 0x3c]

.branch_294d:
    mov ecx, dword [esp + 0x3c]
    test ecx, ecx
    jge near .branch_26d2
    movsx eax, word [engine_28912a]
    cmp eax, 1
    jl short .branch_29c9
    mov esi, dword [esp + 0x4c]
    mov eax, dword [engine_14187]
    cmp eax, esi
    jl short .branch_29c9
    cmp eax, dword [esp + 0x48]
    jg short .branch_29c9
    lea edx, [eax + eax]
    mov ebp, dword [engine_2863cc]
    movsx eax, word [edx + uwall]
    cmp eax, ebp
    jg short .branch_29c9
    movsx eax, word [edx + dwall]
    cmp eax, ebp
    jl short .branch_29c9
    mov eax, dword [esp + 0x98]
    mov ecx, 3
    mov esi, 1
    mov word [engine_289124], ax
    mov word [engine_289122], cx
    mov eax, dword [esp + 0xc0]
    mov word [engine_28912a], si
    mov word [engine_289128], ax

.branch_29c9:
    mov eax, dword [esp + 0x64]
    mov dword [globalorientation], eax
    mov eax, dword [esp + 0xbc]
    mov word [globalpicnum], ax
    cwde
    test eax, 0xfffff000
    je short .branch_29f0
    xor edi, edi
    mov word [globalpicnum], di

.branch_29f0:
    movsx edx, word [globalpicnum]
    cmp dword [edx*4 + waloff], 0
    jne short .branch_2a08
    mov eax, edx
    call loadtile

.branch_2a08:
    mov ax, word [globalpicnum]
    cwde
    mov ebx, eax
    cmp byte [eax + walock], 0xc8
    jae short .branch_2a21
    mov byte [eax + walock], 0xc7

.branch_2a21:
    shr eax, 3
    and ebx, 7
    mov dl, byte [eax + engine_1ecda0]
    mov bl, byte [ebx + pow2char]
    or dl, bl
    mov byte [eax + engine_1ecda0], dl
    movsx eax, word [globalpicnum]
    mov eax, dword [eax*4 + waloff]
    mov dword [globalbufplc], eax
    mov eax, dword [engine_286a98]
    mov dword [globvis], eax
    mov eax, dword [esp + 0xa0]
    mov ch, byte [eax + 0x20]
    test ch, ch
    je short .branch_2a7e
    mov al, ch
    xor ebx, ebx
    add al, 0x10
    mov bl, al
    mov eax, dword [globvis]
    imul ebx
    shrd eax, edx, 4
    mov dword [globvis], eax

.branch_2a7e:
    movsx ebp, word [globalpicnum]
    movzx ebp, byte [ebp + picsiz]
    mov eax, ebp
    sar eax, 4
    and ebp, 0xf
    and eax, 0xf
    mov ecx, dword [esp + 0x60]
    mov dword [esp + 4], eax
    cmp ecx, dword [ebp*4 + pow2long]
    je short .branch_2acd
    mov ebx, dword [esp + 0x60]
    inc ebp
    mov eax, dword [globalx1]
    mov ecx, ebp
    imul ebx
    shrd eax, edx, cl
    mov dword [globalx1], eax
    mov eax, dword [globalx2]
    imul ebx
    shrd eax, edx, cl
    mov dword [globalx2], eax

.branch_2acd:
    mov eax, dword [globalxpanning]
    mov ecx, dword [globalypanning]
    mov esi, dword [globalx2]
    mov dword [esp + 0x1c], eax
    mov ebx, ecx
    mov edi, dword [esp + 0x1c]
    mov eax, dword [globalx1]
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 6
    mov dword [globalxpanning], eax
    mov esi, eax
    mov ebx, ecx
    neg esi
    mov eax, dword [globaly1]
    mov dword [globalxpanning], esi
    mov esi, dword [globaly2]
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 6
    mov edx, dword [globalx2]
    mov dword [globalypanning], eax
    mov edi, eax
    mov eax, dword [globalx1]
    sub eax, edx
    mov edx, eax
    mov eax, dword [engine_286b08]
    imul edx, eax
    mov ebx, dword [globaly2]
    mov eax, dword [globaly1]
    mov dword [globalx1], edx
    mov edx, dword [engine_286b08]
    sub eax, ebx
    imul eax, edx
    neg edi
    mov dword [globaly1], eax
    mov al, byte [esp + 0x64]
    mov dword [globalypanning], edi
    test al, 2
    jne short .branch_2b83
    mov ebx, dword [esp + 4]
    mov eax, ebp
    call msethlineshift
    jmp short .branch_2b8e

.branch_2b83:
    mov ebx, dword [esp + 4]
    mov eax, ebp
    call tsethlineshift

.branch_2b8e:
    mov edx, dword [esp + 0x48]
    mov eax, dword [esp + 0x4c]
    dec edx
    call ceilspritescan

.branch_2b9c:
    add esp, 0xc8
    jmp near transmaskvline_restore

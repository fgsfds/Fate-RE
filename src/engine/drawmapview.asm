; Project visible automap sectors and floor sprites into textured polygons.
BITS 32
ORG 0x59d2c

sprite equ 0x2040a0
sector equ 0x27c3a0
wall equ 0x2310a0
numsectors equ 0x289154
picanm equ 0x1ed3a0
sqrtable equ 0x1dfa60
picsiz equ 0x1e5fe0
pow2long equ 0x14031
tilesizx equ 0x1f2020
move_tile_heights equ 0x1f4020
walock equ 0x1f8ca0
waloff equ 0x1ffca0
palookup equ 0x203ca0
pow2char equ 0x14029
rx1 equ 0x1cd160
ry1 equ 0x1d1160
globalpicnum equ 0x289144
globalshade equ 0x286a88
globvis equ 0x286ab8
window_left equ 0x286b9c
window_top equ 0x286b94
numpalookups equ 0x289156
asm1 equ 0x286aa4
asm2 equ 0x286aa8
asm3 equ 0x286aac
globalbufplc equ 0x286a90
globalorientation equ 0x286a84
globalx1 equ 0x286a80
globalx2 equ 0x286a4c
globaly1 equ 0x286a50
globaly2 equ 0x286a58
presentation_width equ 0x287e90
presentation_height equ 0x287e8c
sintable equ 0x2300a0
window_right equ 0x286b98
window_bottom equ 0x286b90
engine_14010 equ 0x14010
engine_1400c equ 0x1400c
engine_1ecd20 equ 0x1ecd20
engine_287e7c equ 0x287e7c
engine_14004 equ 0x14004
engine_1ec6a0 equ 0x1ec6a0
engine_1c5160 equ 0x1c5160
engine_286bac equ 0x286bac
engine_28891e equ 0x28891e
engine_2040ac equ 0x2040ac
engine_2710be equ 0x2710be
engine_1f9ca0 equ 0x1f9ca0
engine_286af0 equ 0x286af0
engine_1ecda0 equ 0x1ecda0
engine_286a98 equ 0x286a98
engine_2891d7 equ 0x2891d7
engine_286ad0 equ 0x286ad0
engine_286ad4 equ 0x286ad4
engine_2310a8 equ 0x2310a8
engine_2310a4 equ 0x2310a4
engine_286b20 equ 0x286b20
engine_286b23 equ 0x286b23
engine_27c3ba equ 0x27c3ba
engine_2891d5 equ 0x2891d5
engine_2891d6 equ 0x2891d6
engine_2040a8 equ 0x2040a8
engine_1c5164 equ 0x1c5164
engine_1c5168 equ 0x1c5168
engine_1c516c equ 0x1c516c
engine_1cd164 equ 0x1cd164
engine_1d1164 equ 0x1d1164
engine_1d1168 equ 0x1d1168
engine_1cd168 equ 0x1cd168
engine_1cd16c equ 0x1cd16c
engine_1d116c equ 0x1d116c
engine_27c3ac equ 0x27c3ac
engine_27c3b4 equ 0x27c3b4
engine_27c3bc equ 0x27c3bc
clippoly equ 0x5b230
setpalookupaddress equ 0x740e0
animateoffs equ 0x50758
loadtile equ 0x4bb0d
sethlinesizes equ 0x73ff0
fillpolygon equ 0x5bfb7
msethlineshift equ 0x74a50
tsethlineshift equ 0x74bc0

drawmapview_:
    push esi
    push edi
    push ebp
    sub esp, 0x94
    push eax
    push edx
    mov esi, ebx
    mov edx, ecx
    mov ecx, dword [window_left]
    mov eax, dword [window_bottom]
    xor ebx, ebx
    mov edi, dword [window_top]
    mov dword [engine_14010], ebx
    mov ebx, dword [window_right]
    inc eax
    inc ebx
    sub eax, edi
    sub ebx, ecx
    imul eax, ebx
    movsx ecx, word [numsectors]
    mov ebp, dword [engine_1400c]
    add ecx, 0x1f
    mov edi, engine_1ecd20
    sar ecx, 5
    add ebp, eax
    xor eax, eax
    mov dword [engine_1400c], ebp
    rep stosd
    mov eax, dword [window_left]
    shl eax, 0x10
    mov dword [esp + 0x68], eax
    mov eax, dword [window_top]
    shl eax, 0x10
    mov dword [esp + 0x6c], eax
    mov eax, dword [window_right]
    inc eax
    shl eax, 0x10
    mov edi, 0x600
    dec eax
    movsx ecx, dx
    mov dword [esp + 0x70], eax
    mov eax, dword [window_bottom]
    sub edi, ecx
    inc eax
    and edi, 0x7ff
    shl eax, 0x10
    add edi, edi
    dec eax
    mov ebx, esi
    mov dword [esp + 0x64], eax
    mov ax, word [edi + sintable]
    shl ebx, 8
    cwde
    mov edx, eax
    sar edx, 4
    shl eax, 0x1c
    idiv ebx
    mov dword [esp + 0x4c], eax
    mov eax, 0x800
    sub eax, ecx
    mov ecx, eax
    and ecx, 0x7ff
    add ecx, ecx
    mov ax, word [ecx + sintable]
    cwde
    mov edx, eax
    sar edx, 4
    shl eax, 0x1c
    idiv ebx
    mov dword [esp + 0x48], eax
    mov ax, word [ecx + sintable]
    cwde
    imul ebx
    shrd eax, edx, 8
    mov ebp, eax
    mov dword [esp + 0x58], eax
    mov ax, word [edi + sintable]
    cwde
    imul ebx
    shrd eax, edx, 8
    mov ebx, dword [engine_287e7c]
    mov ecx, eax
    mov dword [esp + 0x54], eax
    mov eax, ebp
    imul ebx
    shrd eax, edx, 0x10
    mov ebx, dword [engine_287e7c]
    mov dword [esp + 0x5c], eax
    mov eax, ecx
    imul ebx
    shrd eax, edx, 0x10
    mov dword [esp + 0x60], eax
    cmp dword [engine_14004], 0
    jle short .branch_143
    mov eax, 2
    mov edx, 0x3c4
    out dx, al

.branch_143:
    xor edx, edx
    mov ecx, sector
    mov dword [esp + 0x88], edx
    mov dword [esp + 0x78], edx
    mov dword [esp + 0x74], ecx
    jmp near .branch_a1b

.branch_15e:
    mov eax, esi
    sar eax, 3
    xor edx, edx
    mov dl, byte [eax + engine_1ec6a0]
    mov eax, esi
    and eax, 7
    mov al, byte [eax + pow2char]
    and eax, 0xff
    test edx, eax
    je near .branch_a07
    mov eax, dword [esp + 0x74]
    movsx eax, word [eax]
    mov dword [esp + 0x50], eax
    mov eax, dword [esp + 0x74]
    movsx eax, word [eax + 2]
    mov edx, wall
    mov dword [esp + 0x80], eax
    mov eax, dword [esp + 0x50]
    xor edi, edi
    shl eax, 5
    mov dword [esp + 0x84], edi
    add edx, eax
    mov dword [esp + 0x98], edi
    mov dword [esp + 0x8c], edx
    jmp near .branch_2f0

.branch_1c7:
    mov ebp, dword [esp + 0x8c]
    mov edx, dword [esp + 4]
    mov eax, dword [esp + 0x8c]
    mov ebx, dword [esp]
    mov edi, dword [esp + 0x54]
    mov ebp, dword [ebp]
    mov eax, dword [eax + 4]
    sub ebp, edx
    sub eax, ebx
    mov ebx, dword [esp + 0x58]
    mov esi, eax
    mov dword [esp + 0x94], eax
    neg esi
    mov eax, ebp
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0xc
    mov edx, dword [presentation_width]
    mov edi, dword [esp + 0x60]
    shl edx, 0xf
    mov ebx, dword [esp + 0x5c]
    add eax, edx
    mov esi, ebp
    mov dword [esp + 0x90], eax
    mov eax, dword [esp + 0x94]
    mov ebp, dword [esp + 0x90]
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0xc
    mov edx, dword [esp + 0x64]
    mov esi, dword [presentation_height]
    mov edi, dword [esp + 0x6c]
    shl esi, 0xf
    mov ebx, dword [esp + 0x70]
    add esi, eax
    sub ebx, ebp
    mov ecx, esi
    mov eax, ebp
    sub ecx, edi
    mov edi, dword [esp + 0x68]
    sub edx, esi
    sub eax, edi
    mov ebp, dword [esp + 0x98]
    sar eax, 0x1f
    add ebx, ebx
    adc eax, eax
    add ecx, ecx
    adc eax, eax
    add edx, edx
    adc eax, eax
    mov ebx, eax
    shl ebx, 4
    or al, 0xf0
    xor eax, ebx
    mov edx, dword [esp + 0x90]
    mov ebx, dword [esp + 0x50]
    mov edi, dword [esp + 0x8c]
    or ebp, eax
    mov eax, dword [esp + 0x84]
    mov dword [esp + 0x98], ebp
    add edi, 0x20
    lea ecx, [eax + 1]
    mov dword [eax*4 + rx1], edx
    mov dword [eax*4 + ry1], esi
    mov edx, dword [esp + 0x8c]
    mov esi, dword [esp + 0x80]
    mov dword [esp + 0x84], ecx
    dec esi
    movsx edx, word [edx + 8]
    mov dword [esp + 0x8c], edi
    sub edx, ebx
    mov dword [esp + 0x80], esi
    mov dword [eax*4 + engine_1c5160], edx

.branch_2f0:
    cmp dword [esp + 0x80], 0
    jg near .branch_1c7
    mov eax, dword [esp + 0x98]
    and eax, 0xf0
    cmp eax, 0xf0
    jne near .branch_a07
    mov eax, dword [rx1]
    mov dword [esp + 0x44], eax
    mov eax, dword [presentation_height]
    mov edx, dword [ry1]
    shl eax, 0xf
    sub edx, eax
    mov ebx, dword [engine_286bac]
    mov eax, edx
    imul ebx
    shrd eax, edx, 0x10
    mov edx, dword [presentation_height]
    shl edx, 0xf
    add eax, edx
    mov dword [esp + 0x3c], eax
    test byte [esp + 0x98], 0xf
    je short .branch_378
    mov edx, dword [esp + 0x98]
    mov eax, dword [esp + 0x84]
    call clippoly
    mov dword [esp + 0x84], eax
    cmp eax, 3
    jl near .branch_a07

.branch_378:
    mov eax, dword [esp + 0x78]
    movsx eax, word [nosplit eax*2 + engine_28891e]
    jmp short .branch_3df

.branch_386:
    imul eax, ebp, 0x2c
    mov dx, word [eax + engine_2040ac]
    xor dh, dh
    and dl, 0x30
    movsx edx, dx
    cmp edx, 0x20
    jne short .branch_3d0
    mov ax, word [eax + engine_2040ac]
    xor ah, ah
    and al, 0x48
    cwde
    cmp eax, 0x48
    je short .branch_3d0
    mov ebp, dword [esp + 0x88]
    imul eax, ebp, 0x2c
    mov edx, dword [esp + 0x98]
    mov word [eax + engine_2710be], dx
    lea eax, [ebp + 1]
    mov dword [esp + 0x88], eax

.branch_3d0:
    mov eax, dword [esp + 0x98]
    movsx eax, word [nosplit eax*2 + engine_1f9ca0]

.branch_3df:
    mov dword [esp + 0x98], eax
    mov ebp, dword [esp + 0x98]
    test ebp, ebp
    jge short .branch_386
    mov edx, dword [esp + 0x78]
    mov eax, dword [esp + 0x78]
    and edx, 7
    sar eax, 3
    mov dl, byte [edx + pow2char]
    or byte [eax + engine_1ecd20], dl
    mov eax, dword [esp + 0x74]
    movsx eax, word [eax + 0xe]
    mov dword [globalorientation], eax
    test byte [globalorientation], 1
    jne near .branch_a07
    mov edx, dword [esp + 0x74]
    xor eax, eax
    mov al, byte [edx + 0x1d]
    shl eax, 2
    mov ebx, dword [engine_286af0]
    mov edx, dword [eax + palookup]
    cmp edx, ebx
    je short .branch_44e
    mov eax, edx
    mov dword [engine_286af0], edx
    call setpalookupaddress

.branch_44e:
    mov eax, dword [esp + 0x74]
    mov ax, word [eax + 0x18]
    mov word [globalpicnum], ax
    cwde
    test eax, 0xfffff000
    je short .branch_46d
    xor edx, edx
    mov word [globalpicnum], dx

.branch_46d:
    mov ax, word [globalpicnum]
    cwde
    mov ebx, eax
    cmp byte [eax + walock], 0xc8
    jae short .branch_486
    mov byte [eax + walock], 0xc7

.branch_486:
    shr eax, 3
    and ebx, 7
    mov dl, byte [eax + engine_1ecda0]
    mov bl, byte [ebx + pow2char]
    or dl, bl
    mov byte [eax + engine_1ecda0], dl
    movsx eax, word [globalpicnum]
    lea edx, [eax + eax]
    cmp word [edx + tilesizx], 0
    jle near .branch_a07
    cmp word [edx + move_tile_heights], 0
    jle near .branch_a07
    test byte [eax*4 + picanm], 0xc0
    je short .branch_4e1
    movsx edx, word [esp + 0x78]
    call animateoffs
    add word [globalpicnum], ax

.branch_4e1:
    movsx eax, word [globalpicnum]
    cmp dword [eax*4 + waloff], 0
    jne short .branch_4f7
    call loadtile

.branch_4f7:
    movsx eax, word [globalpicnum]
    mov eax, dword [eax*4 + waloff]
    movsx edx, word [numpalookups]
    mov dword [globalbufplc], eax
    mov eax, dword [esp + 0x74]
    dec edx
    movsx eax, byte [eax + 0x1c]
    cmp eax, edx
    jl short .branch_520
    mov eax, edx

.branch_520:
    test eax, eax
    jle short .branch_53c
    movsx eax, word [numpalookups]
    mov edx, dword [esp + 0x74]
    dec eax
    movsx edx, byte [edx + 0x1c]
    cmp edx, eax
    jge short .branch_53e
    mov eax, edx
    jmp short .branch_53e

.branch_53c:
    xor eax, eax

.branch_53e:
    mov dword [globalshade], eax
    mov eax, dword [engine_286a98]
    mov dword [globvis], eax
    mov eax, dword [esp + 0x74]
    mov cl, byte [eax + 0x20]
    test cl, cl
    je short .branch_570
    mov al, cl
    xor ebx, ebx
    add al, 0x10
    mov bl, al
    mov eax, dword [globvis]
    imul ebx
    shrd eax, edx, 4
    mov dword [globvis], eax

.branch_570:
    xor ch, ch
    mov al, byte [globalorientation]
    mov byte [engine_2891d7], ch
    test al, 0x40
    jne short .branch_5b6
    mov eax, dword [esp + 4]
    mov dword [engine_286ad0], eax
    mov eax, dword [esp + 0x4c]
    mov dword [globalx1], eax
    mov eax, dword [esp + 0x48]
    mov dword [globaly1], eax
    mov eax, dword [esp]
    mov dword [engine_286ad4], eax
    mov eax, dword [esp + 0x4c]
    mov dword [globalx2], eax
    mov eax, dword [esp + 0x48]
    jmp near .branch_7ea

.branch_5b6:
    mov eax, dword [esp + 0x50]
    shl eax, 5
    movsx edx, word [eax + engine_2310a8]
    shl edx, 5
    mov esi, dword [eax + wall]
    mov ebp, dword [edx + wall]
    sub ebp, esi
    mov edi, dword [eax + engine_2310a4]
    mov eax, ebp
    imul eax, ebp
    mov edx, dword [edx + engine_2310a4]
    sub edx, edi
    mov dword [esp + 0x94], edx
    imul edx, edx
    add eax, edx
    mov dword [engine_286b20], eax
    fild dword [engine_286b20]
    fstp dword [engine_286b20]
    mov bl, byte [engine_286b23]
    sub bl, 0x44
    jge short .branch_61c
    xor ebx, ebx
    mov bx, word [nosplit eax*2 + sqrtable]
    jmp short .branch_633

.branch_61c:
    lea ecx, [nosplit ebx*2]
    shr eax, cl
    mov cl, bl
    xor ebx, ebx
    mov bx, word [nosplit eax*2 + sqrtable]
    shl ebx, cl

.branch_633:
    shr ebx, 0xa
    test ebx, ebx
    je near .branch_a07
    mov eax, 0x100000
    mov edx, eax
    sar edx, 0x1f
    idiv ebx
    mov edi, dword [esp + 0x48]
    mov esi, dword [esp + 0x94]
    mov ebx, dword [esp + 0x4c]
    mov dword [esp + 0x98], eax
    mov eax, ebp
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0xa
    mov ebx, dword [esp + 0x98]
    mov esi, dword [esp + 0x94]
    mov edi, dword [esp + 0x4c]
    imul ebx
    shrd eax, edx, 0xa
    mov ebx, dword [esp + 0x48]
    mov dword [globalx1], eax
    neg esi
    mov eax, ebp
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0xa
    mov ebx, dword [esp + 0x98]
    imul ebx
    shrd eax, edx, 0xa
    mov edx, dword [esp + 0x44]
    mov ebp, dword [presentation_width]
    sar edx, 8
    shl ebp, 7
    sub edx, ebp
    mov ebx, dword [esp + 0x3c]
    mov ebp, edx
    mov edx, dword [presentation_height]
    sar ebx, 8
    shl edx, 7
    mov dword [globaly1], eax
    sub ebx, edx
    mov edi, eax
    mov dword [esp + 0x94], ebx
    neg ebp
    mov edx, dword [esp + 0x94]
    mov esi, ebp
    neg edx
    mov ebx, dword [globalx1]
    mov eax, edx
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0x1c
    mov esi, dword [esp + 0x94]
    mov edi, dword [globaly1]
    mov ebx, dword [globalx1]
    mov dword [engine_286ad0], eax
    mov eax, ebp
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0x1c
    mov dword [engine_286ad4], eax
    mov eax, dword [globalx1]
    mov dword [globalx2], eax
    mov ecx, eax
    mov eax, dword [globaly1]
    mov edx, dword [esp + 0x78]
    mov dword [globaly2], eax
    mov esi, eax
    mov eax, edx
    shl eax, 2
    add eax, edx
    movsx eax, word [eax*8 + engine_27c3ba]
    imul eax, eax
    neg ecx
    mov dword [globalx2], ecx
    neg esi
    add eax, 0x1000000
    mov dword [globaly2], esi
    mov dword [engine_286b20], eax
    fild dword [engine_286b20]
    fstp dword [engine_286b20]
    mov bl, byte [engine_286b23]
    sub bl, 0x44
    jge short .branch_7a3
    xor ebx, ebx
    mov bx, word [nosplit eax*2 + sqrtable]
    jmp short .branch_7ba

.branch_7a3:
    lea ecx, [nosplit ebx*2]
    shr eax, cl
    mov cl, bl
    xor ebx, ebx
    mov bx, word [nosplit eax*2 + sqrtable]
    shl ebx, cl

.branch_7ba:
    shr ebx, 0xa
    mov eax, dword [engine_286ad4]
    mov ecx, ebx
    imul ebx
    shrd eax, edx, 0xc
    mov dword [engine_286ad4], eax
    mov eax, dword [globalx2]
    imul ebx
    shrd eax, edx, 0xc
    mov dword [globalx2], eax
    mov eax, dword [globaly2]
    imul ebx
    shrd eax, edx, 0xc

.branch_7ea:
    mov dword [globaly2], eax
    movsx eax, word [globalpicnum]
    mov dl, byte [eax + picsiz]
    and dl, 0xf
    mov dh, 8
    sub dh, dl
    mov al, byte [eax + picsiz]
    mov byte [engine_2891d5], dh
    and eax, 0xff
    mov edx, 8
    sar eax, 4
    sub edx, eax
    mov ah, byte [globalorientation]
    mov byte [engine_2891d6], dl
    test ah, 8
    je short .branch_83b
    inc byte [engine_2891d5]
    inc byte [engine_2891d6]

.branch_83b:
    movsx eax, word [globalpicnum]
    xor ebx, ebx
    mov ecx, dword [globalbufplc]
    mov bl, byte [eax + picsiz]
    mov al, byte [eax + picsiz]
    sar ebx, 4
    and al, 0xf
    and eax, 0xff
    call sethlinesizes
    mov eax, dword [globalorientation]
    and eax, 4
    test eax, eax
    jle near .branch_900
    mov eax, dword [engine_286ad0]
    mov dword [esp + 0x98], eax
    mov eax, dword [engine_286ad4]
    mov dword [engine_286ad0], eax
    mov edi, eax
    mov eax, dword [esp + 0x98]
    mov dword [engine_286ad4], eax
    mov ebp, eax
    mov eax, dword [globalx2]
    mov dword [esp + 0x98], eax
    mov eax, dword [globaly1]
    mov dword [globalx2], eax
    mov eax, dword [esp + 0x98]
    mov dword [globaly1], eax
    mov eax, dword [globalx1]
    mov dword [esp + 0x98], eax
    mov eax, dword [globaly2]
    neg edi
    mov dword [globalx1], eax
    neg eax
    mov dword [engine_286ad0], edi
    mov dword [globalx1], eax
    mov eax, dword [esp + 0x98]
    neg ebp
    mov edx, eax
    mov dword [globaly2], eax
    neg edx
    mov dword [engine_286ad4], ebp
    mov dword [globaly2], edx

.branch_900:
    mov eax, dword [globalorientation]
    and eax, 0x10
    test eax, eax
    jle short .branch_936
    mov ebx, dword [globalx1]
    mov ecx, dword [globaly1]
    mov esi, dword [engine_286ad0]
    neg ebx
    neg ecx
    neg esi
    mov dword [globalx1], ebx
    mov dword [globaly1], ecx
    mov dword [engine_286ad0], esi

.branch_936:
    mov eax, dword [globalorientation]
    and eax, 0x20
    test eax, eax
    jle short .branch_96a
    mov edi, dword [globalx2]
    mov ebp, dword [globaly2]
    mov eax, dword [engine_286ad4]
    neg edi
    neg ebp
    neg eax
    mov dword [globalx2], edi
    mov dword [globaly2], ebp
    mov dword [engine_286ad4], eax

.branch_96a:
    mov al, byte [engine_2891d5]
    mov edx, dword [globaly1]
    mov cl, al
    shl edx, cl
    mov dword [asm1], edx
    mov dl, byte [engine_2891d6]
    mov ebx, dword [globalx2]
    mov cl, dl
    shl ebx, cl
    mov dword [asm2], ebx
    mov cl, al
    mov ebx, dword [globalx1]
    shl ebx, cl
    mov esi, dword [globaly2]
    mov dword [globalx1], ebx
    mov cl, dl
    mov ebx, dword [esp + 0x74]
    mov edx, dword [engine_286ad0]
    shl esi, cl
    xor ecx, ecx
    mov dword [globaly2], esi
    mov cl, al
    xor eax, eax
    add ecx, 0x14
    mov al, byte [ebx + 0x1e]
    shl edx, cl
    shl eax, 0x18
    xor ecx, ecx
    add edx, eax
    mov cl, byte [engine_2891d6]
    mov dword [engine_286ad0], edx
    xor eax, eax
    add ecx, 0x14
    mov al, byte [ebx + 0x1f]
    mov edx, dword [engine_286ad4]
    shl eax, 0x18
    shl edx, cl
    sub edx, eax
    mov eax, dword [esp + 0x84]
    mov dword [engine_286ad4], edx
    call fillpolygon

.branch_a07:
    mov edx, dword [esp + 0x78]
    mov ebx, dword [esp + 0x74]
    inc edx
    add ebx, 0x28
    mov dword [esp + 0x78], edx
    mov dword [esp + 0x74], ebx

.branch_a1b:
    mov esi, dword [esp + 0x78]
    movsx eax, word [numsectors]
    cmp eax, esi
    jg near .branch_15e
    mov eax, dword [esp + 0x88]
    mov dword [esp + 0x18], eax

.branch_a39:
    mov ecx, dword [esp + 0x18]
    xor esi, esi
    sar ecx, 1
    mov dword [esp + 0x98], esi
    mov dword [esp + 0x18], ecx
    jmp short .branch_aa6

.branch_a4e:
    mov ebx, ebp

.branch_a50:
    mov eax, dword [esp + 0x18]
    add eax, ebx
    imul edx, ebx, 0x2c
    imul eax, eax, 0x2c
    movsx esi, word [edx + engine_2710be]
    imul ecx, esi, 0x2c
    movsx edi, word [eax + engine_2710be]
    imul edi, edi, 0x2c
    mov ecx, dword [ecx + engine_2040a8]
    cmp ecx, dword [edi + engine_2040a8]
    jle short .branch_a9f
    test ebx, ebx
    jl short .branch_a9f
    mov cx, word [eax + engine_2710be]
    mov word [edx + engine_2710be], cx
    mov edx, dword [esp + 0x18]
    mov word [eax + engine_2710be], si
    sub ebx, edx
    jmp short .branch_a50

.branch_a9f:
    inc dword [esp + 0x98]

.branch_aa6:
    mov eax, dword [esp + 0x88]
    mov edi, dword [esp + 0x18]
    mov ebp, dword [esp + 0x98]
    sub eax, edi
    cmp eax, ebp
    jg short .branch_a4e
    cmp edi, 1
    jg near .branch_a39
    mov eax, dword [esp + 0x88]
    dec eax
    mov dword [esp + 0x78], eax
    jmp near .branch_14ee

.branch_ad8:
    imul eax, edx, 0x2c
    movsx eax, word [eax + engine_2710be]
    imul eax, eax, 0x2c
    mov edx, sprite
    add edx, eax
    mov ax, word [edx + 0xc]
    xor ah, ah
    and al, 0x30
    cwde
    mov dword [esp + 0x7c], edx
    cmp eax, 0x20
    jne near .branch_14ea
    movsx ecx, word [edx + 0xe]
    mov ebx, dword [esp + 0x7c]
    mov edx, dword [ecx*4 + picanm]
    movsx ebx, byte [ebx + 0x16]
    sar edx, 8
    mov eax, dword [ecx*4 + picanm]
    and edx, 0xff
    sar eax, 0x10
    movsx edx, dl
    and eax, 0xff
    add ebx, edx
    movsx edx, al
    mov eax, dword [esp + 0x7c]
    movsx eax, byte [eax + 0x17]
    add edx, eax
    mov eax, dword [esp + 0x7c]
    mov ax, word [eax + 0xc]
    xor ah, ah
    and al, 4
    cwde
    test eax, eax
    jle short .branch_b52
    neg ebx

.branch_b52:
    mov eax, dword [esp + 0x7c]
    mov ax, word [eax + 0xc]
    xor ah, ah
    and al, 8
    cwde
    test eax, eax
    jle short .branch_b65
    neg edx

.branch_b65:
    mov esi, dword [esp + 0x7c]
    movsx esi, word [esi + 0x1c]
    lea eax, [esi + 0x200]
    and eax, 0x7ff
    movsx eax, word [nosplit eax*2 + sintable]
    mov dword [esp + 0xc], eax
    movsx eax, word [nosplit esi*2 + sintable]
    mov dword [esp + 0x38], eax
    mov eax, ecx
    movsx ecx, word [nosplit ecx*2 + tilesizx]
    mov dword [esp + 0x10], ecx
    mov ebp, dword [esp + 0x10]
    mov edi, dword [esp + 0x7c]
    sar ebp, 1
    movzx edi, byte [edi + 0x14]
    add ebp, ebx
    imul ebp, edi
    mov ecx, dword [esp + 0x7c]
    movsx esi, word [nosplit eax*2 + move_tile_heights]
    xor eax, eax
    mov al, byte [ecx + 0x15]
    mov dword [esp + 8], eax
    mov eax, esi
    sar eax, 1
    add eax, edx
    mov edx, dword [esp + 8]
    imul edx, eax
    mov ecx, 0x10
    mov ebx, ebp
    mov eax, dword [esp + 0x38]
    mov dword [esp + 0x94], edx
    imul ebx
    shrd eax, edx, cl
    mov edx, dword [esp + 0x7c]
    mov edx, dword [edx]
    mov ebx, dword [esp + 0x94]
    add edx, eax
    mov eax, dword [esp + 0xc]
    mov dword [esp + 0x1c], edx
    imul ebx
    shrd eax, edx, cl
    mov edx, dword [esp + 0x1c]
    add edx, eax
    mov eax, dword [esp + 0x38]
    mov dword [esp + 0x14], edx
    imul ebx
    shrd eax, edx, cl
    mov edx, dword [esp + 0x7c]
    mov edx, dword [edx + 4]
    mov ebx, ebp
    add edx, eax
    mov eax, dword [esp + 0xc]
    mov dword [esp + 0x1c], edx
    imul ebx
    shrd eax, edx, cl
    mov ecx, dword [esp + 0x10]
    mov ebx, edi
    imul ebx, ecx
    mov edi, dword [esp + 8]
    imul edi, esi
    mov edx, dword [esp + 0x1c]
    sub edx, eax
    mov eax, dword [esp + 0x38]
    mov ecx, 0x10
    mov dword [esp + 0x40], edx
    imul ebx
    shrd eax, edx, cl
    mov edx, dword [esp + 0x14]
    sub edx, eax
    mov eax, dword [esp + 0xc]
    mov dword [esp + 0x30], edx
    imul ebx
    shrd eax, edx, cl
    mov edx, dword [esp + 0x40]
    mov ebx, edi
    add edx, eax
    mov eax, dword [esp + 0xc]
    mov dword [esp + 0x34], edx
    imul ebx
    shrd eax, edx, cl
    mov esi, eax
    neg esi
    mov eax, dword [esp + 0x30]
    add eax, esi
    mov dword [esp + 0x2c], eax
    mov eax, dword [esp + 0x14]
    add eax, esi
    mov edi, 2
    mov dword [esp + 0x20], eax
    mov eax, dword [esp + 0x38]
    mov ebp, 3
    imul ebx
    shrd eax, edx, cl
    mov edx, 4
    mov ecx, dword [esp + 4]
    mov ebx, dword [esp + 0x58]
    mov esi, eax
    mov eax, dword [esp + 0x34]
    neg esi
    mov dword [engine_1c5164], edi
    add eax, esi
    mov dword [engine_1c5168], ebp
    mov dword [esp + 0x28], eax
    mov eax, dword [esp + 0x40]
    mov ebp, dword [esp + 0x14]
    add eax, esi
    mov esi, 1
    mov dword [esp + 0x24], eax
    mov dword [engine_1c5160], esi
    xor eax, eax
    mov esi, dword [esp]
    mov dword [engine_1c516c], eax
    mov dword [esp + 0x98], eax
    mov eax, dword [esp + 0x40]
    mov edi, dword [esp + 0x54]
    sub eax, esi
    sub ebp, ecx
    mov esi, eax
    mov dword [esp + 0x94], eax
    neg esi
    mov eax, ebp
    mov dword [esp + 0x84], edx
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0xc
    mov edx, dword [presentation_width]
    mov edi, dword [esp + 0x60]
    shl edx, 0xf
    mov ebx, dword [esp + 0x5c]
    add eax, edx
    mov esi, ebp
    mov dword [esp + 0x90], eax
    mov eax, dword [esp + 0x94]
    mov ebp, dword [esp + 0x90]
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0xc
    mov edx, dword [esp + 0x64]
    mov esi, dword [presentation_height]
    mov edi, dword [esp + 0x6c]
    shl esi, 0xf
    mov ebx, dword [esp + 0x70]
    add esi, eax
    sub ebx, ebp
    mov ecx, esi
    mov eax, ebp
    sub ecx, edi
    mov edi, dword [esp + 0x68]
    sub edx, esi
    sub eax, edi
    sar eax, 0x1f
    add ebx, ebx
    adc eax, eax
    add ecx, ecx
    adc eax, eax
    add edx, edx
    adc eax, eax
    mov ebx, eax
    shl ebx, 4
    or al, 0xf0
    xor eax, ebx
    mov edx, dword [esp]
    mov dword [esp + 0x98], eax
    mov dword [rx1], ebp
    mov ebp, dword [esp + 0x30]
    mov eax, dword [esp + 4]
    mov edi, dword [esp + 0x54]
    sub ebp, eax
    mov eax, dword [esp + 0x34]
    mov ebx, dword [esp + 0x58]
    sub eax, edx
    mov dword [ry1], esi
    mov esi, eax
    mov dword [esp + 0x94], eax
    neg esi
    mov eax, ebp
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0xc
    mov edx, dword [presentation_width]
    mov edi, dword [esp + 0x60]
    shl edx, 0xf
    mov ebx, dword [esp + 0x5c]
    add eax, edx
    mov esi, ebp
    mov dword [esp + 0x90], eax
    mov eax, dword [esp + 0x94]
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0xc
    mov esi, dword [presentation_height]
    shl esi, 0xf
    add esi, eax
    mov edx, dword [esp + 0x64]
    mov ebx, dword [esp + 0x6c]
    mov edi, dword [esp + 0x90]
    mov ebp, dword [esp + 0x68]
    mov ecx, esi
    mov eax, edi
    sub edx, esi
    sub ecx, ebx
    mov ebx, dword [esp + 0x70]
    sub eax, ebp
    sub ebx, edi
    mov ebp, dword [esp + 0x2c]
    sar eax, 0x1f
    add ebx, ebx
    adc eax, eax
    add ecx, ecx
    adc eax, eax
    add edx, edx
    adc eax, eax
    mov ebx, eax
    shl ebx, 4
    or al, 0xf0
    xor eax, ebx
    mov edx, dword [esp + 0x98]
    mov ebx, dword [esp + 4]
    mov ecx, dword [esp]
    mov dword [engine_1cd164], edi
    mov dword [engine_1d1164], esi
    mov edi, dword [esp + 0x54]
    or edx, eax
    mov eax, dword [esp + 0x28]
    sub ebp, ebx
    sub eax, ecx
    mov ebx, dword [esp + 0x58]
    mov esi, eax
    mov dword [esp + 0x94], eax
    neg esi
    mov eax, ebp
    mov dword [esp + 0x98], edx
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0xc
    mov edx, dword [presentation_width]
    mov edi, dword [esp + 0x60]
    shl edx, 0xf
    mov ebx, dword [esp + 0x5c]
    add eax, edx
    mov esi, ebp
    mov dword [esp + 0x90], eax
    mov eax, dword [esp + 0x94]
    mov ebp, dword [esp + 0x90]
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0xc
    mov edx, dword [esp + 0x64]
    mov esi, dword [presentation_height]
    mov edi, dword [esp + 0x6c]
    shl esi, 0xf
    mov ebx, dword [esp + 0x70]
    add esi, eax
    sub ebx, ebp
    mov ecx, esi
    mov eax, ebp
    sub ecx, edi
    mov edi, dword [esp + 0x68]
    sub edx, esi
    sub eax, edi
    mov ebp, dword [esp + 0x98]
    sar eax, 0x1f
    add ebx, ebx
    adc eax, eax
    add ecx, ecx
    adc eax, eax
    add edx, edx
    adc eax, eax
    mov ebx, eax
    shl ebx, 4
    or al, 0xf0
    xor eax, ebx
    mov edx, dword [esp + 0x90]
    mov ebx, dword [engine_1cd164]
    mov ecx, dword [ry1]
    mov edi, dword [engine_1d1164]
    mov dword [engine_1d1168], esi
    or ebp, eax
    mov eax, dword [esp + 0x90]
    mov dword [esp + 0x98], ebp
    add esi, ecx
    mov ebp, dword [esp + 0x6c]
    mov dword [engine_1cd168], eax
    sub esi, edi
    mov edi, dword [esp + 0x68]
    mov eax, dword [rx1]
    mov ecx, esi
    add eax, edx
    sub ecx, ebp
    mov edx, dword [esp + 0x64]
    sub eax, ebx
    mov ebx, dword [esp + 0x70]
    mov dword [esp + 0x90], eax
    sub edx, esi
    sub ebx, eax
    sub eax, edi
    mov ebp, dword [esp + 0x98]
    sar eax, 0x1f
    add ebx, ebx
    adc eax, eax
    add ecx, ecx
    adc eax, eax
    add edx, edx
    adc eax, eax
    mov ebx, eax
    shl ebx, 4
    or al, 0xf0
    xor eax, ebx
    or ebp, eax
    mov eax, dword [esp + 0x90]
    mov dword [engine_1cd16c], eax
    mov eax, ebp
    mov dword [engine_1d116c], esi
    and eax, 0xf0
    mov dword [esp + 0x98], ebp
    cmp eax, 0xf0
    jne near .branch_14ea
    mov eax, dword [rx1]
    mov dword [esp + 0x44], eax
    mov eax, dword [presentation_height]
    mov edx, dword [ry1]
    shl eax, 0xf
    sub edx, eax
    mov ebx, dword [engine_286bac]
    mov eax, edx
    imul ebx
    shrd eax, edx, 0x10
    mov edx, dword [presentation_height]
    shl edx, 0xf
    add eax, edx
    mov bl, byte [esp + 0x98]
    mov dword [esp + 0x3c], eax
    test bl, 0xf
    je short .branch_1044
    mov eax, 4
    mov edx, ebp
    call clippoly
    mov dword [esp + 0x84], eax
    cmp eax, 3
    jl near .branch_14ea

.branch_1044:
    mov eax, dword [esp + 0x7c]
    mov ax, word [eax + 0xe]
    mov word [globalpicnum], ax
    cwde
    test eax, 0xfffff000
    je short .branch_1063
    xor edi, edi
    mov word [globalpicnum], di

.branch_1063:
    mov ax, word [globalpicnum]
    cwde
    mov ebx, eax
    cmp byte [eax + walock], 0xc8
    jae short .branch_107c
    mov byte [eax + walock], 0xc7

.branch_107c:
    shr eax, 3
    and ebx, 7
    mov dl, byte [eax + engine_1ecda0]
    mov bl, byte [ebx + pow2char]
    or dl, bl
    mov byte [eax + engine_1ecda0], dl
    movsx ebx, word [globalpicnum]
    lea eax, [ebx + ebx]
    cmp word [eax + tilesizx], 0
    jle near .branch_14ea
    cmp word [eax + move_tile_heights], 0
    jle near .branch_14ea
    test byte [ebx*4 + picanm], 0xc0
    je short .branch_10d9
    movsx edx, word [esp + 0x78]
    mov eax, ebx
    call animateoffs
    add word [globalpicnum], ax

.branch_10d9:
    movsx eax, word [globalpicnum]
    cmp dword [eax*4 + waloff], 0
    jne short .branch_10ef
    call loadtile

.branch_10ef:
    movsx eax, word [globalpicnum]
    mov eax, dword [eax*4 + waloff]
    mov edx, dword [esp + 0x7c]
    mov dword [globalbufplc], eax
    movsx edx, word [edx + 0x18]
    mov eax, edx
    shl eax, 2
    add eax, edx
    shl eax, 3
    mov dx, word [eax + engine_27c3ac]
    xor dh, dh
    and dl, 1
    movsx edx, dx
    test edx, edx
    jle short .branch_1130
    movsx eax, byte [eax + engine_27c3b4]
    jmp short .branch_1137

.branch_1130:
    movsx eax, byte [eax + engine_27c3bc]

.branch_1137:
    mov dword [globalshade], eax
    mov eax, dword [esp + 0x7c]
    mov ecx, dword [globalshade]
    movsx eax, byte [eax + 0x10]
    movsx edx, word [numpalookups]
    add eax, ecx
    dec edx
    add eax, 6
    cmp eax, edx
    jl short .branch_115d
    mov eax, edx

.branch_115d:
    test eax, eax
    jle short .branch_1184
    mov eax, dword [esp + 0x7c]
    mov esi, dword [globalshade]
    movsx eax, byte [eax + 0x10]
    movsx edx, word [numpalookups]
    add eax, esi
    dec edx
    add eax, 6
    cmp eax, edx
    jl short .branch_1186
    mov eax, edx
    jmp short .branch_1186

.branch_1184:
    xor eax, eax

.branch_1186:
    mov ebx, dword [esp + 0x7c]
    mov dword [globalshade], eax
    xor edx, edx
    mov dl, byte [ebx + 0x11]
    shl eax, 8
    mov edx, dword [edx*4 + palookup]
    add edx, eax
    mov eax, dword [engine_286a98]
    mov dword [globvis], eax
    mov eax, dword [esp + 0x74]
    mov dword [asm3], edx
    mov ch, byte [eax + 0x20]
    test ch, ch
    je short .branch_11d3
    mov al, ch
    xor ebx, ebx
    add al, 0x10
    mov bl, al
    mov eax, dword [globvis]
    imul ebx
    shrd eax, edx, 4
    mov dword [globvis], eax

.branch_11d3:
    mov eax, dword [esp + 0x7c]
    mov ax, word [eax + 0xc]
    xor ah, ah
    and al, 2
    cwde
    mov ebp, dword [esp + 0x30]
    sar eax, 1
    mov edi, dword [esp + 0x14]
    inc eax
    mov edx, dword [esp + 0x40]
    mov byte [engine_2891d7], al
    mov eax, dword [esp + 0x34]
    sub ebp, edi
    sub eax, edx
    mov edx, ebp
    imul edx, ebp
    mov dword [esp + 0x94], eax
    imul eax, eax
    add edx, eax
    mov dword [esp + 0x98], edx
    je near .branch_14ea
    mov eax, 0x40000000
    mov edx, eax
    mov esi, dword [esp + 0x98]
    sar edx, 0x1f
    idiv esi
    mov edi, dword [esp + 0x48]
    mov ebx, dword [esp + 0x4c]
    mov esi, dword [esp + 0x94]
    mov dword [esp + 0x98], eax
    mov eax, ebp
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0xa
    mov ebx, dword [esp + 0x98]
    mov esi, dword [esp + 0x94]
    mov edi, dword [esp + 0x4c]
    imul ebx
    shrd eax, edx, 0xa
    mov ebx, dword [esp + 0x48]
    mov dword [globalx1], eax
    neg esi
    mov eax, ebp
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0xa
    mov ebx, dword [esp + 0x98]
    mov ebp, dword [esp + 0x40]
    imul ebx
    shrd eax, edx, 0xa
    mov edx, dword [esp + 0x14]
    mov dword [globaly1], eax
    mov eax, dword [esp + 0x20]
    mov edi, dword [esp + 0x24]
    sub eax, edx
    sub ebp, edi
    mov dword [esp + 0x94], eax
    mov eax, ebp
    imul eax, ebp
    mov edx, dword [esp + 0x94]
    imul edx, edx
    add eax, edx
    mov dword [esp + 0x98], eax
    je near .branch_14ea
    mov eax, 0x40000000
    mov edx, eax
    mov esi, dword [esp + 0x98]
    sar edx, 0x1f
    idiv esi
    mov edi, dword [esp + 0x48]
    mov ebx, dword [esp + 0x4c]
    mov esi, dword [esp + 0x94]
    mov dword [esp + 0x98], eax
    mov eax, ebp
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0xa
    mov ebx, dword [esp + 0x98]
    mov esi, dword [esp + 0x94]
    mov edi, dword [esp + 0x4c]
    imul ebx
    shrd eax, edx, 0xa
    mov ebx, dword [esp + 0x48]
    mov dword [globalx2], eax
    neg esi
    mov eax, ebp
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0xa
    mov ebx, dword [esp + 0x98]
    imul ebx
    shrd eax, edx, 0xa
    movsx ebp, word [globalpicnum]
    movzx ebp, byte [ebp + picsiz]
    mov dword [globaly2], eax
    mov eax, ebp
    sar eax, 4
    and ebp, 0xf
    and eax, 0xf
    mov edi, dword [esp + 0x10]
    mov dword [esp + 0x94], eax
    cmp edi, dword [ebp*4 + pow2long]
    je short .branch_13a3
    mov eax, dword [globalx1]
    inc ebp
    mov ebx, edi
    mov ecx, ebp
    imul ebx
    shrd eax, edx, cl
    mov dword [globalx1], eax
    mov eax, dword [globaly1]
    imul ebx
    shrd eax, edx, cl
    mov dword [globaly1], eax

.branch_13a3:
    mov eax, dword [esp + 0x44]
    mov edx, dword [presentation_width]
    sar eax, 8
    shl edx, 7
    sub eax, edx
    mov edx, dword [esp + 0x3c]
    mov dword [esp + 0x44], eax
    mov eax, dword [presentation_height]
    sar edx, 8
    shl eax, 7
    mov edi, dword [globaly1]
    sub edx, eax
    mov ebx, dword [globalx1]
    mov ecx, edx
    mov esi, dword [esp + 0x44]
    neg ecx
    neg esi
    mov eax, ecx
    mov dword [esp + 0x3c], edx
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0x1c
    mov edi, dword [globaly2]
    mov ebx, dword [globalx2]
    mov dword [engine_286ad0], eax
    mov esi, ecx
    mov eax, dword [esp + 0x44]
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0x1c
    mov dword [engine_286ad4], eax
    mov eax, dword [esp + 0x7c]
    mov ax, word [eax + 0xc]
    xor ah, ah
    and al, 2
    cwde
    test eax, eax
    jne short .branch_1441
    mov ebx, dword [esp + 0x94]
    mov eax, ebp
    call msethlineshift
    jmp short .branch_144f

.branch_1441:
    mov ebx, dword [esp + 0x94]
    mov eax, ebp
    call tsethlineshift

.branch_144f:
    mov eax, dword [esp + 0x7c]
    mov ax, word [eax + 0xc]
    xor ah, ah
    and al, 4
    cwde
    test eax, eax
    jle short .branch_1488
    mov ebp, dword [globalx1]
    mov eax, dword [globaly1]
    mov edx, dword [engine_286ad0]
    neg ebp
    neg eax
    neg edx
    mov dword [globalx1], ebp
    mov dword [globaly1], eax
    mov dword [engine_286ad0], edx

.branch_1488:
    mov eax, dword [globaly1]
    mov ebx, dword [globalx1]
    mov ecx, dword [engine_286ad0]
    mov esi, dword [globaly2]
    mov edi, dword [engine_286ad4]
    shl eax, 2
    shl ebx, 2
    shl ecx, 0x16
    shl esi, 2
    shl edi, 0x16
    mov dword [asm1], eax
    mov dword [globalx1], ebx
    mov eax, dword [globalx2]
    mov dword [engine_286ad0], ecx
    shl eax, 2
    mov dword [globaly2], esi
    mov dword [asm2], eax
    mov eax, dword [esp + 0x84]
    mov dword [engine_286ad4], edi
    call fillpolygon

.branch_14ea:
    dec dword [esp + 0x78]

.branch_14ee:
    mov edx, dword [esp + 0x78]
    test edx, edx
    jge near .branch_ad8
    add esp, 0x9c
    pop ebp
    pop edi
    pop esi
    ret

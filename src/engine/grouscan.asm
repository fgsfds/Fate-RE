; Draw a sloped sector plane using the vertical slope rasterizer.
BITS 32
ORG 0x5f1f8

sector equ 0x27c3a0
wall equ 0x2310a0
picanm equ 0x1ed3a0
sqrtable equ 0x1dfa60
picsiz equ 0x1e5fe0
tilesizx equ 0x1f2020
tilesizy equ 0x1f4020
walock equ 0x1f8ca0
waloff equ 0x1ffca0
chainplace equ 0x286b4c
chainstat equ 0x14003
frameplace equ 0x286b74
row_offset equ 0x286bb0
palookup equ 0x203ca0
pow2char equ 0x14029
globalhoriz equ 0x286ae4
globalpal equ 0x286adc
globalpicnum equ 0x289144
globalshade equ 0x286a88
globalzd equ 0x286a8c
globvis equ 0x286ab8
viewoffset equ 0x286ae8
asm1 equ 0x286aa4
asm3 equ 0x286aac
globalorientation equ 0x286a84
globalx1 equ 0x286a80
globalx2 equ 0x286a4c
globaly1 equ 0x286a50
globaly2 equ 0x286a58
reciptable equ 0x1d3160
gotpic equ 0x1ecda0
projection_scale equ 0x286b00
tile_y_shift equ 0x2891d6
globalposy equ 0x286ad4
globalposx equ 0x286ad0
globalposz equ 0x286ad8
engine_2310a4 equ 0x2310a4
engine_286b20 equ 0x286b20
engine_286b23 equ 0x286b23
engine_286b04 equ 0x286b04
engine_286af8 equ 0x286af8
engine_286a78 equ 0x286a78
engine_286ac8 equ 0x286ac8
engine_286a7c equ 0x286a7c
engine_286b08 equ 0x286b08
engine_286b14 equ 0x286b14
engine_286a60 equ 0x286a60
engine_286a70 equ 0x286a70
engine_286a9c equ 0x286a9c
engine_286bb4 equ 0x286bb4
engine_286af4 equ 0x286af4
engine_19e6e0 equ 0x19e6e0
engine_19f360 equ 0x19f360
engine_1e0a60 equ 0x1e0a60
engine_1a3e60 equ 0x1a3e60
engine_1a7ce0 equ 0x1a7ce0
engine_286a48 equ 0x286a48
engine_286a54 equ 0x286a54
getceilzofslope equ 0x5de70
getflorzofslope equ 0x5df75
animateoffs equ 0x50758
loadtile equ 0x4bb0d
setupslopevlin equ 0x74f20
getpalookup equ 0x5fed7
slopevlin equ 0x74f70
faketimerhandler equ 0x31ec4

grouscan_:
    push esi
    push edi
    push ebp
    sub esp, 0x60
    push eax
    push edx
    mov esi, ebx
    mov byte [esp + 0x64], cl
    movsx ecx, bx
    mov eax, ecx
    shl eax, 2
    add eax, ecx
    mov ebp, sector
    shl eax, 3
    add ebp, eax
    cmp byte [esp + 0x64], 0
    jne short .select_floor
    mov ebx, dword [globalposy]
    mov edx, dword [globalposx]
    mov eax, ecx
    call getceilzofslope
    cmp eax, dword [globalposz]
    jge near .restore_stack
    movsx eax, word [ebp + 0xc]
    mov dword [globalorientation], eax
    mov ax, word [ebp + 0x10]
    mov word [globalpicnum], ax
    movsx eax, byte [ebp + 0x14]
    mov dword [globalshade], eax
    xor eax, eax
    mov al, byte [ebp + 0x15]
    mov dword [globalpal], eax
    movsx eax, word [ebp + 0x12]
    mov dword [esp + 0x1c], eax
    mov eax, dword [ebp + 4]
    jmp short .select_tile

.select_floor:
    mov ebx, dword [globalposy]
    mov edx, dword [globalposx]
    mov eax, ecx
    call getflorzofslope
    cmp eax, dword [globalposz]
    jle near .restore_stack
    movsx eax, word [ebp + 0xe]
    mov dword [globalorientation], eax
    mov ax, word [ebp + 0x18]
    mov word [globalpicnum], ax
    movsx eax, byte [ebp + 0x1c]
    mov dword [globalshade], eax
    xor eax, eax
    mov al, byte [ebp + 0x1d]
    mov dword [globalpal], eax
    movsx eax, word [ebp + 0x1a]
    mov dword [esp + 0x1c], eax
    mov eax, dword [ebp + 8]

.select_tile:
    mov dword [esp + 0x28], eax
    movsx eax, word [globalpicnum]
    test byte [eax*4 + picanm], 0xc0
    je short .branch_0ef
    movsx edx, si
    call animateoffs
    add word [globalpicnum], ax

.branch_0ef:
    movsx edx, word [globalpicnum]
    lea eax, [edx + edx]
    cmp word [eax + tilesizx], 0
    jle near .restore_stack
    cmp word [eax + tilesizy], 0
    jle near .restore_stack
    cmp dword [edx*4 + waloff], 0
    jne short .branch_126
    mov eax, edx
    call loadtile

.branch_126:
    mov ax, word [globalpicnum]
    cwde
    mov ebx, eax
    cmp byte [eax + walock], 0xc8
    jae short .branch_13f
    mov byte [eax + walock], 0xc7

.branch_13f:
    shr eax, 3
    and ebx, 7
    mov dl, byte [eax + gotpic]
    mov bl, byte [ebx + pow2char]
    or dl, bl
    mov byte [eax + gotpic], dl
    movsx eax, word [ebp]
    mov edx, wall
    shl eax, 5
    add edx, eax
    movsx eax, word [edx + 8]
    mov dword [esp + 0x30], edx
    shl eax, 5
    mov ebx, dword [esp + 0x30]
    mov edx, dword [eax + wall]
    mov esi, dword [ebx]
    sub edx, esi
    mov dword [esp + 0x2c], edx
    imul edx, edx
    mov edi, dword [ebx + 4]
    mov eax, dword [eax + engine_2310a4]
    sub eax, edi
    mov dword [esp + 0x24], eax
    imul eax, eax
    add eax, edx
    mov dword [engine_286b20], eax
    fild dword [engine_286b20]
    fstp dword [engine_286b20]
    mov bl, byte [engine_286b23]
    sub bl, 0x44
    jge short .branch_1c3
    xor ebx, ebx
    mov bx, word [nosplit eax*2 + sqrtable]
    jmp short .branch_1da

.branch_1c3:
    lea ecx, [nosplit ebx*2]
    shr eax, cl
    mov cl, bl
    xor ebx, ebx
    mov bx, word [nosplit eax*2 + sqrtable]
    shl ebx, cl

.branch_1da:
    shr ebx, 0xa
    mov eax, ebx
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
    mov ecx, eax
    mov ebx, eax
    mov eax, dword [esp + 0x1c]
    imul ebx
    shrd eax, edx, 0x15
    mov edx, dword [esp + 0x2c]
    imul edx, eax
    mov dword [esp + 0x2c], edx
    mov edx, dword [esp + 0x24]
    imul edx, eax
    mov ebx, dword [engine_286b04]
    mov eax, dword [engine_286af8]
    mov dword [esp + 0x24], edx
    imul ebx
    shrd eax, edx, 0x13
    mov ebx, dword [engine_286b04]
    mov esi, eax
    mov dword [engine_286a78], eax
    neg esi
    mov eax, dword [engine_286ac8]
    mov dword [engine_286a78], esi
    imul ebx
    shrd eax, edx, 0x13
    mov dword [engine_286a7c], eax
    mov eax, dword [globalposx]
    shl eax, 8
    mov dword [globalx1], eax
    mov eax, dword [globalposy]
    shl eax, 8
    mov edx, dword [engine_286b08]
    mov dword [globaly1], eax
    mov edi, eax
    mov eax, dword [esp + 4]
    sub eax, edx
    mov edx, dword [engine_286b04]
    imul edx, eax
    mov esi, dword [engine_286ac8]
    neg edi
    shl esi, 4
    mov dword [globaly1], edi
    mov eax, dword [engine_286af8]
    mov ebx, edx
    mov dword [esp + 0x34], edx
    imul ebx
    shrd eax, edx, 0x1b
    sub esi, eax
    mov dword [globalx2], esi
    mov esi, dword [engine_286af8]
    mov eax, dword [engine_286ac8]
    shl esi, 4
    imul ebx
    shrd eax, edx, 0x1b
    add esi, eax
    mov eax, dword [engine_286b14]
    mov dword [globaly2], esi
    shl eax, 9
    mov esi, dword [globalhoriz]
    mov dword [globalzd], eax
    mov ebx, eax
    mov eax, 1
    sub eax, esi
    imul ebx
    shrd eax, edx, 0xa
    mov dword [esp + 0x14], eax
    mov eax, dword [esp + 0x24]
    mov edi, dword [globalx2]
    mov dword [esp + 0x18], eax
    neg eax
    mov ebx, dword [globaly2]
    mov dword [esp + 0x18], eax
    mov esi, eax
    mov eax, dword [esp + 0x2c]
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0x11
    mov edx, dword [esp + 0x14]
    sub edx, eax
    mov dword [engine_286a60], edx
    mov esi, dword [esp + 0x18]
    mov eax, dword [esp + 0x2c]
    mov edi, dword [engine_286a78]
    mov ebx, dword [engine_286a7c]
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0x19
    mov edx, eax
    mov dword [engine_286a70], eax
    neg edx
    mov bh, byte [globalorientation]
    mov dword [engine_286a70], edx
    test bh, 0x40
    je near .branch_557
    mov eax, dword [esp + 0x30]
    movsx eax, word [eax + 8]
    mov edx, dword [esp + 0x30]
    shl eax, 5
    mov ebx, dword [edx]
    mov eax, dword [eax + wall]
    sub eax, ebx
    mov ebx, ecx
    imul ebx
    shrd eax, edx, 0xe
    mov dword [esp + 0xc], eax
    mov eax, dword [esp + 0x30]
    movsx eax, word [eax + 8]
    mov edx, dword [esp + 0x30]
    shl eax, 5
    mov esi, dword [edx + 4]
    mov eax, dword [eax + engine_2310a4]
    sub eax, esi
    imul ebx
    shrd eax, edx, 0xe
    mov dword [esp + 0x20], eax
    mov eax, dword [esp + 0x1c]
    imul eax, eax
    add eax, 0x1000000
    mov edi, dword [esp + 0x20]
    mov dword [engine_286b20], eax
    fild dword [engine_286b20]
    fstp dword [engine_286b20]
    mov bl, byte [engine_286b23]
    sub bl, 0x44
    jge short .branch_40a
    xor ebx, ebx
    mov bx, word [nosplit eax*2 + sqrtable]
    jmp short .branch_421

.branch_40a:
    lea ecx, [nosplit ebx*2]
    shr eax, cl
    mov cl, bl
    xor ebx, ebx
    mov bx, word [nosplit eax*2 + sqrtable]
    shl ebx, cl

.branch_421:
    shr ebx, 0xa
    mov eax, dword [engine_286a78]
    mov ecx, ebx
    mov dword [esp + 0x48], eax
    mov eax, dword [engine_286a7c]
    mov ebx, dword [esp + 0xc]
    mov dword [esp + 8], eax
    mov esi, eax
    mov eax, dword [esp + 0x48]
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0x10
    mov esi, dword [esp + 0x48]
    mov dword [engine_286a78], eax
    mov eax, dword [esp + 8]
    mov ebx, dword [esp + 0xc]
    neg eax
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0x10
    mov ebx, ecx
    imul ebx
    shrd eax, edx, 0xc
    mov dword [engine_286a7c], eax
    mov eax, dword [esp + 0x30]
    mov edx, dword [globalposx]
    mov eax, dword [eax]
    sub eax, edx
    shl eax, 8
    mov dword [esp + 0x48], eax
    mov eax, dword [esp + 0x30]
    mov ebx, dword [globalposy]
    mov eax, dword [eax + 4]
    sub eax, ebx
    shl eax, 8
    mov ebx, dword [esp + 0xc]
    mov dword [esp + 8], eax
    mov dword [esp + 0x14], eax
    mov esi, eax
    mov eax, dword [esp + 0x48]
    neg esi
    neg eax
    mov dword [esp + 0x14], esi
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0x10
    mov esi, dword [esp + 0x48]
    mov ebx, dword [esp + 0xc]
    mov dword [globalx1], eax
    mov eax, dword [esp + 0x14]
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0x10
    mov ebx, ecx
    imul ebx
    shrd eax, edx, 0xc
    mov dword [globaly1], eax
    mov eax, dword [globalx2]
    mov dword [esp + 0x48], eax
    mov eax, dword [globaly2]
    mov ebx, dword [esp + 0xc]
    mov dword [esp + 8], eax
    mov esi, eax
    mov eax, dword [esp + 0x48]
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0x10
    mov esi, dword [esp + 0x48]
    mov dword [globalx2], eax
    mov eax, dword [esp + 8]
    mov ebx, dword [esp + 0xc]
    neg eax
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0x10
    mov ebx, ecx
    imul ebx
    shrd eax, edx, 0xc
    mov dword [globaly2], eax

.branch_557:
    test byte [globalorientation], 4
    je short .branch_5d9
    mov eax, dword [engine_286a78]
    mov dword [esp + 0x34], eax
    mov eax, dword [engine_286a7c]
    mov dword [engine_286a78], eax
    mov edi, eax
    mov eax, dword [esp + 0x34]
    mov dword [engine_286a7c], eax
    neg eax
    mov dword [engine_286a7c], eax
    mov eax, dword [globalx1]
    mov dword [esp + 0x34], eax
    mov eax, dword [globaly1]
    mov dword [globalx1], eax
    mov eax, dword [esp + 0x34]
    mov dword [globaly1], eax
    mov eax, dword [globalx2]
    neg edi
    mov dword [esp + 0x34], eax
    mov eax, dword [globaly2]
    mov dword [engine_286a78], edi
    mov dword [globalx2], eax
    mov edx, eax
    mov eax, dword [esp + 0x34]
    neg edx
    mov ebx, eax
    mov dword [globaly2], eax
    neg ebx
    mov dword [globalx2], edx
    mov dword [globaly2], ebx

.branch_5d9:
    test byte [globalorientation], 0x10
    je short .branch_60c
    mov ecx, dword [globalx1]
    mov esi, dword [globalx2]
    mov edi, dword [engine_286a78]
    neg ecx
    neg esi
    neg edi
    mov dword [globalx1], ecx
    mov dword [globalx2], esi
    mov dword [engine_286a78], edi

.branch_60c:
    test byte [globalorientation], 0x20
    je short .branch_63d
    mov eax, dword [globaly1]
    mov edx, dword [globaly2]
    mov ebx, dword [engine_286a7c]
    neg eax
    neg edx
    neg ebx
    mov dword [globaly1], eax
    mov dword [globaly2], edx
    mov dword [engine_286a7c], ebx

.branch_63d:
    mov eax, dword [esp + 0x28]
    mov edx, dword [esp + 0x30]
    mov ecx, dword [globalposz]
    mov edi, dword [globalposx]
    mov esi, dword [edx]
    sub eax, ecx
    mov ebx, dword [edx + 4]
    mov ecx, eax
    sub edi, esi
    mov eax, dword [globalposy]
    mov esi, dword [esp + 0x24]
    sub eax, ebx
    neg esi
    mov ebx, eax
    mov eax, dword [esp + 0x2c]
    shl ecx, 8
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 9
    add eax, ecx
    mov dword [esp + 0x28], eax
    mov ebx, dword [esp + 0x28]
    mov eax, dword [globalx2]
    imul ebx
    shrd eax, edx, 0x14
    mov dword [globalx2], eax
    mov eax, dword [engine_286a78]
    imul ebx
    shrd eax, edx, 0x1c
    mov dword [engine_286a78], eax
    neg ebx
    mov eax, dword [globaly2]
    imul ebx
    shrd eax, edx, 0x14
    mov dword [globaly2], eax
    mov eax, dword [engine_286a7c]
    imul ebx
    shrd eax, edx, 0x1c
    mov dword [engine_286a7c], eax
    movsx eax, word [globalpicnum]
    mov dl, byte [eax + picsiz]
    and dl, 0xf
    mov ebx, 8
    and edx, 0xff
    sub ebx, edx
    mov al, byte [eax + picsiz]
    mov dword [esp + 0x34], ebx
    and eax, 0xff
    mov edx, 8
    sar eax, 4
    sub edx, eax
    mov ah, byte [globalorientation]
    mov dword [esp + 0x54], edx
    test ah, 8
    je short .branch_720
    lea ecx, [ebx + 1]
    lea esi, [edx + 1]
    mov dword [esp + 0x34], ecx
    mov dword [esp + 0x54], esi

.branch_720:
    mov ecx, dword [esp + 0x34]
    mov edi, dword [globalx1]
    mov eax, dword [globalx2]
    mov edx, dword [engine_286a78]
    mov ebx, dword [globaly1]
    add ecx, 0xc
    mov esi, dword [globaly2]
    shl edi, cl
    mov cl, byte [esp + 0x34]
    mov dword [globalx1], edi
    mov edi, dword [engine_286a7c]
    shl eax, cl
    shl edx, cl
    mov ecx, dword [esp + 0x54]
    mov dword [globalx2], eax
    mov dword [engine_286a78], edx
    add ecx, 0xc
    mov dl, byte [esp + 0x64]
    shl ebx, cl
    mov cl, byte [esp + 0x54]
    mov dword [globaly1], ebx
    shl esi, cl
    shl edi, cl
    mov dword [globaly2], esi
    mov dword [engine_286a7c], edi
    test dl, dl
    jne short .branch_7b9
    xor eax, eax
    mov al, byte [ebp + 0x16]
    mov ecx, dword [globalx1]
    shl eax, 0x18
    add ecx, eax
    mov dword [globalx1], ecx
    xor eax, eax
    mov al, byte [ebp + 0x17]
    shl eax, 0x18
    lea esi, [ebx + eax]
    mov dword [globaly1], esi
    jmp short .branch_7df

.branch_7b9:
    xor eax, eax
    mov al, byte [ebp + 0x1e]
    mov edx, dword [globalx1]
    shl eax, 0x18
    add edx, eax
    mov dword [globalx1], edx
    xor eax, eax
    mov al, byte [ebp + 0x1f]
    shl eax, 0x18
    add ebx, eax
    mov dword [globaly1], ebx

.branch_7df:
    mov eax, dword [globalzd]
    sar eax, 0xd
    mov edi, eax
    mov dword [asm1], eax
    neg edi
    mov eax, dword [engine_286a9c]
    mov dword [asm1], edi
    mov dword [globvis], eax
    mov dh, byte [ebp + 0x20]
    test dh, dh
    je short .branch_81f
    mov al, dh
    xor ebx, ebx
    add al, 0x10
    mov bl, al
    mov eax, dword [globvis]
    imul ebx
    shrd eax, edx, 4
    mov dword [globvis], eax

.branch_81f:
    mov ebx, dword [esp + 0x28]
    mov eax, dword [globvis]
    imul ebx
    shrd eax, edx, 0xd
    mov ebx, dword [engine_286b14]
    mov dword [globvis], eax
    imul ebx
    shrd eax, edx, 0x10
    mov dword [globvis], eax
    mov eax, dword [globalpal]
    mov eax, dword [eax*4 + palookup]
    mov dword [esp + 0x54], eax
    movsx eax, word [globalpicnum]
    mov edx, eax
    mov ecx, dword [engine_286bb4]
    xor edx, eax
    neg ecx
    mov dl, byte [eax + picsiz]
    mov ebx, dword [eax*4 + waloff]
    mov esi, edx
    mov al, dl
    sar esi, 4
    and al, 0xf
    shl esi, 8
    and eax, 0xff
    add eax, esi
    call setupslopevlin
    mov eax, dword [globalzd]
    sar eax, 0x10
    mov ebx, dword [projection_scale]
    mov dword [esp + 0x50], eax
    mov eax, dword [engine_286a70]
    imul ebx
    shrd eax, edx, 0x10
    mov dword [esp + 0x10], eax
    test eax, eax
    jle short .branch_8bb
    mov dword [esp + 0x3c], 0x20000
    jmp short .branch_8cd

.branch_8bb:
    mov eax, 0x7fc
    sub eax, dword [engine_286af4]
    shl eax, 0xf
    mov dword [esp + 0x3c], eax

.branch_8cd:
    mov eax, dword [esp + 4]
    mov bl, byte [esp + 0x64]
    add eax, eax
    test bl, bl
    jne short .branch_8e4
    movsx eax, word [eax + engine_19e6e0]
    jmp short .branch_8fe

.branch_8e4:
    mov dx, word [eax + engine_19e6e0]
    mov si, word [eax + engine_19f360]
    cmp dx, si
    jle short .branch_8fb
    mov eax, edx
    jmp short .branch_8fd

.branch_8fb:
    mov eax, esi

.branch_8fd:
    cwde

.branch_8fe:
    mov dword [esp + 0x40], eax
    mov eax, dword [esp + 0x40]
    mov ebx, dword [globalzd]
    imul ebx
    shrd eax, edx, 0x10
    mov edx, dword [engine_286a60]
    sar edx, 6
    add eax, edx
    mov dword [esp + 0x5c], eax
    mov eax, dword [globalzd]
    mov edx, dword [globalzd]
    sar eax, 0x10
    test edx, edx
    jle short .branch_939
    add dword [esp + 0x5c], eax
    jmp short .branch_93d

.branch_939:
    sub dword [esp + 0x5c], eax

.branch_93d:
    mov eax, dword [esp + 0x5c]
    mov esi, dword [esp + 0x50]
    add eax, esi
    mov dword [esp + 0x58], eax
    mov eax, dword [esp + 0x3c]
    mov edi, dword [esp + 0x40]
    sar eax, 0xf
    add eax, edi
    mov ebp, engine_1e0a60
    shl eax, 2
    add ebp, eax
    lea eax, [ebp + 4]
    mov dword [esp + 0x60], eax
    mov eax, dword [esp + 4]
    jmp near .branch_cc7

.branch_972:
    mov bh, byte [esp + 0x64]
    add eax, eax
    test bh, bh
    jne short .branch_9a3
    movsx edx, word [eax + engine_19e6e0]
    mov bx, word [eax + engine_1a3e60]
    mov dword [esp + 0x40], edx
    mov dx, word [eax + engine_1a7ce0]
    cmp dx, bx
    jge short .branch_99e
    mov eax, edx
    jmp short .branch_9a0

.branch_99e:
    mov eax, ebx

.branch_9a0:
    cwde
    jmp short .branch_9cd

.branch_9a3:
    mov dx, word [eax + engine_19e6e0]
    mov di, word [eax + engine_19f360]
    cmp dx, di
    jle short .branch_9ba
    mov eax, edx
    jmp short .branch_9bc

.branch_9ba:
    mov eax, edi

.branch_9bc:
    cwde
    mov dword [esp + 0x40], eax
    mov eax, dword [esp + 0x48]
    movsx eax, word [nosplit eax*2 + engine_1a7ce0]

.branch_9cd:
    dec eax
    mov dword [esp + 0x44], eax
    mov eax, dword [esp + 0x40]
    mov ebx, dword [esp + 0x44]
    cmp eax, ebx
    jg near .branch_c7b
    mov eax, dword [esp + 0x3c]
    mov edx, dword [esp + 0x40]
    sar eax, 0xf
    mov edi, engine_1e0a60
    add edx, eax
    add eax, ebx
    shl edx, 2
    shl eax, 2
    add edi, edx
    mov edx, engine_1e0a60
    add edx, eax
    mov dword [esp + 0x4c], edx

.branch_a09:
    cmp edi, ebp
    ja short .branch_a80
    mov eax, dword [esp + 0x5c]
    mov esi, dword [globalshade]
    mov edx, dword [globvis]
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
    mov ebx, edx
    imul ebx
    shrd eax, edx, 0x18
    mov edx, esi
    call getpalookup
    mov esi, dword [esp + 0x54]
    shl eax, 8
    add eax, esi
    mov edx, dword [esp + 0x5c]
    mov dword [ebp], eax
    sub edx, dword [esp + 0x50]
    sub ebp, 4
    mov dword [esp + 0x5c], edx
    jmp short .branch_a09

.branch_a80:
    mov eax, dword [esp + 0x4c]
    cmp eax, dword [esp + 0x60]
    jb near .branch_b0d
    mov eax, dword [esp + 0x58]
    mov esi, dword [globalshade]
    mov edx, dword [globvis]
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
    mov ebx, edx
    imul ebx
    shrd eax, edx, 0x18
    mov edx, esi
    call getpalookup
    mov esi, dword [esp + 0x54]
    shl eax, 8
    mov edx, dword [esp + 0x60]
    add eax, esi
    lea edi, [edx + 4]
    mov dword [edx], eax
    mov eax, dword [esp + 0x50]
    mov edx, dword [esp + 0x58]
    add edx, eax
    mov dword [esp + 0x60], edi
    mov dword [esp + 0x58], edx
    jmp near .branch_a80

.branch_b0d:
    mov eax, dword [globalx2]
    sar eax, 0xa
    mov dword [engine_286a48], eax
    mov eax, dword [globaly2]
    sar eax, 0xa
    mov ebx, dword [globalzd]
    mov dword [engine_286a54], eax
    mov eax, dword [esp + 0x44]
    imul ebx
    shrd eax, edx, 0x10
    mov edx, dword [engine_286a60]
    sar edx, 6
    add eax, edx
    mov ecx, dword [esp + 0x40]
    mov dword [asm3], eax
    mov eax, dword [esp + 0x44]
    mov esi, dword [esp + 0x44]
    sub eax, ecx
    shl esi, 2
    inc eax
    mov cl, byte [chainstat]
    mov dword [esp + 0x38], eax
    test cl, cl
    je near .branch_bef
    mov eax, dword [esp + 0x48]
    add eax, dword [viewoffset]
    and eax, 3
    mov al, byte [eax + pow2char]
    mov edx, 0x3c5
    and eax, 0xff
    out dx, al
    mov eax, dword [asm3]
    mov edi, dword [globaly1]
    sar eax, 3
    mov edx, dword [globalx1]
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
    mov ebx, dword [esp + 0x48]
    add ebx, dword [viewoffset]
    sar ebx, 2
    add ebx, dword [esi + row_offset]
    mov ecx, dword [chainplace]
    jmp short .branch_c54

.branch_bef:
    mov eax, dword [asm3]
    mov edi, dword [globaly1]
    sar eax, 3
    mov edx, dword [globalx1]
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
    mov ebx, dword [esi + row_offset]
    mov esi, dword [esp + 0x48]
    mov ecx, dword [frameplace]
    add ebx, esi
    add ebx, ecx
    mov ecx, dword [viewoffset]

.branch_c54:
    mov esi, edx
    add ecx, ebx
    mov edx, dword [esp + 0x38]
    mov dword [esp + 0x14], ecx
    mov ebx, eax
    mov ecx, dword [esp + 0x4c]
    mov eax, dword [esp + 0x14]
    call slopevlin
    test byte [esp + 0x48], 0xf
    jne short .branch_c7b
    call faketimerhandler

.branch_c7b:
    mov edi, dword [esp + 0x3c]
    mov eax, dword [engine_286a78]
    mov ebx, dword [globalx2]
    mov ecx, dword [globaly2]
    add ebx, eax
    mov eax, dword [engine_286a7c]
    mov esi, dword [engine_286a60]
    add ecx, eax
    mov eax, dword [engine_286a70]
    mov dword [globalx2], ebx
    add esi, eax
    mov eax, dword [esp + 0x10]
    mov dword [globaly2], ecx
    add edi, eax
    mov eax, dword [esp + 0x48]
    mov dword [engine_286a60], esi
    inc eax
    mov dword [esp + 0x3c], edi

.branch_cc7:
    mov dword [esp + 0x48], eax
    mov eax, dword [esp + 0x48]
    cmp eax, dword [esp]
    jle near .branch_972

.restore_stack:
    add esp, 0x68
    pop ebp
    pop edi
    pop esi
    ret

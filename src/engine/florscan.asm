; Scan a flat floor into horizontal rendering spans.
BITS 32
ORG 0x47f0c

sector equ 0x27c3a0
wall equ 0x2310a0
picanm equ 0x1ed3a0
sqrtable equ 0x1dfa60
picsiz equ 0x1e5fe0
tilesizx equ 0x1f2020
tilesizy equ 0x1f4020
walock equ 0x1f8ca0
waloff equ 0x1ffca0
palookup equ 0x203ca0
pow2char equ 0x14029
globalpicnum equ 0x289144
globalshade equ 0x286a88
globalxpanning equ 0x286abc
globalzd equ 0x286a8c
globvis equ 0x286ab8
globalbufplc equ 0x286a90
globalorientation equ 0x286a84
globalx1 equ 0x286a80
globalx2 equ 0x286a4c
globaly1 equ 0x286a50
globaly2 equ 0x286a58
globalypanning equ 0x286ac0
globalposz equ 0x286ad8
current_palookup equ 0x286af0
lower_plane_edge equ 0x19f360
lower_plane_edge_next equ 0x19f362
upper_plane_edge equ 0x19e6e0
upper_plane_edge_next equ 0x19e6e2
upper_clip_edge equ 0x1a3e60
lower_clip_edge equ 0x1a7ce0
lastx_next equ 0x197d54
lastx_previous equ 0x197d4c
tile_x_shift equ 0x2891d5
tile_y_shift equ 0x2891d6
engine_1ecda0 equ 0x1ecda0
engine_286a94 equ 0x286a94
engine_286af8 equ 0x286af8
engine_286ac8 equ 0x286ac8
engine_286ad0 equ 0x286ad0
engine_286ad4 equ 0x286ad4
engine_2310a8 equ 0x2310a8
engine_2310a4 equ 0x2310a4
engine_286b20 equ 0x286b20
engine_286b23 equ 0x286b23
engine_286b08 equ 0x286b08
setpalookupaddress equ 0x740e0
animateoffs equ 0x50758
loadtile equ 0x4bb0d
sethlinesizes equ 0x73ff0
hline equ 0x4a7f3
faketimerhandler equ 0x31ec4
ceiling_timer_tail equ 0x47eff
ceiling_return equ 0x47f04

florscan_:
    push ecx
    push esi
    push edi
    push ebp
    sub esp, 0xc
    push eax
    push edx
    mov esi, ebx
    movsx ebx, bx
    mov eax, ebx
    shl eax, 2
    add eax, ebx
    mov ebp, sector
    shl eax, 3
    add ebp, eax
    xor eax, eax
    mov al, byte [ebp + 0x1d]
    shl eax, 2
    mov ebx, dword [current_palookup]
    mov edx, dword [eax + palookup]
    cmp edx, ebx
    je short .branch_044
    mov eax, edx
    mov dword [current_palookup], edx
    call setpalookupaddress

.branch_044:
    mov eax, dword [globalposz]
    mov ecx, dword [ebp + 8]
    sub eax, ecx
    mov dword [globalzd], eax
    test eax, eax
    jg short ceiling_return
    mov ax, word [ebp + 0x18]
    mov word [globalpicnum], ax
    cwde
    test eax, 0xfffff000
    je short .branch_072
    xor edx, edx
    mov word [globalpicnum], dx

.branch_072:
    mov ax, word [globalpicnum]
    cwde
    mov ebx, eax
    cmp byte [eax + walock], 0xc8
    jae short .branch_08b
    mov byte [eax + walock], 0xc7

.branch_08b:
    shr eax, 3
    and ebx, 7
    mov dl, byte [eax + engine_1ecda0]
    mov bl, byte [ebx + pow2char]
    or dl, bl
    mov byte [eax + engine_1ecda0], dl
    movsx ebx, word [globalpicnum]
    lea eax, [ebx + ebx]
    cmp word [eax + tilesizx], 0
    jle near ceiling_return
    cmp word [eax + tilesizy], 0
    jle near ceiling_return
    test byte [ebx*4 + picanm], 0xc0
    je short .branch_0e6
    movsx edx, si
    mov eax, ebx
    call animateoffs
    add word [globalpicnum], ax

.branch_0e6:
    movsx eax, word [globalpicnum]
    cmp dword [eax*4 + waloff], 0
    jne short .branch_0fc
    call loadtile

.branch_0fc:
    movsx eax, word [globalpicnum]
    mov eax, dword [eax*4 + waloff]
    mov dword [globalbufplc], eax
    movsx eax, byte [ebp + 0x1c]
    mov dword [globalshade], eax
    mov eax, dword [engine_286a94]
    mov dword [globvis], eax
    mov dh, byte [ebp + 0x20]
    test dh, dh
    je short .branch_141
    mov al, dh
    xor ebx, ebx
    add al, 0x10
    mov bl, al
    mov eax, dword [globvis]
    imul ebx
    shrd eax, edx, 4
    mov dword [globvis], eax

.branch_141:
    movsx eax, word [ebp + 0xe]
    mov dword [globalorientation], eax
    test byte [globalorientation], 0x40
    jne short .branch_19a
    mov eax, dword [engine_286af8]
    mov dword [globalx1], eax
    mov dword [globalx2], eax
    mov eax, dword [engine_286ac8]
    mov dword [globaly1], eax
    mov dword [globaly2], eax
    mov eax, dword [engine_286ad0]
    shl eax, 0x14
    mov dword [globalxpanning], eax
    mov eax, dword [engine_286ad4]
    shl eax, 0x14
    mov edi, eax
    mov dword [globalypanning], eax
    neg edi
    mov dword [globalypanning], edi
    jmp near .branch_366

.branch_19a:
    movsx eax, word [ebp]
    mov dword [esp + 8], eax
    shl eax, 5
    movsx ebx, word [eax + engine_2310a8]
    shl ebx, 5
    mov esi, dword [eax + wall]
    mov ecx, dword [ebx + wall]
    sub ecx, esi
    mov edi, dword [eax + engine_2310a4]
    mov eax, ecx
    imul eax, ecx
    mov ebx, dword [ebx + engine_2310a4]
    sub ebx, edi
    mov edx, ebx
    imul edx, ebx
    mov dword [esp + 0x10], ecx
    add eax, edx
    mov dword [esp + 0xc], ebx
    mov dword [engine_286b20], eax
    fild dword [engine_286b20]
    fstp dword [engine_286b20]
    mov bl, byte [engine_286b23]
    sub bl, 0x44
    jge short .branch_207
    xor ebx, ebx
    mov bx, word [nosplit eax*2 + sqrtable]
    jmp short .branch_21e

.branch_207:
    lea ecx, [nosplit ebx*2]
    shr eax, cl
    mov cl, bl
    xor ebx, ebx
    mov bx, word [nosplit eax*2 + sqrtable]
    shl ebx, cl

.branch_21e:
    shr ebx, 0xa
    test ebx, ebx
    jne short .branch_22c
    mov ecx, 0x400
    jmp short .branch_23a

.branch_22c:
    mov eax, 0x100000
    mov edx, eax
    sar edx, 0x1f
    idiv ebx
    mov ecx, eax

.branch_23a:
    mov esi, dword [esp + 0xc]
    mov eax, dword [esp + 0x10]
    mov edi, dword [engine_286ac8]
    mov ebx, dword [engine_286af8]
    neg esi
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0xa
    mov ebx, ecx
    mov esi, dword [esp + 0xc]
    imul ebx
    shrd eax, edx, 0xa
    mov edi, dword [engine_286af8]
    mov ebx, dword [engine_286ac8]
    mov dword [globalx1], eax
    mov eax, dword [esp + 0x10]
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0xa
    mov ebx, ecx
    imul ebx
    shrd eax, edx, 0xa
    mov edx, dword [globalx1]
    mov edi, dword [engine_286ad0]
    mov dword [globaly1], eax
    mov dword [globaly2], eax
    mov esi, eax
    mov eax, dword [esp + 8]
    mov dword [globalx2], edx
    mov ecx, edx
    neg esi
    mov edx, dword [engine_286ad4]
    neg ecx
    mov dword [globaly2], esi
    shl eax, 5
    mov dword [globalx2], ecx
    mov ebx, dword [eax + wall]
    mov eax, dword [eax + engine_2310a4]
    sub ebx, edi
    mov edi, dword [engine_286af8]
    shl ebx, 6
    sub eax, edx
    mov dword [esp + 0x10], ebx
    shl eax, 6
    mov esi, ebx
    mov ebx, dword [engine_286ac8]
    neg esi
    mov dword [esp + 0xc], eax
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0xe
    mov esi, dword [esp + 0xc]
    mov edi, dword [engine_286af8]
    mov ebx, dword [engine_286ac8]
    mov ecx, eax
    mov eax, dword [esp + 0x10]
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0xe
    mov ebx, dword [globalx1]
    imul ebx, ecx
    mov edx, dword [globaly1]
    imul edx, eax
    imul eax, dword [globalx2]
    sub ebx, edx
    mov dword [globalxpanning], ebx
    imul ecx, dword [globaly2]
    add ecx, eax
    mov dword [globalypanning], ecx

.branch_366:
    movsx eax, word [globalpicnum]
    mov dl, byte [eax + picsiz]
    and dl, 0xf
    mov dh, 8
    sub dh, dl
    mov al, byte [eax + picsiz]
    mov byte [tile_x_shift], dh
    and eax, 0xff
    mov edx, 8
    sar eax, 4
    sub edx, eax
    mov bh, byte [globalorientation]
    mov byte [tile_y_shift], dl
    test bh, 8
    je short .branch_3b6
    inc byte [tile_x_shift]
    mov ch, dl
    inc ch
    mov byte [tile_y_shift], ch

.branch_3b6:
    mov eax, dword [globalorientation]
    and eax, 4
    test eax, eax
    jle short .branch_415
    mov eax, dword [globalypanning]
    mov ecx, dword [globalxpanning]
    mov dword [globalxpanning], eax
    mov dword [globalypanning], ecx
    mov eax, dword [globaly1]
    mov ecx, dword [globalx2]
    mov dword [globalx2], eax
    mov dword [globaly1], ecx
    mov edx, ecx
    mov ecx, dword [globalx1]
    neg eax
    neg edx
    mov dword [globalx2], eax
    mov eax, dword [globaly2]
    mov dword [globaly1], edx
    mov dword [globalx1], eax
    mov dword [globaly2], ecx

.branch_415:
    mov eax, dword [globalorientation]
    and eax, 0x10
    test eax, eax
    jle short .branch_44b
    mov ebx, dword [globalx1]
    mov ecx, dword [globaly1]
    mov esi, dword [globalxpanning]
    neg ebx
    neg ecx
    neg esi
    mov dword [globalx1], ebx
    mov dword [globaly1], ecx
    mov dword [globalxpanning], esi

.branch_44b:
    mov eax, dword [globalorientation]
    and eax, 0x20
    test eax, eax
    jle short .branch_47f
    mov edi, dword [globalx2]
    mov eax, dword [globaly2]
    mov edx, dword [globalypanning]
    neg edi
    neg eax
    neg edx
    mov dword [globalx2], edi
    mov dword [globaly2], eax
    mov dword [globalypanning], edx

.branch_47f:
    mov bl, byte [tile_x_shift]
    mov esi, dword [globalx1]
    mov edi, dword [globaly1]
    mov al, byte [tile_y_shift]
    mov cl, bl
    mov edx, dword [globalx2]
    shl esi, cl
    shl edi, cl
    mov dword [globalx1], esi
    mov dword [globaly1], edi
    mov cl, al
    mov esi, dword [globaly2]
    mov edi, dword [globalxpanning]
    shl edx, cl
    shl esi, cl
    mov cl, bl
    mov dword [globalx2], edx
    shl edi, cl
    mov cl, al
    mov eax, dword [globalypanning]
    mov dword [globaly2], esi
    shl eax, cl
    mov dword [globalxpanning], edi
    mov dword [globalypanning], eax
    xor eax, eax
    mov al, byte [ebp + 0x1e]
    shl eax, 0x18
    lea edx, [edi + eax]
    mov ecx, dword [globaly1]
    mov dword [globalxpanning], edx
    xor eax, eax
    mov ebx, dword [globalypanning]
    mov al, byte [ebp + 0x1f]
    mov edx, dword [globalx1]
    shl eax, 0x18
    neg edx
    add ebx, eax
    sub edx, ecx
    mov eax, dword [engine_286b08]
    imul edx, eax
    mov dword [globaly1], edx
    mov edx, dword [globalx2]
    sub edx, esi
    imul edx, eax
    mov ecx, dword [globalbufplc]
    mov dword [globalypanning], ebx
    xor ebx, ebx
    movsx eax, word [globalpicnum]
    mov dword [globalx2], edx
    mov bl, byte [eax + picsiz]
    mov al, byte [eax + picsiz]
    sar ebx, 4
    and al, 0xf
    and eax, 0xff
    call sethlinesizes
    mov eax, dword [esp + 4]
    add eax, eax
    mov dx, word [eax + lower_plane_edge]
    mov bx, word [eax + upper_plane_edge]
    cmp dx, bx
    jle short .branch_581
    mov eax, edx
    jmp short .branch_583

.branch_581:
    mov eax, ebx

.branch_583:
    movsx ebx, ax
    mov esi, dword [esp + 4]
    mov ecx, ebx
    jmp near .test_column

.scan_column:
    lea eax, [esi + esi]
    mov di, word [eax + lower_plane_edge]
    mov dx, word [eax + upper_plane_edge]
    cmp di, dx
    jle short .branch_5ab
    mov eax, edi
    jmp short .branch_5ad

.branch_5ab:
    mov eax, edx

.branch_5ad:
    movsx edi, ax
    movsx ebp, word [nosplit esi*2 + lower_clip_edge]
    dec edi
    lea eax, [ebp - 1]
    cmp edi, eax
    jge near .branch_61e
    cmp edi, ecx
    jl short .branch_5e0

.branch_5c8:
    lea eax, [ecx - 1]
    cmp ebx, eax
    jge short .branch_5dc
    inc ebx
    lea eax, [esi - 1]
    mov edx, ebx
    call hline
    jmp short .branch_5c8

.branch_5dc:
    mov ebx, edi
    jmp short .branch_5ff

.branch_5e0:
    cmp ebx, edi
    jge short .branch_5f1
    inc ebx
    lea eax, [esi - 1]
    mov edx, ebx
    call hline
    jmp short .branch_5e0

.branch_5f1:
    cmp ebx, edi
    jle short .branch_5ff
    dec ebx
    mov dword [ebx*4 + lastx_next], esi
    jmp short .branch_5f1

.branch_5ff:
    cmp ecx, ebp
    jle short .branch_610
    dec ecx
    lea eax, [esi - 1]
    mov edx, ecx
    call hline
    jmp short .branch_5ff

.branch_610:
    cmp ecx, ebp
    jge short .branch_658
    inc ecx
    mov dword [ecx*4 + lastx_previous], esi
    jmp short .branch_610

.branch_61e:
    lea eax, [ecx - 1]
    cmp ebx, eax
    jge short .branch_632
    inc ebx
    lea eax, [esi - 1]
    mov edx, ebx
    call hline
    jmp short .branch_61e

.branch_632:
    cmp esi, dword [esp]
    je short .flush_last_column
    lea eax, [esi + esi]
    mov bx, word [eax + lower_plane_edge_next]
    mov cx, word [eax + upper_plane_edge_next]
    cmp bx, cx
    jle short .branch_651
    mov eax, ebx
    jmp short .branch_653

.branch_651:
    mov eax, ecx

.branch_653:
    movsx ebx, ax
    mov ecx, ebx

.branch_658:
    inc esi

.test_column:
    cmp esi, dword [esp]
    jle near .scan_column

.flush_last_column:
    lea eax, [ecx - 1]
    cmp ebx, eax
    jge near ceiling_timer_tail
    inc ebx
    mov eax, dword [esp]
    mov edx, ebx
    call hline
    jmp short .flush_last_column

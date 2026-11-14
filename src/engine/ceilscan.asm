; Scan a flat ceiling into horizontal rendering spans.
BITS 32
ORG 0x478b5

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

ceilscan_:
    push ecx
    push esi
    push edi
    push ebp
    sub esp, 0xc
    push eax
    push edx
    movsx ecx, bx
    mov eax, ecx
    shl eax, 2
    add eax, ecx
    mov ebp, sector
    shl eax, 3
    add ebp, eax
    xor eax, eax
    mov al, byte [ebp + 0x15]
    shl eax, 2
    mov ecx, dword [current_palookup]
    mov edx, dword [eax + palookup]
    cmp edx, ecx
    je short .branch_042
    mov eax, edx
    mov dword [current_palookup], edx
    call setpalookupaddress

.branch_042:
    mov esi, dword [globalposz]
    mov eax, dword [ebp + 4]
    sub eax, esi
    mov dword [globalzd], eax
    test eax, eax
    jg near .restore_stack
    mov ax, word [ebp + 0x10]
    mov word [globalpicnum], ax
    cwde
    test eax, 0xfffff000
    je short .branch_075
    xor edx, edx
    mov word [globalpicnum], dx

.branch_075:
    movsx eax, word [globalpicnum]
    test byte [eax*4 + picanm], 0xc0
    je short .branch_095
    movsx edx, bx
    call animateoffs
    add word [globalpicnum], ax

.branch_095:
    movsx eax, word [globalpicnum]
    lea ebx, [eax + eax]
    cmp word [ebx + tilesizx], 0
    jle near .restore_stack
    cmp word [ebx + tilesizy], 0
    jle near .restore_stack
    cmp dword [eax*4 + waloff], 0
    jne short .branch_0ca
    call loadtile

.branch_0ca:
    movsx eax, word [globalpicnum]
    mov eax, dword [eax*4 + waloff]
    mov dword [globalbufplc], eax
    mov ax, word [globalpicnum]
    cwde
    mov ebx, eax
    cmp byte [eax + walock], 0xc8
    jae short .branch_0f6
    mov byte [eax + walock], 0xc7

.branch_0f6:
    shr eax, 3
    and ebx, 7
    mov dl, byte [eax + engine_1ecda0]
    mov bl, byte [ebx + pow2char]
    or dl, bl
    mov byte [eax + engine_1ecda0], dl
    movsx eax, byte [ebp + 0x14]
    mov dword [globalshade], eax
    mov eax, dword [engine_286a94]
    mov dword [globvis], eax
    mov ch, byte [ebp + 0x20]
    test ch, ch
    je short .branch_142
    mov al, ch
    xor ebx, ebx
    add al, 0x10
    mov bl, al
    mov eax, dword [globvis]
    imul ebx
    shrd eax, edx, 4
    mov dword [globvis], eax

.branch_142:
    movsx eax, word [ebp + 0xc]
    mov dword [globalorientation], eax
    test byte [globalorientation], 0x40
    jne short .branch_19b
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
    jmp near .branch_367

.branch_19b:
    movsx eax, word [ebp]
    mov dword [esp + 0xc], eax
    shl eax, 5
    movsx ebx, word [eax + engine_2310a8]
    shl ebx, 5
    mov esi, dword [eax + wall]
    mov ecx, dword [ebx + wall]
    sub ecx, esi
    mov edx, ecx
    imul edx, ecx
    mov edi, dword [eax + engine_2310a4]
    mov ebx, dword [ebx + engine_2310a4]
    sub ebx, edi
    mov eax, ebx
    imul eax, ebx
    mov dword [esp + 8], ecx
    add eax, edx
    mov dword [esp + 0x10], ebx
    mov dword [engine_286b20], eax
    fild dword [engine_286b20]
    fstp dword [engine_286b20]
    mov bl, byte [engine_286b23]
    sub bl, 0x44
    jge short .branch_208
    xor ebx, ebx
    mov bx, word [nosplit eax*2 + sqrtable]
    jmp short .branch_21f

.branch_208:
    lea ecx, [nosplit ebx*2]
    shr eax, cl
    mov cl, bl
    xor ebx, ebx
    mov bx, word [nosplit eax*2 + sqrtable]
    shl ebx, cl

.branch_21f:
    shr ebx, 0xa
    test ebx, ebx
    jne short .branch_22d
    mov ecx, 0x400
    jmp short .branch_23b

.branch_22d:
    mov eax, 0x100000
    mov edx, eax
    sar edx, 0x1f
    idiv ebx
    mov ecx, eax

.branch_23b:
    mov esi, dword [esp + 0x10]
    mov eax, dword [esp + 8]
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
    mov esi, dword [esp + 0x10]
    imul ebx
    shrd eax, edx, 0xa
    mov edi, dword [engine_286af8]
    mov ebx, dword [engine_286ac8]
    mov dword [globalx1], eax
    mov eax, dword [esp + 8]
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
    mov eax, dword [esp + 0xc]
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
    mov dword [esp + 8], ebx
    shl eax, 6
    mov esi, ebx
    mov ebx, dword [engine_286ac8]
    neg esi
    mov dword [esp + 0x10], eax
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0xe
    mov esi, dword [esp + 0x10]
    mov edi, dword [engine_286af8]
    mov ebx, dword [engine_286ac8]
    mov ecx, eax
    mov eax, dword [esp + 8]
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0xe
    mov edx, dword [globalx1]
    imul edx, ecx
    mov ebx, dword [globaly1]
    imul ebx, eax
    imul eax, dword [globalx2]
    sub edx, ebx
    imul ecx, dword [globaly2]
    add ecx, eax
    mov dword [globalxpanning], edx
    mov dword [globalypanning], ecx

.branch_367:
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
    mov ah, byte [globalorientation]
    mov byte [tile_y_shift], dl
    test ah, 8
    je short .branch_3b3
    inc byte [tile_x_shift]
    inc byte [tile_y_shift]

.branch_3b3:
    mov eax, dword [globalorientation]
    and eax, 4
    test eax, eax
    jle short .branch_412
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

.branch_412:
    mov eax, dword [globalorientation]
    and eax, 0x10
    test eax, eax
    jle short .branch_448
    mov ebx, dword [globalx1]
    mov ecx, dword [globaly1]
    mov esi, dword [globalxpanning]
    neg ebx
    neg ecx
    neg esi
    mov dword [globalx1], ebx
    mov dword [globaly1], ecx
    mov dword [globalxpanning], esi

.branch_448:
    mov eax, dword [globalorientation]
    and eax, 0x20
    test eax, eax
    jle short .branch_47c
    mov edi, dword [globalx2]
    mov eax, dword [globaly2]
    mov edx, dword [globalypanning]
    neg edi
    neg eax
    neg edx
    mov dword [globalx2], edi
    mov dword [globaly2], eax
    mov dword [globalypanning], edx

.branch_47c:
    mov al, byte [tile_x_shift]
    mov ebx, dword [globalx1]
    mov esi, dword [globaly1]
    mov edi, dword [globalx2]
    mov cl, al
    mov edx, dword [globaly2]
    shl ebx, cl
    shl esi, cl
    mov dword [globalx1], ebx
    mov bl, byte [tile_y_shift]
    mov dword [globaly1], esi
    mov cl, bl
    mov esi, dword [globalxpanning]
    shl edi, cl
    shl edx, cl
    mov dword [globalx2], edi
    mov dword [globaly2], edx
    mov cl, al
    mov edi, dword [globalypanning]
    shl esi, cl
    mov cl, bl
    xor eax, eax
    shl edi, cl
    mov dword [globalxpanning], esi
    mov dword [globalypanning], edi
    mov al, byte [ebp + 0x16]
    shl eax, 0x18
    lea edx, [esi + eax]
    mov dword [globalxpanning], edx
    xor eax, eax
    mov ecx, dword [globaly1]
    mov al, byte [ebp + 0x17]
    mov edx, dword [globalx1]
    shl eax, 0x18
    neg edx
    lea ebx, [edi + eax]
    sub edx, ecx
    mov eax, dword [engine_286b08]
    imul edx, eax
    mov esi, dword [globaly2]
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
    mov ebx, dword [esp + 4]
    movsx ebx, word [nosplit ebx*2 + upper_plane_edge]
    mov esi, dword [esp + 4]
    mov ecx, ebx
    jmp near .test_column

.scan_column:
    lea eax, [esi + esi]
    movsx edi, word [eax + upper_plane_edge]
    mov dx, word [eax + upper_clip_edge]
    dec edi
    cmp dx, word [eax + lower_clip_edge]
    jge short .branch_59a
    mov eax, edx
    jmp short .branch_5a1

.branch_59a:
    mov ax, word [eax + lower_clip_edge]

.branch_5a1:
    movsx ebp, ax
    lea eax, [ebp - 1]
    cmp edi, eax
    jge near .branch_609
    cmp edi, ecx
    jl short .branch_5cb

.branch_5b3:
    lea eax, [ecx - 1]
    cmp ebx, eax
    jge short .branch_5c7
    inc ebx
    lea eax, [esi - 1]
    mov edx, ebx
    call hline
    jmp short .branch_5b3

.branch_5c7:
    mov ebx, edi
    jmp short .branch_5ea

.branch_5cb:
    cmp ebx, edi
    jge short .branch_5dc
    inc ebx
    lea eax, [esi - 1]
    mov edx, ebx
    call hline
    jmp short .branch_5cb

.branch_5dc:
    cmp ebx, edi
    jle short .branch_5ea
    dec ebx
    mov dword [ebx*4 + lastx_next], esi
    jmp short .branch_5dc

.branch_5ea:
    cmp ecx, ebp
    jle short .branch_5fb
    dec ecx
    lea eax, [esi - 1]
    mov edx, ecx
    call hline
    jmp short .branch_5ea

.branch_5fb:
    cmp ecx, ebp
    jge short .branch_62c
    inc ecx
    mov dword [ecx*4 + lastx_previous], esi
    jmp short .branch_5fb

.branch_609:
    lea eax, [ecx - 1]
    cmp ebx, eax
    jge short .branch_61d
    inc ebx
    lea eax, [esi - 1]
    mov edx, ebx
    call hline
    jmp short .branch_609

.branch_61d:
    cmp esi, dword [esp]
    je short .branch_636
    movsx ebx, word [nosplit esi*2 + upper_plane_edge_next]
    mov ecx, ebx

.branch_62c:
    inc esi

.test_column:
    cmp esi, dword [esp]
    jle near .scan_column

.branch_636:
    lea eax, [ecx - 1]
    cmp ebx, eax
    jge short .run_timer
    inc ebx
    mov eax, dword [esp]
    mov edx, ebx
    call hline
    jmp short .branch_636

.run_timer:
    call faketimerhandler
; Shared return used by keepaway.

.restore_stack:
    add esp, 0x14
    pop ebp
    pop edi
    pop esi
    pop ecx
    ret

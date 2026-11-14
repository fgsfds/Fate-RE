; Collect visible wall scans and group them into wall bunches.
BITS 32
ORG 0x44bd6

move_sprites equ 0x2040a0
sector equ 0x27c3a0
wall equ 0x2310a0
pow2char equ 0x14029
rx1 equ 0x1cd160
ry1 equ 0x1d1160
rx2 equ 0x1cb160
ry2 equ 0x1cf160
xdimen equ 0x140b5
sector_wallnum equ 0x27c3a2
wall_point2 equ 0x2310a8
scan_wall equ 0x1c2160
scan_sector equ 0x1dbde0
xb2 equ 0x1c3160
xb1 equ 0x1c5160
yb1 equ 0x1c7160
yb2 equ 0x1c9160
bunchfirst equ 0x1d7560
bunchlast equ 0x1d9560
scan_next equ 0x1d8560
scan_next_previous equ 0x1d855e
scan_count equ 0x289130
bunch_count equ 0x289132
globalposx equ 0x286ad0
globalposy equ 0x286ad4
half_view_width equ 0x286b08
engine_2891d8 equ 0x2891d8
engine_1ec6a0 equ 0x1ec6a0
engine_197b50 equ 0x197b50
engine_289138 equ 0x289138
engine_28891e equ 0x28891e
engine_2891d9 equ 0x2891d9
engine_287e84 equ 0x287e84
engine_286ac8 equ 0x286ac8
engine_286af8 equ 0x286af8
engine_2710a0 equ 0x2710a0
engine_2710be equ 0x2710be
engine_1f9ca0 equ 0x1f9ca0
engine_1ecd20 equ 0x1ecd20
engine_231088 equ 0x231088
drawrooms_return equ 0x44764

scansector_:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 0x34
    push eax
    test ax, ax
    jl near drawrooms_return
    cmp byte [engine_2891d8], 0
    je short .branch_03a
    mov edx, dword [esp]
    xor dh, dh
    and dl, 7
    movsx eax, word [esp]
    movsx edx, dx
    sar eax, 3
    mov dl, byte [edx + pow2char]
    or byte [eax + engine_1ec6a0], dl

.branch_03a:
    mov eax, dword [esp]
    mov ebx, 1
    mov word [engine_197b50], ax
    mov word [engine_289138], bx

.branch_04f:
    mov cx, word [engine_289138]
    dec ecx
    movsx eax, cx
    mov ax, word [nosplit eax*2 + engine_197b50]
    mov dword [esp], eax
    cwde
    mov ax, word [nosplit eax*2 + engine_28891e]
    mov word [engine_289138], cx
    jmp near .branch_13c

.branch_07a:
    movsx eax, si
    imul eax, eax, 0x2c
    mov esi, move_sprites
    add esi, eax
    movsx eax, word [esi + 0xc]
    test ah, 0x80
    je short .branch_09d
    cmp byte [engine_2891d9], 0
    je near .branch_12f

.branch_09d:
    cmp byte [esi + 0x14], 0
    jbe near .branch_12f
    cmp byte [esi + 0x15], 0
    jbe near .branch_12f
    cmp dword [engine_287e84], 0x400
    jge short .branch_12f
    mov ebx, dword [globalposx]
    mov eax, dword [esi]
    sub eax, ebx
    mov ebx, eax
    mov ax, word [esi + 0xc]
    xor ah, ah
    mov ecx, dword [globalposy]
    and al, 0x30
    mov edx, dword [esi + 4]
    cwde
    sub edx, ecx
    test eax, eax
    jne short .branch_0f5
    imul ebx, dword [engine_286ac8]
    imul edx, dword [engine_286af8]
    add edx, ebx
    test edx, edx
    jle short .branch_12f

.branch_0f5:
    imul edi, dword [engine_287e84], 0x2c
    mov ecx, 0x2c
    add edi, engine_2710a0
    test cl, 1
    je short .branch_10d
    movsb

.branch_10d:
    shr ecx, 2
    jae short .branch_114
    movsw

.branch_114:
    rep movsd
    mov eax, dword [engine_287e84]
    imul edx, eax, 0x2c
    mov ebx, dword [esp + 0x34]
    inc eax
    mov word [edx + engine_2710be], bx
    mov dword [engine_287e84], eax

.branch_12f:
    movsx eax, word [esp + 0x34]
    mov ax, word [nosplit eax*2 + engine_1f9ca0]

.branch_13c:
    mov dword [esp + 0x34], eax
    mov esi, dword [esp + 0x34]
    test si, si
    jge near .branch_07a
    mov edx, dword [esp]
    movsx ebx, word [esp]
    xor dh, dh
    mov eax, ebx
    and dl, 7
    sar eax, 3
    movsx edx, dx
    mov cl, byte [eax + engine_1ecd20]
    mov dl, byte [edx + pow2char]
    or cl, dl
    mov byte [eax + engine_1ecd20], cl
    mov ax, word [bunch_count]
    mov dword [esp + 0x24], eax
    mov ax, word [scan_count]
    mov dword [esp + 0x20], eax
    mov eax, ebx
    shl eax, 2
    add eax, ebx
    mov dx, word [eax*8 + sector]
    mov di, word [eax*8 + sector_wallnum]
    mov eax, dword [esp + 0x20]
    mov dword [esp + 0x2c], edx
    mov dword [esp + 0x30], eax
    add edx, edi
    mov eax, dword [esp + 0x2c]
    mov dword [esp + 0x28], edx
    mov dword [esp + 0x34], eax
    cwde
    mov edx, wall
    shl eax, 5
    add edx, eax
    mov dword [esp + 0x1c], edx
    jmp near .branch_648

.branch_1ce:
    mov esi, dword [esp + 0x1c]
    mov eax, dword [esp + 0x1c]
    mov ecx, dword [esp + 0x1c]
    mov ebp, dword [esp + 0x1c]
    mov edx, dword [globalposx]
    movsx eax, word [eax + 8]
    mov ecx, dword [ecx]
    shl eax, 5
    sub ecx, edx
    add eax, wall
    mov ebx, dword [globalposy]
    mov dword [esp + 0x18], ecx
    mov ecx, dword [eax]
    mov si, word [esi + 0xc]
    sub ecx, edx
    mov ebp, dword [ebp + 4]
    mov dword [esp + 0x14], ecx
    mov ecx, dword [eax + 4]
    sub ebp, ebx
    sub ecx, ebx
    test si, si
    jl near .branch_2bc
    mov eax, dword [esp + 0x1c]
    mov ax, word [eax + 0xe]
    xor ah, ah
    and al, 0x20
    cwde
    test eax, eax
    jne near .branch_2bc
    movsx eax, si
    sar eax, 3
    xor edx, edx
    mov dl, byte [eax + engine_1ecd20]
    mov eax, esi
    xor ah, ah
    and al, 7
    cwde
    mov al, byte [eax + pow2char]
    and eax, 0xff
    test edx, eax
    jne short .branch_2bc
    mov edx, dword [esp + 0x18]
    imul edx, ecx
    mov eax, dword [esp + 0x14]
    imul eax, ebp
    sub edx, eax
    mov eax, edx
    add edx, 0x40000
    cmp edx, 0x80000
    jae short .branch_2bc
    mov edx, dword [esp + 0x14]
    mov ebx, dword [esp + 0x18]
    sub edx, ebx
    mov ebx, edx
    imul ebx, edx
    mov edx, ecx
    sub edx, ebp
    imul edx, edx
    add ebx, edx
    mov dword [esp + 8], ebx
    mov ebx, eax
    mov edi, dword [esp + 8]
    imul ebx
    shrd eax, edx, 5
    cmp eax, edi
    jg short .branch_2bc
    mov dx, word [engine_289138]
    movsx eax, dx
    inc edx
    mov word [nosplit eax*2 + engine_197b50], si
    mov word [engine_289138], dx

.branch_2bc:
    mov eax, dword [esp + 0x34]
    cmp ax, word [esp + 0x2c]
    je short .branch_2d8
    cwde
    shl eax, 5
    mov esi, dword [esp + 0x34]
    cmp si, word [eax + engine_231088]
    je short .branch_324

.branch_2d8:
    mov esi, dword [esp + 0x18]
    mov edi, dword [engine_286af8]
    mov ebx, dword [engine_286ac8]
    mov eax, ebp
    neg esi
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 6
    mov edi, dword [engine_286af8]
    mov ebx, dword [engine_286ac8]
    mov dword [esp + 4], eax
    mov esi, ebp
    mov eax, dword [esp + 0x18]
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 6
    mov ebp, eax
    jmp short .branch_330

.branch_324:
    mov eax, dword [esp + 0xc]
    mov ebp, dword [esp + 0x10]
    mov dword [esp + 4], eax

.branch_330:
    mov esi, dword [esp + 0x14]
    mov edi, dword [engine_286af8]
    mov ebx, dword [engine_286ac8]
    mov eax, ecx
    neg esi
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 6
    mov edi, dword [engine_286af8]
    mov ebx, dword [engine_286ac8]
    mov dword [esp + 0xc], eax
    mov esi, ecx
    mov eax, dword [esp + 0x14]
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 6
    mov dword [esp + 0x10], eax
    cmp ebp, 0x100
    jge short .branch_38f
    cmp eax, 0x100
    jl near .branch_5f6

.branch_38f:
    mov esi, dword [esp + 0xc]
    mov ebx, dword [esp + 0x10]
    mov eax, dword [esp + 4]
    mov edi, ebp
    neg esi
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    test edx, edx
    jge near .branch_5f6
    mov eax, ebp
    mov edx, dword [esp + 4]
    neg eax
    cmp eax, edx
    jg near .branch_43a
    cmp ebp, edx
    jl near .branch_5f6
    test ebp, ebp
    je near .branch_5f6
    mov ebx, dword [half_view_width]
    mov ecx, ebp
    mov eax, edx
    imul ebx
    idiv ecx
    mov edx, dword [half_view_width]
    add edx, eax
    movsx eax, word [scan_count]
    shl eax, 2
    mov ecx, dword [esp + 4]
    mov dword [eax + xb1], edx
    test ecx, ecx
    jl short .branch_409
    lea esi, [edx + 1]
    mov dword [eax + xb1], esi

.branch_409:
    movsx eax, word [scan_count]
    shl eax, 2
    mov edi, dword [xdimen]
    cmp edi, dword [eax + xb1]
    jg short .branch_42a
    lea edx, [edi - 1]
    mov dword [eax + xb1], edx

.branch_42a:
    movsx eax, word [scan_count]
    mov dword [eax*4 + yb2], ebp
    jmp short .branch_48e

.branch_43a:
    mov eax, dword [esp + 0x10]
    mov ebx, dword [esp + 0xc]
    neg eax
    cmp eax, ebx
    jg near .branch_5f6
    movsx eax, word [scan_count]
    xor ecx, ecx
    mov esi, dword [esp + 0x10]
    mov dword [eax*4 + xb1], ecx
    mov eax, ebp
    sub eax, esi
    add eax, edx
    sub eax, ebx
    je near .branch_5f6
    lea ebx, [edx + ebp]
    mov edx, esi
    sub edx, ebp
    mov ecx, eax
    mov eax, edx
    imul ebx
    idiv ecx
    lea edx, [eax + ebp]
    movsx eax, word [scan_count]
    mov dword [eax*4 + yb2], edx

.branch_48e:
    movsx eax, word [scan_count]
    shl eax, 2
    cmp dword [eax + yb2], 0x100
    jl near .branch_5f6
    mov edx, dword [esp + 0xc]
    mov ebx, dword [esp + 0x10]
    cmp edx, ebx
    jg near .branch_534
    mov eax, ebx
    neg eax
    cmp eax, edx
    jg near .branch_5f6
    test ebx, ebx
    je near .branch_5f6
    mov ecx, dword [esp + 0x10]
    mov ebx, dword [half_view_width]
    mov eax, edx
    imul ebx
    idiv ecx
    mov edx, dword [half_view_width]
    add edx, eax
    movsx eax, word [scan_count]
    dec edx
    shl eax, 2
    mov esi, dword [esp + 0xc]
    mov dword [eax + xb2], edx
    test esi, esi
    jl short .branch_506
    lea edi, [edx + 1]
    mov dword [eax + xb2], edi

.branch_506:
    movsx eax, word [scan_count]
    shl eax, 2
    mov ebx, dword [xdimen]
    cmp ebx, dword [eax + xb2]
    jg short .branch_527
    lea edx, [ebx - 1]
    mov dword [eax + xb2], edx

.branch_527:
    movsx eax, word [scan_count]
    mov edx, dword [esp + 0x10]
    jmp short .branch_579

.branch_534:
    mov ecx, dword [esp + 4]
    cmp ebp, ecx
    jl near .branch_5f6
    mov edx, dword [xdimen]
    dec edx
    mov dword [eax + xb2], edx
    mov eax, dword [esp + 0xc]
    sub eax, ecx
    add eax, ebp
    sub eax, ebx
    je near .branch_5f6
    mov ebx, ebp
    mov edx, dword [esp + 0x10]
    sub ebx, ecx
    sub edx, ebp
    mov ecx, eax
    mov eax, edx
    imul ebx
    idiv ecx
    lea edx, [eax + ebp]
    movsx eax, word [scan_count]

.branch_579:
    mov dword [eax*4 + yb1], edx
    movsx esi, word [scan_count]
    mov eax, esi
    shl eax, 2
    cmp dword [eax + yb1], 0x100
    jl short .branch_5f6
    mov edx, dword [eax + xb1]
    cmp edx, dword [eax + xb2]
    jg short .branch_5f6
    mov edx, dword [esp]
    mov word [nosplit esi*2 + scan_sector], dx
    mov edx, dword [esp + 0x34]
    mov word [nosplit esi*2 + scan_wall], dx
    mov edx, dword [esp + 4]
    mov dword [eax + rx1], edx
    mov edx, dword [esp + 0xc]
    mov dword [eax + rx2], edx
    mov edx, dword [esp + 0x10]
    mov dword [eax + ry1], ebp
    mov dword [eax + ry2], edx
    mov ax, word [scan_count]
    inc eax
    mov word [scan_count], ax
    mov word [nosplit esi*2 + scan_next], ax

.branch_5f6:
    movsx eax, word [esp + 0x34]
    shl eax, 5
    mov edi, dword [esp + 0x34]
    cmp di, word [eax + wall_point2]
    jle short .branch_634
    mov eax, dword [esp + 0x30]
    mov dx, word [scan_count]
    cmp ax, dx
    jge short .branch_634
    movsx eax, dx
    mov edx, dword [esp + 0x30]
    mov word [nosplit eax*2 + scan_next_previous], dx
    mov ax, word [scan_count]
    mov dword [esp + 0x30], eax

.branch_634:
    mov ebx, dword [esp + 0x34]
    mov ebp, dword [esp + 0x1c]
    inc ebx
    add ebp, 0x20
    mov dword [esp + 0x34], ebx
    mov dword [esp + 0x1c], ebp

.branch_648:
    mov eax, dword [esp + 0x34]
    cmp ax, word [esp + 0x28]
    jl near .branch_1ce
    mov eax, dword [esp + 0x20]
    mov edi, 0xffffffff
    mov dword [esp + 0x34], eax
    jmp short .branch_6d0

.branch_666:
    movsx edx, ax
    movsx ebx, word [nosplit edx*2 + scan_wall]
    movsx ecx, word [nosplit edx*2 + scan_next]
    shl ebx, 5
    mov si, word [nosplit ecx*2 + scan_wall]
    cmp si, word [ebx + wall_point2]
    jne short .branch_69d
    mov edx, dword [edx*4 + xb2]
    cmp edx, dword [ecx*4 + xb1]
    jl short .branch_6cc

.branch_69d:
    mov dx, word [bunch_count]
    movsx eax, word [esp + 0x34]
    movsx ebx, dx
    mov cx, word [nosplit eax*2 + scan_next]
    inc edx
    mov word [nosplit ebx*2 + bunchfirst], cx
    mov word [nosplit eax*2 + scan_next], di
    mov word [bunch_count], dx

.branch_6cc:
    inc dword [esp + 0x34]

.branch_6d0:
    mov eax, dword [esp + 0x34]
    cmp ax, word [scan_count]
    jl short .branch_666
    mov eax, dword [esp + 0x24]
    mov dword [esp + 0x34], eax
    jmp short .branch_71d

.branch_6e7:
    movsx edx, ax
    mov dx, word [nosplit edx*2 + bunchfirst]

.branch_6f2:
    movsx eax, dx
    add eax, eax
    mov cx, word [eax + scan_next]
    test cx, cx
    jl short .branch_707
    mov edx, ecx
    jmp short .branch_6f2

.branch_707:
    mov esi, dword [esp + 0x34]
    movsx eax, word [esp + 0x34]
    inc esi
    mov word [nosplit eax*2 + bunchlast], dx
    mov dword [esp + 0x34], esi

.branch_71d:
    mov eax, dword [esp + 0x34]
    cmp ax, word [bunch_count]
    jl short .branch_6e7
    cmp word [engine_289138], 0
    jg near .branch_04f
    jmp near drawrooms_return

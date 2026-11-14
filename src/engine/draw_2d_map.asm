; Draw the 2D map with wall and sprite visibility, selection colors and map bounds.
BITS 32
ORG 0x55227

pow2char equ 0x14029
qsetmode equ 0x140ba
editstatus equ 0x14185
faketimerhandler equ 0x31ec4
restore_ebp_edi_esi_ebx_edx_ecx equ 0x548c8
draw_2d_line equ 0x548ce
sub_54f22 equ 0x54f22
sub_54f84 equ 0x54f84
show_2d_walls equ 0x1ec920
show_2d_sprites equ 0x1ecfa0
engine_1f9ca0 equ 0x1f9ca0
sprites equ 0x2040a0
sprite_y equ 0x2040a4
engine_2040ac equ 0x2040ac
sprite_angle equ 0x2040bc
sintable equ 0x2300a0
walls equ 0x2310a0
engine_2310a4 equ 0x2310a4
nextwall equ 0x2310aa
ydim16 equ 0x286a5c
pageoffset equ 0x286a74
save_state_287e74 equ 0x287e74
engine_28891e equ 0x28891e
frame_state_28913a equ 0x28913a
frame_state_28913c equ 0x28913c
frame_state_289142 equ 0x289142
wall_count equ 0x289152
sector_count equ 0x289154

draw_2d_map:
    push esi
    push edi
    push ebp
    sub esp, 0x40
    push eax
    push edx
    push ebx
    push ecx
    cmp dword [qsetmode], strict dword 0xc8
    jz near .branch_55e24
    cmp word [editstatus], 0x0
    jnz short .branch_55270
    call faketimerhandler
    call sub_54f22
    call faketimerhandler
    movsx eax, word [esp + 0x60]
    mov edx, [esp + 0x8]
    push eax
    movsx ebx, bx
    mov eax, [esp + 0x10]
    call sub_54f84

.branch_55270:
    call faketimerhandler
    movsx eax, word [wall_count]
    dec eax
    mov esi, eax
    shl esi, byte 0x5
    mov [esp + 0x24], eax
    add esi, walls
    jmp near .branch_55819

.branch_55291:
    cmp word [editstatus], 0x0
    jnz short .branch_552f5
    mov eax, ebx
    sar eax, byte 0x3
    xor edx, edx
    mov dl, [eax + show_2d_walls]
    mov eax, ebx
    and eax, 0x7
    mov al, [eax + pow2char]
    and eax, strict dword 0xff
    test edx, eax
    jz near .branch_5580d
    movsx ebp, word [esi + 0xa]
    test ebp, ebp
    jl short .branch_55305
    cmp ebp, ebx
    jnl short .branch_55305
    mov eax, ebp
    sar eax, byte 0x3
    xor edx, edx
    mov dl, [eax + show_2d_walls]
    mov eax, ebp
    and eax, 0x7
    mov al, [eax + pow2char]
    and eax, strict dword 0xff
    and edx, eax
    test edx, edx
    jg near .branch_5580d
    jmp short .branch_55305

.branch_552f5:
    movsx ebp, word [esi + 0xa]
    test ebp, ebp
    jl short .branch_55305
    cmp ebp, ebx
    jl near .branch_5580d

.branch_55305:
    test ebp, ebp
    jnl short .branch_55330
    mov bl, 0x7
    mov ecx, [esp + 0x24]
    movsx eax, word [frame_state_28913c]
    mov [esp + 0x4c], bl
    cmp eax, ecx
    jnz short .branch_55382
    mov al, [save_state_287e74]
    and al, 0x2
    shl al, byte 0x2
    add al, bl
    mov [esp + 0x4c], al
    jmp short .branch_55382

.branch_55330:
    mov byte [esp + 0x4c], 0x4
    mov ax, [esi + 0xe]
    xor ah, ah
    and al, 0x1
    cwde
    test eax, eax
    jz short .branch_55347
    mov byte [esp + 0x4c], 0x5

.branch_55347:
    mov edx, [esp + 0x24]
    movsx eax, word [frame_state_28913c]
    cmp eax, edx
    jz short .branch_5536e
    cmp word [frame_state_28913c], 0x0
    jl short .branch_55382
    shl eax, byte 0x5
    movsx eax, word [eax + nextwall]
    cmp eax, edx
    jnz short .branch_55382

.branch_5536e:
    mov al, [save_state_287e74]
    and al, 0x2
    mov dh, [esp + 0x4c]
    shl al, byte 0x2
    add dh, al
    mov [esp + 0x4c], dh

.branch_55382:
    mov edi, [esp + 0xc]
    mov eax, [esi]
    mov ebx, [esp]
    sub eax, edi
    mov ebp, [esp + 0x8]
    imul ebx
    shrd eax, edx, byte 0xe
    mov [esp + 0x1c], eax
    mov [esp + 0x28], eax
    mov eax, [esi + 0x4]
    sub eax, ebp
    imul ebx
    shrd eax, edx, byte 0xe
    mov edi, eax
    mov [esp + 0x2c], eax
    movsx eax, word [esi + 0x8]
    shl eax, byte 0x5
    mov edx, [esp + 0xc]
    mov eax, [eax + walls]
    sub eax, edx
    imul ebx
    shrd eax, edx, byte 0xe
    mov [esp + 0x20], eax
    mov [esp + 0x30], eax
    movsx eax, word [esi + 0x8]
    shl eax, byte 0x5
    mov eax, [eax + engine_2310a4]
    sub eax, ebp
    imul ebx
    shrd eax, edx, byte 0xe
    mov ebp, eax
    mov [esp + 0x34], eax
    mov ax, [esi + 0xe]
    xor ah, ah
    and al, 0x40
    cwde
    test eax, eax
    jng near .branch_554c8
    mov eax, [esp + 0x20]
    mov ecx, [esp + 0x1c]
    sub eax, ecx
    test eax, eax
    jns short .branch_5540d
    neg eax

.branch_5540d:
    mov edx, eax
    mov eax, ebp
    sub eax, edi
    test eax, eax
    jns short .branch_55419
    neg eax

.branch_55419:
    cmp edx, eax
    jl short .branch_55472
    xor eax, eax
    mov al, [esp + 0x4c]
    mov [esp + 0x18], eax
    push eax
    mov eax, [esp + 0x24]
    add eax, strict dword 0x140
    lea ecx, [ebp + 0xc9]
    mov [esp + 0x14], eax
    mov eax, [esp + 0x20]
    lea edx, [edi + 0xc9]
    add eax, strict dword 0x140
    mov ebx, [esp + 0x14]
    mov [esp + 0x18], eax
    call draw_2d_line
    mov ecx, [esp + 0x18]
    mov ebx, [esp + 0x10]
    mov eax, [esp + 0x14]
    push ecx
    lea edx, [edi + 0xc7]
    lea ecx, [ebp + 0xc7]
    jmp short .branch_554be

.branch_55472:
    mov ebx, [esp + 0x20]
    add ebp, strict dword 0xc8
    xor eax, eax
    add edi, strict dword 0xc8
    mov al, [esp + 0x4c]
    add ebx, strict dword 0x141
    mov [esp + 0x18], eax
    push eax
    lea eax, [ecx + 0x141]
    mov edx, edi
    mov ecx, ebp
    call draw_2d_line
    mov edx, [esp + 0x18]
    mov ebx, [esp + 0x20]
    mov eax, [esp + 0x1c]
    mov ecx, ebp
    push edx
    add ebx, strict dword 0x13f
    add eax, strict dword 0x13f
    mov edx, edi

.branch_554be:
    call draw_2d_line
    add byte [esp + 0x4c], 0x8

.branch_554c8:
    mov ecx, [esp + 0x34]
    mov ebx, [esp + 0x30]
    mov edi, [esp + 0x2c]
    xor eax, eax
    mov ebp, [esp + 0x28]
    mov al, [esp + 0x4c]
    add ecx, strict dword 0xc8
    add ebx, strict dword 0x140
    add edi, strict dword 0xc8
    add ebp, strict dword 0x140
    push eax
    mov edx, edi
    mov eax, ebp
    call draw_2d_line
    cmp dword [esp], strict dword 0x100
    jl near .branch_5580d
    movsx eax, word [editstatus]
    cmp eax, 0x1
    jnz near .branch_5580d
    cmp ebp, 0x2
    jl near .branch_5580d
    cmp ebp, strict dword 0x27d
    jg near .branch_5580d
    cmp edi, 0x2
    jl near .branch_5580d
    mov edx, [ydim16]
    sub edx, 0x3
    cmp edi, edx
    jg near .branch_5580d
    mov cl, 0x2
    mov dl, [save_state_287e74]
    and dl, cl
    movsx ebx, word [frame_state_289142]
    shl dl, cl
    mov [esp + 0x4c], cl
    add dl, cl
    mov ecx, [esp + 0x24]
    cmp ebx, ecx
    jz short .branch_5559c
    cmp word [frame_state_28913a], 0x0
    jng short .branch_555a0
    cmp eax, eax
    jnz short .branch_555a0
    mov eax, ecx
    sar eax, byte 0x3
    xor ebx, ebx
    mov bl, [eax + show_2d_walls]
    mov eax, ecx
    and eax, 0x7
    mov al, [eax + pow2char]
    and eax, strict dword 0xff
    test ebx, eax
    jz short .branch_555a0

.branch_5559c:
    mov [esp + 0x4c], dl

.branch_555a0:
    mov eax, [esp + 0x2c]
    add eax, strict dword 0xc8
    mov ebx, [esp + 0x28]
    lea eax, [eax + eax*4]
    add ebx, strict dword 0x140
    shl eax, byte 0x7
    mov edi, [pageoffset]
    add ebx, eax
    xor eax, eax
    add ebx, edi
    mov al, [esp + 0x4c]
    lea edi, [ebx-0x502]
    mov dx, 0x3ce
    shl ax, byte 0x8
    out dx, ax
    mov ecx, edi
    mov eax, 0x8008
    mov dx, 0x3ce
    ror ah, cl
    shr edi, byte 0x3
    out dx, ax
    mov cl, [edi + 0xa0000]
    mov [edi + 0xa0000], al
    lea edi, [ebx-0x501]
    mov ecx, edi
    mov eax, 0x8008
    mov dx, 0x3ce
    ror ah, cl
    shr edi, byte 0x3
    out dx, ax
    mov cl, [edi + 0xa0000]
    mov [edi + 0xa0000], al
    lea edi, [ebx-0x500]
    mov ecx, edi
    mov eax, 0x8008
    mov dx, 0x3ce
    ror ah, cl
    shr edi, byte 0x3
    out dx, ax
    mov cl, [edi + 0xa0000]
    mov [edi + 0xa0000], al
    lea edi, [ebx-0x4ff]
    mov ecx, edi
    mov eax, 0x8008
    mov dx, 0x3ce
    ror ah, cl
    shr edi, byte 0x3
    out dx, ax
    mov cl, [edi + 0xa0000]
    mov [edi + 0xa0000], al
    lea edi, [ebx-0x4fe]
    mov ecx, edi
    mov eax, 0x8008
    mov dx, 0x3ce
    ror ah, cl
    shr edi, byte 0x3
    out dx, ax
    mov cl, [edi + 0xa0000]
    mov [edi + 0xa0000], al
    lea edi, [ebx + 0x4fe]
    mov ecx, edi
    mov eax, 0x8008
    mov dx, 0x3ce
    ror ah, cl
    shr edi, byte 0x3
    out dx, ax
    mov cl, [edi + 0xa0000]
    mov [edi + 0xa0000], al
    lea edi, [ebx + 0x4ff]
    mov ecx, edi
    mov eax, 0x8008
    mov dx, 0x3ce
    ror ah, cl
    shr edi, byte 0x3
    out dx, ax
    mov cl, [edi + 0xa0000]
    mov [edi + 0xa0000], al
    lea edi, [ebx + 0x500]
    mov ecx, edi
    mov eax, 0x8008
    mov dx, 0x3ce
    ror ah, cl
    shr edi, byte 0x3
    out dx, ax
    mov cl, [edi + 0xa0000]
    mov [edi + 0xa0000], al
    lea edi, [ebx + 0x501]
    mov ecx, edi
    mov eax, 0x8008
    mov dx, 0x3ce
    ror ah, cl
    shr edi, byte 0x3
    out dx, ax
    mov cl, [edi + 0xa0000]
    mov [edi + 0xa0000], al
    lea edi, [ebx + 0x502]
    mov ecx, edi
    mov eax, 0x8008
    mov dx, 0x3ce
    ror ah, cl
    shr edi, byte 0x3
    out dx, ax
    mov cl, [edi + 0xa0000]
    mov [edi + 0xa0000], al
    lea edi, [ebx-0x282]
    mov ecx, edi
    mov eax, 0x8008
    mov dx, 0x3ce
    ror ah, cl
    shr edi, byte 0x3
    out dx, ax
    mov cl, [edi + 0xa0000]
    mov [edi + 0xa0000], al
    lea edi, [ebx-0x2]
    mov ecx, edi
    mov eax, 0x8008
    mov dx, 0x3ce
    ror ah, cl
    shr edi, byte 0x3
    out dx, ax
    mov cl, [edi + 0xa0000]
    mov [edi + 0xa0000], al
    lea edi, [ebx + 0x27e]
    mov ecx, edi
    mov eax, 0x8008
    mov dx, 0x3ce
    ror ah, cl
    shr edi, byte 0x3
    out dx, ax
    mov cl, [edi + 0xa0000]
    mov [edi + 0xa0000], al
    lea edi, [ebx-0x27e]
    mov ecx, edi
    mov eax, 0x8008
    mov dx, 0x3ce
    ror ah, cl
    shr edi, byte 0x3
    out dx, ax
    mov cl, [edi + 0xa0000]
    mov [edi + 0xa0000], al
    lea edi, [ebx + 0x2]
    mov ecx, edi
    mov eax, 0x8008
    mov dx, 0x3ce
    ror ah, cl
    shr edi, byte 0x3
    out dx, ax
    mov cl, [edi + 0xa0000]
    mov [edi + 0xa0000], al
    lea edi, [ebx + 0x282]
    mov ecx, edi
    mov eax, 0x8008
    mov dx, 0x3ce
    ror ah, cl
    shr edi, byte 0x3
    out dx, ax
    mov cl, [edi + 0xa0000]
    mov [edi + 0xa0000], al

.branch_5580d:
    mov ebp, [esp + 0x24]
    dec ebp
    sub esi, 0x20
    mov [esp + 0x24], ebp

.branch_55819:
    mov ebx, [esp + 0x24]
    test ebx, ebx
    jnl near .branch_55291
    mov ecx, [esp]
    call faketimerhandler
    cmp ecx, strict dword 0x100
    jnl short .branch_55843
    cmp word [editstatus], 0x0
    jnz near .branch_55d5b

.branch_55843:
    xor esi, esi
    mov [esp + 0x24], esi
    jmp near .branch_55d48

.branch_5584e:
    movsx ebp, word [nosplit edx*2 + engine_28891e]
    jmp near .branch_55d3c

.branch_5585b:
    movsx eax, word [editstatus]
    cmp eax, 0x1
    jz short .branch_5588c
    mov eax, ebp
    sar eax, byte 0x3
    xor edx, edx
    mov dl, [eax + show_2d_sprites]
    mov eax, ebp
    and eax, 0x7
    mov al, [eax + pow2char]
    and eax, strict dword 0xff
    test edx, eax
    jz near .branch_55d34

.branch_5588c:
    imul eax, ebp, 0x2c
    mov ax, [eax + engine_2040ac]
    xor ah, ah
    and al, 0x1
    mov ch, 0x3
    cwde
    mov [esp + 0x4c], ch
    test eax, eax
    jng short .branch_558aa
    mov byte [esp + 0x4c], 0x5

.branch_558aa:
    movsx eax, word [editstatus]
    cmp eax, 0x1
    jnz short .branch_5590c
    mov dl, [save_state_287e74]
    and dl, 0x2
    shl dl, byte 0x2
    movsx ebx, word [frame_state_289142]
    mov dh, [esp + 0x4c]
    lea ecx, [ebp + 0x4000]
    add dl, dh
    cmp ecx, ebx
    jz short .branch_55908
    cmp word [frame_state_28913a], 0x0
    jng short .branch_5590c
    cmp eax, eax
    jnz short .branch_5590c
    mov eax, ebp
    sar eax, byte 0x3
    xor ebx, ebx
    mov bl, [eax + show_2d_sprites]
    mov eax, ebp
    and eax, 0x7
    mov al, [eax + pow2char]
    and eax, strict dword 0xff
    test ebx, eax
    jz short .branch_5590c

.branch_55908:
    mov [esp + 0x4c], dl

.branch_5590c:
    imul esi, ebp, 0x2c
    mov ecx, [esp + 0xc]
    mov eax, [esi + sprites]
    mov ebx, [esp]
    sub eax, ecx
    mov edi, [esp + 0x8]
    imul ebx
    shrd eax, edx, byte 0xe
    mov [esp + 0x3c], eax
    mov [esp + 0x28], eax
    mov eax, [esi + sprite_y]
    sub eax, edi
    imul ebx
    shrd eax, edx, byte 0xe
    mov [esp + 0x38], eax
    mov [esp + 0x2c], eax
    mov eax, [esp + 0x3c]
    add eax, strict dword 0x140
    mov [esp + 0x48], eax
    cmp eax, 0x2
    jl near .branch_55d34
    cmp eax, strict dword 0x27d
    jg near .branch_55d34
    mov eax, [esp + 0x38]
    add eax, strict dword 0xc8
    mov [esp + 0x44], eax
    cmp eax, 0x2
    jl near .branch_55d34
    mov eax, [ydim16]
    mov ecx, [esp + 0x44]
    sub eax, 0x3
    cmp eax, ecx
    jl near .branch_55d34
    mov eax, ecx
    mov edi, [esp + 0x48]
    lea eax, [eax + eax*4]
    shl eax, byte 0x7
    mov ebx, [pageoffset]
    add eax, edi
    add ebx, eax
    xor eax, eax
    mov al, [esp + 0x4c]
    lea edi, [ebx-0x501]
    mov [esp + 0x40], eax
    mov dx, 0x3ce
    shl ax, byte 0x8
    out dx, ax
    mov ecx, edi
    mov eax, 0x8008
    mov dx, 0x3ce
    ror ah, cl
    shr edi, byte 0x3
    out dx, ax
    mov cl, [edi + 0xa0000]
    mov [edi + 0xa0000], al
    lea edi, [ebx-0x500]
    mov ecx, edi
    mov eax, 0x8008
    mov dx, 0x3ce
    ror ah, cl
    shr edi, byte 0x3
    out dx, ax
    mov cl, [edi + 0xa0000]
    mov [edi + 0xa0000], al
    lea edi, [ebx-0x4ff]
    mov ecx, edi
    mov eax, 0x8008
    mov dx, 0x3ce
    ror ah, cl
    shr edi, byte 0x3
    out dx, ax
    mov cl, [edi + 0xa0000]
    mov [edi + 0xa0000], al
    lea edi, [ebx + 0x4ff]
    mov ecx, edi
    mov eax, 0x8008
    mov dx, 0x3ce
    ror ah, cl
    shr edi, byte 0x3
    out dx, ax
    mov cl, [edi + 0xa0000]
    mov [edi + 0xa0000], al
    lea edi, [ebx + 0x500]
    mov ecx, edi
    mov eax, 0x8008
    mov dx, 0x3ce
    ror ah, cl
    shr edi, byte 0x3
    out dx, ax
    mov cl, [edi + 0xa0000]
    mov [edi + 0xa0000], al
    lea edi, [ebx + 0x501]
    mov ecx, edi
    mov eax, 0x8008
    mov dx, 0x3ce
    ror ah, cl
    shr edi, byte 0x3
    out dx, ax
    mov cl, [edi + 0xa0000]
    mov [edi + 0xa0000], al
    lea edi, [ebx-0x282]
    mov ecx, edi
    mov eax, 0x8008
    mov dx, 0x3ce
    ror ah, cl
    shr edi, byte 0x3
    out dx, ax
    mov cl, [edi + 0xa0000]
    mov [edi + 0xa0000], al
    lea edi, [ebx-0x2]
    mov ecx, edi
    mov eax, 0x8008
    mov dx, 0x3ce
    ror ah, cl
    shr edi, byte 0x3
    out dx, ax
    mov cl, [edi + 0xa0000]
    mov [edi + 0xa0000], al
    lea edi, [ebx + 0x27e]
    mov ecx, edi
    mov eax, 0x8008
    mov dx, 0x3ce
    ror ah, cl
    shr edi, byte 0x3
    out dx, ax
    mov cl, [edi + 0xa0000]
    mov [edi + 0xa0000], al
    lea edi, [ebx-0x27e]
    mov ecx, edi
    mov eax, 0x8008
    mov dx, 0x3ce
    ror ah, cl
    shr edi, byte 0x3
    out dx, ax
    mov cl, [edi + 0xa0000]
    mov [edi + 0xa0000], al
    lea edi, [ebx + 0x2]
    mov ecx, edi
    mov eax, 0x8008
    mov dx, 0x3ce
    ror ah, cl
    shr edi, byte 0x3
    out dx, ax
    mov cl, [edi + 0xa0000]
    mov [edi + 0xa0000], al
    lea edi, [ebx + 0x282]
    mov ecx, edi
    mov eax, 0x8008
    mov dx, 0x3ce
    ror ah, cl
    shr edi, byte 0x3
    out dx, ax
    mov cl, [edi + 0xa0000]
    mov [edi + 0xa0000], al
    lea edi, [ebx + 0x281]
    mov ecx, edi
    mov eax, 0x8008
    mov dx, 0x3ce
    ror ah, cl
    shr edi, byte 0x3
    out dx, ax
    mov cl, [edi + 0xa0000]
    mov [edi + 0xa0000], al
    lea edi, [ebx + 0x27f]
    mov ecx, edi
    mov eax, 0x8008
    mov dx, 0x3ce
    ror ah, cl
    shr edi, byte 0x3
    out dx, ax
    mov cl, [edi + 0xa0000]
    mov [edi + 0xa0000], al
    lea edi, [ebx-0x27f]
    mov ecx, edi
    mov eax, 0x8008
    mov dx, 0x3ce
    ror ah, cl
    shr edi, byte 0x3
    out dx, ax
    mov cl, [edi + 0xa0000]
    mov [edi + 0xa0000], al
    lea edi, [ebx-0x281]
    mov ecx, edi
    mov eax, 0x8008
    mov dx, 0x3ce
    ror ah, cl
    shr edi, byte 0x3
    out dx, ax
    mov cl, [edi + 0xa0000]
    mov [edi + 0xa0000], al
    movsx eax, word [esi + sprite_angle]
    add eax, strict dword 0xa00
    and eax, strict dword 0x7ff
    mov ax, [nosplit eax*2 + sintable]
    mov ebx, [esp]
    cwde
    imul ebx
    shrd eax, edx, byte 0xb
    mov edx, eax
    mov ebx, 0x300
    sar edx, byte 0x1f
    idiv ebx
    mov [esp + 0x30], eax
    movsx eax, word [esi + sprite_angle]
    add eax, strict dword 0x800
    and eax, strict dword 0x7ff
    mov ax, [nosplit eax*2 + sintable]
    mov ebx, [esp]
    cwde
    imul ebx
    shrd eax, edx, byte 0xb
    mov edx, eax
    mov ebx, 0x300
    sar edx, byte 0x1f
    idiv ebx
    mov [esp + 0x34], eax
    mov ax, [esi + engine_2040ac]
    xor al, al
    and ah, 0x1
    cwde
    test eax, eax
    jng near .branch_55d09
    mov edx, [esp + 0x30]
    mov edi, [esp + 0x44]
    mov ebx, [esp + 0x34]
    movsx eax, word [esi + sprite_angle]
    mov esi, [esp + 0x48]
    add eax, strict dword 0x100
    add edi, ebx
    add esi, edx
    test ah, 0x2
    jnz short .branch_55ccc
    mov edx, [esp + 0x40]
    mov eax, [esp + 0x48]
    lea ecx, [edi-0x1]
    push edx
    mov edx, [esp + 0x3c]
    mov ebx, esi
    add edx, strict dword 0xc7
    call draw_2d_line
    mov ebx, [esp + 0x40]
    mov edx, [esp + 0x38]
    mov eax, [esp + 0x48]
    lea ecx, [edi + 0x1]
    push ebx
    add edx, strict dword 0xc9
    mov ebx, esi
    jmp short .branch_55cff

.branch_55ccc:
    mov ecx, [esp + 0x40]
    mov eax, [esp + 0x3c]
    mov edx, [esp + 0x44]
    lea ebx, [esi-0x1]
    push ecx
    add eax, strict dword 0x13f
    mov ecx, edi
    call draw_2d_line
    mov eax, [esp + 0x40]
    mov edx, [esp + 0x44]
    lea ebx, [esi + 0x1]
    push eax
    mov eax, [esp + 0x40]
    mov ecx, edi
    add eax, strict dword 0x141

.branch_55cff:
    call draw_2d_line
    add byte [esp + 0x4c], 0x8

.branch_55d09:
    mov edx, [esp + 0x2c]
    xor eax, eax
    mov ecx, [esp + 0x34]
    mov al, [esp + 0x4c]
    mov ebx, [esp + 0x30]
    push eax
    mov eax, [esp + 0x2c]
    add edx, strict dword 0xc8
    add eax, strict dword 0x140
    add ecx, edx
    add ebx, eax
    call draw_2d_line

.branch_55d34:
    movsx ebp, word [nosplit ebp*2 + engine_1f9ca0]

.branch_55d3c:
    test ebp, ebp
    jnl near .branch_5585b
    inc dword [esp + 0x24]

.branch_55d48:
    mov edx, [esp + 0x24]
    movsx eax, word [sector_count]
    cmp eax, edx
    jg near .branch_5584e

.branch_55d5b:
    movsx ecx, word [esp + 0x4]
    call faketimerhandler
    lea eax, [ecx + 0xa00]
    and eax, strict dword 0x7ff
    mov ax, [nosplit eax*2 + sintable]
    mov ebx, [esp]
    cwde
    imul ebx
    shrd eax, edx, byte 0xb
    mov edx, eax
    mov ebx, 0x300
    sar edx, byte 0x1f
    idiv ebx
    mov [esp + 0x28], eax
    lea eax, [ecx + 0x800]
    and eax, strict dword 0x7ff
    mov ax, [nosplit eax*2 + sintable]
    mov ebx, [esp]
    cwde
    imul ebx
    shrd eax, edx, byte 0xb
    mov edx, eax
    mov ebx, 0x300
    sar edx, byte 0x1f
    idiv ebx
    mov edi, [esp + 0x28]
    mov ecx, 0xc8
    push strict byte 0xf
    mov ebx, 0x140
    mov [esp + 0x30], eax
    sub ecx, eax
    lea esi, [eax + 0xc8]
    sub ebx, edi
    add edi, strict dword 0x140
    mov edx, esi
    mov eax, edi
    mov ebp, [esp + 0x2c]
    call draw_2d_line
    push strict byte 0xf
    mov ecx, 0xc8
    mov ebx, [esp + 0x30]
    mov edx, esi
    mov eax, edi
    add ebx, strict dword 0x140
    sub ecx, ebp
    call draw_2d_line
    push strict byte 0xf
    mov ebx, 0x140
    mov eax, [esp + 0x30]
    lea ecx, [ebp + 0xc8]
    mov edx, esi
    sub ebx, eax
    mov eax, edi
    call draw_2d_line

.branch_55e24:
    add esp, 0x50
    jmp near restore_ebp_edi_esi_ebx_edx_ecx

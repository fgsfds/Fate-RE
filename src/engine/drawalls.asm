; Render the planes and visible walls in a wall bunch.
BITS 32
ORG 0x45610

sector equ 0x27c3a0
wall equ 0x2310a0
picanm equ 0x1ed3a0
picsiz equ 0x1e5fe0
pow2long equ 0x14031
tilesizy equ 0x1f4020
pow2char equ 0x14029
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
globalorientation equ 0x286a84
globalypanning equ 0x286ac0
sintable equ 0x2300a0
bunchfirst equ 0x1d7560
bunchlast equ 0x1d9560
scan_next equ 0x1d8560
scan_sector equ 0x1dbde0
scan_wall_index equ 0x1c2160
xb2 equ 0x1c3160
xb1 equ 0x1c5160
upper_plane_edge equ 0x19e6e0
lower_plane_edge equ 0x19f360
upper_clip_edge equ 0x1a3e60
lower_clip_edge equ 0x1a7ce0
engine_286b8c equ 0x286b8c
engine_286af4 equ 0x286af4
engine_286aa0 equ 0x286aa0
engine_289146 equ 0x289146
engine_286b88 equ 0x286b88
engine_286a85 equ 0x286a85
engine_289150 equ 0x289150
engine_2310ac equ 0x2310ac
engine_27c3ac equ 0x27c3ac
engine_2310ae equ 0x2310ae
engine_2891da equ 0x2891da
engine_286b08 equ 0x286b08
engine_286b04 equ 0x286b04
engine_289148 equ 0x289148
engine_19ffdc equ 0x19ffdc
engine_1dcde0 equ 0x1dcde0
engine_286b14 equ 0x286b14
engine_1a4adc equ 0x1a4adc
engine_1a4ae0 equ 0x1a4ae0
engine_19ffe0 equ 0x19ffe0
engine_1ed1a0 equ 0x1ed1a0
engine_27c3ae equ 0x27c3ae
engine_140b1 equ 0x140b1
engine_28914e equ 0x28914e
engine_28912a equ 0x28912a
engine_14187 equ 0x14187
engine_2863cc equ 0x2863cc
engine_289124 equ 0x289124
engine_289128 equ 0x289128
engine_289122 equ 0x289122
engine_286a9c equ 0x286a9c
engine_286ad8 equ 0x286ad8
engine_289134 equ 0x289134
engine_1d555c equ 0x1d555c
engine_1db5df equ 0x1db5df
engine_1d5560 equ 0x1d5560
engine_28914c equ 0x28914c
engine_19b6e0 equ 0x19b6e0
engine_1a8960 equ 0x1a8960
engine_1da560 equ 0x1da560
engine_1db5e0 equ 0x1db5e0
engine_1ecd20 equ 0x1ecd20
wallmost equ 0x5e824
grouscan equ 0x5f1f8
ceilscan equ 0x478b5
animateoffs equ 0x50758
wallscan equ 0x48586
florscan equ 0x47f0c
prepwall equ 0x4751e
scansector equ 0x44bd6
transmaskvline_restore equ 0x4abbe

drawalls_:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 0x58
    push eax
    movsx eax, word [nosplit eax*2 + bunchfirst]
    mov dword [esp + 0x40], eax
    movsx eax, word [nosplit eax*2 + scan_sector]
    mov dword [esp + 0x1c], eax
    mov edx, eax
    shl eax, 2
    add eax, edx
    mov edx, sector
    shl eax, 3
    add edx, eax
    mov al, byte [edx + 0xc]
    mov byte [esp + 0x58], al
    mov al, byte [edx + 0xe]
    mov byte [esp + 0x4c], al
    mov ah, 0xff
    mov dword [esp + 0x24], edx
    mov byte [esp + 0x54], ah
    mov byte [esp + 0x48], ah
    jmp short .test_plane_scan

.calculate_plane_bounds:
    mov ebx, dword [esp + 0x1c]
    mov eax, upper_clip_edge
    xor ecx, ecx
    call wallmost
    mov cl, byte [esp + 0x54]
    mov ebx, dword [esp + 0x1c]
    mov edx, dword [esp + 0x40]
    and cl, al
    mov eax, lower_plane_edge
    mov byte [esp + 0x54], cl
    mov ecx, 1
    call wallmost
    mov ch, byte [esp + 0x48]
    and ch, al
    mov eax, dword [esp + 0x40]
    movsx eax, word [nosplit eax*2 + scan_next]
    mov byte [esp + 0x48], ch
    mov dword [esp + 0x40], eax

.test_plane_scan:
    mov edx, dword [esp + 0x40]
    test edx, edx
    jge short .calculate_plane_bounds
    mov al, byte [esp + 0x54]
    and al, 3
    and eax, 0xff
    cmp eax, 3
    je near .select_floor_renderer
    mov al, byte [esp + 0x58]
    xor edx, edx
    and al, 3
    mov dl, al
    mov eax, dword [esp]
    add eax, eax
    cmp edx, 2
    jne short .branch_0f9
    movsx ebx, word [esp + 0x1c]
    movsx edx, word [eax + bunchlast]
    xor ecx, ecx
    movsx eax, word [eax + bunchfirst]
    mov edx, dword [edx*4 + xb2]
    mov eax, dword [eax*4 + xb1]
    call grouscan
    jmp near .select_floor_renderer

.branch_0f9:
    mov dl, byte [esp + 0x58]
    and dl, 1
    and edx, 0xff
    jne short .branch_133
    movsx ebx, word [esp + 0x1c]
    movsx edx, word [eax + bunchlast]
    movsx eax, word [eax + bunchfirst]
    mov edx, dword [edx*4 + xb2]
    mov eax, dword [eax*4 + xb1]
    call ceilscan
    jmp near .select_floor_renderer

.branch_133:
    mov eax, dword [globalhoriz]
    mov ebx, dword [engine_286b8c]
    mov dword [esp + 0xc], eax
    cmp ebx, 0x10000
    je short .branch_16e
    mov eax, dword [engine_286af4]
    mov edx, dword [esp + 0xc]
    sar eax, 1
    sub edx, eax
    mov eax, edx
    imul ebx
    shrd eax, edx, 0x10
    mov edx, dword [engine_286af4]
    sar edx, 1
    add eax, edx
    mov dword [globalhoriz], eax

.branch_16e:
    mov edx, dword [esp + 0x24]
    xor eax, eax
    mov al, byte [edx + 0x15]
    xor ecx, ecx
    mov dword [globalpal], eax
    mov dword [globalorientation], ecx
    mov ax, word [edx + 0x10]
    mov word [globalpicnum], ax
    cwde
    test eax, 0xfffff000
    je short .branch_19f
    xor edx, edx
    mov word [globalpicnum], dx

.branch_19f:
    mov eax, dword [esp + 0x24]
    movsx eax, byte [eax + 0x14]
    mov dword [globalshade], eax
    mov eax, dword [engine_286aa0]
    mov dword [globvis], eax
    mov eax, dword [esp + 0x24]
    mov dh, byte [eax + 0x20]
    test dh, dh
    je short .branch_1d9
    mov al, dh
    xor ebx, ebx
    add al, 0x10
    mov bl, al
    mov eax, dword [globvis]
    imul ebx
    shrd eax, edx, 4
    mov dword [globvis], eax

.branch_1d9:
    mov edx, dword [esp + 0x24]
    xor eax, eax
    mov al, byte [edx + 0x16]
    mov dword [globalxpanning], eax
    xor eax, eax
    mov al, byte [edx + 0x17]
    mov dword [globalypanning], eax
    movsx eax, word [globalpicnum]
    test byte [eax*4 + picanm], 0xc0
    je short .branch_213
    movsx edx, word [esp + 0x1c]
    call animateoffs
    add word [globalpicnum], ax

.branch_213:
    movsx eax, word [globalpicnum]
    xor edx, edx
    mov dl, byte [eax + picsiz]
    sar edx, 4
    mov word [engine_289146], dx
    movsx edx, word [nosplit eax*2 + tilesizy]
    movsx eax, word [engine_289146]
    cmp edx, dword [eax*4 + pow2long]
    je short .branch_24b
    inc word [engine_289146]

.branch_24b:
    mov eax, 0x20
    mov si, word [engine_289146]
    movsx edx, word [globalpicnum]
    mov edi, dword [engine_286b88]
    sub eax, esi
    movsx edx, word [nosplit edx*2 + tilesizy]
    mov word [engine_289146], ax
    sar edx, 1
    movsx ecx, ax
    mov eax, dword [globalypanning]
    add edx, edi
    shl eax, 0x18
    shl edx, cl
    movsx ecx, word [engine_289146]
    add edx, eax
    mov eax, 8
    sub ecx, 0x13
    mov bh, byte [engine_286a85]
    shl eax, cl
    mov dword [globalzd], edx
    mov dword [globalyscale], eax
    test bh, 1
    je short .branch_2c1
    mov ebp, eax
    mov eax, edx
    neg ebp
    neg eax
    mov dword [globalyscale], ebp
    mov dword [globalzd], eax

.branch_2c1:
    movsx eax, word [globalpicnum]
    mov al, byte [eax + picsiz]
    and al, 0xf
    mov edx, 0xb
    and eax, 0xff
    sub edx, eax
    movsx eax, word [engine_289150]
    sub edx, eax
    mov eax, dword [esp]
    mov esi, 0xffffffff
    movsx eax, word [nosplit eax*2 + bunchfirst]
    mov dword [esp + 8], edx
    jmp near .branch_599

.branch_2fe:
    movsx eax, word [nosplit ebx*2 + scan_wall_index]
    mov ebx, eax
    shl ebx, 5
    mov dword [esp + 0x28], eax
    movsx eax, word [ebx + engine_2310ac]
    mov dword [esp + 0x20], eax
    cmp eax, -1
    je short .branch_34b
    mov ecx, eax
    shl eax, 2
    add eax, ecx
    mov ax, word [eax*8 + engine_27c3ac]
    xor ah, ah
    and al, 1
    cwde
    test eax, eax
    je short .branch_34b
    mov ax, word [ebx + engine_2310ae]
    xor ah, ah
    and al, 0x20
    cwde
    test eax, eax
    jle near .branch_476

.branch_34b:
    cmp esi, -1
    jne short .branch_35b
    mov esi, dword [esp + 0x40]
    mov esi, dword [esi*4 + xb1]

.branch_35b:
    mov edi, dword [esp + 0x40]
    mov al, byte [engine_2891da]
    shl edi, 2
    test al, al
    jne short .branch_3b5
    mov edi, dword [edi + xb1]
    jmp short .branch_3a6

.branch_373:
    mov ecx, dword [engine_286b08]
    mov eax, edi
    mov ebx, dword [engine_286b04]
    sub eax, ecx
    imul ebx
    shrd eax, edx, 0x17
    movsx edx, word [engine_289148]
    add edx, eax
    mov cl, byte [esp + 8]
    and edx, 0x7ff
    inc edi
    sar edx, cl
    mov dword [edi*4 + engine_19ffdc], edx

.branch_3a6:
    mov eax, dword [esp + 0x40]
    cmp edi, dword [eax*4 + xb2]
    jle short .branch_373
    jmp short .branch_3ef

.branch_3b5:
    mov cl, byte [esp + 8]
    mov edi, dword [edi + xb1]
    jmp short .branch_3e2

.branch_3c1:
    movsx eax, word [engine_289148]
    movsx edx, word [nosplit edi*2 + engine_1dcde0]
    add edx, eax
    and edx, 0x7ff
    inc edi
    sar edx, cl
    mov dword [edi*4 + engine_19ffdc], edx

.branch_3e2:
    mov edx, dword [esp + 0x40]
    cmp edi, dword [edx*4 + xb2]
    jle short .branch_3c1

.branch_3ef:
    xor eax, eax
    mov edi, dword [esp + 0x40]
    mov al, byte [engine_2891da]
    shl edi, 2
    cmp eax, 2
    jne short .branch_44b
    mov edi, dword [edi + xb1]
    jmp short .branch_439

.branch_40a:
    movsx eax, word [nosplit edi*2 + engine_1dcde0]
    add eax, 0x200
    and eax, 0x7ff
    mov ax, word [nosplit eax*2 + sintable]
    mov ebx, dword [engine_286b14]
    cwde
    inc edi
    imul ebx
    shrd eax, edx, 0xe
    mov dword [edi*4 + engine_1a4adc], eax

.branch_439:
    mov eax, dword [esp + 0x40]
    cmp edi, dword [eax*4 + xb2]
    jle short .branch_40a
    jmp near .branch_58d

.branch_44b:
    mov edx, dword [engine_286b14]
    mov ebp, dword [edi + xb1]
    mov eax, dword [edi + xb2]
    mov edi, ebp
    sub eax, ebp
    shl edi, 2
    lea ecx, [eax + 1]
    add edi, engine_1a4ae0
    mov eax, edx
    rep stosd
    jmp near .branch_58d

.branch_476:
    test esi, esi
    jl near .branch_58d
    movsx eax, word [globalpicnum]
    mov dword [esp + 0x38], eax
    mov al, byte [eax + picsiz]
    and al, 0xf
    and eax, 0xff
    mov dword [esp + 0x34], eax
    mov edi, dword [esp + 0x40]
    mov cl, byte [esp + 0x34]
    mov eax, dword [edx + engine_19ffe0]
    mov edi, dword [edi*4 + xb1]
    sar eax, cl
    mov ebx, dword [esp + 0x38]
    mov ax, word [nosplit eax*2 + engine_1ed1a0]
    mov ebp, dword [edi*4 + engine_19ffdc]
    add ebx, eax
    mov eax, dword [edx + engine_19ffe0]
    xor eax, ebp
    sar eax, cl
    mov word [globalpicnum], bx
    test eax, eax
    jne short .branch_4f9
    push engine_19ffe0
    mov ecx, upper_clip_edge
    mov ebx, upper_plane_edge
    push engine_1a4ae0
    lea edx, [edi - 1]
    mov eax, esi
    jmp near .branch_579

.branch_4f9:
    mov edi, esi

.branch_4fb:
    mov eax, dword [esp + 0x40]
    lea edx, [esi - 1]
    cmp esi, dword [eax*4 + xb1]
    jge short .branch_55f
    mov cl, byte [esp + 0x34]
    mov eax, dword [esi*4 + engine_19ffe0]
    sar eax, cl
    mov ebx, dword [esp + 0x38]
    movsx eax, word [nosplit eax*2 + engine_1ed1a0]
    add ebx, eax
    movsx eax, word [globalpicnum]
    mov dword [esp + 4], ebx
    cmp eax, ebx
    je short .branch_55c
    push engine_19ffe0
    mov ecx, upper_clip_edge
    push engine_1a4ae0
    mov ebx, upper_plane_edge
    mov eax, edi
    call wallscan
    mov eax, dword [esp + 4]
    mov edi, esi
    mov word [globalpicnum], ax

.branch_55c:
    inc esi
    jmp short .branch_4fb

.branch_55f:
    cmp edi, esi
    jge short .branch_57e
    push engine_19ffe0
    mov ecx, upper_clip_edge
    push engine_1a4ae0
    mov ebx, upper_plane_edge
    mov eax, edi

.branch_579:
    call wallscan

.branch_57e:
    mov eax, dword [esp + 0x38]
    mov esi, 0xffffffff
    mov word [globalpicnum], ax

.branch_58d:
    mov eax, dword [esp + 0x40]
    movsx eax, word [nosplit eax*2 + scan_next]

.branch_599:
    mov dword [esp + 0x40], eax
    mov edx, esi
    mov ebx, dword [esp + 0x40]
    shl edx, 2
    test ebx, ebx
    jge near .branch_2fe
    test esi, esi
    jl near .branch_6d3
    movsx eax, word [globalpicnum]
    mov dword [esp + 0x38], eax
    mov al, byte [eax + picsiz]
    and al, 0xf
    and eax, 0xff
    mov dword [esp + 0x34], eax
    mov cl, byte [esp + 0x34]
    mov eax, dword [edx + engine_19ffe0]
    sar eax, cl
    mov ebx, dword [esp + 0x38]
    mov ax, word [nosplit eax*2 + engine_1ed1a0]
    add ebx, eax
    mov eax, dword [esp]
    movsx edi, word [nosplit eax*2 + bunchlast]
    shl edi, 2
    mov word [globalpicnum], bx
    mov ebx, dword [edi + xb2]
    mov eax, dword [edx + engine_19ffe0]
    xor eax, dword [ebx*4 + engine_19ffe0]
    mov cl, byte [esp + 0x34]
    sar eax, cl
    test eax, eax
    jne short .branch_63b
    push engine_19ffe0
    mov ecx, upper_clip_edge
    mov edx, ebx
    push engine_1a4ae0
    mov eax, esi
    mov ebx, upper_plane_edge
    jmp near .branch_6c4

.branch_63b:
    mov edi, esi

.branch_63d:
    mov eax, dword [esp]
    movsx eax, word [nosplit eax*2 + bunchlast]
    cmp esi, dword [eax*4 + xb2]
    jg short .branch_6a8
    mov cl, byte [esp + 0x34]
    mov eax, dword [esi*4 + engine_19ffe0]
    sar eax, cl
    mov edx, dword [esp + 0x38]
    movsx eax, word [nosplit eax*2 + engine_1ed1a0]
    add edx, eax
    movsx eax, word [globalpicnum]
    mov dword [esp + 4], edx
    cmp eax, edx
    je short .branch_6a5
    push engine_19ffe0
    mov ecx, upper_clip_edge
    mov ebx, upper_plane_edge
    push engine_1a4ae0
    lea edx, [esi - 1]
    mov eax, edi
    call wallscan
    mov eax, dword [esp + 4]
    mov edi, esi
    mov word [globalpicnum], ax

.branch_6a5:
    inc esi
    jmp short .branch_63d

.branch_6a8:
    cmp edi, esi
    jg short .branch_6c9
    push engine_19ffe0
    mov ecx, upper_clip_edge
    mov ebx, upper_plane_edge
    push engine_1a4ae0
    mov edx, esi
    mov eax, edi

.branch_6c4:
    call wallscan

.branch_6c9:
    mov eax, dword [esp + 0x38]
    mov word [globalpicnum], ax

.branch_6d3:
    mov eax, dword [esp + 0xc]
    mov dword [globalhoriz], eax

.select_floor_renderer:
    mov al, byte [esp + 0x48]
    and al, 0xc
    and eax, 0xff
    cmp eax, 0xc
    je near .branch_d16
    mov al, byte [esp + 0x4c]
    xor edx, edx
    and al, 3
    mov dl, al
    mov eax, dword [esp]
    add eax, eax
    cmp edx, 2
    jne short .branch_734
    movsx ebx, word [esp + 0x1c]
    mov ecx, 1
    movsx edx, word [eax + bunchlast]
    movsx eax, word [eax + bunchfirst]
    mov edx, dword [edx*4 + xb2]
    mov eax, dword [eax*4 + xb1]
    call grouscan
    jmp near .branch_d16

.branch_734:
    mov dl, byte [esp + 0x4c]
    and dl, 1
    and edx, 0xff
    jne short .branch_76e
    movsx ebx, word [esp + 0x1c]
    movsx edx, word [eax + bunchlast]
    movsx eax, word [eax + bunchfirst]
    mov edx, dword [edx*4 + xb2]
    mov eax, dword [eax*4 + xb1]
    call florscan
    jmp near .branch_d16

.branch_76e:
    mov eax, dword [globalhoriz]
    mov ebx, dword [engine_286b8c]
    mov dword [esp + 0xc], eax
    cmp ebx, 0x10000
    je short .branch_7a9
    mov eax, dword [engine_286af4]
    mov edx, dword [esp + 0xc]
    sar eax, 1
    sub edx, eax
    mov eax, edx
    imul ebx
    shrd eax, edx, 0x10
    mov edx, dword [engine_286af4]
    sar edx, 1
    add eax, edx
    mov dword [globalhoriz], eax

.branch_7a9:
    mov edx, dword [esp + 0x24]
    xor eax, eax
    mov al, byte [edx + 0x1d]
    xor ecx, ecx
    mov dword [globalpal], eax
    mov dword [globalorientation], ecx
    mov ax, word [edx + 0x18]
    mov word [globalpicnum], ax
    cwde
    test eax, 0xfffff000
    je short .branch_7da
    xor edi, edi
    mov word [globalpicnum], di

.branch_7da:
    mov eax, dword [esp + 0x24]
    movsx eax, byte [eax + 0x1c]
    mov dword [globalshade], eax
    mov eax, dword [engine_286aa0]
    mov dword [globvis], eax
    mov eax, dword [esp + 0x24]
    mov dl, byte [eax + 0x20]
    test dl, dl
    je short .branch_814
    mov al, dl
    xor ebx, ebx
    add al, 0x10
    mov bl, al
    mov eax, dword [globvis]
    imul ebx
    shrd eax, edx, 4
    mov dword [globvis], eax

.branch_814:
    mov edx, dword [esp + 0x24]
    xor eax, eax
    mov al, byte [edx + 0x1e]
    mov dword [globalxpanning], eax
    xor eax, eax
    mov al, byte [edx + 0x1f]
    mov dword [globalypanning], eax
    movsx eax, word [globalpicnum]
    test byte [eax*4 + picanm], 0xc0
    je short .branch_84e
    movsx edx, word [esp + 0x1c]
    call animateoffs
    add word [globalpicnum], ax

.branch_84e:
    movsx eax, word [globalpicnum]
    xor edx, edx
    mov dl, byte [eax + picsiz]
    sar edx, 4
    mov word [engine_289146], dx
    movsx edx, word [nosplit eax*2 + tilesizy]
    movsx eax, word [engine_289146]
    cmp edx, dword [eax*4 + pow2long]
    je short .branch_886
    inc word [engine_289146]

.branch_886:
    mov eax, 0x20
    mov cx, word [engine_289146]
    movsx edx, word [globalpicnum]
    mov edi, dword [engine_286b88]
    sub eax, ecx
    movsx edx, word [nosplit edx*2 + tilesizy]
    mov word [engine_289146], ax
    sar edx, 1
    movsx ecx, ax
    mov eax, dword [globalypanning]
    add edx, edi
    shl eax, 0x18
    shl edx, cl
    movsx ecx, word [engine_289146]
    add edx, eax
    mov eax, 8
    sub ecx, 0x13
    mov bh, byte [engine_286a85]
    shl eax, cl
    mov dword [globalzd], edx
    mov dword [globalyscale], eax
    test bh, 1
    je short .branch_8fc
    mov ebp, eax
    mov eax, edx
    neg ebp
    neg eax
    mov dword [globalyscale], ebp
    mov dword [globalzd], eax

.branch_8fc:
    movsx eax, word [globalpicnum]
    mov al, byte [eax + picsiz]
    and al, 0xf
    mov edx, 0xb
    and eax, 0xff
    sub edx, eax
    movsx eax, word [engine_289150]
    sub edx, eax
    mov eax, dword [esp]
    mov esi, 0xffffffff
    movsx eax, word [nosplit eax*2 + bunchfirst]
    mov dword [esp + 8], edx
    jmp near .branch_bd3

.branch_939:
    movsx eax, word [nosplit ebx*2 + scan_wall_index]
    mov ebx, eax
    shl ebx, 5
    mov dword [esp + 0x28], eax
    movsx eax, word [ebx + engine_2310ac]
    mov dword [esp + 0x20], eax
    cmp eax, -1
    je short .branch_986
    mov ecx, eax
    shl eax, 2
    add eax, ecx
    mov ax, word [eax*8 + engine_27c3ae]
    xor ah, ah
    and al, 1
    cwde
    test eax, eax
    je short .branch_986
    mov ax, word [ebx + engine_2310ae]
    xor ah, ah
    and al, 0x20
    cwde
    test eax, eax
    jle near .branch_ab2

.branch_986:
    cmp esi, -1
    jne short .branch_996
    mov esi, dword [esp + 0x40]
    mov esi, dword [esi*4 + xb1]

.branch_996:
    mov edi, dword [esp + 0x40]
    mov cl, byte [engine_2891da]
    shl edi, 2
    test cl, cl
    jne short .branch_9f1
    mov edi, dword [edi + xb1]
    jmp short .branch_9e2

.branch_9af:
    mov ecx, dword [engine_286b08]
    mov eax, edi
    mov ebx, dword [engine_286b04]
    sub eax, ecx
    imul ebx
    shrd eax, edx, 0x17
    movsx edx, word [engine_289148]
    add edx, eax
    mov cl, byte [esp + 8]
    and edx, 0x7ff
    inc edi
    sar edx, cl
    mov dword [edi*4 + engine_19ffdc], edx

.branch_9e2:
    mov edx, dword [esp + 0x40]
    cmp edi, dword [edx*4 + xb2]
    jle short .branch_9af
    jmp short .branch_a2b

.branch_9f1:
    mov cl, byte [esp + 8]
    mov edi, dword [edi + xb1]
    jmp short .branch_a1e

.branch_9fd:
    movsx edx, word [engine_289148]
    movsx eax, word [nosplit edi*2 + engine_1dcde0]
    add edx, eax
    and edx, 0x7ff
    inc edi
    sar edx, cl
    mov dword [edi*4 + engine_19ffdc], edx

.branch_a1e:
    mov eax, dword [esp + 0x40]
    cmp edi, dword [eax*4 + xb2]
    jle short .branch_9fd

.branch_a2b:
    xor eax, eax
    mov edi, dword [esp + 0x40]
    mov al, byte [engine_2891da]
    shl edi, 2
    cmp eax, 2
    jne short .branch_a87
    mov edi, dword [edi + xb1]
    jmp short .branch_a75

.branch_a46:
    movsx eax, word [nosplit edi*2 + engine_1dcde0]
    add eax, 0x200
    and eax, 0x7ff
    mov ax, word [nosplit eax*2 + sintable]
    mov ebx, dword [engine_286b14]
    cwde
    inc edi
    imul ebx
    shrd eax, edx, 0xe
    mov dword [edi*4 + engine_1a4adc], eax

.branch_a75:
    mov eax, dword [esp + 0x40]
    cmp edi, dword [eax*4 + xb2]
    jle short .branch_a46
    jmp near .branch_bc7

.branch_a87:
    mov edx, dword [engine_286b14]
    mov ebp, dword [edi + xb1]
    mov eax, dword [edi + xb2]
    mov edi, ebp
    sub eax, ebp
    shl edi, 2
    lea ecx, [eax + 1]
    add edi, engine_1a4ae0
    mov eax, edx
    rep stosd
    jmp near .branch_bc7

.branch_ab2:
    test esi, esi
    jl near .branch_bc7
    movsx eax, word [globalpicnum]
    mov dword [esp + 0x38], eax
    mov al, byte [eax + picsiz]
    and al, 0xf
    and eax, 0xff
    mov dword [esp + 0x34], eax
    mov cl, byte [esp + 0x34]
    mov eax, dword [edx + engine_19ffe0]
    sar eax, cl
    mov ebx, dword [esp + 0x38]
    mov ax, word [nosplit eax*2 + engine_1ed1a0]
    add ebx, eax
    mov eax, dword [esp + 0x40]
    mov edi, dword [eax*4 + xb1]
    mov eax, dword [edx + engine_19ffe0]
    xor eax, dword [edi*4 + engine_19ffdc]
    sar eax, cl
    mov word [globalpicnum], bx
    test eax, eax
    jne short .branch_b33
    push engine_19ffe0
    mov ecx, lower_clip_edge
    mov ebx, lower_plane_edge
    push engine_1a4ae0
    lea edx, [edi - 1]
    mov eax, esi
    jmp near .branch_bb3

.branch_b33:
    mov edi, esi

.branch_b35:
    mov eax, dword [esp + 0x40]
    lea edx, [esi - 1]
    cmp esi, dword [eax*4 + xb1]
    jge short .branch_b99
    mov cl, byte [esp + 0x34]
    mov ebp, dword [esi*4 + engine_19ffe0]
    sar ebp, cl
    mov ebx, dword [esp + 0x38]
    movsx eax, word [nosplit ebp*2 + engine_1ed1a0]
    add ebx, eax
    movsx eax, word [globalpicnum]
    mov dword [esp + 4], ebx
    cmp eax, ebx
    je short .branch_b96
    push engine_19ffe0
    mov ecx, lower_clip_edge
    push engine_1a4ae0
    mov ebx, lower_plane_edge
    mov eax, edi
    call wallscan
    mov eax, dword [esp + 4]
    mov edi, esi
    mov word [globalpicnum], ax

.branch_b96:
    inc esi
    jmp short .branch_b35

.branch_b99:
    cmp edi, esi
    jge short .branch_bb8
    push engine_19ffe0
    mov ecx, lower_clip_edge
    push engine_1a4ae0
    mov ebx, lower_plane_edge
    mov eax, edi

.branch_bb3:
    call wallscan

.branch_bb8:
    mov eax, dword [esp + 0x38]
    mov esi, 0xffffffff
    mov word [globalpicnum], ax

.branch_bc7:
    mov eax, dword [esp + 0x40]
    movsx eax, word [nosplit eax*2 + scan_next]

.branch_bd3:
    mov dword [esp + 0x40], eax
    mov edx, esi
    mov ebx, dword [esp + 0x40]
    shl edx, 2
    test ebx, ebx
    jge near .branch_939
    test esi, esi
    jl near .branch_d0d
    movsx eax, word [globalpicnum]
    mov dword [esp + 0x38], eax
    mov al, byte [eax + picsiz]
    and al, 0xf
    and eax, 0xff
    mov dword [esp + 0x34], eax
    mov cl, byte [esp + 0x34]
    mov eax, dword [edx + engine_19ffe0]
    sar eax, cl
    mov ebx, dword [esp + 0x38]
    mov ax, word [nosplit eax*2 + engine_1ed1a0]
    add ebx, eax
    mov eax, dword [esp]
    movsx edi, word [nosplit eax*2 + bunchlast]
    shl edi, 2
    mov word [globalpicnum], bx
    mov ebx, dword [edi + xb2]
    mov eax, dword [edx + engine_19ffe0]
    xor eax, dword [ebx*4 + engine_19ffe0]
    mov cl, byte [esp + 0x34]
    sar eax, cl
    test eax, eax
    jne short .branch_c75
    push engine_19ffe0
    mov ecx, lower_clip_edge
    mov edx, ebx
    push engine_1a4ae0
    mov eax, esi
    mov ebx, lower_plane_edge
    jmp near .branch_cfe

.branch_c75:
    mov edi, esi

.branch_c77:
    mov eax, dword [esp]
    movsx eax, word [nosplit eax*2 + bunchlast]
    cmp esi, dword [eax*4 + xb2]
    jg short .branch_ce2
    mov cl, byte [esp + 0x34]
    mov eax, dword [esi*4 + engine_19ffe0]
    sar eax, cl
    mov edx, dword [esp + 0x38]
    movsx eax, word [nosplit eax*2 + engine_1ed1a0]
    add edx, eax
    movsx eax, word [globalpicnum]
    mov dword [esp + 4], edx
    cmp eax, edx
    je short .branch_cdf
    push engine_19ffe0
    mov ecx, lower_clip_edge
    mov ebx, lower_plane_edge
    push engine_1a4ae0
    lea edx, [esi - 1]
    mov eax, edi
    call wallscan
    mov eax, dword [esp + 4]
    mov edi, esi
    mov word [globalpicnum], ax

.branch_cdf:
    inc esi
    jmp short .branch_c77

.branch_ce2:
    cmp edi, esi
    jg short .branch_d03
    push engine_19ffe0
    mov ecx, lower_clip_edge
    mov ebx, lower_plane_edge
    push engine_1a4ae0
    mov edx, esi
    mov eax, edi

.branch_cfe:
    call wallscan

.branch_d03:
    mov eax, dword [esp + 0x38]
    mov word [globalpicnum], ax

.branch_d0d:
    mov eax, dword [esp + 0xc]
    mov dword [globalhoriz], eax

.branch_d16:
    mov eax, dword [esp]
    movsx eax, word [nosplit eax*2 + bunchfirst]
    jmp near .branch_1ef6

.process_wall:
    mov ebp, dword [ebx*4 + xb2]
    mov eax, dword [ebx*4 + xb1]
    mov dx, word [nosplit ebp*2 + upper_plane_edge]
    mov si, word [nosplit ebp*2 + lower_clip_edge]
    mov dword [esp + 0x30], eax
    cmp dx, si
    jl short .branch_d70
    mov esi, eax
    jmp short .branch_d64

.branch_d51:
    mov ax, word [nosplit esi*2 + upper_plane_edge]
    cmp ax, word [nosplit esi*2 + lower_clip_edge]
    jl short .branch_d68
    inc esi

.branch_d64:
    cmp esi, ebp
    jl short .branch_d51

.branch_d68:
    cmp esi, ebp
    jge near .branch_1eea

.branch_d70:
    mov eax, dword [esp + 0x40]
    movsx eax, word [nosplit eax*2 + scan_wall_index]
    mov edx, wall
    mov dword [esp + 0x28], eax
    shl eax, 5
    add edx, eax
    movsx eax, word [edx + 0xc]
    mov dword [esp + 0x3c], edx
    mov dword [esp + 0x20], eax
    mov edx, eax
    shl eax, 2
    add eax, edx
    mov edx, sector
    shl eax, 3
    add edx, eax
    mov eax, dword [engine_140b1]
    xor ecx, ecx
    mov dword [esp + 0x14], eax
    movsx eax, word [engine_28914e]
    mov dword [esp + 0x18], ecx
    mov dword [esp + 0x10], eax
    movsx eax, word [engine_28912a]
    mov dword [esp + 0x2c], edx
    cmp eax, 2
    jne near .branch_e8b
    mov esi, dword [esp + 0x30]
    mov eax, dword [engine_14187]
    cmp eax, esi
    jl near .branch_e8b
    cmp ebp, eax
    jl near .branch_e8b
    add eax, eax
    mov ebx, dword [engine_2863cc]
    movsx edx, word [eax + upper_clip_edge]
    cmp edx, ebx
    jl short .branch_e28
    mov eax, dword [esp + 0x1c]
    mov word [engine_289124], ax
    mov eax, dword [esp + 0x28]
    mov word [engine_289128], ax
    mov eax, 1
    mov word [engine_289122], ax
    mov word [engine_28912a], ax
    jmp short .branch_e8b

.branch_e28:
    movsx eax, word [eax + lower_plane_edge]
    cmp eax, ebx
    jg short .branch_e5b
    mov eax, dword [esp + 0x1c]
    mov esi, 2
    mov edi, 1
    mov word [engine_289124], ax
    mov word [engine_289122], si
    mov eax, dword [esp + 0x28]
    mov word [engine_28912a], di
    jmp short .branch_e85

.branch_e5b:
    cmp dword [esp + 0x20], 0
    jge short .branch_e8b
    mov eax, dword [esp + 0x1c]
    mov ecx, 1
    xor ebx, ebx
    mov word [engine_289124], ax
    mov word [engine_289122], bx
    mov eax, dword [esp + 0x28]
    mov word [engine_28912a], cx

.branch_e85:
    mov word [engine_289128], ax

.branch_e8b:
    cmp dword [esp + 0x20], 0
    jge near .branch_10bb
    mov eax, dword [esp + 0x3c]
    movsx eax, word [eax + 0xe]
    mov dword [globalorientation], eax
    mov eax, dword [esp + 0x3c]
    mov ax, word [eax + 0x10]
    mov word [globalpicnum], ax
    cwde
    test eax, 0xfffff000
    je short .branch_ec2
    xor ecx, ecx
    mov word [globalpicnum], cx

.branch_ec2:
    mov edx, dword [esp + 0x3c]
    xor eax, eax
    mov al, byte [edx + 0x18]
    mov dword [globalxpanning], eax
    xor eax, eax
    mov al, byte [edx + 0x19]
    mov dword [globalypanning], eax
    movsx eax, word [globalpicnum]
    test byte [eax*4 + picanm], 0xc0
    je short .branch_f02
    movsx edx, word [esp + 0x28]
    add edx, 0x4000
    call animateoffs
    add word [globalpicnum], ax

.branch_f02:
    mov eax, dword [esp + 0x3c]
    movsx eax, byte [eax + 0x14]
    mov dword [globalshade], eax
    mov eax, dword [engine_286a9c]
    mov dword [globvis], eax
    mov eax, dword [esp + 0x24]
    mov bh, byte [eax + 0x20]
    test bh, bh
    je short .branch_f3c
    mov al, bh
    add al, 0x10
    xor ebx, ebx
    mov bl, al
    mov eax, dword [globvis]
    imul ebx
    shrd eax, edx, 4
    mov dword [globvis], eax

.branch_f3c:
    mov edx, dword [esp + 0x3c]
    xor eax, eax
    mov al, byte [edx + 0x15]
    mov dword [globalpal], eax
    movsx eax, word [globalpicnum]
    xor edx, edx
    mov dl, byte [eax + picsiz]
    sar edx, 4
    mov word [engine_289146], dx
    movsx edx, word [nosplit eax*2 + tilesizy]
    movsx eax, word [engine_289146]
    cmp edx, dword [eax*4 + pow2long]
    je short .branch_f82
    inc word [engine_289146]

.branch_f82:
    mov eax, 0x20
    mov dx, word [engine_289146]
    sub eax, edx
    mov word [engine_289146], ax
    mov edx, dword [esp + 0x3c]
    movsx ecx, word [engine_289146]
    xor eax, eax
    sub ecx, 0x13
    mov al, byte [edx + 0x17]
    shl eax, cl
    mov cl, byte [globalorientation]
    mov dword [globalyscale], eax
    test cl, 4
    jne short .branch_fd4
    mov edx, dword [esp + 0x24]
    mov eax, dword [engine_286ad8]
    mov ebx, dword [edx + 4]
    mov ecx, dword [globalyscale]
    sub eax, ebx
    imul eax, ecx
    jmp short .branch_feb

.branch_fd4:
    mov edx, dword [esp + 0x24]
    mov eax, dword [engine_286ad8]
    mov edi, dword [edx + 8]
    mov edx, dword [globalyscale]
    sub eax, edi
    imul eax, edx

.branch_feb:
    shl eax, 8
    mov dword [globalzd], eax
    mov eax, dword [globalypanning]
    mov esi, dword [globalzd]
    shl eax, 0x18
    add esi, eax
    mov ch, byte [engine_286a85]
    mov dword [globalzd], esi
    test ch, 1
    je short .branch_102b
    mov edi, dword [globalyscale]
    mov eax, esi
    neg edi
    neg eax
    mov dword [globalyscale], edi
    mov dword [globalzd], eax

.branch_102b:
    cmp dword [esp + 0x18], 0
    jne short .branch_103f
    mov edx, dword [esp + 0x3c]
    mov eax, dword [esp + 0x40]
    call prepwall

.branch_103f:
    push lwall
    mov ecx, lower_plane_edge
    mov ebx, upper_clip_edge
    mov eax, dword [esp + 0x34]
    push swall
    mov edx, ebp
    mov esi, dword [esp + 0x38]
    call wallscan
    mov ebx, 1
    jmp short .branch_1094

.branch_1069:
    lea edi, [esi + esi]
    mov ax, word [edi + upper_plane_edge]
    cmp ax, word [edi + lower_clip_edge]
    jg short .branch_1093
    xor ecx, ecx
    mov word [edi + upper_plane_edge], bx
    mov word [edi + lower_clip_edge], cx
    sub word [engine_289134], bx

.branch_1093:
    inc esi

.branch_1094:
    cmp esi, ebp
    jle short .branch_1069
    mov eax, dword [engine_140b1]
    inc eax
    mov edx, dword [esp + 0x40]
    xor cl, cl
    mov dword [eax*4 + engine_1d555c], edx
    mov byte [eax + engine_1db5df], cl
    mov dword [engine_140b1], eax
    jmp near .branch_1e18

.branch_10bb:
    mov eax, dword [esp + 0x2c]
    mov edx, dword [esp + 0x2c]
    mov eax, dword [eax + 4]
    cmp eax, dword [edx + 8]
    jne short .branch_1125
    mov eax, dword [esp + 0x2c]
    movsx edx, word [edx + 0xc]
    movsx eax, word [eax + 0xe]
    or eax, edx
    test al, 2
    je short .branch_10f9
    mov eax, dword [esp + 0x2c]
    mov edx, dword [esp + 0x2c]
    mov ax, word [eax + 0x12]
    mov bx, word [edx + 0x1a]
    cmp ax, bx
    sete al
    mov byte [esp + 0x50], al
    jmp short .branch_10fe

.branch_10f9:
    mov byte [esp + 0x50], 1

.branch_10fe:
    cmp byte [esp + 0x50], 0
    je short .branch_112b
    mov eax, dword [engine_140b1]
    mov edx, dword [esp + 0x40]
    mov dword [eax*4 + engine_1d5560], edx
    inc eax
    xor dl, dl
    mov dword [engine_140b1], eax
    mov byte [eax + engine_1db5df], dl
    jmp short .branch_112b

.branch_1125:
    xor ch, ch
    mov byte [esp + 0x50], ch

.branch_112b:
    mov eax, dword [esp + 0x3c]
    mov ax, word [eax + 0xe]
    xor ah, ah
    and al, 0x10
    cwde
    test eax, eax
    je short .branch_115a
    mov dx, word [engine_28914c]
    mov ebx, dword [esp + 0x40]
    movsx eax, dx
    inc edx
    mov word [nosplit eax*2 + engine_19b6e0], bx
    mov word [engine_28914c], dx

.branch_115a:
    mov al, byte [esp + 0x58]
    and al, 1
    and eax, 0xff
    je short .branch_117c
    mov eax, dword [esp + 0x2c]
    mov ax, word [eax + 0xc]
    xor ah, ah
    and al, 1
    cwde
    test eax, eax
    jne near .branch_15fa

.branch_117c:
    mov eax, dword [esp + 0x2c]
    mov edx, dword [esp + 0x24]
    mov eax, dword [eax + 4]
    cmp eax, dword [edx + 4]
    jg near .branch_1279
    xor edx, edx
    mov eax, dword [esp + 0x2c]
    mov dl, byte [esp + 0x58]
    movsx eax, word [eax + 0xc]
    or eax, edx
    test al, 2
    jne near .branch_1279
    mov esi, dword [esp + 0x30]
    jmp short .branch_11e8

.branch_11ae:
    lea edi, [esi + esi]
    mov ax, word [edi + upper_plane_edge]
    mov bx, word [edi + lower_clip_edge]
    cmp ax, bx
    jg short .branch_11e7
    mov ax, word [edi + upper_clip_edge]
    cmp ax, word [edi + upper_plane_edge]
    jle short .branch_11e7
    mov word [edi + upper_plane_edge], ax
    cmp ax, bx
    jle short .branch_11e7
    dec word [engine_289134]

.branch_11e7:
    inc esi

.branch_11e8:
    cmp esi, ebp
    jle short .branch_11ae
    mov eax, dword [esp + 0x2c]
    mov edx, dword [esp + 0x24]
    mov eax, dword [eax + 4]
    cmp eax, dword [edx + 4]
    jge near .branch_15fa
    cmp byte [esp + 0x50], 0
    jne near .branch_15fa
    mov ecx, dword [esp + 0x30]
    mov eax, ebp
    sub eax, ecx
    inc eax
    movsx edx, word [engine_28914e]
    mov dword [esp + 0x44], eax
    add eax, edx
    cmp eax, 0xc800
    jge near .branch_15fa
    mov cl, 1
    mov edi, engine_1a8960
    mov esi, dword [esp + 0x30]
    mov eax, dword [engine_140b1]
    mov bx, word [engine_28914e]
    add edx, edx
    mov word [nosplit eax*2 + engine_1da560], bx
    mov byte [eax + engine_1db5e0], cl
    inc eax
    add edi, edx
    add esi, esi
    mov ebx, dword [esp + 0x40]
    mov ecx, dword [esp + 0x44]
    mov dword [engine_140b1], eax
    add esi, upper_plane_edge
    add ecx, ecx
    mov dword [eax*4 + engine_1d555c], ebx
    jmp near .branch_15e0

.branch_1279:
    mov ebx, dword [esp + 0x20]
    mov edx, dword [esp + 0x40]
    mov eax, dwall
    xor ecx, ecx
    call wallmost
    mov eax, dword [esp + 0x30]
    mov dword [esp + 0x44], eax
    jmp short .branch_12b8

.branch_1297:
    lea esi, [ebx + ebx]
    mov ax, word [esi + dwall]
    mov cx, word [esi + lower_plane_edge]
    cmp ax, cx
    jle short .branch_12b4
    mov word [esi + dwall], cx

.branch_12b4:
    inc dword [esp + 0x44]

.branch_12b8:
    mov ebx, dword [esp + 0x44]
    cmp ebp, ebx
    jge short .branch_1297
    movsx eax, word [engine_28912a]
    cmp eax, 2
    jne short .branch_1318
    mov ecx, dword [esp + 0x30]
    mov eax, dword [engine_14187]
    cmp eax, ecx
    jl short .branch_1318
    cmp ebp, eax
    jl short .branch_1318
    mov edi, dword [engine_2863cc]
    movsx eax, word [nosplit eax*2 + dwall]
    cmp eax, edi
    jl short .branch_1318
    mov eax, dword [esp + 0x1c]
    mov ecx, 1
    xor ebx, ebx
    mov word [engine_289124], ax
    mov word [engine_289122], bx
    mov eax, dword [esp + 0x28]
    mov word [engine_28912a], cx
    mov word [engine_289128], ax

.branch_1318:
    mov eax, dword [esp + 0x3c]
    movsx eax, word [eax + 0xe]
    mov dword [globalorientation], eax
    mov eax, dword [esp + 0x3c]
    mov ax, word [eax + 0x10]
    mov word [globalpicnum], ax
    cwde
    test eax, 0xfffff000
    je short .branch_1344
    xor esi, esi
    mov word [globalpicnum], si

.branch_1344:
    mov edx, dword [esp + 0x3c]
    xor eax, eax
    mov al, byte [edx + 0x18]
    mov dword [globalxpanning], eax
    xor eax, eax
    mov al, byte [edx + 0x19]
    mov dword [globalypanning], eax
    movsx eax, word [globalpicnum]
    xor edx, edx
    mov dl, byte [eax + picsiz]
    sar edx, 4
    mov word [engine_289146], dx
    movsx edx, word [nosplit eax*2 + tilesizy]
    movsx eax, word [engine_289146]
    cmp edx, dword [eax*4 + pow2long]
    je short .branch_1394
    inc word [engine_289146]

.branch_1394:
    mov eax, 0x20
    mov dx, word [engine_289146]
    sub eax, edx
    mov word [engine_289146], ax
    movsx eax, word [globalpicnum]
    test byte [eax*4 + picanm], 0xc0
    je short .branch_13d0
    movsx edx, word [esp + 0x28]
    add edx, 0x4000
    call animateoffs
    add word [globalpicnum], ax

.branch_13d0:
    mov eax, dword [esp + 0x3c]
    movsx eax, byte [eax + 0x14]
    mov dword [globalshade], eax
    mov eax, dword [engine_286a9c]
    mov dword [globvis], eax
    mov eax, dword [esp + 0x24]
    mov bh, byte [eax + 0x20]
    test bh, bh
    je short .branch_140a
    mov al, bh
    add al, 0x10
    xor ebx, ebx
    mov bl, al
    mov eax, dword [globvis]
    imul ebx
    shrd eax, edx, 4
    mov dword [globvis], eax

.branch_140a:
    mov edx, dword [esp + 0x3c]
    xor eax, eax
    mov al, byte [edx + 0x15]
    movsx ecx, word [engine_289146]
    mov dword [globalpal], eax
    xor eax, eax
    sub ecx, 0x13
    mov al, byte [edx + 0x17]
    shl eax, cl
    mov cl, byte [globalorientation]
    mov dword [globalyscale], eax
    test cl, 4
    jne short .branch_1452
    mov edx, dword [esp + 0x2c]
    mov eax, dword [engine_286ad8]
    mov edi, dword [edx + 4]
    mov edx, dword [globalyscale]
    sub eax, edi
    imul eax, edx
    jmp short .branch_1469

.branch_1452:
    mov edx, dword [esp + 0x24]
    mov eax, dword [engine_286ad8]
    mov ecx, dword [edx + 4]
    mov esi, dword [globalyscale]
    sub eax, ecx
    imul eax, esi

.branch_1469:
    shl eax, 8
    mov dword [globalzd], eax
    mov eax, dword [globalypanning]
    mov ebx, dword [globalzd]
    shl eax, 0x18
    add ebx, eax
    mov ch, byte [engine_286a85]
    mov dword [globalzd], ebx
    test ch, 1
    je short .branch_14aa
    mov ecx, dword [globalyscale]
    mov esi, ebx
    neg ecx
    neg esi
    mov dword [globalyscale], ecx
    mov dword [globalzd], esi

.branch_14aa:
    cmp dword [esp + 0x18], 0
    jne short .branch_14c7
    mov eax, 1
    mov edx, dword [esp + 0x3c]
    mov dword [esp + 0x18], eax
    mov eax, dword [esp + 0x40]
    call prepwall

.branch_14c7:
    push lwall
    mov ecx, dwall
    mov ebx, upper_clip_edge
    mov eax, dword [esp + 0x34]
    push swall
    mov edx, ebp
    mov esi, dword [esp + 0x38]
    call wallscan
    jmp short .branch_154a

.branch_14ec:
    lea edi, [esi + esi]
    mov ax, word [edi + upper_plane_edge]
    cmp ax, word [edi + lower_clip_edge]
    jg short .branch_1549
    mov ax, word [edi + upper_clip_edge]
    mov bx, word [edi + dwall]
    cmp ax, bx
    jg short .branch_1514
    mov eax, ebx

.branch_1514:
    cwde
    mov dword [esp + 0x44], eax
    lea edi, [esi + esi]
    mov edx, dword [esp + 0x44]
    movsx eax, word [edi + upper_plane_edge]
    cmp eax, edx
    jge short .branch_1549
    mov eax, dword [esp + 0x44]
    mov cx, word [edi + lower_clip_edge]
    mov word [edi + upper_plane_edge], ax
    cmp ax, cx
    jle short .branch_1549
    dec word [engine_289134]

.branch_1549:
    inc esi

.branch_154a:
    cmp esi, ebp
    jle short .branch_14ec
    mov edx, dword [esp + 0x2c]
    mov eax, dword [engine_286ad8]
    cmp eax, dword [edx + 4]
    jge short .branch_1563
    cmp byte [esp + 0x50], 0
    je short .branch_157b

.branch_1563:
    xor edx, edx
    mov eax, dword [esp + 0x2c]
    mov dl, byte [esp + 0x58]
    movsx eax, word [eax + 0xc]
    or eax, edx
    test al, 2
    je near .branch_15fa

.branch_157b:
    mov ecx, dword [esp + 0x30]
    mov eax, ebp
    sub eax, ecx
    inc eax
    movsx edx, word [engine_28914e]
    mov dword [esp + 0x44], eax
    add eax, edx
    cmp eax, 0xc800
    jge short .branch_15fa
    mov ecx, dword [esp + 0x44]
    mov edi, engine_1a8960
    mov esi, dword [esp + 0x30]
    mov eax, dword [engine_140b1]
    mov bx, word [engine_28914e]
    add edx, edx
    mov word [nosplit eax*2 + engine_1da560], bx
    inc eax
    add ecx, ecx
    add edi, edx
    add esi, esi
    mov ebx, dword [esp + 0x40]
    mov dword [engine_140b1], eax
    mov dword [eax*4 + engine_1d555c], ebx
    mov bl, 1
    add esi, upper_plane_edge
    mov byte [eax + engine_1db5df], bl

.branch_15e0:
    test cl, 1
    je short .branch_15e6
    movsb

.branch_15e6:
    shr ecx, 2
    jae short .branch_15ed
    movsw

.branch_15ed:
    rep movsd
    mov eax, dword [esp + 0x44]
    add word [engine_28914e], ax

.branch_15fa:
    mov al, byte [esp + 0x4c]
    and al, 1
    and eax, 0xff
    je short .branch_161c
    mov eax, dword [esp + 0x2c]
    mov ax, word [eax + 0xe]
    xor ah, ah
    and al, 1
    cwde
    test eax, eax
    jne near .branch_1b9b

.branch_161c:
    mov eax, dword [esp + 0x2c]
    mov edx, dword [esp + 0x24]
    mov eax, dword [eax + 8]
    cmp eax, dword [edx + 8]
    jl near .branch_1720
    xor edx, edx
    mov eax, dword [esp + 0x2c]
    mov dl, byte [esp + 0x4c]
    movsx eax, word [eax + 0xe]
    or eax, edx
    test al, 2
    jne near .branch_1720
    mov esi, dword [esp + 0x30]
    jmp short .branch_168f

.branch_164e:
    lea edi, [esi + esi]
    mov ax, word [edi + upper_plane_edge]
    mov dx, word [edi + lower_clip_edge]
    cmp ax, dx
    jg short .branch_168e
    mov ax, word [edi + lower_plane_edge]
    cmp ax, dx
    jge short .branch_168e
    mov word [edi + lower_clip_edge], ax
    mov ax, word [edi + upper_plane_edge]
    cmp ax, word [edi + lower_clip_edge]
    jle short .branch_168e
    dec word [engine_289134]

.branch_168e:
    inc esi

.branch_168f:
    cmp esi, ebp
    jle short .branch_164e
    mov eax, dword [esp + 0x2c]
    mov edx, dword [esp + 0x24]
    mov eax, dword [eax + 8]
    cmp eax, dword [edx + 8]
    jle near .branch_1b9b
    cmp byte [esp + 0x50], 0
    jne near .branch_1b9b
    mov ecx, dword [esp + 0x30]
    mov eax, ebp
    sub eax, ecx
    inc eax
    movsx edx, word [engine_28914e]
    mov dword [esp + 0x44], eax
    add eax, edx
    cmp eax, 0xc800
    jge near .branch_1b9b
    mov cl, 2
    mov edi, engine_1a8960
    mov esi, dword [esp + 0x30]
    mov eax, dword [engine_140b1]
    mov bx, word [engine_28914e]
    add edx, edx
    mov word [nosplit eax*2 + engine_1da560], bx
    mov byte [eax + engine_1db5e0], cl
    inc eax
    add edi, edx
    add esi, esi
    mov ebx, dword [esp + 0x40]
    mov ecx, dword [esp + 0x44]
    mov dword [engine_140b1], eax
    add esi, lower_clip_edge
    add ecx, ecx
    mov dword [eax*4 + engine_1d555c], ebx
    jmp near .branch_1b81

.branch_1720:
    mov ecx, 1
    mov ebx, dword [esp + 0x20]
    mov edx, dword [esp + 0x40]
    mov eax, uwall
    call wallmost
    mov eax, dword [esp + 0x30]
    mov dword [esp + 0x44], eax
    jmp short .branch_1762

.branch_1741:
    lea esi, [edi + edi]
    mov ax, word [esi + uwall]
    mov dx, word [esi + upper_clip_edge]
    cmp ax, dx
    jge short .branch_175e
    mov word [esi + uwall], dx

.branch_175e:
    inc dword [esp + 0x44]

.branch_1762:
    mov edi, dword [esp + 0x44]
    cmp ebp, edi
    jge short .branch_1741
    movsx eax, word [engine_28912a]
    cmp eax, 2
    jne short .branch_17e1
    mov edx, dword [esp + 0x30]
    mov eax, dword [engine_14187]
    cmp eax, edx
    jl short .branch_17e1
    cmp ebp, eax
    jl short .branch_17e1
    mov ecx, dword [engine_2863cc]
    movsx eax, word [nosplit eax*2 + uwall]
    cmp eax, ecx
    jg short .branch_17e1
    mov eax, dword [esp + 0x1c]
    mov word [engine_289124], ax
    mov eax, dword [esp + 0x28]
    mov word [engine_289128], ax
    mov eax, dword [esp + 0x3c]
    mov ax, word [eax + 0xe]
    xor ah, ah
    and al, 2
    cwde
    test eax, eax
    jle short .branch_17cc
    mov eax, dword [esp + 0x3c]
    mov ax, word [eax + 0xa]
    mov word [engine_289128], ax

.branch_17cc:
    xor ecx, ecx
    mov esi, 1
    mov word [engine_289122], cx
    mov word [engine_28912a], si

.branch_17e1:
    mov eax, dword [esp + 0x3c]
    mov ax, word [eax + 0xe]
    xor ah, ah
    and al, 2
    cwde
    test eax, eax
    jle near .branch_18b2
    mov eax, dword [esp + 0x3c]
    movsx eax, word [eax + 0xa]
    mov edx, wall
    mov dword [esp + 0x28], eax
    shl eax, 5
    add edx, eax
    movsx eax, word [edx + 0xe]
    mov dword [globalorientation], eax
    mov ax, word [edx + 0x10]
    mov word [globalpicnum], ax
    cwde
    mov dword [esp + 0x3c], edx
    test eax, 0xfffff000
    je short .branch_1834
    xor ebx, ebx
    mov word [globalpicnum], bx

.branch_1834:
    mov edx, dword [esp + 0x3c]
    xor eax, eax
    mov al, byte [edx + 0x18]
    mov dword [globalxpanning], eax
    xor eax, eax
    mov al, byte [edx + 0x19]
    mov dword [globalypanning], eax
    movsx eax, word [globalpicnum]
    test byte [eax*4 + picanm], 0xc0
    je short .branch_1874
    movsx edx, word [esp + 0x28]
    add edx, 0x4000
    call animateoffs
    add word [globalpicnum], ax

.branch_1874:
    mov eax, dword [esp + 0x3c]
    movsx eax, byte [eax + 0x14]
    mov edx, dword [esp + 0x3c]
    mov dword [globalshade], eax
    xor eax, eax
    mov al, byte [edx + 0x15]
    mov dword [globalpal], eax
    mov eax, dword [esp + 0x40]
    movsx eax, word [nosplit eax*2 + scan_wall_index]
    mov edx, wall
    mov dword [esp + 0x28], eax
    shl eax, 5
    add edx, eax
    mov dword [esp + 0x3c], edx
    jmp near .branch_1939

.branch_18b2:
    mov eax, dword [esp + 0x3c]
    movsx eax, word [eax + 0xe]
    mov dword [globalorientation], eax
    mov eax, dword [esp + 0x3c]
    mov ax, word [eax + 0x10]
    mov word [globalpicnum], ax
    cwde
    test eax, 0xfffff000
    je short .branch_18de
    xor edi, edi
    mov word [globalpicnum], di

.branch_18de:
    mov edx, dword [esp + 0x3c]
    xor eax, eax
    mov al, byte [edx + 0x18]
    mov dword [globalxpanning], eax
    xor eax, eax
    mov al, byte [edx + 0x19]
    mov dword [globalypanning], eax
    movsx eax, word [globalpicnum]
    test byte [eax*4 + picanm], 0xc0
    je short .branch_191e
    movsx edx, word [esp + 0x28]
    add edx, 0x4000
    call animateoffs
    add word [globalpicnum], ax

.branch_191e:
    mov eax, dword [esp + 0x3c]
    movsx eax, byte [eax + 0x14]
    mov edx, dword [esp + 0x3c]
    mov dword [globalshade], eax
    xor eax, eax
    mov al, byte [edx + 0x15]
    mov dword [globalpal], eax

.branch_1939:
    mov eax, dword [engine_286a9c]
    mov dword [globvis], eax
    mov eax, dword [esp + 0x24]
    mov bh, byte [eax + 0x20]
    test bh, bh
    je short .branch_1966
    mov al, bh
    add al, 0x10
    xor ebx, ebx
    mov bl, al
    mov eax, dword [globvis]
    imul ebx
    shrd eax, edx, 4
    mov dword [globvis], eax

.branch_1966:
    movsx eax, word [globalpicnum]
    xor edx, edx
    mov dl, byte [eax + picsiz]
    sar edx, 4
    mov word [engine_289146], dx
    movsx edx, word [nosplit eax*2 + tilesizy]
    movsx eax, word [engine_289146]
    cmp edx, dword [eax*4 + pow2long]
    je short .branch_199e
    inc word [engine_289146]

.branch_199e:
    mov eax, 0x20
    mov di, word [engine_289146]
    sub eax, edi
    mov word [engine_289146], ax
    mov edx, dword [esp + 0x3c]
    movsx ecx, word [engine_289146]
    xor eax, eax
    sub ecx, 0x13
    mov al, byte [edx + 0x17]
    shl eax, cl
    mov cl, byte [globalorientation]
    mov dword [globalyscale], eax
    test cl, 4
    jne short .branch_19f0
    mov edx, dword [esp + 0x2c]
    mov eax, dword [engine_286ad8]
    mov ebx, dword [edx + 8]
    mov ecx, dword [globalyscale]
    sub eax, ebx
    imul eax, ecx
    jmp short .branch_1a07

.branch_19f0:
    mov edx, dword [esp + 0x24]
    mov eax, dword [engine_286ad8]
    mov edi, dword [edx + 4]
    mov edx, dword [globalyscale]
    sub eax, edi
    imul eax, edx

.branch_1a07:
    shl eax, 8
    mov dword [globalzd], eax
    mov eax, dword [globalypanning]
    mov esi, dword [globalzd]
    shl eax, 0x18
    add esi, eax
    mov ch, byte [engine_286a85]
    mov dword [globalzd], esi
    test ch, 1
    je short .branch_1a47
    mov edi, dword [globalyscale]
    mov eax, esi
    neg edi
    neg eax
    mov dword [globalyscale], edi
    mov dword [globalzd], eax

.branch_1a47:
    cmp dword [esp + 0x18], 0
    jne short .branch_1a64
    mov edx, dword [esp + 0x3c]
    mov eax, dword [esp + 0x40]
    mov ebx, 1
    call prepwall
    mov dword [esp + 0x18], ebx

.branch_1a64:
    push lwall
    mov ecx, lower_plane_edge
    mov ebx, uwall
    mov eax, dword [esp + 0x34]
    push swall
    mov edx, ebp
    mov esi, dword [esp + 0x38]
    call wallscan
    jmp short .branch_1aeb

.branch_1a89:
    lea edi, [esi + esi]
    mov ax, word [edi + upper_plane_edge]
    cmp ax, word [edi + lower_clip_edge]
    jg short .branch_1aea
    mov ax, word [edi + lower_plane_edge]
    mov dx, word [edi + uwall]
    cmp ax, dx
    jl short .branch_1ab1
    mov eax, edx

.branch_1ab1:
    cwde
    mov dword [esp + 0x44], eax
    lea edi, [esi + esi]
    mov edx, dword [esp + 0x44]
    movsx eax, word [edi + lower_clip_edge]
    cmp eax, edx
    jle short .branch_1aea
    mov eax, dword [esp + 0x44]
    mov word [edi + lower_clip_edge], ax
    mov ax, word [edi + upper_plane_edge]
    cmp ax, word [edi + lower_clip_edge]
    jle short .branch_1aea
    dec word [engine_289134]

.branch_1aea:
    inc esi

.branch_1aeb:
    cmp esi, ebp
    jle short .branch_1a89
    mov edx, dword [esp + 0x2c]
    mov eax, dword [engine_286ad8]
    cmp eax, dword [edx + 8]
    jle short .branch_1b04
    cmp byte [esp + 0x50], 0
    je short .branch_1b1c

.branch_1b04:
    xor edx, edx
    mov eax, dword [esp + 0x2c]
    mov dl, byte [esp + 0x4c]
    movsx eax, word [eax + 0xe]
    or eax, edx
    test al, 2
    je near .branch_1b9b

.branch_1b1c:
    mov edi, dword [esp + 0x30]
    mov eax, ebp
    sub eax, edi
    inc eax
    movsx edx, word [engine_28914e]
    mov dword [esp + 0x44], eax
    add eax, edx
    cmp eax, 0xc800
    jge short .branch_1b9b
    mov ecx, dword [esp + 0x44]
    mov edi, engine_1a8960
    mov esi, dword [esp + 0x30]
    mov eax, dword [engine_140b1]
    mov bx, word [engine_28914e]
    add edx, edx
    mov word [nosplit eax*2 + engine_1da560], bx
    inc eax
    add ecx, ecx
    add edi, edx
    add esi, esi
    mov ebx, dword [esp + 0x40]
    mov dword [engine_140b1], eax
    mov dword [eax*4 + engine_1d555c], ebx
    mov bl, 2
    add esi, lower_clip_edge
    mov byte [eax + engine_1db5df], bl

.branch_1b81:
    test cl, 1
    je short .branch_1b87
    movsb

.branch_1b87:
    shr ecx, 2
    jae short .branch_1b8e
    movsw

.branch_1b8e:
    rep movsd
    mov eax, dword [esp + 0x44]
    add word [engine_28914e], ax

.branch_1b9b:
    mov eax, dword [esp + 0x3c]
    mov ax, word [eax + 0xe]
    xor ah, ah
    and al, 0x20
    cwde
    test eax, eax
    jle near .branch_1e18
    mov eax, dword [esp + 0x3c]
    movsx eax, word [eax + 0xe]
    mov dword [globalorientation], eax
    mov eax, dword [esp + 0x3c]
    mov ax, word [eax + 0x12]
    mov word [globalpicnum], ax
    cwde
    test eax, 0xfffff000
    je short .branch_1bdb
    xor eax, eax
    mov word [globalpicnum], ax

.branch_1bdb:
    mov edx, dword [esp + 0x3c]
    xor eax, eax
    mov al, byte [edx + 0x18]
    mov dword [globalxpanning], eax
    xor eax, eax
    mov al, byte [edx + 0x19]
    mov dword [globalypanning], eax
    movsx eax, word [globalpicnum]
    test byte [eax*4 + picanm], 0xc0
    je short .branch_1c1b
    movsx edx, word [esp + 0x28]
    add edx, 0x4000
    call animateoffs
    add word [globalpicnum], ax

.branch_1c1b:
    mov eax, dword [esp + 0x3c]
    movsx eax, byte [eax + 0x14]
    mov dword [globalshade], eax
    mov eax, dword [engine_286a9c]
    mov dword [globvis], eax
    mov eax, dword [esp + 0x24]
    mov dl, byte [eax + 0x20]
    test dl, dl
    je short .branch_1c55
    mov al, dl
    xor ebx, ebx
    add al, 0x10
    mov bl, al
    mov eax, dword [globvis]
    imul ebx
    shrd eax, edx, 4
    mov dword [globvis], eax

.branch_1c55:
    mov edx, dword [esp + 0x3c]
    xor eax, eax
    mov al, byte [edx + 0x15]
    mov dword [globalpal], eax
    movsx eax, word [globalpicnum]
    xor edx, edx
    mov dl, byte [eax + picsiz]
    sar edx, 4
    mov word [engine_289146], dx
    movsx edx, word [nosplit eax*2 + tilesizy]
    movsx eax, word [engine_289146]
    cmp edx, dword [eax*4 + pow2long]
    je short .branch_1c9b
    inc word [engine_289146]

.branch_1c9b:
    mov eax, 0x20
    mov cx, word [engine_289146]
    sub eax, ecx
    mov word [engine_289146], ax
    mov edx, dword [esp + 0x3c]
    movsx ecx, word [engine_289146]
    xor eax, eax
    sub ecx, 0x13
    mov al, byte [edx + 0x17]
    shl eax, cl
    mov dh, byte [globalorientation]
    mov dword [globalyscale], eax
    test dh, 4
    jne short .branch_1ced
    mov edx, dword [esp + 0x2c]
    mov eax, dword [engine_286ad8]
    mov ebx, dword [edx + 4]
    mov ecx, dword [globalyscale]
    sub eax, ebx
    imul eax, ecx
    jmp short .branch_1d04

.branch_1ced:
    mov edx, dword [esp + 0x24]
    mov eax, dword [engine_286ad8]
    mov edi, dword [edx + 4]
    mov edx, dword [globalyscale]
    sub eax, edi
    imul eax, edx

.branch_1d04:
    shl eax, 8
    mov dword [globalzd], eax
    mov eax, dword [globalypanning]
    mov esi, dword [globalzd]
    shl eax, 0x18
    add esi, eax
    mov bl, byte [engine_286a85]
    mov dword [globalzd], esi
    test bl, 1
    je short .branch_1d44
    mov edi, dword [globalyscale]
    mov eax, esi
    neg edi
    neg eax
    mov dword [globalyscale], edi
    mov dword [globalzd], eax

.branch_1d44:
    cmp dword [esp + 0x18], 0
    jne short .branch_1d58
    mov edx, dword [esp + 0x3c]
    mov eax, dword [esp + 0x40]
    call prepwall

.branch_1d58:
    push lwall
    mov ecx, lower_plane_edge
    mov ebx, upper_clip_edge
    mov eax, dword [esp + 0x34]
    push swall
    mov edx, ebp
    mov esi, dword [esp + 0x38]
    call wallscan
    mov ebx, 1
    jmp short .branch_1dad

.branch_1d82:
    lea edi, [esi + esi]
    mov ax, word [edi + upper_plane_edge]
    cmp ax, word [edi + lower_clip_edge]
    jg short .branch_1dac
    xor ecx, ecx
    mov word [edi + upper_plane_edge], bx
    mov word [edi + lower_clip_edge], cx
    sub word [engine_289134], bx

.branch_1dac:
    inc esi

.branch_1dad:
    cmp esi, ebp
    jle short .branch_1d82
    mov eax, dword [engine_140b1]
    inc eax
    mov edx, dword [esp + 0x40]
    xor bh, bh
    mov dword [eax*4 + engine_1d555c], edx
    mov byte [eax + engine_1db5df], bh
    movsx edx, word [engine_28912a]
    mov dword [engine_140b1], eax
    cmp edx, 2
    jne short .branch_1e18
    mov ebx, dword [esp + 0x30]
    mov eax, dword [engine_14187]
    cmp eax, ebx
    jl short .branch_1e18
    cmp ebp, eax
    jl short .branch_1e18
    mov eax, dword [esp + 0x1c]
    mov esi, 4
    mov edi, 1
    mov word [engine_289124], ax
    mov word [engine_289122], si
    mov eax, dword [esp + 0x28]
    mov word [engine_28912a], di
    mov word [engine_289128], ax

.branch_1e18:
    cmp word [engine_289134], 0
    jl near .branch_1f06
    mov eax, dword [esp + 0x20]
    sar eax, 3
    xor edx, edx
    mov dl, byte [eax + engine_1ecd20]
    mov eax, dword [esp + 0x20]
    and eax, 7
    mov al, byte [eax + pow2char]
    and eax, 0xff
    test edx, eax
    jne near .branch_1eea
    cmp dword [esp + 0x20], 0
    jl near .branch_1eea
    mov eax, dword [esp + 0x3c]
    mov ax, word [eax + 0xe]
    xor ah, ah
    and al, 0x20
    cwde
    test eax, eax
    jne near .branch_1eea
    mov dx, word [nosplit ebp*2 + upper_plane_edge]
    cmp dx, word [nosplit ebp*2 + lower_clip_edge]
    jge short .branch_1e8d
    movsx eax, word [esp + 0x20]
    call scansector
    jmp short .branch_1eea

.branch_1e8d:
    mov esi, dword [esp + 0x30]
    jmp short .branch_1eb2

.branch_1e93:
    mov ax, word [nosplit esi*2 + upper_plane_edge]
    cmp ax, word [nosplit esi*2 + lower_clip_edge]
    jge short .branch_1eb1
    movsx eax, word [esp + 0x20]
    call scansector
    jmp short .branch_1eb6

.branch_1eb1:
    inc esi

.branch_1eb2:
    cmp esi, ebp
    jl short .branch_1e93

.branch_1eb6:
    cmp esi, ebp
    jne short .branch_1eea
    mov eax, dword [esp + 0x14]
    mov dword [engine_140b1], eax
    mov eax, dword [esp + 0x10]
    mov word [engine_28914e], ax
    mov eax, dword [esp + 0x14]
    inc eax
    mov edx, dword [esp + 0x40]
    xor ch, ch
    mov dword [eax*4 + engine_1d555c], edx
    mov byte [eax + engine_1db5df], ch
    mov dword [engine_140b1], eax

.branch_1eea:
    mov eax, dword [esp + 0x40]
    movsx eax, word [nosplit eax*2 + scan_next]

.branch_1ef6:
    mov dword [esp + 0x40], eax
    mov ebx, dword [esp + 0x40]
    test ebx, ebx
    jge near .process_wall

.branch_1f06:
    add esp, 0x5c
    jmp near transmaskvline_restore

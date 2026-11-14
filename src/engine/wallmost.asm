; Project a sector plane along a wall, including sloped planes.
BITS 32
ORG 0x5e824

sector equ 0x27c3a0
wall equ 0x2310a0
sqrtable equ 0x1dfa60
globalhoriz equ 0x286ae4
xdimen equ 0x140b5
sector_ceilingz equ 0x27c3a4
sector_floorz equ 0x27c3a8
sector_ceilingstat equ 0x27c3ac
sector_floorstat equ 0x27c3ae
sector_ceilingheinum equ 0x27c3b2
sector_floorheinum equ 0x27c3ba
globalposz equ 0x286ad8
view_height equ 0x286af4
scan_wall equ 0x1c2160
xb2 equ 0x1c3160
xb1 equ 0x1c5160
yb1 equ 0x1c7160
yb2 equ 0x1c9160
engine_2310a8 equ 0x2310a8
engine_2310a4 equ 0x2310a4
engine_286b20 equ 0x286b20
engine_286b23 equ 0x286b23
engine_286ac8 equ 0x286ac8
engine_286af8 equ 0x286af8
engine_286ad0 equ 0x286ad0
engine_286ad4 equ 0x286ad4
engine_286acc equ 0x286acc
engine_286afc equ 0x286afc
engine_286b00 equ 0x286b00
owallmost equ 0x5e350

wallmost_:
    push esi
    push edi
    push ebp
    sub esp, 0x70
    push eax
    mov ebp, edx
    mov dword [esp + 0x40], ebx
    mov byte [esp + 0x70], cl
    mov eax, ebx
    shl eax, 2
    add eax, ebx
    shl eax, 3
    test cl, cl
    jne short .branch_04a
    mov ebx, dword [eax + sector_ceilingz]
    mov ax, word [eax + sector_ceilingstat]
    xor ah, ah
    and al, 2
    mov ecx, dword [globalposz]
    cwde
    sub ebx, ecx
    test eax, eax
    jne short .branch_06f
    mov eax, dword [esp]

.branch_040:
    call owallmost
    jmp near .branch_9cd

.branch_04a:
    mov ebx, dword [eax + sector_floorz]
    mov ax, word [eax + sector_floorstat]
    xor ah, ah
    and al, 2
    mov edx, dword [globalposz]
    cwde
    sub ebx, edx
    test eax, eax
    jne short .branch_06f
    mov eax, dword [esp]
    mov edx, ebp
    jmp short .branch_040

.branch_06f:
    movsx edi, word [nosplit ebp*2 + scan_wall]
    shl edi, 5
    mov eax, dword [edi + wall]
    mov dword [esp + 0x5c], eax
    movsx eax, word [edi + engine_2310a8]
    shl eax, 5
    mov esi, dword [esp + 0x5c]
    mov edx, dword [eax + wall]
    sub edx, esi
    mov dword [esp + 0x48], edx
    mov edx, dword [edi + engine_2310a4]
    mov eax, dword [eax + engine_2310a4]
    mov dword [esp + 0x60], edx
    sub eax, edx
    mov edx, dword [esp + 0x40]
    mov dword [esp + 0x44], eax
    mov eax, edx
    shl eax, 2
    add eax, edx
    movsx eax, word [eax*8 + sector]
    mov dword [esp + 0x2c], eax
    shl eax, 5
    movsx edi, word [eax + engine_2310a8]
    shl edi, 5
    mov ebx, dword [eax + wall]
    mov edx, dword [edi + wall]
    sub edx, ebx
    mov ecx, dword [eax + engine_2310a4]
    mov dword [esp + 0x34], edx
    mov edx, dword [edi + engine_2310a4]
    sub edx, ecx
    mov dword [esp + 0x3c], edx
    mov edx, dword [esp + 0x34]
    imul edx, edx
    mov eax, dword [esp + 0x3c]
    imul eax, eax
    add edx, eax
    mov eax, edx
    mov dword [engine_286b20], eax
    fild dword [engine_286b20]
    fstp dword [engine_286b20]
    mov bl, byte [engine_286b23]
    sub bl, 0x44
    jge short .branch_136
    xor ebx, ebx
    mov bx, word [nosplit eax*2 + sqrtable]
    jmp short .branch_14d

.branch_136:
    lea ecx, [nosplit ebx*2]
    shr eax, cl
    mov cl, bl
    xor ebx, ebx
    mov bx, word [nosplit eax*2 + sqrtable]
    shl ebx, cl

.branch_14d:
    shr ebx, 0xa
    cmp ebx, 0x10
    jle short .branch_19d
    mov eax, edx
    mov dword [engine_286b20], eax
    fild dword [engine_286b20]
    fstp dword [engine_286b20]
    mov bl, byte [engine_286b23]
    sub bl, 0x44
    jge short .branch_17f
    xor ebx, ebx
    mov bx, word [nosplit eax*2 + sqrtable]
    jmp short .branch_196

.branch_17f:
    lea ecx, [nosplit ebx*2]
    shr eax, cl
    mov cl, bl
    xor ebx, ebx
    mov bx, word [nosplit eax*2 + sqrtable]
    shl ebx, cl

.branch_196:
    shr ebx, 0xa
    mov ecx, ebx
    jmp short .branch_1a2

.branch_19d:
    mov ecx, 0x10

.branch_1a2:
    cmp dword [ebp*4 + xb1], 0
    jne short .branch_1c5
    mov eax, dword [engine_286ac8]
    mov edi, dword [engine_286af8]
    mov edx, dword [engine_286ac8]
    mov ebx, edi
    add eax, edi
    sub ebx, edx
    jmp short .branch_1dd

.branch_1c5:
    mov eax, dword [esp + 0x5c]
    mov ebx, dword [engine_286ad0]
    mov esi, dword [engine_286ad4]
    sub eax, ebx
    mov ebx, dword [esp + 0x60]
    sub ebx, esi

.branch_1dd:
    mov edx, dword [esp + 0x60]
    mov esi, dword [engine_286ad4]
    mov edi, eax
    sub edx, esi
    imul edi, edx
    mov esi, dword [engine_286ad0]
    mov edx, dword [esp + 0x5c]
    sub edx, esi
    imul edx, ebx
    imul eax, dword [esp + 0x44]
    sub edi, edx
    imul ebx, dword [esp + 0x48]
    sub ebx, eax
    mov eax, ebx
    test eax, eax
    jns short .branch_213
    neg eax

.branch_213:
    mov edx, eax
    mov eax, edi
    sar eax, 3
    test eax, eax
    jns short .branch_220
    neg eax

.branch_220:
    cmp edx, eax
    jle short .branch_232
    mov eax, edi
    mov edx, eax
    sar edx, 4
    shl eax, 0x1c
    idiv ebx
    mov edi, eax

.branch_232:
    mov eax, dword [esp + 0x40]
    mov esi, eax
    shl esi, 2
    add esi, eax
    mov dh, byte [esp + 0x70]
    shl esi, 3
    test dh, dh
    jne short .branch_268
    mov ax, word [esi + sector_ceilingheinum]
    mov ebx, ecx
    cwde
    mov edx, eax
    sar edx, 0x11
    shl eax, 0xf
    idiv ebx
    mov dword [esp + 0x64], eax
    mov eax, dword [esi + sector_ceilingz]
    jmp short .branch_286

.branch_268:
    mov ax, word [esi + sector_floorheinum]
    mov ebx, ecx
    cwde
    mov edx, eax
    sar edx, 0x11
    shl eax, 0xf
    idiv ebx
    mov dword [esp + 0x64], eax
    mov eax, dword [esi + sector_floorz]

.branch_286:
    mov dword [esp + 0x6c], eax
    mov eax, dword [esp + 0x6c]
    mov edx, dword [globalposz]
    mov esi, dword [esp + 0x2c]
    sub eax, edx
    shl esi, 5
    shl eax, 7
    mov ebx, dword [esi + wall]
    mov dword [esp + 0x10], eax
    mov eax, dword [esp + 0x5c]
    sub eax, ebx
    shl eax, 8
    mov ebx, edi
    mov dword [esp + 0xc], eax
    mov eax, dword [esp + 0x48]
    imul ebx
    shrd eax, edx, 0x14
    mov edx, dword [esp + 0xc]
    add edx, eax
    mov eax, dword [esp + 0x3c]
    mov dword [esp + 0xc], edx
    mov edx, dword [esp + 0x64]
    neg eax
    imul edx, eax
    mov eax, dword [esp + 0x60]
    mov dword [esp + 0x14], edx
    mov edx, dword [esi + engine_2310a4]
    mov esi, eax
    sub esi, edx
    mov eax, dword [esp + 0x44]
    shl esi, 8
    imul ebx
    shrd eax, edx, 0x14
    lea ebx, [eax + esi]
    mov eax, dword [esp + 0x34]
    imul eax, dword [esp + 0x64]
    mov edi, dword [esp + 0xc]
    mov esi, dword [esp + 0x14]
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0x18
    mov edx, dword [esp + 0x10]
    add edx, eax
    mov dword [esp + 0x6c], edx
    mov edx, dword [xdimen]
    mov edi, dword [ebp*4 + xb2]
    dec edx
    cmp edx, edi
    jne short .branch_350
    mov eax, dword [engine_286ac8]
    mov edx, dword [engine_286af8]
    mov esi, dword [engine_286ac8]
    sub eax, edx
    lea ebx, [edx + esi]
    jmp short .branch_374

.branch_350:
    mov eax, dword [esp + 0x48]
    mov edx, dword [esp + 0x5c]
    mov ebx, dword [engine_286ad0]
    add eax, edx
    mov esi, dword [esp + 0x60]
    sub eax, ebx
    mov ebx, dword [esp + 0x44]
    mov edi, dword [engine_286ad4]
    add ebx, esi
    sub ebx, edi

.branch_374:
    mov edx, dword [esp + 0x60]
    sub edx, dword [engine_286ad4]
    imul edx, eax
    mov esi, dword [engine_286ad0]
    mov edi, dword [esp + 0x5c]
    sub edi, esi
    imul edi, ebx
    imul eax, dword [esp + 0x44]
    sub edx, edi
    mov edi, edx
    imul ebx, dword [esp + 0x48]
    sub ebx, eax
    mov eax, ebx
    test eax, eax
    jns short .branch_3a8
    neg eax

.branch_3a8:
    mov edx, eax
    mov eax, edi
    sar eax, 3
    test eax, eax
    jns short .branch_3b5
    neg eax

.branch_3b5:
    cmp edx, eax
    jle short .branch_3c7
    mov eax, edi
    mov edx, eax
    sar edx, 4
    shl eax, 0x1c
    idiv ebx
    mov edi, eax

.branch_3c7:
    mov eax, dword [esp + 0x40]
    mov esi, eax
    shl esi, 2
    add esi, eax
    mov bl, byte [esp + 0x70]
    shl esi, 3
    test bl, bl
    jne short .branch_3fd
    mov ax, word [esi + sector_ceilingheinum]
    mov ebx, ecx
    cwde
    mov edx, eax
    sar edx, 0x11
    shl eax, 0xf
    idiv ebx
    mov dword [esp + 0x64], eax
    mov esi, dword [esi + sector_ceilingz]
    jmp short .branch_41b

.branch_3fd:
    mov ax, word [esi + sector_floorheinum]
    mov ebx, ecx
    cwde
    mov edx, eax
    sar edx, 0x11
    shl eax, 0xf
    idiv ebx
    mov dword [esp + 0x64], eax
    mov esi, dword [esi + sector_floorz]

.branch_41b:
    mov eax, dword [globalposz]
    mov ecx, dword [esp + 0x2c]
    sub esi, eax
    shl ecx, 5
    shl esi, 7
    mov edx, dword [ecx + wall]
    mov dword [esp + 0x14], esi
    mov esi, dword [esp + 0x5c]
    mov ebx, edi
    sub esi, edx
    mov eax, dword [esp + 0x48]
    shl esi, 8
    imul ebx
    shrd eax, edx, 0x14
    add esi, eax
    mov eax, dword [esp + 0x3c]
    mov edx, dword [esp + 0x64]
    neg eax
    imul edx, eax
    mov ebx, dword [ecx + engine_2310a4]
    mov eax, dword [esp + 0x60]
    mov dword [esp + 0x10], edx
    mov ecx, eax
    mov eax, dword [esp + 0x44]
    sub ecx, ebx
    mov ebx, edi
    shl ecx, 8
    imul ebx
    shrd eax, edx, 0x14
    lea ebx, [eax + ecx]
    mov eax, dword [esp + 0x34]
    imul eax, dword [esp + 0x64]
    mov edi, esi
    mov esi, dword [esp + 0x10]
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0x18
    mov esi, dword [esp + 0x14]
    mov ebx, dword [ebp*4 + yb2]
    add esi, eax
    mov eax, dword [engine_286acc]
    imul ebx
    shrd eax, edx, 0x14
    mov dword [esp + 8], eax
    mov ebx, dword [ebp*4 + yb1]
    mov eax, dword [engine_286acc]
    imul ebx
    shrd eax, edx, 0x14
    mov edi, eax
    mov dword [esp + 0x18], eax
    mov ebx, dword [ebp*4 + yb2]
    mov eax, dword [engine_286afc]
    imul ebx
    shrd eax, edx, 0x14
    mov dword [esp + 0x28], eax
    mov ebx, dword [ebp*4 + yb1]
    mov eax, dword [engine_286afc]
    imul ebx
    shrd eax, edx, 0x14
    mov dword [esp + 0x20], eax
    cmp esi, edi
    setl al
    mov edx, eax
    mov edi, dword [esp + 8]
    and edx, 0xff
    mov eax, dword [esp + 0x6c]
    add edx, edx
    cmp eax, edi
    setl al
    and eax, 0xff
    mov ebx, dword [esp + 0x28]
    add eax, edx
    mov edx, dword [esp + 0x6c]
    cmp edx, ebx
    setg dl
    and edx, 0xff
    shl edx, 2
    mov ecx, dword [esp + 0x20]
    add eax, edx
    cmp esi, ecx
    setg dl
    and edx, 0xff
    shl edx, 3
    mov edi, ebp
    add eax, edx
    shl edi, 2
    mov dword [esp + 0x68], eax
    mov eax, dword [edi + xb1]
    mov dword [esp + 0x54], eax
    mov eax, dword [edi + xb2]
    mov dword [esp + 0x50], eax
    mov eax, dword [edi + yb2]
    mov dword [esp + 0x24], eax
    mov eax, dword [edi + yb1]
    mov dword [esp + 0x30], eax
    mov eax, dword [esp + 0x6c]
    mov dword [esp + 0x38], eax
    mov eax, dword [esp + 0x68]
    mov dword [esp + 4], esi
    and eax, 3
    mov ecx, dword [esp + 0x50]
    mov dword [esp + 0x1c], eax
    mov eax, dword [esp + 0x54]
    mov edx, dword [esp]
    sub ecx, eax
    lea ebx, [eax + eax]
    add ecx, ecx
    mov eax, dword [esp + 0x1c]
    add ecx, 2
    add ebx, edx
    cmp eax, 3
    jne short .branch_5f9
    mov edi, ebx
    xor eax, eax

.branch_5b7:
    cmp ecx, 4
    jae short .branch_5c9
    test cl, 1
    je short .branch_5c2
    stosb

.branch_5c2:
    shr ecx, 1
    db 0xf3                       ; REP precedes the operand-size prefix
    stosw
    jmp short .branch_5f4

.branch_5c9:
    test edi, 1
    je short .branch_5d3
    stosb
    dec ecx

.branch_5d3:
    test edi, 2
    je short .branch_5e0
    stosw
    sub ecx, 2

.branch_5e0:
    mov ebx, ecx
    shr ecx, 2
    rep stosd
    test bl, 2
    je short .branch_5ee
    stosw

.branch_5ee:
    test bl, 1
    je short .branch_5f4
    stosb

.branch_5f4:
    jmp near .branch_9c9

.branch_5f9:
    mov eax, dword [esp + 0x68]
    and eax, 0xc
    cmp eax, 0xc
    jne short .branch_619
    mov eax, dword [view_height]
    mov esi, dword [view_height]
    shl eax, 0x10
    mov edi, ebx
    add eax, esi
    jmp short .branch_5b7

.branch_619:
    test byte [esp + 0x68], 3
    je near .branch_759
    mov ebx, dword [esp + 0x18]
    mov edx, dword [esp + 8]
    mov ecx, dword [esp + 0x6c]
    sub ebx, edx
    mov eax, ecx
    add ebx, ecx
    sub eax, edx
    sub ebx, esi
    mov edx, eax
    sar edx, 2
    shl eax, 0x1e
    idiv ebx
    mov ecx, eax
    mov ebx, dword [edi + yb2]
    mov eax, dword [edi + yb1]
    sub eax, ebx
    mov ebx, ecx
    imul ebx
    shrd eax, edx, 0x1e
    mov edx, dword [edi + yb2]
    add edx, eax
    mov dword [esp + 0x58], edx
    mov eax, esi
    sub eax, dword [esp + 0x6c]
    imul ebx
    shrd eax, edx, 0x1e
    mov edx, dword [esp + 0x6c]
    mov ebx, dword [edi + xb1]
    add edx, eax
    mov eax, dword [edi + xb2]
    sub eax, ebx
    mov dword [esp + 0x4c], edx
    mov dword [esp + 0x14], eax
    mov ebx, ecx
    mov eax, dword [edi + yb1]
    mov ecx, dword [esp + 0x58]
    imul ebx
    shrd eax, edx, 0x1e
    mov ebx, dword [esp + 0x14]
    imul ebx
    idiv ecx
    mov ecx, dword [edi + xb1]
    mov edx, dword [esp + 0x1c]
    add eax, ecx
    cmp edx, 2
    jne short .branch_6e6
    cmp eax, ecx
    jl short .branch_6cf
    mov esi, dword [esp + 0x4c]
    mov edx, dword [esp + 0x58]
    mov dword [esp + 0x50], eax
    mov dword [esp + 0x30], edx

.branch_6cf:
    mov ecx, dword [ebp*4 + xb2]
    sub ecx, eax
    add eax, eax
    mov ebx, dword [esp]
    lea edi, [eax + 2]
    add ecx, ecx
    add edi, ebx
    jmp short .branch_71a

.branch_6e6:
    cmp eax, dword [edi + xb2]
    jg short .branch_702
    mov edx, dword [esp + 0x4c]
    mov dword [esp + 0x6c], edx
    mov edx, dword [esp + 0x58]
    mov dword [esp + 0x54], eax
    mov dword [esp + 0x24], edx

.branch_702:
    sub eax, dword [ebp*4 + xb1]
    add eax, eax
    mov edi, dword [ebp*4 + xb1]
    lea ecx, [eax + 2]
    add edi, edi
    add edi, dword [esp]

.branch_71a:
    xor eax, eax
    cmp ecx, 4
    jae short .branch_72e
    test cl, 1
    je short .branch_727
    stosb

.branch_727:
    shr ecx, 1
    db 0xf3                       ; REP precedes the operand-size prefix
    stosw
    jmp short .branch_759

.branch_72e:
    test edi, 1
    je short .branch_738
    stosb
    dec ecx

.branch_738:
    test edi, 2
    je short .branch_745
    stosw
    sub ecx, 2

.branch_745:
    mov ebx, ecx
    shr ecx, 2
    rep stosd
    test bl, 2
    je short .branch_753
    stosw

.branch_753:
    test bl, 1
    je short .branch_759
    stosb

.branch_759:
    test byte [esp + 0x68], 0xc
    je near .branch_8c3
    mov ebx, dword [esp + 0x20]
    mov ecx, dword [esp + 0x28]
    mov edi, dword [esp + 0x38]
    mov edx, dword [esp + 4]
    sub ebx, ecx
    mov eax, edi
    add ebx, edi
    sub eax, ecx
    sub ebx, edx
    mov edi, ebp
    mov edx, eax
    sar edx, 2
    shl eax, 0x1e
    idiv ebx
    shl edi, 2
    mov ecx, eax
    mov eax, dword [edi + yb1]
    mov edx, dword [edi + yb2]
    mov ebx, ecx
    sub eax, edx
    imul ebx
    shrd eax, edx, 0x1e
    mov edx, dword [edi + yb2]
    mov ebx, dword [esp + 0x38]
    add edx, eax
    mov eax, dword [esp + 4]
    sub eax, ebx
    mov ebx, ecx
    mov dword [esp + 0x58], edx
    imul ebx
    shrd eax, edx, 0x1e
    mov edx, dword [esp + 0x38]
    add edx, eax
    mov dword [esp + 0x4c], edx
    mov eax, dword [edi + xb2]
    mov edx, dword [edi + xb1]
    sub eax, edx
    mov dword [esp + 0x14], eax
    mov eax, dword [edi + yb1]
    mov ecx, dword [esp + 0x58]
    imul ebx
    shrd eax, edx, 0x1e
    mov ebx, dword [esp + 0x14]
    imul ebx
    idiv ecx
    mov edx, dword [esp + 0x68]
    mov ebx, dword [edi + xb1]
    and edx, 0xc
    add eax, ebx
    cmp edx, 8
    jne short .branch_841
    cmp eax, ebx
    jl short .branch_81b
    mov esi, dword [esp + 0x4c]
    mov dword [esp + 0x30], ecx
    mov dword [esp + 0x50], eax

.branch_81b:
    mov edx, dword [view_height]
    mov ebx, dword [view_height]
    mov ecx, dword [ebp*4 + xb2]
    mov ebp, dword [esp]
    shl edx, 0x10
    sub ecx, eax
    add eax, eax
    add edx, ebx
    lea edi, [eax + 2]
    add ecx, ecx
    jmp short .branch_882

.branch_841:
    cmp eax, dword [edi + xb2]
    jg short .branch_85d
    mov edx, dword [esp + 0x4c]
    mov dword [esp + 0x6c], edx
    mov edx, dword [esp + 0x58]
    mov dword [esp + 0x54], eax
    mov dword [esp + 0x24], edx

.branch_85d:
    mov edx, dword [view_height]
    mov edi, dword [view_height]
    mov ebx, dword [ebp*4 + xb1]
    mov ebp, dword [esp]
    sub eax, ebx
    shl edx, 0x10
    add eax, eax
    add edx, edi
    lea ecx, [eax + 2]
    lea edi, [ebx + ebx]

.branch_882:
    mov eax, edx
    add edi, ebp
    cmp ecx, 4
    jae short .branch_898
    test cl, 1
    je short .branch_891
    stosb

.branch_891:
    shr ecx, 1
    db 0xf3                       ; REP precedes the operand-size prefix
    stosw
    jmp short .branch_8c3

.branch_898:
    test edi, 1
    je short .branch_8a2
    stosb
    dec ecx

.branch_8a2:
    test edi, 2
    je short .branch_8af
    stosw
    sub ecx, 2

.branch_8af:
    mov ebx, ecx
    shr ecx, 2
    rep stosd
    test bl, 2
    je short .branch_8bd
    stosw

.branch_8bd:
    test bl, 1
    je short .branch_8c3
    stosb

.branch_8c3:
    mov ecx, dword [esp + 0x24]
    mov eax, dword [esp + 0x6c]
    mov ebx, dword [engine_286b00]
    imul ebx
    idiv ecx
    mov ecx, dword [esp + 0x30]
    mov ebx, dword [engine_286b00]
    mov edi, eax
    mov eax, esi
    shl edi, 4
    imul ebx
    idiv ecx
    mov ecx, dword [esp + 0x50]
    mov edx, eax
    mov eax, dword [esp + 0x54]
    shl edx, 4
    sub ecx, eax
    sub edx, edi
    inc ecx
    mov eax, edx
    sar edx, 0x1f
    idiv ecx
    mov ebp, dword [esp + 0x54]
    add ebp, ebp
    add ebp, dword [esp]
    mov edx, dword [globalhoriz]
    mov esi, eax
    shl edx, 0x10
    mov eax, ebp
    add edx, edi
    test ecx, ecx
    je short .branch_962
    test al, 2
    je short .branch_933
    mov ebx, edx
    sar ebx, 0x10
    mov word [eax], bx
    add edx, esi
    add eax, 2
    dec ecx
    je short .branch_962

.branch_933:
    sub ecx, 2
    jb short .branch_95a

.branch_938:
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
    jae short .branch_938
    test cl, 1
    je short .branch_962

.branch_95a:
    mov ebx, edx
    sar ebx, 0x10
    mov word [eax], bx

.branch_962:
    cmp word [ebp], 0
    jge short .branch_96f
    mov word [ebp], 0

.branch_96f:
    mov eax, dword [esp + 0x54]
    mov ecx, dword [esp]
    add eax, eax
    add eax, ecx
    mov esi, dword [view_height]
    movsx edx, word [eax]
    cmp edx, esi
    jle short .branch_991
    mov dx, word [view_height]
    mov word [eax], dx

.branch_991:
    mov eax, dword [esp + 0x50]
    mov edi, dword [esp]
    add eax, eax
    add eax, edi
    cmp word [eax], 0
    jge short .branch_9a7
    mov word [eax], 0

.branch_9a7:
    mov eax, dword [esp + 0x50]
    mov ebp, dword [esp]
    add eax, eax
    add eax, ebp
    mov ebx, dword [view_height]
    movsx edx, word [eax]
    cmp edx, ebx
    jle short .branch_9c9
    mov dx, word [view_height]
    mov word [eax], dx

.branch_9c9:
    mov eax, dword [esp + 0x68]

.branch_9cd:
    add esp, 0x74
    pop ebp
    pop edi
    pop esi
    ret

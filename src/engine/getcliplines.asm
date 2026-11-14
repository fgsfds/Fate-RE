; Collect wall and sprite clip lines for movement.
BITS 32
ORG 0x52c88

clipnum equ 0x289136
sqrtable equ 0x1dfa60
clipsectnum equ 0x28912e
clipsectorlist equ 0x195f50
sector equ 0x27c3a0
wall equ 0x2310a0
editstatus equ 0x14185
headspritesect equ 0x28891e
sprite equ 0x2040a0
tilesizy equ 0x1f4020
picanm equ 0x1ed3a0
sintable equ 0x2300a0
tilesizx equ 0x1f2020
rxi equ 0x1990b0
ryi equ 0x199110
nextspritesect equ 0x1f9ca0
rintersect equ 0x5272c
getflorzofslope equ 0x5df75
getceilzofslope equ 0x5de70
addclipline equ 0x53bed
clipinsideboxline equ 0x4c1b2
clipmove_return equ 0x52c82

getcliplines_:
    push esi
    push edi
    push ebp
    sub esp, 0x74
    push eax
    push edx
    push ebx
    xor edx, edx
    mov ebx, dword [esp + 0x94]
    mov word [clipnum], dx
    test bx, bx
    jl near .restore_stack
    add eax, ecx
    sar eax, 1
    mov edx, dword [esp + 0x90]
    mov dword [esp + 0x54], eax
    mov eax, dword [esp + 4]
    mov ebx, dword [esp + 8]
    add eax, edx
    sub ecx, ebx
    sar eax, 1
    mov dword [esp + 0x40], ecx
    mov dword [esp + 0x50], eax
    mov eax, edx
    mov edx, dword [esp + 0x40]
    imul edx, edx
    mov ecx, dword [esp + 4]
    sub eax, ecx
    mov dword [esp + 0x3c], eax
    imul eax, eax
    add eax, edx
    mov ebp, dword [esp + 0x98]
    test eax, eax
    jns short .branch_06c
    neg eax

.branch_06c:
    bsr ecx, eax
    cmp cl, 0xb
    jge short .branch_07e
    movzx eax, word [nosplit eax*2 + sqrtable]
    jmp short .branch_092

.branch_07e:
    sub cl, 9
    and cl, 0xfe
    sar eax, cl
    movzx eax, word [nosplit eax*2 + sqrtable]
    sar cl, 1
    shl eax, cl

.branch_092:
    sar eax, 0xa
    add eax, 0x400
    add eax, ebp
    add eax, 8
    mov dword [esp + 0x58], eax
    mov eax, dword [esp + 0x54]
    mov edx, dword [esp + 0x58]
    sub eax, edx
    mov dword [esp + 0x48], eax
    mov eax, dword [esp + 0x50]
    sub eax, edx
    mov dword [esp + 0x44], eax
    mov eax, dword [esp + 0x54]
    add eax, edx
    xor edi, edi
    mov dword [esp + 0x2c], eax
    mov eax, dword [esp + 0x50]
    mov dword [esp + 0x38], edi
    add eax, edx
    mov ecx, 1
    mov dword [esp + 0x4c], eax
    mov eax, dword [esp + 0x94]
    mov word [clipsectnum], cx
    mov word [clipsectorlist], ax

.test_wall_sector:
    mov ebp, dword [esp + 0x38]
    movsx eax, word [clipsectnum]
    cmp eax, ebp
    jle near .start_sprite_sectors
    movsx edx, word [nosplit ebp*2 + clipsectorlist]
    mov eax, edx
    shl eax, 2
    add eax, edx
    shl eax, 3
    add eax, sector
    movsx edx, word [eax]
    movsx eax, word [eax + 2]
    lea ebx, [edx + eax]
    mov esi, wall
    mov dword [esp + 0x6c], edx
    shl edx, 5
    mov dword [esp + 0x34], ebx
    add esi, edx
    jmp near .test_wall

.process_wall:
    movsx eax, word [esi + 8]
    mov edx, dword [esi]
    shl eax, 5
    mov dword [esp + 0x74], edx
    mov edx, dword [esi + 4]
    add eax, wall
    mov dword [esp + 0x70], edx
    mov edx, dword [eax]
    mov eax, dword [eax + 4]
    mov edi, dword [esp + 0x48]
    mov dword [esp + 0x64], eax
    mov eax, dword [esp + 0x74]
    mov dword [esp + 0x68], edx
    cmp eax, edi
    jge short .branch_173
    cmp edx, edi
    jl near .advance_wall

.branch_173:
    mov eax, dword [esp + 0x74]
    mov edx, dword [esp + 0x2c]
    cmp eax, edx
    jle short .branch_189
    cmp edx, dword [esp + 0x68]
    jl near .advance_wall

.branch_189:
    mov eax, dword [esp + 0x70]
    mov ecx, dword [esp + 0x44]
    cmp eax, ecx
    jge short .branch_19f
    cmp ecx, dword [esp + 0x64]
    jg near .advance_wall

.branch_19f:
    mov eax, dword [esp + 0x70]
    mov ebp, dword [esp + 0x4c]
    cmp eax, ebp
    jle short .branch_1b5
    cmp ebp, dword [esp + 0x64]
    jl near .advance_wall

.branch_1b5:
    mov ebp, dword [esp + 0x68]
    mov ebx, dword [esp + 0x74]
    mov ecx, dword [esp + 0x70]
    mov edx, dword [esp + 4]
    sub ebp, ebx
    sub edx, ecx
    imul edx, ebp
    mov eax, dword [esp + 0x64]
    sub eax, ecx
    mov dword [esp + 0x5c], eax
    mov eax, dword [esp + 8]
    mov ecx, dword [esp + 0x5c]
    sub eax, ebx
    imul eax, ecx
    cmp edx, eax
    jl near .advance_wall
    test ebp, ebp
    jle short .branch_1fb
    mov eax, dword [esp + 0x44]
    sub eax, dword [esp + 0x70]
    mov edx, ebp
    jmp short .branch_207

.branch_1fb:
    mov eax, dword [esp + 0x4c]
    mov edi, dword [esp + 0x70]
    mov edx, ebp
    sub eax, edi

.branch_207:
    imul edx, eax
    mov dword [esp + 0x24], edx
    mov ebx, dword [esp + 0x5c]
    test ebx, ebx
    jle short .branch_224
    mov eax, dword [esp + 0x2c]
    mov edi, dword [esp + 0x74]
    mov edx, ebx
    sub eax, edi
    jmp short .branch_230

.branch_224:
    mov eax, dword [esp + 0x48]
    mov ecx, dword [esp + 0x74]
    mov edx, ebx
    sub eax, ecx

.branch_230:
    imul edx, eax
    mov dword [esp + 0x20], edx
    mov eax, dword [esp + 0x24]
    cmp eax, dword [esp + 0x20]
    jge near .advance_wall
    xor cl, cl
    mov di, word [esi + 0xc]
    mov byte [esp + 0x7c], cl
    test di, di
    jge short .branch_259
    mov byte [esp + 0x7c], 1

.branch_259:
    cmp byte [esp + 0xa4], 0
    jne short .branch_275
    mov ax, word [esi + 0xe]
    xor ah, ah
    and al, 1
    cwde
    test eax, eax
    je short .branch_275
    mov byte [esp + 0x7c], 1

.branch_275:
    xor eax, eax
    mov al, byte [esp + 0xa4]
    cmp eax, 1
    jne short .branch_295
    mov ax, word [esi + 0xe]
    xor ah, ah
    and al, 0x40
    cwde
    test eax, eax
    je short .branch_295
    mov byte [esp + 0x7c], 1

.branch_295:
    movsx edx, word [esi + 0xc]
    mov eax, edx
    shl eax, 2
    add eax, edx
    mov edi, sector
    shl eax, 3
    add edi, eax
    cmp word [editstatus], 0
    jne near .branch_3da
    lea eax, [esp + 0x28]
    push eax
    lea eax, [esp + 0x24]
    push eax
    lea eax, [esp + 0x2c]
    push eax
    mov ebx, dword [esp + 0x70]
    push ebx
    mov ecx, dword [esp + 0x78]
    push ecx
    mov eax, dword [esp + 0x84]
    push eax
    mov edx, dword [esp + 0x8c]
    push edx
    mov ebx, dword [esp + 0x58]
    push 0
    mov ecx, dword [esp + 0x60]
    mov eax, dword [esp + 0x28]
    push ebx
    mov edx, dword [esp + 0x28]
    xor ebx, ebx
    call rintersect
    test eax, eax
    jne short .branch_30f
    mov eax, dword [esp + 8]
    mov dword [esp + 0x24], eax
    mov eax, dword [esp + 4]
    mov dword [esp + 0x20], eax

.branch_30f:
    mov eax, dword [esp + 0x38]
    mov ebx, dword [esp + 0x20]
    mov edx, dword [esp + 0x24]
    movsx eax, word [nosplit eax*2 + clipsectorlist]
    call getflorzofslope
    mov ebx, dword [esp + 0x20]
    mov dword [esp + 0x28], eax
    mov edx, dword [esp + 0x24]
    movsx eax, word [esi + 0xc]
    call getflorzofslope
    mov edx, dword [esp + 0x28]
    sub edx, 0x100
    cmp eax, edx
    jge short .branch_371
    mov dx, word [edi + 0xe]
    xor dh, dh
    and dl, 1
    movsx edx, dx
    test edx, edx
    jne short .branch_371
    mov edx, dword [esp + 0xa0]
    dec edx
    mov ecx, dword [esp]
    sub eax, edx
    cmp eax, ecx
    jg short .branch_371
    mov byte [esp + 0x7c], 1

.branch_371:
    cmp byte [esp + 0x7c], 0
    jne short .branch_3da
    mov eax, dword [esp + 0x38]
    mov ebx, dword [esp + 0x20]
    mov edx, dword [esp + 0x24]
    movsx eax, word [nosplit eax*2 + clipsectorlist]
    call getceilzofslope
    mov ebx, dword [esp + 0x20]
    mov dword [esp + 0x28], eax
    mov edx, dword [esp + 0x24]
    movsx eax, word [esi + 0xc]
    call getceilzofslope
    mov edx, dword [esp + 0x28]
    add edx, 0x100
    cmp eax, edx
    jle short .branch_3da
    mov dx, word [edi + 0xc]
    xor dh, dh
    and dl, 1
    movsx edx, dx
    test edx, edx
    jne short .branch_3da
    mov edx, dword [esp + 0x9c]
    dec edx
    mov edi, dword [esp]
    add eax, edx
    cmp eax, edi
    jl short .branch_3da
    mov byte [esp + 0x7c], 1

.branch_3da:
    cmp byte [esp + 0x7c], 0
    je near .branch_4fb
    mov eax, dword [esp + 0x40]
    mov edi, dword [esp + 0x98]
    test eax, eax
    jge short .branch_3f6
    neg edi

.branch_3f6:
    movsx eax, word [esp + 0x6c]
    mov ecx, dword [esp + 0x70]
    add eax, 0x8000
    mov edx, dword [esp + 0x70]
    mov dword [esp + 0x30], eax
    push eax
    mov eax, dword [esp + 0x78]
    add ecx, edi
    sub eax, edi
    sub edx, edi
    mov ebx, eax
    call addclipline
    mov ebx, dword [esp + 0x30]
    mov ecx, dword [esp + 0x64]
    mov eax, dword [esp + 0x68]
    mov edx, dword [esp + 0x64]
    push ebx
    add ecx, edi
    sub eax, edi
    sub edx, edi
    mov ebx, eax
    call addclipline
    mov ecx, dword [esp + 0x3c]
    mov edi, dword [esp + 0x98]
    test ecx, ecx
    jge short .branch_44d
    neg edi

.branch_44d:
    movsx eax, word [esp + 0x6c]
    mov edx, dword [esp + 0x70]
    mov ebx, dword [esp + 0x74]
    add eax, 0x8000
    sub edx, edi
    sub ebx, edi
    mov dword [esp + 0x30], eax
    push eax
    mov eax, dword [esp + 0x78]
    mov ecx, edx
    add eax, edi
    call addclipline
    mov edx, dword [esp + 0x30]
    mov ebx, dword [esp + 0x68]
    mov eax, dword [esp + 0x68]
    push edx
    mov edx, dword [esp + 0x68]
    sub ebx, edi
    sub edx, edi
    add eax, edi
    mov ecx, edx
    call addclipline
    mov eax, dword [esp + 0x98]
    mov ebx, dword [esp + 0x5c]
    mov dword [esp + 0x24], eax
    test ebx, ebx
    jle short .branch_4ae
    mov ecx, eax
    neg ecx
    mov dword [esp + 0x24], ecx

.branch_4ae:
    mov eax, dword [esp + 0x98]
    mov dword [esp + 0x20], eax
    test ebp, ebp
    jge short .branch_4c5
    mov edi, eax
    neg edi
    mov dword [esp + 0x20], edi

.branch_4c5:
    movsx eax, word [esp + 0x6c]
    mov ecx, dword [esp + 0x64]
    mov ebp, dword [esp + 0x20]
    mov ebx, dword [esp + 0x68]
    mov edx, dword [esp + 0x70]
    add eax, 0x8000
    add ecx, ebp
    add edx, ebp
    push eax
    mov eax, dword [esp + 0x28]
    mov ebp, dword [esp + 0x28]
    add ebx, eax
    mov eax, dword [esp + 0x78]
    add eax, ebp
    call addclipline
    jmp short .advance_wall

.branch_4fb:
    movsx eax, word [clipsectnum]
    dec eax
    mov dword [esp + 0x78], eax
    jmp short .branch_51e

.branch_509:
    mov cx, word [esi + 0xc]
    cmp cx, word [nosplit eax*2 + clipsectorlist]
    je short .branch_526
    lea edx, [eax - 1]
    mov dword [esp + 0x78], edx

.branch_51e:
    mov eax, dword [esp + 0x78]
    test eax, eax
    jge short .branch_509

.branch_526:
    cmp dword [esp + 0x78], 0
    jge short .advance_wall
    mov dx, word [clipsectnum]
    movsx eax, dx
    inc edx
    mov word [clipsectnum], dx
    mov dx, word [esi + 0xc]
    mov word [nosplit eax*2 + clipsectorlist], dx

.advance_wall:
    mov ecx, dword [esp + 0x6c]
    inc ecx
    add esi, 0x20
    mov dword [esp + 0x6c], ecx

.test_wall:
    mov eax, dword [esp + 0x6c]
    cmp eax, dword [esp + 0x34]
    jl near .process_wall
    inc dword [esp + 0x38]
    jmp near .test_wall_sector

.start_sprite_sectors:
    xor eax, eax
    mov dword [esp + 0x78], eax
    jmp near .test_sprite_sector

.get_sprite_head:
    movsx eax, word [nosplit edx*2 + clipsectorlist]
    movsx eax, word [nosplit eax*2 + headspritesect]
    jmp near .branch_f33

.process_sprite:
    imul ebp, ebx, 0x2c
    add ebp, sprite
    movsx eax, word [ebp + 0xc]
    mov dword [esp + 0x60], eax
    cmp byte [esp + 0xa4], 0
    jne short .branch_5b0
    test byte [esp + 0x60], 1
    jne short .branch_5cd

.branch_5b0:
    xor eax, eax
    mov al, byte [esp + 0xa4]
    cmp eax, 1
    jne near .advance_sprite
    test byte [esp + 0x61], 1
    je near .advance_sprite

.branch_5cd:
    mov eax, dword [ebp]
    mov dword [esp + 0x74], eax
    mov eax, dword [ebp + 4]
    mov dword [esp + 0x70], eax
    mov eax, dword [esp + 0x60]
    and eax, 0x30
    cmp eax, 0x10
    jb short .face_sprite
    jbe near .wall_sprite
    cmp eax, 0x20
    je near .floor_sprite
    jmp near .advance_sprite

.face_sprite:
    test eax, eax
    jne near .advance_sprite
    mov eax, dword [esp + 0x74]
    cmp eax, dword [esp + 0x48]
    jl near .advance_sprite
    cmp eax, dword [esp + 0x2c]
    jg near .advance_sprite
    mov eax, dword [esp + 0x70]
    cmp eax, dword [esp + 0x44]
    jl near .advance_sprite
    cmp eax, dword [esp + 0x4c]
    jg near .advance_sprite
    movsx eax, word [ebp + 0xe]
    movsx edx, word [nosplit eax*2 + tilesizy]
    xor eax, eax
    mov al, byte [ebp + 0x15]
    mov ecx, eax
    imul ecx, edx
    mov bl, byte [esp + 0x60]
    shl ecx, 2
    test bl, 0x80
    je short .branch_664
    mov eax, ecx
    mov edx, dword [ebp + 8]
    sar eax, 1
    add edx, eax
    mov dword [esp + 0x28], edx
    jmp short .branch_66b

.branch_664:
    mov eax, dword [ebp + 8]
    mov dword [esp + 0x28], eax

.branch_66b:
    movsx eax, word [ebp + 0xe]
    shl eax, 2
    test byte [eax + picanm+2], 0xff
    je short .branch_6a1
    mov eax, dword [eax + picanm]
    sar eax, 0x10
    and eax, 0xff
    movsx edx, al
    xor eax, eax
    mov al, byte [ebp + 0x15]
    imul eax, edx
    mov esi, dword [esp + 0x28]
    shl eax, 2
    sub esi, eax
    mov dword [esp + 0x28], esi

.branch_6a1:
    mov eax, dword [esp + 0x28]
    mov edx, dword [esp + 0x9c]
    mov edi, dword [esp + 0x28]
    sub eax, ecx
    add edi, edx
    sub eax, dword [esp + 0xa0]
    mov edx, dword [esp]
    mov dword [esp + 0x28], edi
    cmp edx, edi
    jge near .advance_sprite
    cmp eax, edx
    jge near .advance_sprite
    movzx edi, byte [ebp + 0x12]
    mov esi, dword [esp + 0x98]
    shl edi, 2
    mov eax, dword [esp + 0x40]
    add edi, esi
    test eax, eax
    jge short .branch_6ec
    neg edi

.branch_6ec:
    movsx eax, word [esp + 0x6c]
    mov ecx, dword [esp + 0x70]
    add eax, 0xc000
    mov edx, dword [esp + 0x70]
    push eax
    mov eax, dword [esp + 0x78]
    add ecx, edi
    sub eax, edi
    sub edx, edi
    mov ebx, eax
    call addclipline
    xor eax, eax
    mov al, byte [ebp + 0x12]
    mov edi, dword [esp + 0x98]
    shl eax, 2
    mov edx, dword [esp + 0x3c]
    add edi, eax
    test edx, edx
    jge short .branch_72b
    neg edi

.branch_72b:
    movsx eax, word [esp + 0x6c]
    mov edx, dword [esp + 0x70]
    mov ebx, dword [esp + 0x74]
    add eax, 0xc000
    sub edx, edi
    sub ebx, edi
    push eax
    mov eax, dword [esp + 0x78]
    mov ecx, edx
    add eax, edi
    jmp near .add_sprite_clipline

.wall_sprite:
    movsx ecx, word [ebp + 0xe]
    xor edx, edx
    movsx ecx, word [nosplit ecx*2 + tilesizy]
    mov dl, byte [ebp + 0x15]
    imul ecx, edx
    mov al, byte [esp + 0x60]
    shl ecx, 2
    test al, 0x80
    je short .branch_77d
    mov eax, ecx
    mov edx, dword [ebp + 8]
    sar eax, 1
    add edx, eax
    mov dword [esp + 0x28], edx
    jmp short .branch_784

.branch_77d:
    mov eax, dword [ebp + 8]
    mov dword [esp + 0x28], eax

.branch_784:
    movsx eax, word [ebp + 0xe]
    shl eax, 2
    test byte [eax + picanm+2], 0xff
    je short .branch_7ba
    mov eax, dword [eax + picanm]
    sar eax, 0x10
    and eax, 0xff
    movsx edx, al
    xor eax, eax
    mov al, byte [ebp + 0x15]
    imul eax, edx
    mov edx, dword [esp + 0x28]
    shl eax, 2
    sub edx, eax
    mov dword [esp + 0x28], edx

.branch_7ba:
    mov eax, dword [esp + 0x28]
    mov edx, dword [esp + 0x9c]
    mov ebx, dword [esp + 0x28]
    sub eax, ecx
    add ebx, edx
    mov ecx, dword [esp + 0xa0]
    mov edx, dword [esp]
    mov dword [esp + 0x28], ebx
    sub eax, ecx
    cmp edx, ebx
    jge near .advance_sprite
    cmp eax, edx
    jge near .advance_sprite
    movsx ebx, word [ebp + 0xe]
    mov eax, dword [ebx*4 + picanm]
    sar eax, 8
    and eax, 0xff
    movsx edx, al
    movsx eax, byte [ebp + 0x16]
    add eax, edx
    mov edx, dword [esp + 0x60]
    and edx, 4
    test edx, edx
    jle short .branch_816
    neg eax

.branch_816:
    movsx ecx, word [ebp + 0x1c]
    mov edx, ecx
    and edx, 0x7ff
    movzx esi, byte [ebp + 0x14]
    movsx edx, word [nosplit edx*2 + sintable]
    imul edx, esi
    mov dword [esp + 0x24], edx
    lea edx, [ecx + 0x600]
    and edx, 0x7ff
    movsx edx, word [nosplit edx*2 + sintable]
    imul edx, esi
    movsx esi, word [nosplit ebx*2 + tilesizx]
    mov ecx, esi
    sar ecx, 1
    add ecx, eax
    mov eax, dword [esp + 0x24]
    mov ebx, ecx
    mov dword [esp + 0x20], edx
    imul ebx
    shrd eax, edx, 0x10
    mov edx, dword [esp + 0x74]
    mov ebx, esi
    sub edx, eax
    mov eax, dword [esp + 0x24]
    mov dword [esp + 0x74], edx
    imul ebx
    shrd eax, edx, 0x10
    mov edx, dword [esp + 0x74]
    mov ebx, ecx
    add edx, eax
    mov eax, dword [esp + 0x20]
    mov dword [esp + 0x68], edx
    imul ebx
    shrd eax, edx, 0x10
    mov ebx, dword [esp + 0x70]
    mov ecx, dword [esp + 0x58]
    sub ebx, eax
    mov eax, dword [esp + 0x20]
    mov dword [esp + 0x70], ebx
    mov ebx, esi
    mov edi, dword [esp + 0x68]
    imul ebx
    shrd eax, edx, 0x10
    mov edx, dword [esp + 0x70]
    push ecx
    add edx, eax
    mov ebx, dword [esp + 0x78]
    push edx
    mov ecx, dword [esp + 0x78]
    mov eax, dword [esp + 0x5c]
    push edi
    mov dword [esp + 0x70], edx
    mov edx, dword [esp + 0x5c]
    call clipinsideboxline
    test eax, eax
    je near .advance_sprite
    movsx eax, word [ebp + 0x1c]
    add eax, 0x300
    and eax, 0x7ff
    mov ax, word [nosplit eax*2 + sintable]
    mov ebx, dword [esp + 0x98]
    cwde
    imul ebx
    shrd eax, edx, 0xe
    mov dword [esp + 0x24], eax
    movsx eax, word [ebp + 0x1c]
    add eax, 0x100
    and eax, 0x7ff
    mov ax, word [nosplit eax*2 + sintable]
    mov ecx, dword [esp + 4]
    cwde
    mov ebp, dword [esp + 8]
    imul ebx
    shrd eax, edx, 0xe
    mov ebx, dword [esp + 0x74]
    mov edx, dword [esp + 0x64]
    sub ebx, ebp
    sub edx, ecx
    mov ecx, ebx
    imul ecx, edx
    mov ebx, edi
    mov edi, dword [esp + 4]
    mov edx, dword [esp + 0x70]
    sub ebx, ebp
    sub edx, edi
    imul edx, ebx
    mov dword [esp + 0x20], eax
    cmp ecx, edx
    jl short .branch_97f
    movsx edx, word [esp + 0x6c]
    mov ecx, dword [esp + 0x64]
    mov edi, dword [esp + 0x24]
    add edx, 0xc000
    mov ebx, dword [esp + 0x68]
    push edx
    mov edx, dword [esp + 0x74]
    add ebx, eax
    add edx, eax
    mov eax, dword [esp + 0x78]
    sub ecx, edi
    add eax, edi
    jmp short .branch_9b2

.branch_97f:
    test byte [esp + 0x60], 0x40
    jne near .advance_sprite
    movsx edx, word [esp + 0x6c]
    mov ecx, dword [esp + 0x70]
    mov ebp, dword [esp + 0x24]
    add edx, 0xc000
    mov ebx, dword [esp + 0x74]
    push edx
    mov edx, dword [esp + 0x68]
    sub ebx, eax
    sub edx, eax
    mov eax, dword [esp + 0x6c]
    add ecx, ebp
    sub eax, ebp

.branch_9b2:
    call addclipline
    mov edx, dword [esp + 0x68]
    mov eax, dword [esp + 0x74]
    mov ebx, dword [esp + 0x74]
    sub edx, eax
    mov eax, dword [esp + 8]
    sub eax, ebx
    imul edx, eax
    mov ecx, dword [esp + 0x70]
    mov ebx, dword [esp + 0x64]
    mov eax, dword [esp + 4]
    sub ebx, ecx
    sub eax, ecx
    imul eax, ebx
    add eax, edx
    test eax, eax
    jge short .branch_a13
    movsx eax, word [esp + 0x6c]
    mov edi, dword [esp + 0x20]
    mov ebx, dword [esp + 0x74]
    mov ebp, dword [esp + 0x24]
    mov edx, dword [esp + 0x70]
    add eax, 0xc000
    add ecx, edi
    add ebx, ebp
    push eax
    mov eax, dword [esp + 0x78]
    add edx, ebp
    sub eax, edi
    jmp near .add_sprite_clipline

.branch_a13:
    mov ebx, dword [esp + 0x74]
    mov edi, dword [esp + 0x68]
    mov eax, dword [esp + 8]
    sub ebx, edi
    sub eax, edi
    imul ebx, eax
    mov edx, ecx
    mov eax, dword [esp + 0x64]
    mov ecx, dword [esp + 0x64]
    sub edx, eax
    mov eax, dword [esp + 4]
    sub eax, ecx
    imul eax, edx
    add eax, ebx
    test eax, eax
    jge near .advance_sprite
    movsx eax, word [esp + 0x6c]
    mov esi, dword [esp + 0x20]
    mov edx, dword [esp + 0x64]
    mov ebx, edi
    mov edi, dword [esp + 0x24]
    add eax, 0xc000
    sub ecx, esi
    push eax
    sub ebx, edi
    mov eax, dword [esp + 0x6c]
    sub edx, edi
    add eax, esi
    jmp near .add_sprite_clipline

.floor_sprite:
    mov edi, dword [esp + 0x9c]
    mov eax, dword [ebp + 8]
    add eax, edi
    mov dword [esp + 0x28], eax
    mov edx, dword [esp + 0xa0]
    mov eax, dword [ebp + 8]
    mov ebx, dword [esp + 0x28]
    sub eax, edx
    mov edx, dword [esp]
    cmp edx, ebx
    jge near .advance_sprite
    cmp eax, edx
    jge near .advance_sprite
    mov bl, byte [esp + 0x60]
    test bl, 0x40
    je short .branch_ac8
    cmp edx, dword [ebp + 8]
    setg al
    xor edx, edx
    mov dl, al
    test bl, 8
    sete al
    and eax, 0xff
    cmp edx, eax
    je near .advance_sprite

.branch_ac8:
    movsx ebx, word [ebp + 0xe]
    mov eax, dword [ebx*4 + picanm]
    sar eax, 8
    and eax, 0xff
    movsx edx, al
    movsx eax, byte [ebp + 0x16]
    add eax, edx
    mov edx, dword [ebx*4 + picanm]
    sar edx, 0x10
    and edx, 0xff
    movsx ecx, dl
    movsx edx, byte [ebp + 0x17]
    add edx, ecx
    mov ecx, dword [esp + 0x60]
    and ecx, 4
    test ecx, ecx
    jle short .branch_b0a
    neg eax

.branch_b0a:
    mov ecx, dword [esp + 0x60]
    and ecx, 8
    test ecx, ecx
    jle short .branch_b17
    neg edx

.branch_b17:
    movsx ecx, word [ebp + 0x1c]
    lea esi, [ecx + 0x200]
    movsx ecx, word [nosplit ecx*2 + sintable]
    mov dword [esp + 0x10], ecx
    movsx ecx, word [nosplit ebx*2 + tilesizx]
    movsx ebx, word [nosplit ebx*2 + tilesizy]
    mov dword [esp + 0x18], ebx
    xor ebx, ebx
    mov bl, byte [ebp + 0x15]
    mov dword [esp + 0x1c], ecx
    mov dword [esp + 0xc], ebx
    mov ebx, dword [esp + 0x1c]
    xor ecx, ecx
    sar ebx, 1
    mov cl, byte [ebp + 0x14]
    add eax, ebx
    imul eax, ecx
    mov dword [esp + 0x24], eax
    mov eax, dword [esp + 0x18]
    sar eax, 1
    add eax, edx
    mov edx, dword [esp + 0xc]
    imul edx, eax
    and esi, 0x7ff
    movsx esi, word [nosplit esi*2 + sintable]
    mov dword [esp + 0x14], esi
    mov ebx, dword [esp + 0x24]
    mov eax, dword [esp + 0x10]
    mov edi, edx
    mov dword [esp + 0x20], edx
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0x10
    mov edx, dword [esp + 0x74]
    mov esi, dword [esp + 0x14]
    mov edi, dword [esp + 0x24]
    mov ebx, dword [esp + 0x20]
    neg esi
    add edx, eax
    mov eax, dword [esp + 0x10]
    mov dword [rxi], edx
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0x10
    mov ebx, dword [esp + 0x1c]
    imul ebx, ecx
    mov edx, dword [esp + 0x70]
    add edx, eax
    mov eax, dword [esp + 0x10]
    mov dword [ryi], edx
    imul ebx
    shrd eax, edx, 0x10
    mov edx, dword [rxi]
    mov edi, dword [esp + 0xc]
    sub edx, eax
    mov eax, dword [esp + 0x14]
    mov dword [0x1990b4], edx
    imul ebx
    shrd eax, edx, 0x10
    mov ebx, dword [esp + 0x18]
    imul ebx, edi
    mov edx, dword [ryi]
    add eax, edx
    mov dword [0x199114], eax
    mov eax, dword [esp + 0x14]
    imul ebx
    shrd eax, edx, 0x10
    mov ecx, eax
    mov eax, dword [0x1990b4]
    neg ecx
    add eax, ecx
    mov dword [0x1990b8], eax
    mov eax, dword [rxi]
    add ecx, eax
    mov eax, dword [esp + 0x10]
    mov dword [0x1990bc], ecx
    imul ebx
    shrd eax, edx, 0x10
    mov ecx, eax
    mov eax, dword [0x199114]
    neg ecx
    add eax, ecx
    mov dword [0x199118], eax
    mov eax, dword [ryi]
    add ecx, eax
    mov dword [0x19911c], ecx
    movsx eax, word [ebp + 0x1c]
    add eax, 0x100
    and eax, 0x7ff
    mov ax, word [nosplit eax*2 + sintable]
    mov ebx, dword [esp + 0x98]
    cwde
    imul ebx
    shrd eax, edx, 0xe
    mov dword [esp + 0x24], eax
    movsx eax, word [ebp + 0x1c]
    sub eax, 0x100
    and eax, 0x7ff
    mov ax, word [nosplit eax*2 + sintable]
    cwde
    mov ebp, dword [esp + 4]
    imul ebx
    shrd eax, edx, 0xe
    mov ebx, dword [esp + 8]
    mov edx, dword [0x199114]
    mov dword [esp + 0x20], eax
    mov eax, dword [rxi]
    sub edx, ebp
    sub eax, ebx
    imul edx, eax
    mov eax, dword [0x1990b4]
    sub eax, ebx
    mov ebx, dword [ryi]
    sub ebx, ebp
    imul eax, ebx
    cmp edx, eax
    jge short .branch_d4f
    mov ebp, dword [esp + 0x58]
    push ebp
    mov eax, dword [ryi]
    mov edx, dword [rxi]
    push eax
    mov ecx, dword [0x199114]
    mov ebx, dword [0x1990b4]
    push edx
    mov eax, dword [esp + 0x60]
    mov edx, dword [esp + 0x5c]
    call clipinsideboxline
    test eax, eax
    je near .branch_dea
    movsx eax, word [esp + 0x6c]
    mov ebx, dword [esp + 0x20]
    mov esi, dword [esp + 0x24]
    mov ebp, dword [esp + 0x20]
    mov ecx, dword [ryi]
    mov edx, dword [0x199114]
    add eax, 0xc000
    add ecx, ebx
    add edx, esi
    mov ebx, dword [rxi]
    push eax
    mov eax, dword [0x1990b4]
    add ebx, esi
    sub eax, ebp
    jmp near .branch_de5

.branch_d4f:
    mov edi, dword [esp + 8]
    mov ebx, dword [0x1990b8]
    mov eax, dword [0x19911c]
    sub ebx, edi
    sub eax, ebp
    imul ebx, eax
    mov edx, dword [0x1990bc]
    mov eax, dword [0x199118]
    sub edx, edi
    sub eax, ebp
    imul eax, edx
    cmp ebx, eax
    jge short .branch_dea
    mov esi, dword [esp + 0x58]
    push esi
    mov edi, dword [0x199118]
    mov edx, dword [esp + 0x54]
    push edi
    mov ebp, dword [0x1990b8]
    mov eax, dword [esp + 0x5c]
    push ebp
    mov ecx, dword [0x19911c]
    mov ebx, dword [0x1990bc]
    call clipinsideboxline
    test eax, eax
    je short .branch_dea
    movsx eax, word [esp + 0x6c]
    mov edx, dword [esp + 0x24]
    mov esi, dword [esp + 0x24]
    mov edi, dword [esp + 0x20]
    mov ecx, dword [0x199118]
    mov ebx, dword [0x1990b8]
    add eax, 0xc000
    sub ebx, edx
    push eax
    mov eax, dword [esp + 0x24]
    mov edx, dword [0x19911c]
    sub ecx, eax
    mov eax, dword [0x1990bc]
    sub edx, esi
    add eax, edi

.branch_de5:
    call addclipline

.branch_dea:
    mov eax, dword [esp + 8]
    mov edx, dword [0x1990b4]
    mov ebx, dword [esp + 4]
    sub edx, eax
    mov eax, dword [0x199118]
    sub eax, ebx
    imul edx, eax
    mov ecx, dword [esp + 8]
    mov esi, dword [esp + 4]
    mov ebx, dword [0x1990b8]
    mov eax, dword [0x199114]
    sub ebx, ecx
    sub eax, esi
    imul eax, ebx
    cmp edx, eax
    jge short .branch_e90
    mov ebp, dword [esp + 0x58]
    push ebp
    mov eax, dword [0x199114]
    mov edx, dword [0x1990b4]
    push eax
    mov ecx, dword [0x199118]
    mov ebx, dword [0x1990b8]
    push edx
    mov eax, dword [esp + 0x60]
    mov edx, dword [esp + 0x5c]
    call clipinsideboxline
    test eax, eax
    je near .advance_sprite
    movsx eax, word [esp + 0x6c]
    mov ebx, dword [esp + 0x24]
    mov esi, dword [esp + 0x20]
    mov ebp, dword [esp + 0x24]
    mov ecx, dword [0x199114]
    mov edx, dword [0x199118]
    add eax, 0xc000
    add ecx, ebx
    sub edx, esi
    mov ebx, dword [0x1990b4]
    push eax
    mov eax, dword [0x1990b8]
    sub ebx, esi
    sub eax, ebp
    jmp near .add_sprite_clipline

.branch_e90:
    mov ebx, dword [0x1990bc]
    mov eax, dword [ryi]
    sub ebx, ecx
    sub eax, esi
    imul ebx, eax
    mov edx, dword [rxi]
    mov eax, dword [0x19911c]
    sub edx, ecx
    sub eax, esi
    imul eax, edx
    cmp ebx, eax
    jge short .advance_sprite
    mov esi, dword [esp + 0x58]
    push esi
    mov edi, dword [0x19911c]
    mov edx, dword [esp + 0x54]
    push edi
    mov ebp, dword [0x1990bc]
    mov eax, dword [esp + 0x5c]
    push ebp
    mov ecx, dword [ryi]
    mov ebx, dword [rxi]
    call clipinsideboxline
    test eax, eax
    je short .advance_sprite
    movsx eax, word [esp + 0x6c]
    mov edx, dword [esp + 0x20]
    mov esi, dword [esp + 0x20]
    mov edi, dword [esp + 0x24]
    mov ecx, dword [0x19911c]
    mov ebx, dword [0x1990bc]
    add eax, 0xc000
    add ebx, edx
    push eax
    mov eax, dword [esp + 0x28]
    mov edx, dword [ryi]
    sub ecx, eax
    mov eax, dword [rxi]
    add edx, esi
    add eax, edi

.add_sprite_clipline:
    call addclipline

.advance_sprite:
    mov eax, dword [esp + 0x6c]
    movsx eax, word [nosplit eax*2 + nextspritesect]

.branch_f33:
    mov dword [esp + 0x6c], eax
    mov ebx, dword [esp + 0x6c]
    test ebx, ebx
    jge near .process_sprite
    inc dword [esp + 0x78]

.test_sprite_sector:
    mov edx, dword [esp + 0x78]
    movsx eax, word [clipsectnum]
    cmp eax, edx
    jg near .get_sprite_head

.restore_stack:
    add esp, 0x80
    jmp clipmove_return

; Project a constant-height wall edge into screen columns.
BITS 32
ORG 0x5e350

globalhoriz equ 0x286ae4
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
engine_286acc equ 0x286acc
engine_286afc equ 0x286afc
engine_286b00 equ 0x286b00
owallmost equ 0x5e350

owallmost_:
    push ecx
    push esi
    push edi
    push ebp
    sub esp, 0x38
    mov ebp, eax
    mov dword [esp + 0x28], edx
    mov esi, ebx
    mov eax, dword [engine_286acc]
    mov ebx, dword [edx*4 + yb2]
    mov edi, edx
    imul ebx
    shrd eax, edx, 0x14
    mov dword [esp + 0x10], eax
    mov ebx, dword [edi*4 + yb1]
    mov eax, dword [engine_286acc]
    imul ebx
    shrd eax, edx, 0x14
    mov ecx, eax
    mov dword [esp + 4], eax
    mov ebx, dword [edi*4 + yb2]
    mov eax, dword [engine_286afc]
    imul ebx
    shrd eax, edx, 0x14
    mov dword [esp + 0x18], eax
    mov ebx, dword [edi*4 + yb1]
    mov eax, dword [engine_286afc]
    shl esi, 7
    imul ebx
    shrd eax, edx, 0x14
    mov dword [esp + 8], eax
    cmp esi, ecx
    setl al
    mov edx, eax
    and edx, 0xff
    mov ebx, dword [esp + 0x10]
    add edx, edx
    cmp esi, ebx
    setl al
    and eax, 0xff
    mov ecx, dword [esp + 0x18]
    add edx, eax
    cmp esi, ecx
    setg al
    and eax, 0xff
    shl eax, 2
    mov edi, dword [esp + 8]
    add edx, eax
    cmp esi, edi
    setg al
    and eax, 0xff
    mov edi, dword [esp + 0x28]
    shl eax, 3
    shl edi, 2
    add edx, eax
    mov eax, dword [edi + xb1]
    mov dword [esp + 0x2c], eax
    mov eax, dword [edi + yb2]
    mov dword [esp + 0x1c], eax
    mov eax, dword [edi + xb2]
    mov dword [esp + 0x24], eax
    mov eax, dword [edi + yb1]
    mov dword [esp + 0x20], eax
    mov eax, edx
    mov dword [esp + 0x34], edx
    and eax, 3
    mov edx, dword [esp + 0x2c]
    mov dword [esp + 0xc], eax
    mov eax, dword [esp + 0x24]
    sub eax, edx
    add eax, eax
    lea ecx, [eax + 2]
    lea ebx, [edx + edx]
    mov eax, dword [esp + 0xc]
    add ebx, ebp
    cmp eax, 3
    jne short .branch_152
    mov edi, ebx
    xor eax, eax

.branch_110:
    cmp ecx, 4
    jae short .branch_122
    test cl, 1
    je short .branch_11b
    stosb

.branch_11b:
    shr ecx, 1
    db 0xf3                       ; REP precedes the operand-size prefix
    stosw
    jmp short .branch_14d

.branch_122:
    test edi, 1
    je short .branch_12c
    stosb
    dec ecx

.branch_12c:
    test edi, 2
    je short .branch_139
    stosw
    sub ecx, 2

.branch_139:
    mov ebx, ecx
    shr ecx, 2
    rep stosd
    test bl, 2
    je short .branch_147
    stosw

.branch_147:
    test bl, 1
    je short .branch_14d
    stosb

.branch_14d:
    jmp near .branch_4c8

.branch_152:
    mov eax, dword [esp + 0x34]
    and eax, 0xc
    cmp eax, 0xc
    jne short .branch_172
    mov eax, dword [view_height]
    mov esi, dword [view_height]
    shl eax, 0x10
    mov edi, ebx
    add eax, esi
    jmp short .branch_110

.branch_172:
    test byte [esp + 0x34], 3
    je near .branch_286
    mov ebx, dword [esp + 4]
    mov edx, dword [esp + 0x10]
    mov eax, esi
    sub ebx, edx
    sub eax, edx
    mov edx, eax
    sar edx, 2
    shl eax, 0x1e
    idiv ebx
    mov ecx, eax
    mov edx, dword [edi + yb2]
    mov eax, dword [edi + yb1]
    mov ebx, ecx
    sub eax, edx
    imul ebx
    shrd eax, edx, 0x1e
    mov edx, dword [edi + yb2]
    mov ebx, dword [edi + xb1]
    add edx, eax
    mov eax, dword [edi + xb2]
    sub eax, ebx
    mov dword [esp + 0x30], edx
    mov dword [esp], eax
    mov ebx, ecx
    mov eax, dword [edi + yb1]
    mov ecx, dword [esp + 0x30]
    imul ebx
    shrd eax, edx, 0x1e
    mov ebx, dword [esp]
    imul ebx
    idiv ecx
    mov ecx, dword [edi + xb1]
    mov edx, dword [esp + 0xc]
    add eax, ecx
    cmp edx, 2
    jne short .branch_21d
    cmp eax, ecx
    jl short .branch_204
    mov edx, dword [esp + 0x30]
    mov dword [esp + 0x24], eax
    mov dword [esp + 0x20], edx

.branch_204:
    mov edx, dword [esp + 0x28]
    mov ecx, dword [edx*4 + xb2]
    sub ecx, eax
    add eax, eax
    add eax, 2
    add ecx, ecx
    lea edi, [eax + ebp]
    jmp short .branch_247

.branch_21d:
    cmp eax, dword [edi + xb2]
    jg short .branch_231
    mov edx, dword [esp + 0x30]
    mov dword [esp + 0x2c], eax
    mov dword [esp + 0x1c], edx

.branch_231:
    mov ecx, dword [esp + 0x28]
    mov edi, dword [ecx*4 + xb1]
    sub eax, edi
    add eax, eax
    add edi, edi
    lea ecx, [eax + 2]
    add edi, ebp

.branch_247:
    xor eax, eax
    cmp ecx, 4
    jae short .branch_25b
    test cl, 1
    je short .branch_254
    stosb

.branch_254:
    shr ecx, 1
    db 0xf3                       ; REP precedes the operand-size prefix
    stosw
    jmp short .branch_286

.branch_25b:
    test edi, 1
    je short .branch_265
    stosb
    dec ecx

.branch_265:
    test edi, 2
    je short .branch_272
    stosw
    sub ecx, 2

.branch_272:
    mov ebx, ecx
    shr ecx, 2
    rep stosd
    test bl, 2
    je short .branch_280
    stosw

.branch_280:
    test bl, 1
    je short .branch_286
    stosb

.branch_286:
    test byte [esp + 0x34], 0xc
    je near .branch_3c7
    mov ebx, dword [esp + 8]
    mov ecx, dword [esp + 0x18]
    mov eax, esi
    sub ebx, ecx
    sub eax, ecx
    mov edi, dword [esp + 0x28]
    mov edx, eax
    sar edx, 2
    shl eax, 0x1e
    idiv ebx
    shl edi, 2
    mov ecx, eax
    mov edx, dword [edi + yb2]
    mov eax, dword [edi + yb1]
    mov ebx, ecx
    sub eax, edx
    imul ebx
    shrd eax, edx, 0x1e
    mov edx, dword [edi + yb2]
    mov ebx, dword [edi + xb1]
    add edx, eax
    mov eax, dword [edi + xb2]
    sub eax, ebx
    mov dword [esp + 0x30], edx
    mov dword [esp], eax
    mov ebx, ecx
    mov eax, dword [edi + yb1]
    mov ecx, dword [esp + 0x30]
    imul ebx
    shrd eax, edx, 0x1e
    mov ebx, dword [esp]
    imul ebx
    idiv ecx
    mov edx, dword [esp + 0x34]
    mov ecx, dword [edi + xb1]
    and edx, 0xc
    add eax, ecx
    cmp edx, 8
    jne short .branch_34d
    cmp eax, ecx
    jl short .branch_322
    mov edx, dword [esp + 0x30]
    mov dword [esp + 0x24], eax
    mov dword [esp + 0x20], edx

.branch_322:
    mov edx, dword [view_height]
    mov ebx, dword [view_height]
    shl edx, 0x10
    add edx, ebx
    mov ebx, dword [esp + 0x28]
    mov ecx, dword [ebx*4 + xb2]
    sub ecx, eax
    add eax, eax
    lea edi, [eax + 2]
    add ecx, ecx
    mov eax, edx
    add edi, ebp
    jmp short .branch_38a

.branch_34d:
    cmp eax, dword [edi + xb2]
    jg short .branch_361
    mov edx, dword [esp + 0x30]
    mov dword [esp + 0x2c], eax
    mov dword [esp + 0x1c], edx

.branch_361:
    mov edx, dword [esp + 0x28]
    mov ebx, dword [view_height]
    mov ecx, dword [view_height]
    mov edi, dword [edx*4 + xb1]
    shl ebx, 0x10
    sub eax, edi
    add ebx, ecx
    add eax, eax
    add edi, edi
    lea ecx, [eax + 2]
    add edi, ebp
    mov eax, ebx

.branch_38a:
    cmp ecx, 4
    jae short .branch_39c
    test cl, 1
    je short .branch_395
    stosb

.branch_395:
    shr ecx, 1
    db 0xf3                       ; REP precedes the operand-size prefix
    stosw
    jmp short .branch_3c7

.branch_39c:
    test edi, 1
    je short .branch_3a6
    stosb
    dec ecx

.branch_3a6:
    test edi, 2
    je short .branch_3b3
    stosw
    sub ecx, 2

.branch_3b3:
    mov ebx, ecx
    shr ecx, 2
    rep stosd
    test bl, 2
    je short .branch_3c1
    stosw

.branch_3c1:
    test bl, 1
    je short .branch_3c7
    stosb

.branch_3c7:
    mov ecx, dword [esp + 0x1c]
    mov ebx, dword [engine_286b00]
    mov eax, esi
    imul ebx
    idiv ecx
    mov ecx, dword [esp + 0x20]
    mov ebx, dword [engine_286b00]
    mov edi, eax
    mov eax, esi
    shl edi, 4
    imul ebx
    idiv ecx
    mov ecx, dword [esp + 0x24]
    mov edx, eax
    mov esi, dword [esp + 0x2c]
    shl edx, 4
    sub ecx, esi
    sub edx, edi
    inc ecx
    mov eax, edx
    sar edx, 0x1f
    idiv ecx
    lea ebx, [esi + esi]
    lea esi, [ebx + ebp]
    mov dword [esp + 0x14], esi
    mov edx, dword [globalhoriz]
    mov esi, eax
    shl edx, 0x10
    mov eax, dword [esp + 0x14]
    add edx, edi
    test ecx, ecx
    je short .branch_467
    test al, 2
    je short .branch_438
    mov ebx, edx
    sar ebx, 0x10
    mov word [eax], bx
    add edx, esi
    add eax, 2
    dec ecx
    je short .branch_467

.branch_438:
    sub ecx, 2
    jb short .branch_45f

.branch_43d:
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
    jae short .branch_43d
    test cl, 1
    je short .branch_467

.branch_45f:
    mov ebx, edx
    sar ebx, 0x10
    mov word [eax], bx

.branch_467:
    mov eax, dword [esp + 0x14]
    cmp word [eax], 0
    jge short .branch_476
    mov word [eax], 0

.branch_476:
    mov eax, dword [esp + 0x2c]
    add eax, eax
    add eax, ebp
    mov edi, dword [view_height]
    movsx edx, word [eax]
    cmp edx, edi
    jle short .branch_495
    mov dx, word [view_height]
    mov word [eax], dx

.branch_495:
    mov eax, dword [esp + 0x24]
    add eax, eax
    add eax, ebp
    cmp word [eax], 0
    jge short .branch_4a8
    mov word [eax], 0

.branch_4a8:
    mov eax, dword [esp + 0x24]
    add eax, eax
    add ebp, eax
    mov edx, dword [view_height]
    movsx eax, word [ebp]
    cmp eax, edx
    jle short .branch_4c8
    mov ax, word [view_height]
    mov word [ebp], ax

.branch_4c8:
    mov eax, dword [esp + 0x34]
    add esp, 0x38
    pop ebp
    pop edi
    pop esi
    pop ecx
    ret

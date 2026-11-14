; Resolve wall penetration by pushing a position clear and updating its sector.
BITS 32
ORG 0x53edd

clipinsidebox equ 0x4c0c7
getangle equ 0x4c94c
restore_ebp_edi_esi_and_return equ 0x4cc84
updatesector equ 0x542c4
getceilzofslope equ 0x5de70
getflorzofslope equ 0x5df75
clipsectorlist equ 0x195f50
sintable equ 0x2300a0
walls equ 0x2310a0
engine_2310a4 equ 0x2310a4
sectors equ 0x27c3a0
clipsectnum equ 0x28912e

pushmove:
    push esi
    push edi
    push ebp
    sub esp, 0x40
    mov esi, eax
    mov edi, edx
    mov [esp + 0xc], ebx
    mov [esp + 0x8], ecx
    cmp word [ecx], 0x0
    jnl short .branch_53eff
    mov eax, 0xffffffff
    jmp near .branch_542bc

.branch_53eff:
    mov edx, 0x20
    mov ebx, 0x1
    mov [esp + 0x18], edx
    mov [esp + 0x10], ebx

.branch_53f11:
    mov eax, [esp + 0x8]
    xor ecx, ecx
    xor ebx, ebx
    mov [esp + 0x4], ecx
    mov [esp + 0x34], ebx
    mov ax, [eax]
    mov ecx, 0x1
    mov [clipsectorlist], ax
    mov [clipsectnum], cx

.branch_53f36:
    movsx eax, word [esp + 0x34]
    movsx edx, word [nosplit eax*2 + clipsectorlist]
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    shl eax, byte 0x3
    mov ebp, [esp + 0x10]
    add eax, sectors
    test ebp, ebp
    jng short .branch_53f69
    mov dx, [eax]
    mov ax, [eax + 0x2]
    add eax, edx
    mov [esp + 0x38], eax
    jmp short .branch_53f76

.branch_53f69:
    mov dx, [eax]
    mov bx, [eax + 0x2]
    mov [esp + 0x38], edx
    add edx, ebx

.branch_53f76:
    movsx eax, dx
    mov ebp, eax
    shl ebp, byte 0x5
    mov [esp + 0x30], eax
    add ebp, walls
    jmp near .branch_5427c

.branch_53f8d:
    mov ecx, [esp + 0x50]
    movsx ebx, word [esp + 0x30]
    mov edx, [edi]
    mov eax, [esi]
    sub ecx, 0x4
    call clipinsidebox
    cmp eax, 0x1
    jnz near .branch_54269
    mov bx, [ebp + 0xc]
    xor ecx, ecx
    test bx, bx
    jnl short .branch_53fb8
    mov ecx, eax

.branch_53fb8:
    cmp byte [esp + 0x5c], 0x0
    jnz short .branch_53fd1
    mov ax, [ebp + 0xe]
    xor ah, ah
    and al, 0x1
    cwde
    test eax, eax
    jz short .branch_53fd1
    mov ecx, 0x1

.branch_53fd1:
    xor eax, eax
    mov al, [esp + 0x5c]
    cmp eax, 0x1
    jnz short .branch_53fee
    mov ax, [ebp + 0xe]
    xor ah, ah
    and al, 0x40
    cwde
    test eax, eax
    jz short .branch_53fee
    mov ecx, 0x1

.branch_53fee:
    test ecx, ecx
    jnz near .branch_5416c
    movsx edx, word [ebp + 0xc]
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    mov edx, sectors
    shl eax, byte 0x3
    add edx, eax
    movsx eax, word [ebp + 0x8]
    mov ebx, [ebp + 0x0]
    shl eax, byte 0x5
    mov [esp + 0x14], edx
    mov edx, [eax + walls]
    sub edx, ebx
    mov eax, [eax + engine_2310a4]
    mov [esp + 0x20], edx
    mov edx, [ebp + 0x4]
    sub eax, edx
    mov [esp + 0x24], eax
    mov eax, [edi]
    sub eax, edx
    mov edx, [esp + 0x24]
    imul edx, eax
    mov eax, [esi]
    sub eax, ebx
    mov ebx, [esp + 0x20]
    imul eax, ebx
    add eax, edx
    test eax, eax
    jg short .branch_54056
    mov [esp + 0x1c], ecx
    jmp short .branch_5407e

.branch_54056:
    imul ebx, ebx
    mov edx, [esp + 0x24]
    imul edx, edx
    add ebx, edx
    cmp eax, ebx
    jl short .branch_54070
    mov dword [esp + 0x1c], 0x40000000
    jmp short .branch_5407e

.branch_54070:
    mov edx, eax
    sar edx, byte 0x2
    shl eax, byte 0x1e
    idiv ebx
    mov [esp + 0x1c], eax

.branch_5407e:
    mov ebx, [esp + 0x1c]
    mov eax, [esp + 0x20]
    imul ebx
    shrd eax, edx, byte 0x1e
    mov edx, [ebp + 0x0]
    add edx, eax
    mov eax, [esp + 0x24]
    mov [esp + 0x20], edx
    imul ebx
    shrd eax, edx, byte 0x1e
    mov edx, [ebp + 0x4]
    add edx, eax
    movsx eax, word [esp + 0x34]
    mov [esp + 0x24], edx
    mov ebx, edx
    mov edx, [esp + 0x20]
    movsx eax, word [nosplit eax*2 + clipsectorlist]
    call getflorzofslope
    mov ebx, [esp + 0x24]
    mov edx, [esp + 0x20]
    mov [esp], eax
    movsx eax, word [ebp + 0xc]
    call getflorzofslope
    mov edx, [esp]
    sub edx, strict dword 0x100
    cmp eax, edx
    jnl short .branch_54109
    mov edx, [esp + 0x14]
    mov dx, [edx + 0xe]
    xor dh, dh
    and dl, 0x1
    movsx edx, dx
    test edx, edx
    jnz short .branch_54109
    mov edx, [esp + 0x58]
    dec edx
    sub eax, edx
    mov edx, [esp + 0xc]
    cmp eax, [edx]
    jg short .branch_54109
    mov ecx, 0x1

.branch_54109:
    movsx eax, word [esp + 0x34]
    mov ebx, [esp + 0x24]
    mov edx, [esp + 0x20]
    movsx eax, word [nosplit eax*2 + clipsectorlist]
    call getceilzofslope
    mov ebx, [esp + 0x24]
    mov edx, [esp + 0x20]
    mov [esp], eax
    movsx eax, word [ebp + 0xc]
    call getceilzofslope
    mov edx, [esp]
    add edx, strict dword 0x100
    cmp eax, edx
    jng short .branch_5416c
    mov edx, [esp + 0x14]
    mov dx, [edx + 0xc]
    xor dh, dh
    and dl, 0x1
    movsx edx, dx
    test edx, edx
    jnz short .branch_5416c
    mov edx, [esp + 0x54]
    dec edx
    add eax, edx
    mov edx, [esp + 0xc]
    cmp eax, [edx]
    jl short .branch_5416c
    mov ecx, 0x1

.branch_5416c:
    test ecx, ecx
    jz near .branch_5422d
    movsx eax, word [ebp + 0x8]
    mov ecx, [ebp + 0x4]
    shl eax, byte 0x5
    mov ebx, [ebp + 0x0]
    mov edx, [eax + engine_2310a4]
    mov eax, [eax + walls]
    sub edx, ecx
    sub eax, ebx
    call getangle
    lea edx, [eax + 0x400]
    and edx, strict dword 0x7ff
    add eax, strict dword 0x200
    movsx edx, word [nosplit edx*2 + sintable]
    and eax, strict dword 0x7ff
    sar edx, byte 0xb
    movsx eax, word [nosplit eax*2 + sintable]
    mov [esp + 0x28], edx
    sar eax, byte 0xb
    mov dl, 0x10
    mov [esp + 0x2c], eax
    mov [esp + 0x3c], dl

.branch_541d0:
    mov eax, [esp + 0x28]
    add [esi], eax
    mov eax, [esp + 0x2c]
    add [edi], eax
    mov dh, [esp + 0x3c]
    dec dh
    mov [esp + 0x3c], dh
    jz short .branch_54201
    mov ecx, [esp + 0x50]
    movsx ebx, word [esp + 0x30]
    mov edx, [edi]
    mov eax, [esi]
    sub ecx, 0x4
    call clipinsidebox
    test eax, eax
    jnz short .branch_541d0

.branch_54201:
    mov ecx, [esp + 0x18]
    mov ebx, 0xffffffff
    dec ecx
    mov [esp + 0x4], ebx
    mov [esp + 0x18], ecx
    test ecx, ecx
    jg short .branch_5421e
    mov eax, ebx
    jmp near .branch_542bc

.branch_5421e:
    mov ebx, [esp + 0x8]
    mov edx, [edi]
    mov eax, [esi]
    call updatesector
    jmp short .branch_54269

.branch_5422d:
    movsx ecx, word [clipsectnum]
    jmp short .branch_54244

.branch_54236:
    mov dx, [ebp + 0xc]
    cmp dx, [nosplit ecx*2 + clipsectorlist]
    jz short .branch_54249

.branch_54244:
    dec ecx
    test ecx, ecx
    jnl short .branch_54236

.branch_54249:
    test ecx, ecx
    jnl short .branch_54269
    mov ax, [clipsectnum]
    movsx edx, ax
    inc eax
    mov [clipsectnum], ax
    mov ax, [ebp + 0xc]
    mov [nosplit edx*2 + clipsectorlist], ax

.branch_54269:
    mov eax, [esp + 0x10]
    mov edx, [esp + 0x30]
    add edx, eax
    shl eax, byte 0x5
    mov [esp + 0x30], edx
    add ebp, eax

.branch_5427c:
    movsx eax, word [esp + 0x38]
    cmp eax, [esp + 0x30]
    jnz near .branch_53f8d
    mov ecx, [esp + 0x34]
    inc ecx
    mov dx, [clipsectnum]
    mov [esp + 0x34], ecx
    cmp cx, dx
    jl near .branch_53f36
    mov ebx, [esp + 0x10]
    neg ebx
    mov ecx, [esp + 0x4]
    mov [esp + 0x10], ebx
    test ecx, ecx
    jnz near .branch_53f11
    mov eax, ecx

.branch_542bc:
    add esp, 0x40
    jmp near restore_ebp_edi_esi_and_return

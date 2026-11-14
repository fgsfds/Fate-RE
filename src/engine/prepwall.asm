; Prepare per-column wall texture positions and scale factors.
BITS 32
ORG 0x4751e

rx1 equ 0x1cd160
view_x2 equ 0x1d1160
rx2 equ 0x1cb160
view_x1 equ 0x1cf160
lwall equ 0x199150
swall equ 0x1a18e0
screen_width equ 0x140b5
xb1 equ 0x1c5160
xb2 equ 0x1c3160
view_half_width equ 0x286b08
projection_scale equ 0x286b14
wallfront_return equ 0x4551f

prepwall_:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    sub esp, 0x20
    push eax
    push edx
    xor eax, eax
    mov al, byte [edx + 0x16]
    mov ecx, dword [esp + 4]
    shl eax, 3
    mov esi, dword [ecx*4 + xb1]
    mov dword [esp + 0x1c], eax
    mov eax, dword [ecx*4 + view_x2]
    mov ebp, dword [ecx*4 + view_x2]
    sar eax, 2
    mov edx, dword [view_half_width]
    mov dword [esp + 0x14], eax
    mov ebx, eax
    mov eax, dword [ecx*4 + view_x1]
    neg ebx
    sub eax, ebp
    mov dword [esp + 0x14], ebx
    sar eax, 8
    mov ebx, dword [screen_width]
    mov dword [esp + 0x18], eax
    mov eax, dword [ecx*4 + rx1]
    sub esi, edx
    imul ebx
    shrd eax, edx, 5
    mov ebp, eax
    mov ebx, esi
    mov eax, dword [esp + 0x14]
    imul ebx
    shrd eax, edx, 2
    mov edx, dword [ecx*4 + rx2]
    add ebp, eax
    mov eax, dword [ecx*4 + rx1]
    mov ebx, dword [screen_width]
    sub eax, edx
    mov dword [esp + 0x24], ebp
    imul ebx
    shrd eax, edx, 0xb
    mov ebp, eax
    mov ebx, esi
    mov eax, dword [esp + 0x18]
    imul ebx
    shrd eax, edx, 2
    mov ebx, dword [projection_scale]
    lea esi, [eax + ebp]
    mov eax, dword [ecx*4 + view_x2]
    imul ebx
    shrd eax, edx, 0x13
    mov dword [esp + 8], eax
    mov dword [esp + 0x10], eax
    mov ebp, dword [ecx*4 + view_x2]
    mov eax, dword [ecx*4 + view_x1]
    mov ebx, dword [projection_scale]
    sub eax, ebp
    imul ebx
    shrd eax, edx, 0x10
    mov ebp, eax
    mov dword [esp + 0xc], eax
    mov ecx, dword [ecx*4 + xb1]
    test esi, esi
    je short .branch_12c
    mov eax, dword [esp + 0x24]
    mov ebx, esi
    mov edx, eax
    sar edx, 0x14
    shl eax, 0xc
    idiv ebx
    mov ebx, ebp
    mov edi, eax
    imul ebx
    shrd eax, edx, 0x15
    mov edx, dword [esp + 8]
    add edx, eax
    mov dword [ecx*4 + swall], edx
    mov edx, dword [esp + 0x1c]
    imul edi, edx
    mov edx, edi
    sar edx, 0x12
    mov dword [ecx*4 + lwall], edx

.branch_12c:
    mov eax, dword [esp + 4]
    lea edx, [ecx + 4]
    shl eax, 2
    mov ebp, ecx
    mov ebx, dword [eax + xb2]
    shl ebp, 2
    cmp edx, ebx
    jg near .branch_215
    mov eax, dword [esp + 0x14]
    mov edx, dword [esp + 0x24]
    add edx, eax
    mov ebx, dword [esp + 0x18]
    mov dword [esp + 0x24], edx
    add esi, ebx
    je short .branch_199
    mov ebx, esi
    mov eax, edx
    mov dword [esp + 0x20], edi
    mov edx, eax
    sar edx, 0x14
    shl eax, 0xc
    idiv ebx
    mov ebx, dword [esp + 0xc]
    mov edi, eax
    imul ebx
    shrd eax, edx, 0x15
    imul edi, dword [esp + 0x1c]
    mov edx, dword [esp + 0x10]
    add eax, edx
    mov dword [ebp + swall+16], eax
    mov eax, edi
    sar eax, 0x12
    mov dword [ebp + lwall+16], eax

.branch_199:
    mov eax, dword [esp + 0x20]
    add eax, edi
    mov edx, eax
    mov ebp, eax
    sar edx, 0x13
    sar ebp, 1
    mov dword [ecx*4 + lwall+8], edx
    mov edx, dword [esp + 0x20]
    add edx, ebp
    add ebp, edi
    sar edx, 0x13
    sar ebp, 0x13
    mov dword [ecx*4 + lwall+4], edx
    mov edx, dword [ecx*4 + swall+16]
    mov dword [ecx*4 + lwall+12], ebp
    mov ebp, dword [ecx*4 + swall]
    add ebp, edx
    sar ebp, 1
    mov edx, dword [ecx*4 + swall]
    add edx, ebp
    mov dword [ecx*4 + swall+8], ebp
    sar edx, 1
    mov dword [ecx*4 + swall+4], edx
    mov ebp, dword [ecx*4 + swall+16]
    add ebp, dword [ecx*4 + swall+8]
    add ecx, 4
    sar ebp, 1
    mov dword [ecx*4 + swall-4], ebp
    jmp near .branch_12c

.branch_215:
    lea edx, [ecx + 2]
    cmp edx, ebx
    jg near .branch_2a2
    mov eax, dword [esp + 0x14]
    mov edx, dword [esp + 0x24]
    sar eax, 1
    add edx, eax
    mov eax, dword [esp + 0x18]
    sar eax, 1
    mov dword [esp + 0x24], edx
    add esi, eax
    je short .branch_276
    mov ebx, esi
    mov eax, edx
    mov dword [esp + 0x20], edi
    mov edx, eax
    sar edx, 0x14
    shl eax, 0xc
    idiv ebx
    mov ebx, dword [esp + 0xc]
    mov edi, eax
    imul ebx
    shrd eax, edx, 0x15
    mov ebx, dword [esp + 0x10]
    add eax, ebx
    mov dword [ebp + swall+8], eax
    mov eax, dword [esp + 0x1c]
    imul edi, eax
    mov eax, edi
    sar eax, 0x12
    mov dword [ebp + lwall+8], eax

.branch_276:
    mov edx, dword [esp + 0x20]
    mov ebx, dword [ecx*4 + swall+8]
    add edi, edx
    mov edx, dword [ecx*4 + swall]
    add ecx, 2
    add edx, ebx
    sar edi, 0x13
    sar edx, 1
    mov dword [ecx*4 + lwall-4], edi
    mov dword [ecx*4 + swall-4], edx

.branch_2a2:
    mov eax, dword [esp + 4]
    lea edx, [ecx + 1]
    cmp edx, dword [eax*4 + xb2]
    jg short .branch_300
    mov eax, dword [esp + 0x18]
    sar eax, 2
    add esi, eax
    je short .branch_300
    mov eax, dword [esp + 0x14]
    mov ebp, dword [esp + 0x24]
    sar eax, 2
    mov ebx, esi
    add eax, ebp
    mov edx, eax
    sar edx, 0x14
    shl eax, 0xc
    idiv ebx
    mov ebx, dword [esp + 0xc]
    mov esi, eax
    imul ebx
    shrd eax, edx, 0x15
    add eax, dword [esp + 0x10]
    mov ebx, dword [esp + 0x1c]
    mov dword [ecx*4 + swall+4], eax
    mov eax, esi
    imul ebx
    shrd eax, edx, 0x12
    mov dword [ecx*4 + lwall+4], eax

.branch_300:
    mov eax, dword [esp + 4]
    mov eax, dword [eax*4 + xb1]
    shl eax, 2
    cmp dword [eax + lwall], 0
    jge short .branch_31f
    xor ecx, ecx
    mov dword [eax + lwall], ecx

.branch_31f:
    mov eax, dword [esp + 4]
    mov eax, dword [eax*4 + xb2]
    shl eax, 2
    mov esi, dword [esp + 0x1c]
    cmp esi, dword [eax + lwall]
    jg short .branch_346
    test esi, esi
    je short .branch_346
    lea edx, [esi - 1]
    mov dword [eax + lwall], edx

.branch_346:
    mov eax, dword [esp]
    mov ax, word [eax + 0xe]
    xor ah, ah
    and al, 8
    cwde
    test eax, eax
    je near wallfront_return
    mov ecx, dword [esp + 4]
    mov ebp, dword [esp + 0x1c]
    mov eax, dword [esp + 4]
    dec ebp
    mov ecx, dword [ecx*4 + xb1]
    mov dword [esp + 0x1c], ebp
    jmp short .branch_389

.branch_374:
    mov edx, dword [esp + 0x1c]
    mov esi, dword [ecx*4 + lwall]
    inc ecx
    sub edx, esi
    mov dword [ecx*4 + lwall-4], edx

.branch_389:
    cmp ecx, dword [eax*4 + xb2]
    jle short .branch_374
    jmp near wallfront_return

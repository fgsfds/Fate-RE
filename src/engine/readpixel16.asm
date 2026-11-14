; Read a pixel from the 16-color planar framebuffer.
BITS 32
ORG 0x4c293

pow2long equ 0x14031
pageoffset equ 0x286a74
qsetmode equ 0x140ba
ydim16 equ 0x286a5c
transmaskvline_restore equ 0x4abbf

readpixel16_:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    mov ebx, eax
    and eax, 7
    xor al, 7
    mov esi, eax
    shl esi, 2
    mov edx, dword [qsetmode]
    mov esi, dword [esi + pow2long]
    cmp edx, 0x1e0
    jne short .branch_041
    cmp dword [ydim16], 0x150
    jg short .branch_041
    cmp ebx, 0x34800
    jl short .branch_041
    sub ebx, 0x34800
    jmp short .branch_047

.branch_041:
    add ebx, dword [pageoffset]

.branch_047:
    mov eax, 4
    mov edx, 0x3ce
    sar ebx, 3
    out dx, al
    mov edx, 0x3cf
    xor eax, eax
    lea edi, [ebx + 0xa0000]
    out dx, al
    mov al, byte [edi]
    and eax, esi
    test eax, eax
    setg al
    mov ecx, eax
    mov eax, 1
    lea edi, [ebx + 0xa0000]
    out dx, al
    mov al, byte [edi]
    and eax, esi
    and ecx, 0xff
    test eax, eax
    setg al
    and eax, 0xff
    add eax, eax
    add ecx, eax
    mov eax, 2
    lea edi, [ebx + 0xa0000]
    out dx, al
    mov al, byte [edi]
    and eax, esi
    test eax, eax
    setg al
    and eax, 0xff
    shl eax, 2
    add ecx, eax
    mov eax, 3
    lea edi, [ebx + 0xa0000]
    out dx, al
    mov al, byte [edi]
    and eax, esi
    test eax, eax
    setg al
    and eax, 0xff
    shl eax, 3
    add eax, ecx
    jmp near transmaskvline_restore

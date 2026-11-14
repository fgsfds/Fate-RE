; Build Engine & Tools Copyright (c) 1993-1997 Ken Silverman.
; See BUILDLIC.TXT. Adapted for FATE's segment intersection.
BITS 32
ORG 0x5261d
shared_return equ 0x51fbb

lintersect_:
    push esi
    push edi
    push ebp
    sub esp, 24
    push eax
    mov esi, edx
    mov [esp+20], ebx
    mov ebx, [esp+60]
    mov ebp, [esp+44]
    mov edi, ecx
    mov ecx, [esp+64]
    sub edi, eax
    sub ebp, edx
    mov eax, [esp+52]
    mov edx, [esp+56]
    sub eax, ebx
    sub edx, ecx

    ; Denominator and the two segment parameters' numerators.
    mov ebx, edi
    imul ebx, edx
    mov [esp+24], eax
    imul eax, ebp
    sub ebx, eax
    mov eax, [esp+56]
    sub eax, esi
    mov ecx, [esp]
    mov [esp+16], eax
    mov eax, [esp+52]
    sub eax, ecx
    mov ecx, ebp
    imul ecx, eax
    imul eax, edx
    mov [esp+4], ecx
    mov ecx, [esp+16]
    imul ecx, edi
    mov [esp+12], ecx
    mov ecx, [esp+16]
    imul ecx, [esp+24]
    mov edx, [esp+4]
    mov [esp+8], ecx
    mov ecx, [esp+12]
    sub ecx, edx
    sub eax, [esp+8]
    test ebx, ebx
    jl .negative
    jne .positive
.miss:
    xor eax, eax
    jmp near .return
.positive:
    mov edx, eax
    test eax, eax
    jl .miss
    cmp eax, ebx
    jge .miss
    test ecx, ecx
    jl .miss
    cmp ecx, ebx
    jl .hit
    jmp short .miss
.negative:
    mov edx, eax
    test eax, eax
    jg .miss
    cmp eax, ebx
    jle .miss
    test ecx, ecx
    jg .miss
    cmp ecx, ebx
    jle .miss

.hit:
    ; Use a signed 8.24 fraction and project onto the first segment.
    mov eax, edx
    mov edx, eax
    sar edx, 8
    shl eax, 24
    idiv ebx
    mov ecx, eax
    mov ebx, eax
    mov eax, edi
    imul ebx
    shrd eax, edx, 24
    mov edx, [esp]
    add edx, eax
    mov eax, [esp+68]
    mov [eax], edx
    mov eax, ebp
    imul ebx
    shrd eax, edx, 24
    add esi, eax
    mov eax, [esp+72]
    mov ebx, [esp+20]
    mov [eax], esi
    mov eax, [esp+48]
    sub eax, ebx
    mov ebx, ecx
    imul ebx
    shrd eax, edx, 24
    mov edx, [esp+20]
    add edx, eax
    mov eax, [esp+76]
    mov [eax], edx
    mov eax, 1
.return:
    add esp, 28
    jmp near shared_return

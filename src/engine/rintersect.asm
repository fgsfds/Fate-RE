; Build Engine & Tools Copyright (c) 1993-1997 Ken Silverman.
; See BUILDLIC.TXT. Adapted for FATE's ray/segment intersection.
BITS 32
ORG 0x5272c
shared_return equ 0x51fbb

rintersect_:
    push esi
    push edi
    push ebp
    sub esp, 20
    mov edi, eax
    mov [esp+16], edx
    mov [esp], ebx
    mov esi, ecx
    ; Form the denominator and two signed cross-product numerators.
    mov ecx, [esp+48]
    mov ebx, [esp+56]
    mov eax, esi
    sub ecx, ebx
    imul eax, ecx
    mov ebp, [esp+44]
    sub ebp, [esp+52]
    mov edx, [esp+36]
    imul edx, ebp
    mov ebx, [esp+16]
    sub eax, edx
    mov edx, [esp+48]
    sub edx, ebx
    mov [esp+12], edx
    mov edx, [esp+44]
    mov ebx, [esp+36]
    sub edx, edi
    imul ebx, edx
    imul edx, ecx
    mov [esp+8], ebx
    mov ebx, [esp+12]
    imul ebx, esi
    mov [esp+4], ebx
    imul ebp, [esp+12]
    mov ecx, [esp+4]
    mov ebx, [esp+8]
    sub edx, ebp
    sub ecx, ebx
    test eax, eax
    jl .negative
    je near .return
    mov ebp, edx
    test edx, edx
    jge .positive_segment
.miss:
    xor eax, eax
    jmp near .return
.positive_segment:
    test ecx, ecx
    jl .miss
    cmp ecx, eax
    jl .intersection
    jmp short .miss
.negative:
    mov ebp, edx
    test edx, edx
    jg .miss
    test ecx, ecx
    jg .miss
    cmp ecx, eax
    jle .miss
.intersection:
    ; Convert ray distance to 16.16, then project along each axis.
    mov ebx, eax
    mov eax, ebp
    mov edx, eax
    sar edx, 16
    shl eax, 16
    idiv ebx
    mov ebx, eax
    mov eax, esi
    imul ebx
    shrd eax, edx, 16
    add edi, eax
    mov eax, [esp+60]
    mov [eax], edi
    mov eax, [esp+36]
    imul ebx
    shrd eax, edx, 16
    mov edx, [esp+16]
    add edx, eax
    mov eax, [esp+64]
    mov [eax], edx
    mov eax, [esp+40]
    imul ebx
    shrd eax, edx, 16
    mov edx, [esp]
    add edx, eax
    mov eax, [esp+68]
    mov [eax], edx
    mov eax, 1
.return:
    add esp, 20
    jmp near shared_return

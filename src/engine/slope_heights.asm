; Build Engine & Tools Copyright (c) 1993-1997 Ken Silverman.
; See BUILDLIC.TXT. Adapted for FATE's combined collision-height query.
BITS 32
ORG 0x5e07a
sectors equ 0x27c3a0
walls equ 0x2310a0
sqrtable equ 0x1dfa60
shared_return equ 0x548c8

getzsofslope_:
    push esi
    push edi
    push ebp
    sub esp, 8
    push edx
    push ebx
    push ecx
    cwde
    mov esi, eax
    shl esi, 2
    add esi, eax
    mov ebp, sectors
    shl esi, 3
    add ebp, esi
    mov eax, [ebp+4]
    mov [ecx], eax
    mov edx, [esp+36]
    mov eax, [ebp+8]
    mov [edx], eax
    movsx edx, word [ebp+12]
    movsx eax, word [ebp+14]
    or eax, edx
    test al, 2
    je near .done

    movsx eax, word [ebp]
    mov esi, walls
    shl eax, 5
    add esi, eax
    movsx eax, word [esi+8]
    shl eax, 5
    add eax, walls
    mov ebx, [esi]
    mov edx, [eax]
    sub edx, ebx
    mov [esp+16], edx
    imul edx, edx
    mov ecx, [esi+4]
    mov edi, [eax+4]
    sub edi, ecx
    mov eax, edi
    imul eax, edi
    add eax, edx
    test eax, eax
    jns .sqrt
    neg eax
.sqrt:
    bsr ecx, eax
    cmp cl, 11
    jge .scaled
    movzx eax, word [nosplit eax*2+sqrtable]
    jmp .length
.scaled:
    sub cl, 9
    and cl, 0xfe
    sar eax, cl
    movzx eax, word [nosplit eax*2+sqrtable]
    sar cl, 1
    shl eax, cl
.length:
    sar eax, 10
    shl eax, 5
    mov [esp+12], eax
    test eax, eax
    je near .done

    ; Project onto the wall normal with a signed 64-bit cross product.
    mov edx, [esp+8]
    mov eax, edi
    mov ebx, [esi]
    mov ecx, [esi+4]
    neg eax
    sub edx, ebx
    mov ebx, [esp+4]
    mov edi, edx
    mov esi, eax
    mov eax, [esp+16]
    sub ebx, ecx
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 3
    mov dx, [ebp+12]
    xor dh, dh
    and dl, 2
    movsx edx, dx
    mov esi, eax
    test edx, edx
    je .floor
    mov ecx, [esp+12]
    mov dx, [ebp+18]
    mov ebx, eax
    movsx eax, dx
    imul ebx
    idiv ecx
    mov edx, [esp]
    add [edx], eax
.floor:
    mov ax, [ebp+14]
    xor ah, ah
    and al, 2
    cwde
    test eax, eax
    je .done
    mov ecx, [esp+12]
    mov ax, [ebp+26]
    mov ebx, esi
    cwde
    imul ebx
    idiv ecx
    mov edx, [esp+36]
    add [edx], eax
.done:
    add esp, 20
    jmp near shared_return

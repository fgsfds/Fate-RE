; Build Engine & Tools Copyright (c) 1993-1997 Ken Silverman.
; See BUILDLIC.TXT. Adapted for FATE's inlined square-root calculation.
BITS 32
ORG 0x5de70
sector_wall equ 0x27c3a0
wall_x equ 0x2310a0
wall_y equ 0x2310a4
wall_point2 equ 0x2310a8
sqrtable equ 0x1dfa60
shared_return equ 0x4c944

; Sector flag, base height, slope coefficient.
%macro slope_height 3
    push ecx
    push esi
    push edi
    push ebp
    sub esp, 4
    push edx
    push ebx
    cwde
    mov ebp, eax
    shl ebp, 2
    add ebp, eax
    shl ebp, 3
    mov ax, [ebp+%1]
    xor ah, ah
    and al, 2
    cwde
    test eax, eax
    jne %%sloped
%%flat:
    mov eax, [ebp+%2]
    jmp near shared_return
%%sloped:
    movsx esi, word [ebp+sector_wall]
    shl esi, 5
    movsx eax, word [esi+wall_point2]
    shl eax, 5
    mov edx, [esi+wall_x]
    mov edi, [eax+wall_x]
    sub edi, edx
    mov [esp+8], edi
    mov edi, [eax+wall_y]
    mov eax, [esp+8]
    imul eax, eax
    mov ebx, [esi+wall_y]
    sub edi, ebx
    mov edx, edi
    imul edx, edi
    add eax, edx
    test eax, eax
    jns %%sqrt
    neg eax
%%sqrt:
    bsr ecx, eax
    cmp cl, 11
    jge %%scaled_sqrt
    movzx eax, word [nosplit eax*2+sqrtable]
    jmp %%sqrt_done
%%scaled_sqrt:
    sub cl, 9
    and cl, 0xfe
    sar eax, cl
    movzx eax, word [nosplit eax*2+sqrtable]
    sar cl, 1
    shl eax, cl
%%sqrt_done:
    sar eax, 10
    test eax, eax
    je short %%flat
    mov dx, [ebp+%3]
    mov ebx, eax
    movsx eax, dx
    mov edx, eax
    sar edx, 17
    shl eax, 15
    idiv ebx
    imul edi, eax
    mov edx, [esp+8]
    imul edx, eax
    mov ebx, [esp]
    mov [esp+8], edx
    mov eax, [esi+wall_x]
    mov edx, [esp+4]
    mov ecx, [esi+wall_y]
    sub edx, eax
    mov eax, edi
    sub ebx, ecx
    neg eax
    mov edi, edx
    mov esi, eax
    mov eax, [esp+8]
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 23
    add eax, [ebp+%2]
    jmp near shared_return
%endmacro

getceilzofslope_:
    slope_height 0x27c3ac, 0x27c3a4, 0x27c3b2
getflorzofslope_:
    slope_height 0x27c3ae, 0x27c3a8, 0x27c3ba

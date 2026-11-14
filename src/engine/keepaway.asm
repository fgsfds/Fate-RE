; Build Engine & Tools Copyright (c) 1993-1997 Ken Silverman.
; See BUILDLIC.TXT. Adapted for FATE's collision-line arrays.
BITS 32
ORG 0x53c2e
x1 equ 0x190b60
x2 equ 0x190360
y1 equ 0x197350
y2 equ 0x196b50
shared_return equ 0x47f04

    push ecx
    push esi
    push edi
    push ebp
    sub esp, 20
    mov ecx, eax
    movsx ebx, bx
    mov eax, [nosplit ebx*4+x1]
    mov edi, [nosplit ebx*4+x2]
    mov [esp+8], eax
    sub edi, eax
    mov eax, [nosplit ebx*4+y1]
    mov [esp+12], eax
    mov ebp, [esp+12]
    mov eax, [nosplit ebx*4+y2]
    sub eax, ebp
    ; X step is sign(-dy); Y step is sign(dx).
    mov ebx, eax
    neg ebx
    mov [esp+16], eax
    add ebx, ebx
    sbb eax, eax
    cmp eax, ebx
    adc al, 0
    mov ebx, edi
    mov [esp], eax
    add ebx, ebx
    sbb eax, eax
    cmp eax, ebx
    adc al, 0
    mov [esp+4], eax
    mov eax, edi
    test eax, eax
    jns .abs_dx
    neg eax
.abs_dx:
    mov ebx, eax
    mov eax, [esp+16]
    test eax, eax
    jns .abs_dy
    neg eax
.abs_dy:
    cmp ebx, eax
    setle al
.test_side:
    mov esi, [esp+12]
    mov ebx, [edx]
    sub ebx, esi
    imul ebx, edi
    mov ebp, [esp+8]
    mov esi, [ecx]
    sub esi, ebp
    imul esi, [esp+16]
    cmp ebx, esi
    jg near shared_return
    test al, al
    jne .step_y
    mov ebx, [esp]
    add [ecx], ebx
    jmp .toggle
.step_y:
    mov ebx, [esp+4]
    add [edx], ebx
.toggle:
    xor al, 1
    jmp .test_side

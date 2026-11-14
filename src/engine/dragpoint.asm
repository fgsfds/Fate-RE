; Build Engine & Tools Copyright (c) 1993-1997 Ken Silverman.
; See BUILDLIC.TXT. Adapted for FATE's original wall editing routine.
BITS 32
ORG 0x52822
wall_x equ 0x2310a0
wall_y equ 0x2310a4
point2 equ 0x2310a8
nextwall equ 0x2310aa
lastwall equ 0x528cf

dragpoint_:
    push ecx
    push esi
    push edi
    mov ecx, eax
    mov edi, edx
    mov esi, ebx
    cwde
    shl eax, 5
    mov [eax+wall_x], edx
    mov [eax+wall_y], ebx
    mov edx, 8192
.forward:
    mov eax, ecx
.next_forward:
    cwde
    shl eax, 5
    mov bx, [eax+nextwall]
    test bx, bx
    jge .cross_forward

    ; Reverse from the original wall if the forward chain meets a boundary.
    mov eax, ecx
.next_backward:
    movsx ebx, ax
    mov eax, ebx
    call lastwall
    shl eax, 5
    cmp word [eax+nextwall], 0
    jl .done
    mov eax, ebx
    call lastwall
    shl eax, 5
    mov ax, [eax+nextwall]
    movsx ebx, ax
    shl ebx, 5
    mov [ebx+wall_x], edi
    dec edx
    mov [ebx+wall_y], esi
    cmp ax, cx
    je .done
    test dx, dx
    jg .next_backward
    pop edi
    pop esi
    pop ecx
    ret
.cross_forward:
    movsx eax, bx
    shl eax, 5
    mov ax, [eax+point2]
    movsx ebx, ax
    shl ebx, 5
    mov [ebx+wall_x], edi
    dec edx
    mov [ebx+wall_y], esi
    cmp ax, cx
    je .done
    test dx, dx
    jg .next_forward
.done:
    pop edi
    pop esi
    pop ecx
    ret

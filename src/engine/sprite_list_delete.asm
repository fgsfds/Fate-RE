; Build Engine & Tools Copyright (c) 1993-1997 Ken Silverman.
; See BUILDLIC.TXT. Adapted for the FATE sector and status lists.
BITS 32
ORG 0x50a1d
shared_return equ 0x4abbf

; head array, free head, next array, previous array, sprite field
%macro delete_list 5
    push ebx
    push ecx
    push edx
    push esi
    push edi
    movsx ebx, ax
    imul edx, ebx, 44
    movsx edx, word [edx+%5]
    cmp edx, 1024
    jne %%detach
    mov eax, -1
    jmp near shared_return
%%detach:
    add edx, edx
    cmp ax, [edx+%1]
    jne %%previous
    mov bx, [nosplit ebx*2+%3]
    mov [edx+%1], bx
%%previous:
    movsx edx, ax
    add edx, edx
    mov si, [edx+%4]
    test si, si
    jl %%next
    movsx ebx, si
    mov dx, [edx+%3]
    mov [nosplit ebx*2+%3], dx
%%next:
    movsx edx, ax
    add edx, edx
    mov di, [edx+%3]
    test di, di
    jl %%free_head
    movsx ebx, di
    mov dx, [edx+%4]
    mov [nosplit ebx*2+%4], dx
%%free_head:
    mov dx, [%2]
    test dx, dx
    jl %%prepend_free
    movsx edx, dx
    mov [nosplit edx*2+%4], ax
%%prepend_free:
    movsx ebx, ax
    mov word [nosplit ebx*2+%4], -1
    mov cx, [%2]
    mov [nosplit ebx*2+%3], cx
    imul ebx, ebx, 44
    mov esi, 1024
    mov [%2], ax
    xor eax, eax
    mov [ebx+%5], si
    jmp near shared_return
%endmacro

deletespritesect_:
    delete_list 0x28891e, 0x28911e, 0x1f9ca0, 0x1f6020, 0x2040b8
deletespritestat_:
    delete_list 0x28811c, 0x28891c, 0x1fbca0, 0x1fdca0, 0x2040ba

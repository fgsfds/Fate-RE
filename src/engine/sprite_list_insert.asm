; Build Engine & Tools Copyright (c) 1993-1997 Ken Silverman.
; See BUILDLIC.TXT. Adapted for the FATE sector and status lists.
BITS 32
ORG 0x508cd
shared_return equ 0x4abbf

; head array, free head, next array, previous array, sprite field
%macro insert_list 5
    push ebx
    push ecx
    push edx
    push esi
    push edi
    mov edx, eax
    cwde
    cmp eax, 1024
    jge %%reject
    movsx eax, word [%2]
    cmp eax, -1
    jne %%take_free
%%reject:
    mov eax, -1
    jmp near shared_return
%%take_free:
    mov bx, [%2]
    movsx eax, bx
    mov ax, [nosplit eax*2+%3]
    mov [%2], ax
    test ax, ax
    jl %%attach
    cwde
    mov word [nosplit eax*2+%4], -1
%%attach:
    movsx eax, dx
    mov edi, -1
    add eax, eax
    movsx ecx, bx
    mov si, [eax+%1]
    mov [nosplit ecx*2+%4], di
    mov [nosplit ecx*2+%3], si
    test si, si
    jl %%set_head
    movsx eax, si
    mov [nosplit eax*2+%4], bx
%%set_head:
    movsx eax, dx
    mov [nosplit eax*2+%1], bx
    movsx eax, bx
    imul ecx, eax, 44
    mov [ecx+%5], dx
    jmp near shared_return
%endmacro

insertspritesect_:
    insert_list 0x28891e, 0x28911e, 0x1f9ca0, 0x1f6020, 0x2040b8
insertspritestat_:
    insert_list 0x28811c, 0x28891c, 0x1fbca0, 0x1fdca0, 0x2040ba

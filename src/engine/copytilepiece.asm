; Build Engine & Tools Copyright (c) 1993-1997 Ken Silverman.
; See BUILDLIC.TXT. Adapted for FATE's column-major tile copy.
BITS 32
ORG 0x4cb3a
widths equ 0x1f2020
heights equ 0x1f4020
pixels equ 0x1ffca0
loadtile equ 0x4bb0d

copytilepiece_:
    push esi
    push edi
    push ebp
    sub esp,24
    push eax
    push ebx
    push ecx
    movsx ebx,word [nosplit eax*2+widths]
    movsx eax,word [nosplit eax*2+heights]
    mov [esp+32],eax
    mov eax,[esp+56]
    mov [esp+12],ebx
    movsx ebx,word [nosplit eax*2+widths]
    mov [esp+16],ebx
    movsx eax,word [nosplit eax*2+heights]
    mov ebx,[esp+12]
    mov [esp+28],eax
    test ebx,ebx
    jle near .done
    cmp dword [esp+32],0
    jle near .done
    cmp dword [esp+16],0
    jle near .done
    test eax,eax
    jle near .done

    ; Load either tile when its cached pixel pointer is zero.
    mov eax,[esp+8]
    cmp dword [nosplit eax*4+pixels],0
    jne .destination_tile
    movsx eax,word [esp+8]
    call loadtile
.destination_tile:
    mov eax,[esp+56]
    cmp dword [nosplit eax*4+pixels],0
    jne .begin
    movsx eax,word [esp+56]
    call loadtile
.begin:
    xor ecx,ecx
    mov [esp+24],edx
    mov [esp+20],ecx
    jmp near .column_test
.column:
    mov eax,[esp+4]
    xor edx,edx
    jmp near .row_test
.row:
    mov ebx,[esp+60]
    mov esi,[esp+20]
    mov ecx,[esp+64]
    add ebx,esi
    add ecx,edx
    test ebx,ebx
    jl .next_row
    test ecx,ecx
    jl .next_row
    cmp ebx,[esp+16]
    jge .next_row
    cmp ecx,[esp+28]
    jge .next_row
    mov edi,[esp+24]
    imul edi,[esp+32]
    imul ebx,[esp+28]
    mov esi,[esp+8]
    mov esi,[nosplit esi*4+pixels]
    add esi,edi
    mov edi,[esp+56]
    add ebx,[nosplit edi*4+pixels]
    add ecx,ebx
    mov bl,[esi+eax]
    movzx esi,bl
    cmp esi,255
    je .next_row
    mov [ecx],bl
.next_row:
    mov ebx,[esp+32]
    inc eax
    cmp eax,ebx
    jl .increment_row
    xor eax,eax
.increment_row:
    inc edx
.row_test:
    cmp edx,[esp+52]
    jl .row
    mov ebp,[esp+24]
    inc ebp
    mov edx,[esp+12]
    mov [esp+24],ebp
    cmp ebp,edx
    jl .increment_column
    xor ebx,ebx
    mov [esp+24],ebx
.increment_column:
    inc dword [esp+20]
.column_test:
    mov eax,[esp+20]
    cmp eax,[esp]
    jl near .column
.done:
    add esp,36
shared_copy_return:
    pop ebp
    pop edi
    pop esi
    ret 16

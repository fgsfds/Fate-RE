; DOS directory searches and DTA transfer.
BITS 32
ORG 0x67572

dos_search_status equ 0x6e78e
extender_type equ 0x1449a

dos_find_first:
    push ecx
    push eax
    push edx
    mov edx, ebx
    mov ah, 0x1a
    int 0x21
    pop ecx
    pop edx
    mov ah, 0x4e
    int 0x21
    call dos_search_status
    mov edx, ebx
    call copy_dta_to_caller
    pop ecx
    ret

dos_find_next:
    push edx
    mov edx, eax
    mov ah, 0x1a
    int 0x21
    call copy_caller_to_dta
    mov ah, 0x4f
    int 0x21
    call dos_search_status
    call copy_dta_to_caller
    pop edx
    ret

dos_find_close:
    xor eax, eax
    ret

copy_dta_to_caller:
    cmp byte [extender_type], 9
    jne short return_from_read
    push eax
    push ebx
    push ecx
    push esi
    push edi
    mov ah, 0x2f
    int 0x21
    mov esi, ebx
    mov edi, edx
    mov ecx, 0x2b
    rep movsb
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop eax

return_from_read:
    ret

copy_caller_to_dta:
    cmp byte [extender_type], 9
    jne short return_from_write
    push eax
    push ebx
    push ecx
    push esi
    push edi
    mov ah, 0x2f
    int 0x21
    mov edi, ebx
    mov esi, edx
    mov ecx, 0x2b
    rep movsb
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop eax

return_from_write:
    ret

copy_c_string:
    push ebx

copy_next_byte:
    mov bl, byte [edx]
    mov byte [eax], bl
    test bl, bl
    je short return_from_copy
    inc eax
    inc edx
    jmp short copy_next_byte

return_from_copy:
    pop ebx
    ret

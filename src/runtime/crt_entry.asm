; Run C main and dispatch the Watcom initializer and finalizer tables.
BITS 32
ORG 0x6332b

init_table equ 0x199b4
fini_table equ 0x199d8
fini_table_end equ 0x199e4

    times 79 db 0    ; __CMain is supplied by C.

__InitRtns:
    push esi
    push edi
    push ebx
    push edx
    push es
    mov edx, eax

.restart_scan:
    ds mov esi, init_table
    ds mov edi, fini_table
    mov ebx, edi
    mov al, dl

.check_entry:
    cmp esi, edi
    jae short .check_selection
    cmp byte [esi], 2
    je short .advance_entry
    cmp byte [esi + 1], al
    ja short .advance_entry
    mov ebx, esi
    mov al, byte [esi + 1]

.advance_entry:
    add esi, 6
    jmp short .check_entry

.check_selection:
    cmp ebx, edi
    je short .restore_registers
    mov eax, dword [ebx + 2]
    or eax, eax
    je short .mark_processed
    push ds
    pop es
    push edx
    call eax
    pop edx

.mark_processed:
    mov byte [ebx], 2
    jmp short .restart_scan

.restore_registers:
    pop es
    pop edx
    pop ebx
    pop edi
    pop esi
    ret

__FiniRtns:
    push esi
    push edi
    push ebx
    push es
    mov dh, dl
    mov dl, al

.restart_scan:
    ds mov esi, fini_table
    ds mov edi, fini_table_end
    mov ebx, edi
    mov al, dl

.check_entry:
    cmp esi, edi
    jae short .check_selection
    cmp byte [esi], 2
    je short .advance_entry
    cmp al, byte [esi + 1]
    ja short .advance_entry
    mov ebx, esi
    mov al, byte [esi + 1]

.advance_entry:
    add esi, 6
    jmp short .check_entry

.check_selection:
    cmp ebx, edi
    je short .restore_registers
    cmp al, dh
    ja short .mark_processed
    mov eax, dword [ebx + 2]
    or eax, eax
    je short .mark_processed
    push ds
    pop es
    push edx
    call eax
    pop edx

.mark_processed:
    mov byte [ebx], 2
    jmp short .restart_scan

.restore_registers:
    pop es
    pop ebx
    pop edi
    pop esi
    ret

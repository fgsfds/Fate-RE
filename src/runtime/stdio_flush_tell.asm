; Flush stream data or reposition after a buffered read, and report the logical position.
BITS 32
ORG 0x64b2b

lseek_ equ 0x615b6
set_errno equ 0x6468e
tell_ equ 0x6adb5
write_stream_descriptor equ 0x6aebe
psp_selector_data_offset equ 0x94478 - 0x80000

get_psp_selector:
    mov eax, [psp_selector_data_offset]
    ret

flush_stream:
    push ebx
    push ecx
    push edx
    push esi
    mov ecx, eax
    mov ah, byte [eax + 0xd]
    xor esi, esi
    test ah, 0x10
    je short .flush_read_buffer
    mov bh, byte [ecx + 0xd]
    and bh, 0xef
    mov al, byte [ecx + 0xc]
    mov byte [ecx + 0xd], bh
    test al, 2
    je near .reset_buffer
    cmp dword [ecx + 8], 0
    je near .reset_buffer
    mov ebx, dword [ecx + 4]
    mov edx, dword [ecx + 8]
    mov eax, dword [ecx + 0x10]
    call write_stream_descriptor
    cmp eax, -1
    jne short .check_short_write
    mov dl, byte [ecx + 0xc]
    or dl, 0x20
    mov esi, eax
    mov byte [ecx + 0xc], dl
    jmp short .reset_buffer

.check_short_write:
    cmp eax, dword [ecx + 4]
    je short .reset_buffer
    mov eax, 0xc
    call set_errno
    mov ah, byte [ecx + 0xc]
    or ah, 0x20
    mov esi, 0xffffffff
    mov byte [ecx + 0xc], ah
    jmp short .reset_buffer

.flush_read_buffer:
    cmp dword [ecx + 8], 0
    je short .reset_buffer
    mov dl, byte [ecx + 0xc]
    and dl, 0xef
    mov dh, byte [ecx + 0xd]
    mov byte [ecx + 0xc], dl
    test dh, 0x20
    jne short .reset_buffer
    mov eax, dword [ecx + 4]
    test eax, eax
    je short .check_seek_error
    mov edx, eax
    mov ebx, 1
    neg edx
    mov eax, dword [ecx + 0x10]
    call lseek_

.check_seek_error:
    cmp eax, -1
    jne short .reset_buffer
    mov bl, byte [ecx + 0xc]
    or bl, 0x20
    mov esi, eax
    mov byte [ecx + 0xc], bl

.reset_buffer:
    mov eax, dword [ecx + 8]
    mov dword [ecx + 4], 0
    mov dword [ecx], eax
    mov eax, esi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

ftell_:
    push ebx
    push ecx
    push edx
    mov edx, eax
    mov eax, dword [eax + 0x10]
    call tell_
    mov ebx, eax
    cmp eax, -1
    je short .return
    mov ecx, dword [edx + 4]
    test ecx, ecx
    je short .return
    test byte [edx + 0xd], 0x10
    je short .subtract_unread
    lea eax, [nosplit ecx + ebx]
    pop edx
    pop ecx
    pop ebx
    ret

.subtract_unread:
    mov eax, ebx
    sub eax, ecx

.return:
    pop edx
    pop ecx
    pop ebx
    ret

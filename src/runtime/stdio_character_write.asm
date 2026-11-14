; Close DOS descriptors, remove files and buffer stream character writes.
BITS 32
ORG 0x64c20

set_errno equ 0x6468e
allocate_stream_buffer equ 0x64932
flush_stream equ 0x64b31
set_io_mode equ 0x657d8
remove_file_dos equ 0x6af3a

close_descriptor:
    push ebx
    push edx
    mov edx, eax
    mov ebx, eax
    mov ah, 0x3e
    int 0x21
    rcl eax, 1
    ror eax, 1
    test eax, eax
    jl short .close_error
    mov eax, edx
    xor edx, edx
    call set_io_mode
    xor eax, eax
    pop edx
    pop ebx
    ret

.close_error:
    mov eax, 4
    call set_errno
    mov eax, 0xffffffff
    pop edx
    pop ebx
    ret

remove_:
    jmp near remove_file_dos

fputc_:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    mov ebx, eax
    test byte [edx + 0xc], 2
    jne short .check_buffer
    mov eax, 4
    call set_errno
    or byte [edx + 0xc], 0x20

.write_error:
    mov eax, 0xffffffff
    jmp near .return

.check_buffer:
    cmp dword [edx + 8], 0
    jne short .set_flush_mask
    mov eax, edx
    call allocate_stream_buffer

.set_flush_mask:
    mov ecx, 0x400
    cmp ebx, 0xa
    jne short .write_character
    mov al, byte [edx + 0xc]
    mov ecx, 0x600
    test al, 0x40
    jne short .write_character
    or byte [edx + 0xd], 0x10
    mov eax, dword [edx]
    mov byte [eax], 0xd
    mov esi, dword [edx]
    inc esi
    mov edi, dword [edx + 4]
    mov dword [edx], esi
    inc edi
    mov ebp, dword [edx + 0x14]
    mov dword [edx + 4], edi
    cmp edi, ebp
    jne short .write_character
    mov eax, edx
    call flush_stream
    test eax, eax
    jne short .write_error

.write_character:
    or byte [edx + 0xd], 0x10
    mov eax, dword [edx]
    mov byte [eax], bl
    mov eax, dword [edx]
    inc eax
    mov esi, dword [edx + 4]
    mov dword [edx], eax
    inc esi
    mov edi, dword [edx + 0xc]
    mov dword [edx + 4], esi
    test ecx, edi
    jne short .flush_buffer
    cmp esi, dword [edx + 0x14]
    jne short .return_character

.flush_buffer:
    mov eax, edx
    call flush_stream
    test eax, eax
    jne short .write_error

.return_character:
    xor eax, eax
    mov al, bl

.return:
    pop ebp
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

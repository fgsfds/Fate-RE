; Write to a DOS descriptor, seeking to the end for append mode.
BITS 32
ORG 0x6aebe

set_errno equ 0x6468e
set_dos_errno equ 0x6571d
get_io_mode equ 0x65783

write_stream_descriptor:
    push ecx
    push esi
    push edi
    push ebp
    sub esp, 4
    mov esi, eax
    mov dword [esp], edx
    mov ebp, ebx
    call get_io_mode
    test al, 0x80
    je short .write_bytes
    mov al, 2
    mov ebx, esi
    xor edx, edx
    mov ah, 0x42
    mov ecx, edx
    shr ecx, 0x10
    int 0x21
    rcl dx, 1
    ror dx, 1
    shl edx, 0x10
    mov dx, ax
    mov edi, edx
    test edx, edx
    jge short .write_bytes
    xor eax, eax
    mov ax, dx

.translate_error:
    call set_dos_errno
    jmp short .return

.write_bytes:
    mov edx, dword [esp]
    mov ebx, esi
    mov ecx, ebp
    mov ah, 0x40
    int 0x21
    rcl eax, 1
    ror eax, 1
    mov esi, eax
    mov edi, eax
    mov edx, eax
    test eax, eax
    jge short .check_short_write
    xor eax, eax
    mov ax, si
    jmp short .translate_error

.check_short_write:
    cmp eax, ebp
    je short .return_count
    mov eax, 0xc
    call set_errno

.return_count:
    mov eax, edx

.return:
    add esp, 4
    pop ebp
    pop edi
    pop esi
    pop ecx
    ret

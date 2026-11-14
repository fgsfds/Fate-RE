; Delete a DOS file and exchange the runtime hook pointer.
BITS 32
ORG 0x6af3a

set_dos_errno equ 0x6571d
runtime_hook equ 0x17494

remove_file_dos:
    push edx
    mov edx, eax
    mov ah, 0x41
    int 0x21
    rcl eax, 1
    ror eax, 1
    test eax, eax
    jge short .success
    and eax, 0xffff
    call set_dos_errno
    pop edx
    ret

.success:
    xor eax, eax
    pop edx
    ret

exchange_runtime_hook:
    push edx
    mov edx, eax
    mov eax, dword [runtime_hook]
    mov dword [runtime_hook], edx
    pop edx
    ret

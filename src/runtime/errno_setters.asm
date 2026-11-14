; Publish DOS and C runtime error codes.
BITS 32
ORG 0x6468e

get_errno_address equ 0x67a09
get_dos_error_address equ 0x67a0f

set_errno:
    push edx
    mov edx, eax
    call get_errno_address
    mov dword [eax], edx
    pop edx
    ret

set_bad_address:
    mov eax, 0xe
    jmp short set_errno

bad_file_descriptor:
    mov eax, 9
    call set_errno
    mov eax, 0xffffffff
    ret

set_runtime_error:
    push edx
    mov edx, eax
    call get_dos_error_address
    mov dword [eax], edx
    pop edx
    ret

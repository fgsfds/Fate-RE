; Translate DOS return status to the CRT error state.
BITS 32
ORG 0x65718

set_errno equ 0x6468e
set_runtime_error equ 0x646b1
dos_major_version equ 0x144a3
dos_error_table_window equ 0x16a99

translate_exec_result:
    test edx, edx
    jne short set_dos_errno
    ret

set_dos_errno:
    push ebx
    push edx
    mov edx, eax
    mov bl, al
    xor eax, eax
    mov al, dl
    call set_runtime_error
    cmp edx, strict dword 0x100
    jae short decode_explicit_errno
    cmp byte [dos_major_version], 3
    jb short clamp_error_index
    cmp dl, 0x50
    jne short check_extended_error
    mov bl, 0xe
    jmp short clamp_error_index

check_extended_error:
    cmp dl, 0x22
    jb short check_sharing_error
    mov bl, 0x13
    jmp short clamp_error_index

check_sharing_error:
    cmp dl, 0x20
    jb short clamp_error_index
    mov bl, 5

clamp_error_index:
    cmp bl, 0x13
    jbe short map_dos_error
    mov bl, 0x13

map_dos_error:
    xor edx, edx
    mov dl, bl
    mov eax, dword [edx + dos_error_table_window]
    sar eax, 0x18
    jmp short publish_errno

decode_explicit_errno:
    mov eax, edx
    shr eax, 8
    and eax, strict dword 0xff

publish_errno:
    call set_errno
    mov eax, 0xffffffff
    pop edx
    pop ebx
    ret

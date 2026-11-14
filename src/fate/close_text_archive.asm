; Close text archive.
BITS 32
ORG 0x380b4

text_archive_open equ 0x12d94
text_archive_handle equ 0x12d98
close equ 0x6219a

close_text_archive:
    push ebx
    push edx
    mov edx, [text_archive_handle]
    cmp edx, -1
    jz short .branch_380c8
    mov eax, edx
    call close

.branch_380c8:
    xor ebx, ebx
    mov eax, 0x1
    mov [text_archive_open], ebx
    pop edx
    pop ebx
    ret

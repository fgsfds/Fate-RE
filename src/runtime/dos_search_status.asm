; Translate carry and DOS error status for directory searches.
BITS 32
ORG 0x6e78e

set_dos_errno equ 0x6571d

dos_search_status:
    jae short return_success
    and eax, strict dword 0xffff
    push eax
    call set_dos_errno
    pop eax
    jmp short return_status

return_success:
    sub eax, eax

return_status:
    ret

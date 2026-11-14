; Reset the DOS mouse driver and record whether it is present.
BITS 32
ORG 0x5440e

mouse_present equ 0x14002

initialize_mouse:
    mov ax, 0x0
    int byte 0x33
    and eax, strict dword 0xffff
    mov [mouse_present], al
    and eax, strict dword 0xff
    ret

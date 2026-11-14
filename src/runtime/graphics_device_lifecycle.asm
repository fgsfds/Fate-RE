; Graphics runtime entry points.
BITS 32
ORG 0x7003d

graphics_device equ 0x289212

initialize_graphics_device:
    push edx
    mov edx, dword [graphics_device]
    cwde
    call dword [edx]
    pop edx
    ret

shutdown_graphics_device:
    mov eax, dword [graphics_device]
    call dword [eax + 4]
    ret

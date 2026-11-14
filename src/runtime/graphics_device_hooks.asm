; Call the active graphics device before and after drawing.
BITS 32
ORG 0x70052

graphics_device equ 0x289212

begin_graphics_device:
    mov eax, dword [graphics_device]
    call dword [eax + 8]
    ret

end_graphics_device:
    mov eax, dword [graphics_device]
    call dword [eax + 0xc]
    ret

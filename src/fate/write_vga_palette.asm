; Write vga palette.
BITS 32
ORG 0x40b99


write_vga_palette:
    xor eax, eax
    mov edx, 0x3c8
    out dx, al
    mov edx, 0x3c9
    mov cx, 0x100

.write_rgb:
    lodsb
    out dx, al
    lodsb
    out dx, al
    lodsb
    out dx, al
    loop .write_rgb
    cld
    ret

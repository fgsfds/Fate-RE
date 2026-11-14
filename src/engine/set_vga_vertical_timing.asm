; Program the VGA CRTC vertical timing registers.
BITS 32
ORG 0x599c5

restore_ebp_edi_esi equ 0x4918a

set_vga_vertical_timing:
    push esi
    push edi
    push ebp
    mov esi, eax
    mov edi, edx
    mov ebp, ebx
    mov eax, 0x11
    mov edx, 0x3d4
    out dx, al
    mov edx, 0x3d5
    in al, dx
    and eax, 0x7f
    out dx, al
    mov eax, 0x6
    mov edx, 0x3d4
    out dx, al
    mov eax, esi
    mov edx, 0x3d5
    and eax, strict dword 0xff
    out dx, al
    mov eax, esi
    and eax, strict dword 0x100
    sar eax, byte 0x8
    mov bl, al
    mov eax, [esp + 0x14]
    and eax, strict dword 0x100
    sar eax, byte 0x7
    and ebx, strict dword 0xff
    add ebx, eax
    mov eax, ecx
    and eax, strict dword 0x100
    sar eax, byte 0x6
    and ebx, strict dword 0xff
    add ebx, eax
    mov eax, edi
    and eax, strict dword 0x100
    sar eax, byte 0x5
    and ebx, strict dword 0xff
    add ebx, eax
    mov eax, esi
    and eax, strict dword 0x200
    sar eax, byte 0x4
    and ebx, strict dword 0xff
    add ebx, eax
    mov eax, [esp + 0x14]
    and eax, strict dword 0x200
    sar eax, byte 0x3
    and ebx, strict dword 0xff
    add ebx, eax
    mov eax, ecx
    and eax, strict dword 0x200
    sar eax, byte 0x2
    and ebx, strict dword 0xff
    mov edx, 0x3d4
    add ebx, eax
    mov eax, 0x7
    out dx, al
    mov edx, 0x3d5
    in al, dx
    mov esi, eax
    xor eax, eax
    and esi, 0x10
    mov al, bl
    or eax, esi
    out dx, al
    mov eax, 0x9
    mov edx, 0x3d4
    out dx, al
    mov edx, 0x3d5
    in al, dx
    mov ebx, eax
    mov eax, edi
    and eax, strict dword 0x200
    and ebx, strict dword 0xdf
    sar eax, byte 0x4
    or eax, ebx
    out dx, al
    mov eax, 0x10
    mov edx, 0x3d4
    out dx, al
    mov eax, ecx
    mov edx, 0x3d5
    and eax, strict dword 0xff
    out dx, al
    mov eax, 0x11
    mov edx, 0x3d4
    mov ebx, [esp + 0x10]
    out dx, al
    mov edx, 0x3d5
    and ebx, 0xf
    in al, dx
    and eax, strict dword 0xf0
    add eax, ebx
    out dx, al
    mov eax, 0x12
    mov edx, 0x3d4
    out dx, al
    mov eax, [esp + 0x14]
    mov edx, 0x3d5
    and eax, strict dword 0xff
    out dx, al
    mov eax, 0x15
    mov edx, 0x3d4
    out dx, al
    mov eax, edi
    mov edx, 0x3d5
    and eax, strict dword 0xff
    out dx, al
    mov eax, 0x16
    mov edx, 0x3d4
    out dx, al
    mov eax, ebp
    mov edx, 0x3d5
    and eax, strict dword 0xff
    out dx, al
    mov eax, 0x9
    mov edx, 0x3d4
    out dx, al
    mov edx, 0x3d5
    in al, dx
    and eax, strict dword 0xfe
    out dx, al
    jmp near restore_ebp_edi_esi

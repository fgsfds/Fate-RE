; Reset the DOS buffer settings and clear the VBE probe flag.
BITS 32
ORG 0x4476c

video_dos_buffer_size equ 0x13fe8
video_dos_allocation equ 0x13fec
vesa_probe_attempted equ 0x13ff4

reset_vesa_state:
    push ebx
    push edx
    mov edx, 0x400
    xor ebx, ebx
    xor ah, ah
    mov [video_dos_buffer_size], edx
    mov [video_dos_allocation], ebx
    mov [vesa_probe_attempted], ah
    pop edx
    pop ebx
    ret

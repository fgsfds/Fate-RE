; Free video dos memory.
BITS 32
ORG 0x43a1d

frame_state_13fec equ 0x13fec
int386 equ 0x630b3

free_video_dos_memory:
    push ebx
    push edx
    sub esp, 0x1c
    mov edx, 0x101
    mov ebx, esp
    mov ax, [frame_state_13fec]
    mov [esp], dx
    mov [esp + 0xc], ax
    mov edx, esp
    mov eax, 0x31
    call int386
    cld
    mov ax, ds
    mov es, eax
    add esp, 0x1c
    pop edx
    pop ebx
    ret

; Query vesa mode.
BITS 32
ORG 0x43b28

allocate_video_dos_memory equ 0x43a50

query_vesa_mode:
    push ebx
    push ecx
    sub esp, 0x10
    mov ecx, edx
    mov edx, 0x4f01
    mov ebx, 0x100
    mov [esp + 0x4], ax
    mov eax, esp
    mov [esp], dx
    mov edx, ecx
    call allocate_video_dos_memory
    xor eax, eax
    mov ax, [esp]
    cmp eax, 0x4f
    jz short .branch_43b5a
    xor eax, eax
    jmp short .branch_43b6b

.branch_43b5a:
    mov ax, [ecx]
    xor ah, ah
    and al, 0x1
    cwde
    test eax, eax
    jz short .branch_43b6b
    mov eax, 0x1

.branch_43b6b:
    add esp, 0x10
    pop ecx
    pop ebx
    ret

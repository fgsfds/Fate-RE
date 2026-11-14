; Track DOS descriptor modes and lazily detect standard character devices.
BITS 32
ORG 0x65783

isatty_ equ 0x656f3
descriptor_count equ 0x16ab4
descriptor_modes equ 0x16b08

get_io_mode:
    push ebx
    push ecx
    push edx
    mov edx, eax
    cmp eax, [descriptor_count]
    jb short .check_standard_handle
    xor eax, eax
    pop edx
    pop ecx
    pop ebx
    ret

.check_standard_handle:
    cmp eax, 5
    jg short .read_mode
    mov ebx, eax
    mov eax, [descriptor_modes]
    shl ebx, 2
    add eax, ebx
    mov cl, [eax + 1]
    test cl, 0x40
    jne short .read_mode
    mov ch, cl
    or ch, 0x40
    mov [eax + 1], ch
    mov eax, edx
    call isatty_
    test eax, eax
    je short .read_mode
    mov eax, [descriptor_modes]
    or byte [nosplit ebx + eax + 1], 0x20

.read_mode:
    mov eax, [descriptor_modes]
    mov eax, [eax + edx*4]
    pop edx
    pop ecx
    pop ebx
    ret

set_io_mode:
    push ebx
    or dh, 0x40
    mov ebx, edx
    mov edx, eax
    mov eax, [descriptor_modes]
    shl edx, 2
    mov [nosplit edx + eax], ebx
    pop ebx
    ret

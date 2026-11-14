; Parse hexadecimal.
BITS 32
ORG 0x361da

frame_state_12cf0 equ 0x12cf0
parse_hex_digits equ 0x36211
strlen equ 0x60381

parse_hexadecimal:
    push ebx
    push edx
    push esi
    push edi
    mov edi, eax
    call strlen
    mov edx, eax
    xor esi, esi
    xor ebx, ebx

.branch_361eb:
    mov eax, ebx
    inc ebx
    mov al, [edi + eax]
    and eax, strict dword 0xff
    call parse_hex_digits
    imul eax, [nosplit edx*4 + frame_state_12cf0]
    dec edx
    add esi, eax
    test edx, edx
    ja short .branch_361eb
    mov eax, esi
    pop edi
    pop esi
    pop edx
    pop ebx
    ret

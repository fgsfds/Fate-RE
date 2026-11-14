; Set sprite coordinates and update its sector list if necessary.
BITS 32
ORG 0x506f6

changespritesect equ 0x50bc3
updatesector equ 0x542c4
sprite_x equ 0x2040a0
sprite_y equ 0x2040a4
sprite_z equ 0x2040a8
sprite_sector equ 0x2040b8

setsprite:
    push esi
    push edi
    sub esp, 0x4
    mov edi, eax
    mov esi, edx
    mov edx, ebx
    mov eax, ecx
    movsx edi, di
    imul ecx, edi, 0x2c
    mov [ecx + sprite_y], ebx
    mov [ecx + sprite_z], eax
    mov ax, [ecx + sprite_sector]
    mov ebx, esp
    mov [esp], eax
    mov eax, esi
    mov [ecx + sprite_x], esi
    call updatesector
    mov edx, [esp]
    test dx, dx
    jnl short .branch_5073d
    mov eax, 0xffffffff
    jmp short .branch_50752

.branch_5073d:
    cmp dx, [ecx + sprite_sector]
    jz short .branch_50750
    movsx edx, dx
    mov eax, edi
    call changespritesect

.branch_50750:
    xor eax, eax

.branch_50752:
    add esp, 0x4
    pop edi
    pop esi
    ret

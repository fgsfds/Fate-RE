; Calculate interleaved CGA two-bit pixel addresses.
BITS 32
ORG 0x7015e

; The final mask stores are shared with the linked monochrome routine.
cga_store_masks equ 0x70144
current_buffer_selector equ 0x289226
current_buffer_offset equ 0x289228
pixel_address equ 0x2891ec
pixel_selector equ 0x2891f0
pixel_bit_offset equ 0x2891f6

address_cga_two_bit_pixel:
    push ecx
    enter 4, 0
    mov ecx, eax
    mov word [ebp - 4], dx
    movsx eax, dx
    sar eax, 1
    imul edx, eax, 0x50
    movsx eax, cx
    sar eax, 2
    add eax, edx
    test byte [ebp - 4], 1
    je short .store_address
    add ah, 0x20
.store_address:
    and cl, 3
    xor ch, ch
    mov dx, word [current_buffer_selector]
    add ecx, ecx
    movzx eax, ax
    mov word [pixel_bit_offset], cx
    mov word [pixel_selector], dx
    mov dl, byte [pixel_bit_offset]
    add eax, dword [current_buffer_offset]
    inc dl
    mov dword [pixel_address], eax
    inc dl
    mov al, 0xfc
    mov cl, dl
    o16 ror al, cl
    movzx ax, al
    shl eax, 8
    inc eax
    inc eax
    jmp near cga_store_masks

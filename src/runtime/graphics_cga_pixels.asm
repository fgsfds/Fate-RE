; Calculate interleaved CGA pixel addresses and switch back to a text mode.
BITS 32
ORG 0x700e0

set_and_query_bios_mode equ 0x72180
read_graphics_mode_state equ 0x6fc6d

current_buffer_selector equ 0x289226
current_buffer_offset equ 0x289228
pixel_address equ 0x2891ec
pixel_selector equ 0x2891f0
pixel_color equ 0x2891f2
pixel_mask_and_width equ 0x2891f4
pixel_bit_offset equ 0x2891f6

address_cga_mono_pixel:
    push ecx
    enter 4, 0
    mov ecx, eax
    mov word [ebp - 4], dx
    movsx eax, dx
    sar eax, 1
    imul edx, eax, 0x50
    movsx eax, cx
    sar eax, 3
    add edx, eax
    test byte [ebp - 4], 1
    je short .store_address
    add dh, 0x20
.store_address:
    movzx eax, dx
    and cl, 7
    xor ch, ch
    mov dx, word [current_buffer_selector]
    mov word [pixel_bit_offset], cx
    add eax, dword [current_buffer_offset]
    mov word [pixel_selector], dx
    mov dl, byte [pixel_bit_offset]
    mov dword [pixel_address], eax
    inc dl
    mov al, 0xfe
    mov cl, dl
    o16 ror al, cl
    movzx ax, al
    shl eax, 8
    or al, 1
.store_masks:
    mov cl, dl
    mov word [pixel_mask_and_width], ax
    mov al, bl
    o16 ror al, cl
    movzx ax, al
    mov word [pixel_color], ax
    leave
    pop ecx
    ret

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
    jmp near address_cga_mono_pixel.store_masks

set_text_video_mode:
    push edx
    mov edx, eax
    cwde
    call set_and_query_bios_mode
    cmp ax, dx
    jne short .failed
    call read_graphics_mode_state
    mov eax, 1
    pop edx
    ret
.failed:
    xor eax, eax
    pop edx
    ret

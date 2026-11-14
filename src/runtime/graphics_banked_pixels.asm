; Resolve pixel positions and select the active framebuffer bank.
BITS 32
ORG 0x70d0f

end_planar_drawing equ 0x70508
bank_selector_callback equ 0x2891e8
current_buffer_selector equ 0x289226
current_buffer_offset equ 0x289228
pixel_address equ 0x2891ec
pixel_selector equ 0x2891f0
pixel_color equ 0x2891f2
pixel_mask equ 0x2891f4
pixel_bit_offset equ 0x2891f6

finish_banked_planar_drawing:
    call end_planar_drawing
    xor eax, eax

select_graphics_bank:
    push edx
    enter 4, 0
    mov edx, dword [bank_selector_callback]
    cwde
    mov dword [ebp - 4], edx
    call dword [ebp - 4]
    leave
    pop edx
    ret

address_planar_pixel_800:
    push ecx
    push esi
    mov esi, eax
    movsx ecx, dx
    imul eax, ecx, 0x64
    movsx ecx, si
    sar ecx, 3
    mov word [pixel_color], bx
    add eax, ecx
    and esi, 7
    add eax, dword [current_buffer_offset]
    movsx ecx, si
    mov dword [pixel_address], eax
    mov eax, 0x80
    mov dx, word [current_buffer_selector]
    sar eax, cl
    mov word [pixel_selector], dx
    shl eax, 8
    mov word [pixel_bit_offset], si
    mov word [pixel_mask], ax
    pop esi
    pop ecx
    ret

address_banked_planar_pixel_1024:
    push ecx
    mov ecx, eax
    movsx edx, dx
    cwde
    shl edx, 7
    sar eax, 3
    add edx, eax
    mov eax, edx
    and cl, 7
    shr eax, 0x10
    xor ch, ch
    cwde
    and edx, strict dword 0xffff
    call select_graphics_bank
    mov ax, word [current_buffer_selector]
    mov word [pixel_bit_offset], cx
    mov word [pixel_selector], ax
    movsx ecx, cx
    mov eax, 0x80
    mov word [pixel_color], bx
    sar eax, cl
    add edx, dword [current_buffer_offset]
    shl eax, 8
    mov dword [pixel_address], edx
    mov word [pixel_mask], ax
    pop ecx
    ret

address_banked_byte_pixel_640:
    movsx edx, dx
    imul edx, edx, 0x280
.extend_x:
    cwde
.add_x:
    add edx, eax
    mov eax, edx
    shr eax, 0x10
    cwde
    and edx, strict dword 0xffff
    call select_graphics_bank
    mov word [pixel_bit_offset], 0
    mov ax, word [current_buffer_selector]
    mov word [pixel_color], bx
    add edx, dword [current_buffer_offset]
    mov word [pixel_selector], ax
    mov dword [pixel_address], edx
    ret

address_banked_byte_pixel_800:
    movsx edx, dx
    imul edx, edx, 0x320
    jmp short address_banked_byte_pixel_640.extend_x

address_banked_byte_pixel_1024:
    movsx edx, dx
    cwde
    shl edx, 0xa
    jmp short address_banked_byte_pixel_640.add_x

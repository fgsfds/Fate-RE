; Draw a rectangle as horizontal spans and size captured bitmap buffers.
BITS 32
ORG 0x71a82

begin_graphics_device equ 0x70052
end_graphics_device equ 0x7005b
draw_graphics_span equ 0x735c4
graphics_available equ 0x6ffe6
viewport_origin_y equ 0x16c6e
viewport_origin_x equ 0x16c6c
bitmap_layout_flags equ 0x289234
bitmap_bits_per_pixel equ 0x289206

fill_graphics_rectangle:
    push esi
    push edi
    enter 4, 0
    mov edi, eax
    mov esi, edx
    cmp ax, bx
    jle short .order_y
    mov edi, ebx
    mov ebx, eax
.order_y:
    cmp si, cx
    jle short .prepare_rows
    mov eax, esi
    mov esi, ecx
    mov ecx, eax
.prepare_rows:
    sub ebx, edi
    inc ebx
    call begin_graphics_device
    mov dword [ebp - 4], ebx
    jmp short .check_row
.draw_row:
    movsx ebx, word [ebp - 4]
    movsx edx, si
    movsx eax, di
    call draw_graphics_span
    inc esi
.check_row:
    cmp si, cx
    jle short .draw_row
    call end_graphics_device
    leave
    pop edi
    pop esi
    ret

viewport_bitmap_size:
    push esi
    mov esi, eax
    call graphics_available
    test ax, ax
    je short .unavailable
    add cx, word [viewport_origin_y]
    add bx, word [viewport_origin_x]
    add dx, word [viewport_origin_y]
    add si, word [viewport_origin_x]
    movsx ecx, cx
    movsx ebx, bx
    movsx edx, dx
    movsx eax, si
    call bitmap_rectangle_size
    pop esi
    ret
.unavailable:
    xor eax, eax
    pop esi
    ret

bitmap_rectangle_size:
    push esi
    push edi
    mov esi, eax
    mov edi, edx
    movsx eax, bx
    movsx edx, si
    sub eax, edx
    cdq
    xor eax, edx
    sub eax, edx
    mov ebx, eax
    movsx edx, cx
    movsx eax, di
    sub edx, eax
    mov eax, edx
    inc ebx
    cdq
    xor eax, edx
    sub eax, edx
    mov ecx, eax
    movsx eax, bx
    inc ecx
    call bitmap_row_bytes
    movsx edx, ax
    movsx eax, cx
    imul eax, edx
    add eax, 6
    pop edi
    pop esi
    ret

bitmap_row_bytes:
    push edx
    test byte [bitmap_layout_flags], 1
    je short .packed_pixels
    cwde
    add eax, 7
    cdq
    shl edx, 3
    db 0x1b, 0xc2 ; SBB eax, edx, register-destination encoding.
    sar eax, 3
    movsx edx, word [bitmap_bits_per_pixel]
    imul eax, edx
    pop edx
    ret
.packed_pixels:
    movsx edx, word [bitmap_bits_per_pixel]
    cwde
    imul eax, edx
    add eax, 7
    cdq
    shl edx, 3
    db 0x1b, 0xc2 ; SBB eax, edx, register-destination encoding.
    sar eax, 3
    pop edx
    ret

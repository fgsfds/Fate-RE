; Apply video mode parameters and show or hide the text cursor.
BITS 32
ORG 0x6fe1e

read_graphics_mode_state equ 0x6fc6d
set_drawing_action equ 0x71950
draw_clipped_solid_line equ 0x71c23
set_drawing_color equ 0x71a46
graphics_active equ 0x16c65
pixel_width equ 0x2891fc
pixel_height equ 0x2891fe
palette_size equ 0x289204
bitmap_bits_per_pixel equ 0x289206
mode_buffer_offset equ 0x28922e
text_page_count equ 0x289208
mode_buffer_selector equ 0x289232
mode_buffer_stride equ 0x28922c
bitmap_layout_flags equ 0x289234
current_buffer_stride equ 0x289226
current_buffer_offset equ 0x289228
cursor_visible equ 0x16c76
active_text_page equ 0x16c78
bios_data_offset equ 0x16d01
bios_data_selector equ 0x16cf7
text_cursor_row equ 0x2891f8
text_cursor_column equ 0x2891fa
text_cursor_shape equ 0x28923c
drawing_color equ 0x16c80
text_columns equ 0x289200
text_rows equ 0x289202

apply_graphics_mode_state:
    push esi
    push ebp
    mov ebp, esp
    mov esi, eax
    mov byte [graphics_active], 1
    call read_graphics_mode_state
    mov eax, dword [ebp + 0x14]
    mov word [pixel_width], si
    mov word [pixel_height], dx
    mov word [palette_size], bx
    mov word [bitmap_bits_per_pixel], cx
    mov edx, dword [ebp + 0xc]
    mov dword [mode_buffer_offset], eax
    mov eax, dword [ebp + 0x18]
    mov word [text_page_count], dx
    mov edx, dword [ebp + 0x10]
    mov word [mode_buffer_selector], ax
    mov eax, dword [ebp + 0x1c]
    mov word [mode_buffer_stride], dx
    or word [bitmap_layout_flags], ax
    mov eax, dword [ebp + 0x14]
    mov word [current_buffer_stride], dx
    mov dword [current_buffer_offset], eax
    pop ebp
    pop esi
    ret 0x14

show_graphics_cursor:
    cmp word [cursor_visible], 0
    jne short .done
    cmp byte [graphics_active], 0
    jne short .graphics_mode
    mov eax, 1
    call set_bios_cursor_visible
    jmp short .mark_visible
.graphics_mode:
    call toggle_graphics_cursor_line
.mark_visible:
    mov word [cursor_visible], 1
.done:
    ret

hide_graphics_cursor:
    push ebx
    push edx
    push es
    cmp word [cursor_visible], 0
    je short .done
    cmp byte [graphics_active], 0
    jne short .graphics_mode
    xor eax, eax
    call set_bios_cursor_visible
    jmp short .mark_hidden
.graphics_mode:
    movsx eax, word [active_text_page]
    mov edx, dword [bios_data_offset]
    add eax, eax
    add eax, edx
    mov es, word [bios_data_selector]
    add eax, 0x50
    db 0x66, 0x26, 0x8b, 0x18 ; MOV BX, ES:[EAX], original prefix order.
    movsx eax, word [text_cursor_row]
    movsx edx, word [text_cursor_column]
    shl eax, 8
    add eax, edx
    movsx edx, bx
    cmp edx, eax
    jne short .mark_hidden
    call toggle_graphics_cursor_line
.mark_hidden:
    mov word [cursor_visible], 0
.done:
    pop es
    pop edx
    pop ebx
    ret

set_bios_cursor_visible:
    push ebx
    push ecx
    push edx
    mov cx, word [text_cursor_shape]
    test ax, ax
    jne short .write_shape
    or ch, 0x20
.write_shape:
    mov eax, 0x100
    xor ebx, ebx
    xor edx, edx
    push bp
    int 0x10
    pop bp
    pop edx
    pop ecx
    pop ebx
    ret

toggle_graphics_cursor_line:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    enter 4, 0
    mov eax, 4
    call set_drawing_action
    mov esi, eax
    mov ax, word [drawing_color]
    mov dword [ebp - 4], eax
    mov ax, word [palette_size]
    dec eax
    and al, 0xf
    xor ah, ah
    mov word [drawing_color], ax
    movsx eax, word [pixel_width]
    movsx ebx, word [text_columns]
    cdq
    idiv ebx
    mov ecx, eax
    movsx eax, word [pixel_height]
    movsx ebx, word [text_rows]
    cdq
    idiv ebx
    mov edi, eax
    movsx ebx, cx
    movsx eax, word [text_cursor_column]
    imul eax, ebx
    lea edx, [eax + ebx]
    movsx ebx, word [text_cursor_row]
    movsx ecx, di
    inc ebx
    imul ebx, ecx
    dec edx
    dec ebx
    cwde
    movsx ecx, bx
    movsx ebx, dx
    mov edx, ecx
    call draw_clipped_solid_line
    movsx eax, si
    call set_drawing_action
    movsx eax, word [ebp - 4]
    call set_drawing_color
    leave
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

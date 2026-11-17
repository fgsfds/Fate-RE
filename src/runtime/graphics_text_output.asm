; Text-window output, scrolling, and cursor shape.
BITS 32
ORG 0x6e912

initialize_graphics_once equ 0x6fd95
hide_graphics_cursor equ 0x6febd
restore_cursor_if_enabled equ 0x7002e
scroll_text_window equ 0x6f5cf
draw_text_character equ 0x6f9a9

graphics_active equ 0x16c65
graphics_error equ 0x16c66
text_wrap_enabled equ 0x16c72
active_text_page equ 0x16c78
text_cursor_row equ 0x2891f8
text_cursor_column equ 0x2891fa
cursor_shape equ 0x28923c
text_window_right equ 0x28923e
text_window_bottom equ 0x289240
text_window_left equ 0x289242

write_text_window:
    push ecx
    push esi
    push edi
    enter 12, 0
    mov ecx, eax
    mov esi, edx
    mov [ebp-8], ebx
    mov edi, 1
.next_character:
    test si, si
    jle near .update_cursor
    mov dword [ebp-4], 1
    cmp byte [ecx], 10
    jne short .check_carriage_return
    cmp word [ebp-8], 0
    je short .check_carriage_return
    mov ax, [text_window_left]
    mov [text_cursor_column], ax
    mov ax, [text_cursor_row]
    cmp ax, [text_window_bottom]
    jne short .advance_newline
    mov eax, 1
    mov edx, eax
    call scroll_text_window
    jmp short .enable_after_newline
.advance_newline:
    inc word [text_cursor_row]
.enable_after_newline:
    mov edi, 1
    jmp near .consume
.check_carriage_return:
    cmp byte [ecx], 13
    jne short .check_output_enabled
    cmp word [ebp-8], 0
    je short .check_output_enabled
    mov ax, [text_window_left]
    mov edi, 1
    jmp near .store_column
.check_output_enabled:
    test di, di
    je near .consume
    cmp word [ebp-4], 1
    jne short .check_second_byte
.draw_single_byte:
    movzx ax, byte [ecx]
    movsx edx, word [text_cursor_column]
    movsx ebx, ax
    movsx eax, word [text_cursor_row]
    call draw_text_character
    inc word [text_cursor_column]
    jmp short .check_right_edge
.check_second_byte:
    cmp byte [ecx+1], 0
    je short .draw_single_byte
    movsx eax, word [text_window_right]
    movsx edx, word [text_cursor_column]
    dec eax
    cmp edx, eax
    jg short .retry_after_wrap
    movzx ax, byte [ecx]
    shl eax, 8
    mov [ebp-12], eax
    movzx ax, byte [ecx+1]
    add eax, [ebp-12]
    movsx ebx, ax
    movsx eax, word [text_cursor_row]
    call draw_text_character
    add word [text_cursor_column], 2
    jmp short .check_right_edge
.retry_after_wrap:
    add word [text_cursor_column], 2
    dec ecx
    dec ecx
    inc esi
    inc esi
.check_right_edge:
    mov ax, [text_cursor_column]
    cmp ax, [text_window_right]
    jle short .consume
    cmp word [text_wrap_enabled], 0
    je short .disable_output
    mov ax, [text_window_left]
    mov [text_cursor_column], ax
    mov ax, [text_cursor_row]
    cmp ax, [text_window_bottom]
    jne short .advance_wrapped_line
    mov eax, 1
    mov edx, eax
    call scroll_text_window
    jmp short .consume
.advance_wrapped_line:
    inc word [text_cursor_row]
    jmp short .consume
.disable_output:
    mov ax, [text_window_right]
    xor edi, edi
.store_column:
    mov [text_cursor_column], ax
.consume:
    movsx eax, word [ebp-4]
    sub esi, [ebp-4]
    add ecx, eax
    jmp near .next_character
.update_cursor:
    mov eax, 0x200
    mov dx, [text_cursor_row]
    mov bx, [active_text_page]
    xor ecx, ecx
    shl edx, 8
    shl ebx, 8
    add dx, [text_cursor_column]
    push bp
    int 0x10
    pop bp
    leave
    pop edi
    pop esi
    pop ecx
    ret

    times 61 db 0 ; supplied by matching C

    times 32 db 0 ; supplied by matching C

    times 100 db 0 ; supplied by matching C

    times 12 db 0 ; supplied by matching C

    times 69 db 0 ; supplied by matching C

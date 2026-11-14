; Clear graphics and text rectangles and scroll the active text window.
BITS 32
ORG 0x6f4ac

set_drawing_action equ 0x71950
get_fill_pattern equ 0x719a1
set_fill_pattern equ 0x719cb
get_drawing_color equ 0x71a3f
set_drawing_color equ 0x71a46
fill_graphics_rectangle equ 0x71a82
move_graphics_rows equ 0x6f796
move_text_rows equ 0x6f8c7

graphics_active equ 0x16c65
text_attribute equ 0x16c71
cursor_enabled equ 0x16c74
active_text_page equ 0x16c78
bios_data_selector equ 0x16cf7
mono_text_selector equ 0x16cf9
color_text_selector equ 0x16cfb
bios_data_offset equ 0x16d01
mono_text_offset equ 0x16d05
color_text_offset equ 0x16d09
pixel_width equ 0x2891fc
pixel_height equ 0x2891fe
text_columns equ 0x289200
text_rows equ 0x289202
video_mode equ 0x28920a
text_window_right equ 0x28923e
text_window_bottom equ 0x289240
text_window_left equ 0x289242
text_window_top equ 0x289244

clear_graphics_region:
    push esi
    push edi
    enter 8, 0
    push eax
    mov eax, 3
    call set_drawing_action
    mov esi, eax
    lea eax, [ebp-8]
    movsx ecx, cx
    call get_fill_pattern
    xor eax, eax
    movsx ebx, bx
    call set_fill_pattern
    call get_drawing_color
    mov edi, eax
    xor eax, eax
    movsx edx, dx
    call set_drawing_color
    movsx eax, word [ebp-12]
    call fill_graphics_rectangle
    movsx eax, di
    call set_drawing_color
    lea eax, [ebp-8]
    call set_fill_pattern
    movsx eax, si
    call set_drawing_action
    leave
    pop edi
    pop esi
    ret

clear_text_region:
    push esi
    push es
    push fs
    enter 16, 0
    mov esi, eax
    mov [ebp-4], edx
    mov [ebp-8], ebx
    mov [ebp-16], ecx
    cmp word [video_mode], 7
    jne short .color_buffer
    mov fs, [mono_text_selector]
    mov eax, [mono_text_offset]
    jmp short .locate_region
.color_buffer:
    mov fs, [color_text_selector]
    mov eax, [color_text_offset]
.locate_region:
    movsx ebx, word [text_columns]
    movsx ecx, si
    imul ecx, ebx
    mov edx, [bios_data_offset]
    mov es, [bios_data_selector]
    add edx, 0x4c
    movsx ebx, word [ebp-4]
    movsx edx, word [es:edx]
    add ecx, ebx
    movsx ebx, word [active_text_page]
    imul edx, ebx
    add ecx, ecx
    add edx, ecx
    add eax, edx
    mov edx, [ebp-16]
    movzx cx, byte [text_attribute]
    sub edx, [ebp-4]
    shl ecx, 8
    inc edx
    add ecx, 0x20
    mov [ebp-12], edx
    jmp short .check_row
.fill_row:
    push fs
    pop es
    mov edx, eax
    xor ebx, ebx
    jmp short .check_column
.fill_cell:
    inc ebx
    db 0x66 ; operand-size prefix precedes the ES override in the original
    mov [es:edx], ecx
    inc edx
    inc edx
.check_column:
    cmp bx, [ebp-12]
    jl short .fill_cell
    movsx edx, word [text_columns]
    add edx, edx
    inc esi
    add eax, edx
.check_row:
    cmp si, [ebp-8]
    jle short .fill_row
    leave
    pop fs
    pop es
    pop esi
    ret

set_cursor_enabled:
    push edx
    mov edx, eax
    mov ax, [cursor_enabled]
    mov [cursor_enabled], dx
    pop edx
    ret

scroll_text_window:
    push ebx
    push ecx
    push esi
    push edi
    enter 16, 0
    mov edi, eax
    mov esi, edx
    cmp byte [graphics_active], 0
    jne near .graphics_mode
    mov dx, [text_window_bottom]
    sub dx, [text_window_top]
    inc edx
    test si, si
    je short .clear_text
    cmp ax, strict word 2
    jne short .move_text_up
    movsx eax, word [text_window_right]
    movsx ecx, dx
    movsx edx, word [text_window_bottom]
    push eax
    movsx eax, word [text_window_left]
    mov ebx, edx
    push eax
    movsx eax, si
    sub ebx, eax
    sub ecx, eax
    mov eax, ebx
    mov ebx, -1
    jmp short .move_text
.move_text_up:
    movsx eax, word [text_window_right]
    mov ebx, 1
    push eax
    movsx eax, word [text_window_left]
    movsx ecx, dx
    push eax
    movsx eax, si
    movsx edx, word [text_window_top]
    sub ecx, eax
    add eax, edx
.move_text:
    call move_text_rows
.clear_text:
    cmp di, 2
    jne short .clear_text_bottom
    mov ax, [text_window_top]
    add eax, esi
    movsx ecx, word [text_window_right]
    dec eax
    movsx edx, word [text_window_left]
    movsx ebx, ax
    movsx eax, word [text_window_top]
.clear_text_rows:
    call clear_text_region
    jmp near .return
.clear_text_bottom:
    movsx ecx, word [text_window_right]
    mov ax, [text_window_bottom]
    dec esi
    movsx ebx, word [text_window_bottom]
    sub eax, esi
    movsx edx, word [text_window_left]
    cwde
    jmp short .clear_text_rows
.graphics_mode:
    movsx eax, word [pixel_height]
    movsx ebx, word [text_rows]
    cdq
    idiv ebx
    mov ebx, eax
    movsx eax, word [pixel_width]
    movsx ecx, word [text_columns]
    cdq
    idiv ecx
    imul esi, ebx
    mov dx, [text_window_top]
    imul edx, ebx
    mov [ebp-8], edx
    mov dx, [text_window_bottom]
    imul edx, ebx
    add edx, ebx
    dec edx
    mov [ebp-12], edx
    mov dx, [text_window_left]
    imul edx, eax
    mov [ebp-16], edx
    mov dx, [text_window_right]
    imul edx, eax
    add eax, edx
    mov edx, [ebp-12]
    dec eax
    sub edx, [ebp-8]
    mov [ebp-4], eax
    inc edx
    test si, si
    je short .clear_graphics
    cmp di, 2
    jne short .move_graphics_up
    cwde
    movsx ecx, dx
    movsx edx, word [ebp-12]
    push eax
    movsx eax, word [ebp-16]
    mov ebx, edx
    push eax
    movsx eax, si
    sub ebx, eax
    sub ecx, eax
    mov eax, ebx
    mov ebx, -1
    jmp short .move_graphics
.move_graphics_up:
    cwde
    mov ebx, 1
    push eax
    movsx eax, word [ebp-16]
    movsx ecx, dx
    push eax
    movsx eax, si
    movsx edx, word [ebp-8]
    sub ecx, eax
    add eax, edx
.move_graphics:
    call move_graphics_rows
.clear_graphics:
    cmp di, 2
    jne short .clear_graphics_bottom
    mov eax, [ebp-8]
    add eax, esi
    movsx ebx, word [ebp-4]
    dec eax
    movsx edx, word [ebp-8]
    movsx ecx, ax
    jmp short .clear_graphics_rows
.clear_graphics_bottom:
    mov eax, [ebp-12]
    dec esi
    movsx ecx, word [ebp-12]
    sub eax, esi
    movsx ebx, word [ebp-4]
    movsx edx, ax
.clear_graphics_rows:
    movsx eax, word [ebp-16]
    call clear_graphics_region
.return:
    leave
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

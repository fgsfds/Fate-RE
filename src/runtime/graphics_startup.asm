; Initialize text pages, mode state and the starting text window and cursor.
BITS 32
ORG 0x6fbfa

initialize_graphics_memory_windows equ 0x71b8c
detect_display_adapters equ 0x7139e
text_rows equ 0x289202
text_columns equ 0x289200
bios_data_offset equ 0x16d01
bios_data_selector equ 0x16cf7
video_memory_kib equ 0x289210
text_page_count equ 0x289208
pixel_width equ 0x2891fc
pixel_height equ 0x2891fe
bitmap_bits_per_pixel equ 0x289206
bitmap_layout_flags equ 0x289234
palette_size equ 0x289204
video_mode equ 0x28920a
adapter_class_table equ 0x16d1c
monitor_class_table equ 0x16d40
video_memory_table equ 0x16d64
monitor_class equ 0x28920e
adapter_class equ 0x28920c
graphics_active equ 0x16c65
text_cursor_shape equ 0x28923c
graphics_init_pending equ 0x16c64
initial_video_mode equ 0x289246
initial_text_rows equ 0x28923a
text_window_left equ 0x289244
text_window_top equ 0x289242
text_window_bottom equ 0x289240
text_window_right equ 0x28923e
text_cursor_row equ 0x2891f8
text_cursor_column equ 0x2891fa

initialize_text_pages:
    push ebx
    push ecx
    push edx
    push es
    mov ax, word [text_rows]
    imul ax, word [text_columns]
    mov edx, eax
    and dh, 0xfe
    xor dl, al
    cmp dx, ax
    jge short .set_page_size
    inc dh
    inc dh
.set_page_size:
    mov eax, dword [bios_data_offset]
    mov ebx, edx
    mov es, word [bios_data_selector]
    add eax, 0x4c
    add ebx, edx
    db 0x66, 0x26, 0x89, 0x18 ; mov word es:[eax], bx, original prefix order.
    cmp word [video_memory_kib], 0x40
    jne short .use_32_blocks
    mov ecx, 0x10
    jmp short .count_pages
.use_32_blocks:
    mov ecx, 0x20
.count_pages:
    movsx ebx, dx
    movsx eax, cx
    sar ebx, 9
    cdq
    idiv ebx
    mov edx, eax
    cmp ax, strict word 8
    jle short .store_page_count
    mov edx, 8
.store_page_count:
    mov word [text_page_count], dx
    pop es
    pop edx
    pop ecx
    pop ebx
    ret

read_graphics_mode_state:
    push ebx
    push ecx
    push edx
    push es
    mov word [pixel_width], 0
    mov word [pixel_height], 0
    mov word [bitmap_bits_per_pixel], 0
    mov word [bitmap_layout_flags], 0
    mov eax, dword [bios_data_offset]
    mov es, word [bios_data_selector]
    add eax, strict dword 0x84
    db 0x66, 0x26, 0x0f, 0xb6, 0x00 ; movzx ax, byte es:[eax], original prefix order.
    inc eax
    cmp ax, strict word 1
    jne short .store_rows
    mov eax, 0x19
.store_rows:
    mov word [text_rows], ax
    mov eax, dword [bios_data_offset]
    mov es, word [bios_data_selector]
    add eax, 0x4a
    xor ebx, ebx
    xor ecx, ecx
    db 0x66, 0x26, 0x8b, 0x00 ; mov ax, word es:[eax], original prefix order.
    xor edx, edx
    mov word [text_columns], ax
    mov eax, 0xf00
    mov word [palette_size], 0x20
    push bp
    int 0x10
    pop bp
    and al, 0x7f
    xor ah, ah
    mov word [video_mode], ax
    call detect_display_adapters
    xor ah, ah
    cwde
    mov dx, word [nosplit eax*2 + adapter_class_table]
    mov ax, word [nosplit eax*2 + monitor_class_table]
    mov word [monitor_class], ax
    movsx eax, dx
    mov ax, word [nosplit eax*2 + video_memory_table]
    mov word [video_memory_kib], ax
    cwde
    mov word [adapter_class], dx
    cmp eax, -1
    jne short .check_page_layout
    mov eax, 0x1200
    mov ebx, 0x10
    xor ecx, ecx
    xor edx, edx
    push bp
    int 0x10
    pop bp
    xor bh, bh
    inc ebx
    shl ebx, 6
    mov word [video_memory_kib], bx
.check_page_layout:
    cmp byte [graphics_active], 0
    jne short .default_page_count
    cmp word [adapter_class], 4
    jge short .initialize_pages
.default_page_count:
    mov word [text_page_count], 8
    jmp short .read_cursor_shape
.initialize_pages:
    call initialize_text_pages
.read_cursor_shape:
    mov eax, dword [bios_data_offset]
    mov es, word [bios_data_selector]
    add eax, 0x60
    db 0x66, 0x26, 0x8b, 0x00 ; mov ax, word es:[eax], original prefix order.
    mov word [text_cursor_shape], ax
    pop es
    pop edx
    pop ecx
    pop ebx
    ret

initialize_graphics_once:
    push ebx
    push edx
    push es
    cmp byte [graphics_init_pending], 0
    je short .done
    mov byte [graphics_init_pending], 0
    call initialize_graphics_memory_windows
    call read_graphics_mode_state
    mov ax, word [video_mode]
    mov bx, word [text_rows]
    mov word [initial_video_mode], ax
    mov word [initial_text_rows], bx
    mov eax, dword [bios_data_offset]
    mov es, word [bios_data_selector]
    add eax, 0x50
    dec ebx
    db 0x66, 0x26, 0x8b, 0x10 ; mov dx, word es:[eax], original prefix order.
    mov word [text_window_left], 0
    movzx eax, dx
    mov word [text_window_top], 0
    sar eax, 8
    mov word [text_window_bottom], bx
    mov word [text_cursor_row], ax
    mov ax, word [text_columns]
    xor dh, dh
    dec eax
    mov word [text_cursor_column], dx
    mov word [text_window_right], ax
.done:
    pop es
    pop edx
    pop ebx
    ret

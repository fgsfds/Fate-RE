; Text foreground attributes, window bounds, and display clearing.
BITS 32
ORG 0x6f22c

set_text_position equ 0x6ebf2
initialize_graphics_once equ 0x6fd95
hide_graphics_cursor equ 0x6febd
restore_cursor_if_enabled equ 0x7002e
clear_graphics_region equ 0x6f4ac
clear_text_region equ 0x6f50a

graphics_active equ 0x16c65
text_attribute equ 0x16c71
pixel_width equ 0x2891fc
pixel_height equ 0x2891fe
text_columns equ 0x289200
text_rows equ 0x289202
palette_size equ 0x289204
clip_left equ 0x289216
clip_right equ 0x289218
clip_top equ 0x28921a
clip_bottom equ 0x28921c
text_window_right equ 0x28923e
text_window_bottom equ 0x289240
text_window_left equ 0x289242
text_window_top equ 0x289244

get_text_color:
    push edx
    cmp byte [graphics_active], 0
    je short .text_mode
    movzx ax, byte [text_attribute]
    pop edx
    ret
.text_mode:
    mov al, [text_attribute]
    and al, 0x80
    movzx eax, al
    mov edx, eax
    mov al, [text_attribute]
    and al, 0xf
    sar edx, 3
    movzx eax, al
    add eax, edx
    pop edx
    ret

set_text_color:
    push ebx
    push edx
    mov edx, eax
    call get_text_color
    mov ebx, eax
    cmp byte [graphics_active], 0
    je short .text_mode
    call hide_graphics_cursor
    mov dh, [palette_size]
    dec dh
    or dh, 0x80
    and dl, dh
    mov [text_attribute], dl
    call restore_cursor_if_enabled
    mov eax, ebx
    pop edx
    pop ebx
    ret
.text_mode:
    mov dh, dl
    and dh, 0x10
    and dl, 0xf
    shl dh, 3
    and byte [text_attribute], 0x70
    add dl, dh
    or [text_attribute], dl
    mov eax, ebx
    pop edx
    pop ebx
    ret

get_text_window:
    push esi
    mov esi, eax
    call initialize_graphics_once
    mov ax, [text_window_top]
    inc eax
    mov [esi], ax
    mov si, [text_window_bottom]
    inc esi
    mov [ebx], si
    mov bx, [text_window_left]
    inc ebx
    mov [edx], bx
    mov dx, [text_window_right]
    inc edx
    mov [ecx], dx
    pop esi
    ret

set_text_window:
    push esi
    mov esi, eax
    call initialize_graphics_once
    cmp si, bx
    jle short .sort_columns
    mov eax, esi
    mov esi, ebx
    mov ebx, eax
.sort_columns:
    cmp dx, cx
    jle short .zero_based
    mov eax, edx
    mov edx, ecx
    mov ecx, eax
.zero_based:
    dec esi
    dec ebx
    dec edx
    dec ecx
    test si, si
    jge short .check_left
    xor esi, esi
.check_left:
    test dx, dx
    jge short .check_bottom
    xor edx, edx
.check_bottom:
    cmp bx, [text_rows]
    jl short .check_right
    mov bx, [text_rows]
    dec ebx
.check_right:
    cmp cx, [text_columns]
    jl short .apply
    mov cx, [text_columns]
    dec ecx
.apply:
    mov eax, 1
    mov [text_window_top], si
    mov [text_window_bottom], bx
    mov [text_window_left], dx
    mov edx, eax
    mov [text_window_right], cx
    call set_text_position
    pop esi
    ret

clear_graphics_display:
    push ebx
    push ecx
    push edx
    push esi
    cmp ax, strict word 1
    jb near .entire_screen
    jbe short .viewport
    cmp ax, strict word 2
    je short .text_window
    jmp near .entire_screen
.viewport:
    movsx ecx, word [clip_bottom]
    movsx ebx, word [clip_right]
    movsx edx, word [clip_top]
    movsx eax, word [clip_left]
    call clear_graphics_region
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
.text_window:
    movsx eax, word [pixel_width]
    movsx ebx, word [text_columns]
    cdq
    idiv ebx
    mov esi, eax
    movsx eax, word [pixel_height]
    movsx ebx, word [text_rows]
    cdq
    idiv ebx
    mov dx, [text_window_bottom]
    inc edx
    imul edx, eax
    imul ax, [text_window_top]
    dec edx
    movsx ecx, dx
    mov dx, [text_window_right]
    inc edx
    imul edx, esi
    imul si, [text_window_left]
    dec edx
    movsx ebx, dx
    movsx edx, ax
    movsx eax, si
    jmp short .clear_and_home
.entire_screen:
    mov ax, [pixel_height]
    dec eax
    movsx ecx, ax
    mov ax, [pixel_width]
    dec eax
    xor edx, edx
    movsx ebx, ax
    xor eax, eax
.clear_and_home:
    call clear_graphics_region
    mov eax, 1
    mov edx, eax
    call set_text_position
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

clear_screen:
    push ebx
    push ecx
    push edx
    mov edx, eax
    call initialize_graphics_once
    call hide_graphics_cursor
    cmp byte [graphics_active], 0
    je short .text_mode
    movsx eax, dx
    call clear_graphics_display
    jmp short .restore_cursor
.text_mode:
    cmp dx, 1
    jb short .entire_screen
    jbe short .restore_cursor
    cmp dx, 2
    jne short .entire_screen
    movsx ecx, word [text_window_right]
    movsx ebx, word [text_window_bottom]
    movsx edx, word [text_window_left]
    movsx eax, word [text_window_top]
    jmp short .clear_and_home
.entire_screen:
    mov ax, [text_columns]
    dec eax
    movsx ecx, ax
    mov ax, [text_rows]
    dec eax
    xor edx, edx
    movsx ebx, ax
    xor eax, eax
.clear_and_home:
    call clear_text_region
    mov eax, 1
    mov edx, eax
    call set_text_position
.restore_cursor:
    call restore_cursor_if_enabled
    pop edx
    pop ecx
    pop ebx
    ret

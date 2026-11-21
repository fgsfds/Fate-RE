; Clear graphics and text rectangles and scroll the active text window.
BITS 32
ORG 0x6f4ac

clear_text_region equ 0x6f50a

move_graphics_rows equ 0x6f796
move_text_rows equ 0x6f8c7

graphics_active equ 0x16c65
pixel_width equ 0x2891fc
pixel_height equ 0x2891fe
text_columns equ 0x289200
text_rows equ 0x289202
text_window_right equ 0x28923e
text_window_bottom equ 0x289240
text_window_left equ 0x289242
text_window_top equ 0x289244

clear_graphics_region:
    times 94 db 0 ; supplied by matching C

    times 179 db 0 ; supplied by matching C

    times 18 db 0    ; set_cursor_enabled is placed here from C.

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

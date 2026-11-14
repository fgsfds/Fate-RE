; Write a text-mode cell or render a character from the built-in bitmap fonts.
BITS 32
ORG 0x6f9a9

clear_graphics_region equ 0x6f4ac
begin_graphics_device equ 0x70052
end_graphics_device equ 0x7005b
set_drawing_action equ 0x71950
initialize_graphics_once equ 0x6fd95

graphics_active equ 0x16c65
text_attribute equ 0x16c71
active_text_page equ 0x16c78
bios_data_selector equ 0x16cf7
mono_text_selector equ 0x16cf9
color_text_selector equ 0x16cfb
bios_data_offset equ 0x16d01
mono_text_offset equ 0x16d05
color_text_offset equ 0x16d09
font_8_rows equ 0x17ec4
font_14_rows equ 0x18b5c
pixel_address equ 0x2891ec
pixel_width equ 0x2891fc
pixel_height equ 0x2891fe
text_columns equ 0x289200
text_rows equ 0x289202
palette_size equ 0x289204
video_mode equ 0x28920a
video_device equ 0x289212

draw_text_character:
    push ecx
    push esi
    push edi
    push es
    enter 44, 0
    mov edi, eax
    mov [ebp-28], edx
    cmp byte [graphics_active], 0
    jne short .bitmap
    cmp word [video_mode], 7
    jne short .color_buffer
    mov eax, [mono_text_offset]
    mov dx, [mono_text_selector]
    jmp short .locate_cell
.color_buffer:
    mov eax, [color_text_offset]
    mov dx, [color_text_selector]
.locate_cell:
    mov ecx, [bios_data_offset]
    mov es, [bios_data_selector]
    add ecx, 0x4c
    movsx ecx, word [es:ecx]
    mov [ebp-44], ecx
    movsx ecx, word [active_text_page]
    imul ecx, [ebp-44]
    movsx esi, word [text_columns]
    add eax, ecx
    movsx ecx, di
    imul esi, ecx
    mov es, dx
    movzx dx, byte [text_attribute]
    movsx ecx, word [ebp-28]
    shl edx, 8
    add ecx, esi
    add edx, ebx
    db 0x66 ; operand-size prefix precedes the ES override in the original
    mov [es:eax+ecx*2], edx
    jmp near .return
.bitmap:
    movsx eax, word [pixel_height]
    movsx ecx, word [text_rows]
    cdq
    idiv ecx
    mov ecx, eax
    cmp ax, strict word 14
    jge short .tall_font
    movsx eax, bx
    mov edx, font_8_rows
    shl eax, 3
    add edx, eax
    mov dword [ebp-32], 8
    jmp short .position_glyph
.tall_font:
    movsx eax, bx
    imul eax, eax, 14
    mov edx, font_14_rows
    add edx, eax
    mov dword [ebp-32], 14
.position_glyph:
    mov [ebp-36], edx
    imul edi, ecx
    mov eax, [ebp-28]
    shl eax, 3
    mov [ebp-16], eax
    mov eax, ecx
    sub eax, [ebp-32]
    mov [ebp-20], eax
    mov [ebp-12], edi
    test ax, ax
    jle short .choose_action
    cwde
    cdq
    db 0x2b, 0xc2 ; sub eax, edx using the register-load opcode
    sar eax, 1
    mov edx, eax
    movsx eax, di
    add eax, edx
    mov [ebp-12], eax
.choose_action:
    test byte [text_attribute], 0x80
    je short .clear_cell
    cmp word [palette_size], 0x100
    je short .clear_cell
    mov eax, 4
    call set_drawing_action
    mov [ebp-4], eax
    jmp short .begin_glyph
.clear_cell:
    mov eax, [ebp-16]
    add ecx, [ebp-12]
    movsx edx, word [ebp-12]
    dec ecx
    add eax, strict dword 7
    movsx ecx, cx
    movsx ebx, ax
    movsx eax, word [ebp-16]
    call clear_graphics_region
.begin_glyph:
    call begin_graphics_device
    mov esi, [video_device]
    mov eax, [esi+0x3c]
    mov [ebp-40], eax
    mov ax, [palette_size]
    movzx dx, byte [text_attribute]
    dec eax
    and edx, eax
    mov [ebp-8], edx
    cmp word [ebp-20], 2
    jne short .start_rows
    movsx eax, word [ebp-16]
    movsx ecx, dx
    movsx edx, word [ebp-12]
    mov ebx, ecx
    dec edx
    call [esi+0x10]
    mov ebx, [ebp-36]
    mov eax, ecx
    xor edx, edx
    mov ecx, 8
    movzx ebx, byte [ebx]
    les edi, [pixel_address]
    call [ebp-40]
.start_rows:
    mov dword [ebp-24], 0
    jmp short .check_row
.draw_row:
    movsx ecx, word [ebp-8]
    movsx edx, word [ebp-12]
    movsx eax, word [ebp-16]
    inc dword [ebp-24]
    mov ebx, ecx
    inc dword [ebp-12]
    call [esi+0x10]
    mov ebx, [ebp-36]
    mov eax, ecx
    xor edx, edx
    mov ecx, 8
    movzx ebx, byte [ebx]
    les edi, [pixel_address]
    inc dword [ebp-36]
    call [ebp-40]
.check_row:
    mov eax, [ebp-24]
    cmp ax, [ebp-32]
    jl short .draw_row
    cmp word [ebp-20], 2
    jne short .end_glyph
    movsx ecx, word [ebp-8]
    movsx edx, word [ebp-12]
    movsx eax, word [ebp-16]
    mov ebx, ecx
    call [esi+0x10]
    mov ebx, [ebp-36]
    mov eax, ecx
    xor edx, edx
    mov ecx, 8
    movzx ebx, byte [ebx-1]
    les edi, [pixel_address]
    call [ebp-40]
.end_glyph:
    call end_graphics_device
    test byte [text_attribute], 0x80
    je short .return
    cmp word [palette_size], 0x100
    je short .return
    movsx eax, word [ebp-4]
    call set_drawing_action
.return:
    leave
    pop es
    pop edi
    pop esi
    pop ecx
    ret

get_video_configuration:
    push edx
    push esi
    push edi
    push es
    mov edx, eax
    call initialize_graphics_once
    push ds
    pop es
    mov edi, edx
    mov esi, pixel_width
    mov eax, edx
    times 5 movsd
    movsw
    pop es
    pop edi
    pop esi
    pop edx
    ret

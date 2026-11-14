; Reset video state and initialize the mode palette and background color.
BITS 32
ORG 0x6ef09

video_mode_return equ 0x6ed6e
reset_graphics_aspect_settings equ 0x6eea9
set_graphics_clipping equ 0x71689
replace_palette_entry equ 0x716fc
upload_palette_entries equ 0x7174e
find_legacy_palette_index equ 0x718ef

graphics_active equ 0x16c65
viewport_offset_x equ 0x16c68
viewport_offset_y equ 0x16c6a
viewport_origin_x equ 0x16c6c
viewport_origin_y equ 0x16c6e
text_attribute equ 0x16c71
text_wrap_enabled equ 0x16c72
active_text_page equ 0x16c78
text_page_offset equ 0x16c7a
background_color equ 0x16c7c
drawing_color equ 0x16c80
fill_pattern equ 0x16c84
default_fill_pattern equ 0x16c8c
fill_pattern_enabled equ 0x16c94
pattern_transparent equ 0x16c95
pattern_origin_x equ 0x16c97
pattern_origin_y equ 0x16c99
line_pattern equ 0x16c9b
line_pattern_phase equ 0x16c9d
drawing_action equ 0x16c9f
world_bounds equ 0x16cd5
reverse_second_axis equ 0x16ce5
world_first_min equ 0x16ce7
world_second_min equ 0x16ceb
world_first_max equ 0x16cef
world_second_max equ 0x16cf3
legacy_rgb_palette equ 0x17390

text_cursor_row equ 0x2891f8
text_cursor_column equ 0x2891fa
pixel_width equ 0x2891fc
pixel_height equ 0x2891fe
text_columns equ 0x289200
text_rows equ 0x289202
palette_size equ 0x289204
video_mode equ 0x28920a
adapter_class equ 0x28920c
clip_left equ 0x28921e
clip_right equ 0x289220
clip_top equ 0x289222
clip_bottom equ 0x289224
screen_stride equ 0x289226
screen_offset equ 0x289228
mode_buffer_stride equ 0x28922c
mode_buffer_offset equ 0x28922e
text_window_right equ 0x28923e
text_window_bottom equ 0x289240
text_window_left equ 0x289242
text_window_top equ 0x289244

reset_video_state:
    push ecx
    push esi
    push edi
    mov word [viewport_offset_x], 0
    mov word [viewport_offset_y], 0
    mov word [viewport_origin_x], 0
    mov word [viewport_origin_y], 0
    mov dword [world_bounds], 0
    mov dword [world_bounds+4], 0
    mov dword [world_bounds+8], 0
    mov dword [world_bounds+12], 0
    mov word [reverse_second_axis], 1
    mov dword [world_first_min], 0
    mov ax, [pixel_width]
    mov dword [world_second_min], 0
    dec eax
    mov dword [world_first_max], 0x3f800000
    mov [clip_right], ax
    mov ax, [pixel_height]
    mov dword [world_second_max], 0x3f800000
    dec eax
    mov word [clip_left], 0
    mov [clip_bottom], ax
    mov eax, 1
    mov word [clip_top], 0
    call set_graphics_clipping
    mov ax, [text_rows]
    mov word [text_cursor_row], 0
    dec eax
    mov word [text_cursor_column], 0
    mov [text_window_bottom], ax
    mov ax, [text_columns]
    mov word [text_window_top], 0
    dec eax
    mov word [text_window_left], 0
    mov [text_window_right], ax
    cmp byte [graphics_active], 0
    je short .restore_pattern
    call reset_graphics_aspect_settings
.restore_pattern:
    mov edi, fill_pattern
    mov esi, default_fill_pattern
    mov ecx, 8
    push es
    push edi
    push ds
    pop es
    repne movsb
    pop edi
    pop es
    mov byte [fill_pattern_enabled], 0
    mov word [pattern_origin_x], 0
    mov word [pattern_origin_y], 0
    mov byte [text_attribute], 7
    mov dword [background_color], 0
    mov word [text_page_offset], 0
    mov word [active_text_page], 0
    mov ax, [palette_size]
    mov word [line_pattern], -1
    dec eax
    mov word [line_pattern_phase], 0
    and al, 0xf
    xor ah, ah
    mov word [drawing_action], 0
    mov [drawing_color], ax
    mov ax, [mode_buffer_stride]
    mov word [pattern_transparent], 1
    mov [screen_stride], ax
    mov eax, [mode_buffer_offset]
    mov word [text_wrap_enabled], 1
    mov [screen_offset], eax
    call reset_text_display
    pop edi
    pop esi
    pop ecx
    ret

%macro video_bios 0
    push bp
    int 0x10
    pop bp
%endmacro

reset_text_display:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    cmp word [adapter_class], 4
    jl near video_mode_return
    cmp word [video_mode], 7
    je near video_mode_return
    cmp word [video_mode], 0xf
    je near video_mode_return
    mov eax, 0x1010
    mov ebx, 0x10
    xor ecx, ecx
    xor edx, edx
    video_bios
    xor esi, esi
    mov eax, 0x1001
    mov ebx, 0x1000
    xor ecx, ecx
    xor edx, edx
    mov edi, esi
    video_bios
    shl edi, 8
.set_attribute_mapping:
    mov eax, 0x1000
    mov ebx, edi
    xor ecx, ecx
    xor edx, edx
    or ebx, esi
    video_bios
    inc esi
    add edi, strict dword 0x100
    cmp esi, 16
    jl short .set_attribute_mapping
    cmp word [palette_size], 2
    jne short .check_four_colors
    xor eax, eax
    xor edx, edx
    call replace_palette_entry
    mov eax, 1
.set_white:
    mov edx, 0x3f3f3f
    call replace_palette_entry
    jmp near video_mode_return
.check_four_colors:
    cmp word [palette_size], 4
    jne short .check_legacy_palette
    xor eax, eax
    xor edx, edx
    call replace_palette_entry
    mov eax, 1
    mov edx, 0x3f3f15
    call replace_palette_entry
    mov eax, 2
    mov edx, 0x3f153f
    call replace_palette_entry
    mov eax, 3
    jmp short .set_white
.check_legacy_palette:
    cmp word [palette_size], 16
    jl near video_mode_return
    mov eax, legacy_rgb_palette
    mov edx, 16
    call upload_palette_entries
    jmp near video_mode_return

get_background_color:
    mov eax, [background_color]
    ret

set_background_color:
    push ebx
    push ecx
    push edx
    push esi
    mov edx, eax
    mov esi, [background_color]
    mov [background_color], eax
    cmp byte [graphics_active], 0
    je short .set_text_attribute
    cmp word [adapter_class], 2
    jne short .replace_palette_color
    cmp word [video_mode], 6
    je short .replace_palette_color
    call find_legacy_palette_index
    mov ebx, eax
    xor ecx, ecx
    xor edx, edx
    mov eax, 0xb00
    video_bios
    jmp short .return
.replace_palette_color:
    xor eax, eax
    call replace_palette_entry
    jmp short .return
.set_text_attribute:
    call find_legacy_palette_index
    and al, 7
    and byte [text_attribute], 0x8f
    shl al, 4
    or [text_attribute], al
.return:
    mov eax, esi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

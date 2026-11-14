; Set text rows and reset the text window for the current video mode.
BITS 32
ORG 0x70e37

initialize_graphics_once equ 0x6fd95
initialize_text_pages equ 0x6fbfa
reset_text_display equ 0x6f0bb
set_video_mode equ 0x6ec8a

graphics_error equ 0x16c66
graphics_active equ 0x16c65
bios_data_offset equ 0x16d01
bios_data_selector equ 0x16cf7
text_rows equ 0x289202
text_window_left equ 0x289244
text_window_top equ 0x289242
text_cursor_row equ 0x2891f8
text_cursor_column equ 0x2891fa
text_page_offset equ 0x16c7a
text_window_bottom equ 0x289240
text_columns equ 0x289200
text_window_right equ 0x28923e
active_text_page equ 0x16c78
adapter_class equ 0x28920c
monitor_class equ 0x28920e
video_mode equ 0x28920a
cursor_visible equ 0x16c76

set_text_rows:
    push ebx
    push ecx
    push edx
    push es
    mov edx, eax
    mov word [graphics_error], 0
    call initialize_graphics_once
    cmp byte [graphics_active], 0
    je short .text_mode
    movsx eax, dx
    call configure_text_rows_in_graphics_mode
    jmp short .check_error
.text_mode:
    movsx eax, dx
    call configure_text_rows_in_text_mode
.check_error:
    cmp word [graphics_error], 0
    je short .reset_window
    xor eax, eax
    pop es
    pop edx
    pop ecx
    pop ebx
    ret
.reset_window:
    mov eax, dword [bios_data_offset]
    mov es, word [bios_data_selector]
    add eax, 0x84
    db 0x66, 0x26, 0x0f, 0xb6, 0; MOVZX AX, byte ES:[EAX], original prefix order.
    inc eax
    cmp ax, strict word 1
    jne short .store_rows
    mov eax, 0x19
.store_rows:
    mov word [text_rows], ax
    cmp byte [graphics_active], 0
    jne short .reset_display
    call initialize_text_pages
.reset_display:
    call reset_text_display
    mov word [text_window_left], 0
    mov word [text_window_top], 0
    mov word [text_cursor_row], 0
    mov word [text_cursor_column], 0
    mov ax, word [text_rows]
    mov word [text_page_offset], 0
    dec eax
    xor ebx, ebx
    mov word [text_window_bottom], ax
    mov ax, word [text_columns]
    xor ecx, ecx
    dec eax
    xor edx, edx
    mov word [text_window_right], ax
    mov eax, 0x500
    mov word [active_text_page], 0
    push bp
    int 0x10
    pop bp
    mov ax, word [text_rows]
    pop es
    pop edx
    pop ecx
    pop ebx
    ret

configure_text_rows_in_text_mode:
    push ebx
    push edx
    movsx edx, ax
    cmp edx, -1
    jne short .select_rows
    mov ax, word [adapter_class]
    cmp ax, strict word 5
    jb short .check_default_class_4
    jbe short .check_default_monitor
    cmp ax, strict word 7
    jbe short .default_50_rows
    pop edx
    pop ebx
    ret
.check_default_class_4:
    cmp ax, strict word 4
    jne near .done
.default_50_rows:
    mov eax, 0x32
    jmp short .select_rows
.check_default_monitor:
    cmp word [monitor_class], 2
    jne short .default_43_rows
    mov eax, 0x19
    jmp short .select_rows
.default_43_rows:
    mov eax, 0x2b
.select_rows:
    cmp ax, strict word 0x19
    jne short .check_adapter_class
    call set_standard_text_rows
    pop edx
    pop ebx
    ret
.check_adapter_class:
    mov dx, word [adapter_class]
    cmp dx, 5
    jb short .check_class_4
    jbe near .check_ega_monitor
    cmp dx, 7
    jbe short .check_vga_rows
    jmp near .unsupported_adapter
.check_class_4:
    cmp dx, 4
    je near .check_other_rows
    jmp near .unsupported_adapter
.check_vga_rows:
    cmp ax, strict word 0x2b
    jb short .check_28_rows
    jbe short .use_vga_8_scanline_font
    cmp ax, strict word 0x32
    je short .select_vga_50_rows
    jmp short .invalid_rows
.check_28_rows:
    cmp ax, strict word 0x1c
    jne short .invalid_rows
    mov eax, 0x1202
    mov edx, 0x1111
    mov ebx, 0xb0c
    jmp short .apply_vga_font
.use_vga_8_scanline_font:
    mov eax, 0x1201
.prepare_vga_font:
    mov edx, 0x1112
    mov ebx, 0x607
.apply_vga_font:
    call configure_vga_text_font
    pop edx
    pop ebx
    ret
.select_vga_50_rows:
    mov eax, 0x1202
    jmp short .prepare_vga_font
.invalid_rows:
    mov word [graphics_error], 0xfffc
    pop edx
    pop ebx
    ret
.check_ega_monitor:
    cmp word [monitor_class], 2
    jne short .check_ega_43_rows
    cmp ax, strict word 0xe
    jne short .invalid_rows
    mov edx, 0x1111
    mov ebx, 0xb0c
.apply_ega_font:
    cwde
    call configure_ega_text_font
    pop edx
    pop ebx
    ret
.check_ega_43_rows:
    cmp ax, strict word 0x2b
    jne short .invalid_rows
    mov edx, 0x1112
    mov ebx, 0x600
    jmp short .apply_ega_font
.check_other_rows:
    cmp ax, strict word 0x28
    jb short .invalid_rows
    jbe short .prepare_40_rows
    cmp ax, strict word 0x32
    je short .prepare_50_rows
    jmp short .invalid_rows
.prepare_40_rows:
    mov edx, 0x1112
    mov ebx, 0x404
.apply_other_font:
    cwde
    call configure_other_text_font
    pop edx
    pop ebx
    ret
.prepare_50_rows:
    mov edx, 0x1112
    mov ebx, 0x303
    jmp short .apply_other_font
.unsupported_adapter:
    mov word [graphics_error], 0xffff
.done:
    pop edx
    pop ebx
    ret

configure_text_rows_in_graphics_mode:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    mov esi, eax
    mov di, word [video_mode]
    cmp di, 0xf
    jb near .unsupported_mode
    cmp di, 0x10
    jbe short .check_350_line_rows
    cmp di, 0x12
    jbe short .check_480_line_rows
    jmp near .unsupported_mode
.check_350_line_rows:
    cmp ax, strict word 0x19
    jl short .check_350_line_default
    jle short .use_14_scanline_font
    cmp ax, strict word 0x2b
    je short .use_8_scanline_font
    jmp short .invalid_rows
.check_350_line_default:
    cmp ax, strict word 0xffff
    je short .default_43_rows
    jmp short .invalid_rows
.use_14_scanline_font:
    mov edi, 0x1122
    jmp short .reset_bios_mode
.default_43_rows:
    mov esi, 0x2b
.use_8_scanline_font:
    mov edi, 0x1123
    jmp short .reset_bios_mode
.invalid_rows:
    mov word [graphics_error], 0xfffc
    jmp near .done
.check_480_line_rows:
    cmp ax, strict word 0x1e
    jl short .check_480_line_default
    jle short .use_16_scanline_font
    cmp ax, strict word 0x22
    jl short .invalid_rows
    jle short .use_14_scanline_font
    cmp ax, strict word 0x3c
    je short .use_8_scanline_font
    jmp short .invalid_rows
.check_480_line_default:
    cmp ax, strict word 0xffff
    je short .default_60_rows
    jmp short .invalid_rows
.use_16_scanline_font:
    mov edi, 0x1124
    jmp short .reset_bios_mode
.default_60_rows:
    mov esi, 0x3c
    jmp short .use_8_scanline_font
.unsupported_mode:
    mov word [graphics_error], 0xffff
    jmp short .done
.reset_bios_mode:
    mov eax, 0xf00
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    push bp
    int 0x10
    pop bp
    and al, 0x7f
    xor ah, ah
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    push bp
    int 0x10
    pop bp
    cmp word [adapter_class], 5
    jne short .prepare_font
    mov edx, esi
    mov eax, edi
    xor ebx, ebx
    xor ecx, ecx
    dec edx
    jmp short .apply_font
.prepare_font:
    mov eax, edi
    mov edx, esi
    xor ebx, ebx
    xor ecx, ecx
.apply_font:
    push bp
    int 0x10
    pop bp
    mov word [cursor_visible], 0
.done:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

; BIOS video services in this code preserve the low half of EBP explicitly.
%macro video_bios 0
    push bp
    int 0x10
    pop bp
%endmacro

%macro video_bios_without_arguments 0
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    video_bios
%endmacro

%macro reload_current_video_mode 0
    mov eax, 0x0f00
    video_bios_without_arguments
    and al, 0x7f
    xor ah, ah
    video_bios_without_arguments
%endmacro

set_standard_text_rows:
    push ebx
    push ecx
    push edx
    push es
    reload_current_video_mode
    mov ecx, 0x607
    mov eax, [bios_data_offset]
    mov es, [bios_data_selector]
    add eax, strict dword 0x87
    xor ebx, ebx
    xor edx, edx
    and byte [es:eax], 0xfe
    mov eax, 0x100
    video_bios
    mov word [cursor_visible], 1
    pop es
    pop edx
    pop ecx
    pop ebx
    ret

configure_vga_text_font:
    push ecx
    push esi
    push edi
    mov esi, edx
    mov edi, ebx
    mov ebx, 0x30
    xor ecx, ecx
    xor edx, edx
    video_bios
    reload_current_video_mode
    mov eax, 0x500
    video_bios_without_arguments
    mov eax, esi
    video_bios_without_arguments
    mov eax, 0x100
    mov ecx, edi
    xor ebx, ebx
    xor edx, edx
    video_bios
    mov word [cursor_visible], 1
    pop edi
    pop esi
    pop ecx
    ret

configure_ega_text_font:
    push ecx
    push esi
    push edi
    push es
    push ebp
    mov ebp, esp
    push eax
    mov edi, edx
    mov esi, ebx
    mov eax, 0x500
    video_bios_without_arguments
    reload_current_video_mode
    mov eax, edi
    video_bios_without_arguments
    cmp word [ebp-4], 43
    jne short .set_underline
    mov eax, [bios_data_offset]
    mov es, [bios_data_selector]
    add eax, strict dword 0x87
    or byte [es:eax], 1
    jmp short .set_cursor
.set_underline:
    mov edx, 0x3d4
    mov eax, 0x1414
    out dx, ax
.set_cursor:
    mov eax, 0x100
    mov ecx, esi
    xor ebx, ebx
    xor edx, edx
    video_bios
    mov word [cursor_visible], 1
font_frame_return:
    leave
    pop es
    pop edi
    pop esi
    pop ecx
font_return:
    ret

configure_other_text_font:
    push ecx
    push esi
    push edi
    push es
    push ebp
    mov ebp, esp
    push eax
    push edx
    mov esi, ebx
    mov eax, 0x500
    video_bios_without_arguments
    reload_current_video_mode
    push es
    mov eax, 0xa000
    mov es, ax
    db 0x33, 0xc0 ; xor eax, eax using the register-load opcode
    db 0x8b, 0xf8 ; mov edi, eax using the register-load opcode
    mov ecx, 0x1000
.fill_character_words:
    stosw
    inc al
    loop .fill_character_words
    pop es
    mov eax, [ebp-8]
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    and al, 0xf
    video_bios
    mov eax, 0x1103
    video_bios_without_arguments
    mov eax, 0x100
    mov ecx, esi
    xor ebx, ebx
    xor edx, edx
    video_bios
    movsx eax, si
    and eax, 0xff00
    mov edx, 0x3d4
    add eax, 9
    mov bl, [ebp-4]
    out dx, ax
    mov edx, [bios_data_offset]
    mov es, [bios_data_selector]
    lea eax, [edx+0x84]
    dec bl
    and esi, 0x100
    mov [es:eax], bl
    lea eax, [edx+0x85]
    add esi, esi
    mov word [cursor_visible], 1
    db 0x66 ; operand-size prefix precedes the ES override in the original
    mov [es:eax], esi
    jmp near font_frame_return

set_video_mode_and_text_rows:
    cwde
    call set_video_mode
    test ax, ax
    jz near font_return
    movsx eax, dx
    jmp near set_text_rows

; Set text rows and reset the text window for the current video mode.
BITS 32
ORG 0x70e37


graphics_error equ 0x16c66
bios_data_offset equ 0x16d01
bios_data_selector equ 0x16cf7
text_rows equ 0x289202
adapter_class equ 0x28920c
monitor_class equ 0x28920e
video_mode equ 0x28920a
cursor_visible equ 0x16c76

set_text_rows:
    times 230 db 0 ; supplied by matching C

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
    times 91 db 0 ; supplied by matching C

configure_vga_text_font:
    times 116 db 0 ; supplied by matching C

configure_ega_text_font:
    ; The linker supplies this routine and its shared return paths from C.
    times 143 db 0
font_frame_return:
    times 5 db 0
font_return:
    db 0

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

    times 23 db 0 ; supplied by matching C

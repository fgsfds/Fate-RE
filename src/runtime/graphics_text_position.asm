; Text cursor position and video mode selection.
BITS 32
ORG 0x6ebc0

initialize_graphics_once equ 0x6fd95
hide_graphics_cursor equ 0x6febd
restore_cursor_if_enabled equ 0x7002e
detect_display_adapters equ 0x7139e
initialize_graphics_device equ 0x7003d
shutdown_graphics_device equ 0x70049
set_text_rows equ 0x70e37
reset_video_state equ 0x6ef09
set_absolute_graphics_pair equ 0x7162c
set_nonzero_graphics_pair equ 0x7164b
set_graphics_word_a5 equ 0x7166d
set_graphics_word_ab equ 0x71674
set_graphics_pair_ad equ 0x7167b

graphics_active equ 0x16c65
graphics_error equ 0x16c66
cursor_enabled equ 0x16c74
cursor_visible equ 0x16c76
active_text_page equ 0x16c78
video_device_table equ 0x141c4
text_cursor_row equ 0x2891f8
text_cursor_column equ 0x2891fa
pixel_width equ 0x2891fc
pixel_height equ 0x2891fe
text_rows equ 0x289202
graphics_colors equ 0x289206
video_mode equ 0x28920a
video_device equ 0x289212
initial_text_rows equ 0x28923a
text_window_right equ 0x28923e
text_window_bottom equ 0x289240
text_window_left equ 0x289242
text_window_top equ 0x289244
initial_video_mode equ 0x289246

get_text_position:
    enter 4, 0
    call initialize_graphics_once
    mov ax, [text_cursor_row]
    sub ax, [text_window_top]
    inc eax
    mov [ebp-4], ax
    mov ax, [text_cursor_column]
    sub ax, [text_window_left]
    inc eax
    mov [ebp-2], ax
    mov eax, [ebp-4]
    leave
    ret

set_text_position:
    push ebx
    push ecx
    push esi
    mov ebx, eax
    call hide_graphics_cursor
    call get_text_position
    mov esi, eax
    mov ax, [text_window_top]
    dec eax
    add ebx, eax
    mov ax, [text_window_left]
    dec eax
    add edx, eax
    cmp bx, [text_window_top]
    jge short .check_bottom
    mov bx, [text_window_top]
.check_bottom:
    cmp bx, [text_window_bottom]
    jle short .check_left
    mov bx, [text_window_bottom]
.check_left:
    cmp dx, [text_window_left]
    jge short .check_right
    mov dx, [text_window_left]
.check_right:
    cmp dx, [text_window_right]
    jle short .apply
    mov dx, [text_window_right]
.apply:
    mov eax, 0x200
    mov [text_cursor_row], bx
    shl ebx, 8
    mov [text_cursor_column], dx
    add edx, ebx
    mov bx, [active_text_page]
    xor ecx, ecx
    shl ebx, 8
    push bp
    int 0x10
    pop bp
    call restore_cursor_if_enabled
    mov eax, esi
    pop esi
    pop ecx
    pop ebx
    ret

set_video_mode:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    mov esi, eax
    mov word [graphics_error], 0
    call initialize_graphics_once
    movsx eax, si
    call resolve_video_mode
    mov ebx, eax
    cwde
    cmp eax, -1
    jne short .lookup
    mov word [graphics_error], -1
.failure:
    xor eax, eax
    jmp near .return
.lookup:
    mov eax, video_device_table
.next_device:
    movsx edx, word [eax]
    cmp edx, -1
    jne short .check_mode
    mov word [graphics_error], -4
    jmp short .failure
.check_mode:
    cmp bx, [eax]
    je short .switch_device
    add eax, 6
    jmp short .next_device
.switch_device:
    mov edx, [video_device]
    mov di, [video_mode]
    mov ecx, [eax+2]
    test edx, edx
    je short .install_device
    call shutdown_graphics_device
.install_device:
    movsx eax, bx
    mov [video_device], ecx
    call initialize_graphics_device
    test ax, ax
    jne short .set_cursor_flags
    mov [video_device], edx
    test edx, edx
    je short .device_error
    movsx eax, di
    call initialize_graphics_device
.device_error:
    mov word [graphics_error], -2
    jmp short .failure
.set_cursor_flags:
    cmp word [graphics_colors], 0
    setne al
    mov [graphics_active], al
    test al, al
    sete al
    movzx ax, al
    mov [cursor_enabled], ax
    mov [cursor_visible], ax
    movsx eax, si
    cmp eax, -1
    jne short .reset
    movsx eax, word [initial_text_rows]
    call set_text_rows
.reset:
    call reset_video_state
    mov ax, [text_rows]
.return:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

%macro mode_return 0
    pop edx
    pop ecx
    pop ebx
    ret
%endmacro

resolve_video_mode:
    push ebx
    push ecx
    push edx
    mov edx, eax
    cwde
    cmp eax, -3
    jne near .check_color_default
    call detect_display_adapters
    xor ah, ah
    mov edx, eax
    cmp ax, strict word 5
    jb short .mono_low_adapter
    jbe short .mode_0f
    cmp ax, strict word 10
    jb short .mono_middle_adapter
    cmp ax, strict word 12
    jbe short .mode_11
    cmp ax, strict word 15
    jbe short .mode_0b
    cmp ax, strict word 17
.mono_high_adapter:
    jbe short .mode_12
    jmp short .unsupported
.mono_middle_adapter:
    cmp ax, strict word 7
    jb short .unsupported
    cmp ax, strict word 8
    jmp short .mono_high_adapter
.mono_low_adapter:
    cmp ax, strict word 3
    jb short .mono_cga
    jbe short .mode_10
    jmp short .mode_0e
.mono_cga:
    cmp ax, strict word 2
    jne short .unsupported
    mov eax, 6
    mode_return
.mode_10:
    mov eax, 0x10
    mode_return
.mode_0e:
    mov eax, 0x0e
    mode_return
.mode_0f:
    mov eax, 0x0f
    mode_return
.mode_12:
    mov eax, 0x12
    mode_return
.mode_11:
    mov eax, 0x11
    mode_return
.mode_0b:
    mov eax, 0x0b
    mode_return
.unsupported:
    mov eax, -1
    mode_return
.check_color_default:
    cmp eax, -2
    jne near .check_initial_mode
    call detect_display_adapters
    xor ah, ah
    cmp ax, strict word 5
    jb short .color_low_adapter
    jbe short .mode_0f
    cmp ax, strict word 10
    jb short .color_middle_adapter
    cmp ax, strict word 12
    jbe short .mode_13
    cmp ax, strict word 15
    jbe short .mode_0b
    cmp ax, strict word 17
.color_high_adapter:
    jbe short .mode_13
    jmp short .unsupported
.color_middle_adapter:
    cmp ax, strict word 7
    jb short .unsupported
    cmp ax, strict word 8
    jmp short .color_high_adapter
.color_low_adapter:
    cmp ax, strict word 3
    jb short .color_cga
    jbe short .query_ega_memory
    jmp short .mode_0e
.color_cga:
    cmp ax, strict word 2
    jne short .unsupported
    mov eax, 4
    mode_return
.query_ega_memory:
    mov eax, 0x1200
    mov ebx, 0x10
    xor ecx, ecx
    xor edx, edx
    push bp
    int 0x10
    pop bp
    test bx, bx
    jne near .mode_10
    jmp near .mode_0e
.mode_13:
    mov eax, 0x13
    mode_return
.check_initial_mode:
    cmp eax, -1
    jne short .explicit_mode
    mov ax, [initial_video_mode]
    mode_return
.explicit_mode:
    mov eax, edx
    mode_return

reset_graphics_aspect_settings:
    push ebx
    push ecx
    push edx
    movsx ecx, word [pixel_height]
    movsx ebx, word [text_rows]
    lea eax, [ecx+ecx*2]
    add ebx, ebx
    cdq
    idiv ebx
    movsx ebx, ax
    movsx eax, word [pixel_width]
    imul eax, ebx
    imul eax, eax, 15
    shl ecx, 5
    cdq
    idiv ecx
    movsx edx, ax
    mov eax, ebx
    call set_absolute_graphics_pair
    mov eax, 1
    xor edx, edx
    call set_nonzero_graphics_pair
    xor eax, eax
    call set_graphics_word_a5
    xor eax, eax
    xor edx, edx
    call set_graphics_word_ab
    xor eax, eax
    call set_graphics_pair_ad
    mode_return

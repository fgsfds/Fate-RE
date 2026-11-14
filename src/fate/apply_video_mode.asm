; Select a video mode and dimensions from the setup menu.
BITS 32
ORG 0x370ec

frame_state_a89 equ 0xa89
frame_state_a91 equ 0xa91
frame_state_aba equ 0xaba
frame_state_ae8 equ 0xae8
frame_state_af6 equ 0xaf6
frame_state_b13 equ 0xb13
frame_state_b30 equ 0xb30
frame_state_12d30 equ 0x12d30
frame_state_12d48 equ 0x12d48
frame_state_12d4e equ 0x12d4e
frame_state_12d54 equ 0x12d54
frame_state_12d56 equ 0x12d56
frame_state_12d60 equ 0x12d60
frame_state_12d64 equ 0x12d64
frame_state_12d68 equ 0x12d68
frame_state_12d6a equ 0x12d6a
frame_state_12d70 equ 0x12d70
frame_state_12d74 equ 0x12d74
frame_state_12d78 equ 0x12d78
print_video_text_at equ 0x36b0e
prompt_video_settings equ 0x36f73
getch equ 0x62edf
set_background_color equ 0x6f1bf
set_text_color equ 0x6f25d
set_text_window equ 0x6f2e7
clear_screen equ 0x6f42c
set_cursor_enabled equ 0x6f5bd
frame_state_173d54 equ 0x173d54
frame_state_173d56 equ 0x173d56

    db 0x8b, 0xc0 ; mov eax, eax using the original alignment encoding

video_mode_dispatch:
    dd apply_video_mode.load_first_mode_dimensions - 0x10000
    dd apply_video_mode.load_second_mode_dimensions - 0x10000
    dd apply_video_mode.use_default_dimensions - 0x10000
    dd apply_video_mode.use_default_dimensions - 0x10000
    dd apply_video_mode.use_default_dimensions - 0x10000
    dd apply_video_mode.use_default_dimensions - 0x10000

video_width_dispatch:
    dd apply_video_mode.load_first_mode_dimensions - 0x10000
    dd apply_video_mode.load_second_mode_dimensions - 0x10000
    dd apply_video_mode.restore_default_dimensions - 0x10000
    dd apply_video_mode.restore_default_dimensions - 0x10000
    dd apply_video_mode.restore_default_dimensions - 0x10000
    dd apply_video_mode.restore_default_dimensions - 0x10000

video_height_dispatch:
    dd apply_video_mode.load_first_mode_dimensions - 0x10000
    dd apply_video_mode.load_second_mode_dimensions - 0x10000
    dd apply_video_mode.restore_default_dimensions - 0x10000
    dd apply_video_mode.restore_default_dimensions - 0x10000
    dd apply_video_mode.restore_default_dimensions - 0x10000
    dd apply_video_mode.restore_default_dimensions - 0x10000

apply_video_mode:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 0xc
    mov esi, 0x1
    mov ecx, 0x50
    mov ebx, 0x19
    mov ax, [frame_state_12d70]
    mov di, [frame_state_12d74]
    xor edx, edx
    mov [esp + 0x8], eax
    mov ax, [frame_state_12d78]
    mov [esp], edx
    mov [esp + 0x4], eax
    xor eax, eax
    mov edx, esi
    call set_cursor_enabled
    mov eax, 0x3
    call set_text_window
    xor eax, eax
    call set_background_color
    mov eax, 0x2
    call clear_screen
    push strict dword frame_state_a89
    push strict byte 0xa
    push strict byte -1
    call print_video_text_at
    add esp, 0xc
    push strict dword frame_state_a91
    push strict byte 0x13
    push strict byte -1
    call print_video_text_at
    add esp, 0xc
    push strict dword frame_state_aba
    push strict byte 0x14
    push strict byte -1
    call print_video_text_at
    add esp, 0xc
    movsx eax, word [esp + 0x4]
    push eax
    movsx eax, di
    push eax
    movsx eax, word [esp + 0x10]
    mov ebx, [nosplit eax*4 + frame_state_12d30]
    push ebx
    push strict dword frame_state_ae8
    push strict byte 0x15
    push strict byte -1
    call print_video_text_at
    add esp, 0x18

.branch_371ed:
    xor eax, eax
    call set_background_color
    mov eax, 0xb
    call set_text_color
    mov ecx, [esp]
    test ecx, ecx
    jna short .branch_3720c
    cmp ecx, 0x1
    jz short .branch_3722e
    jmp short .branch_37259

.branch_3720c:
    mov eax, 0xa
    call set_text_color
    push strict dword frame_state_af6
    push strict byte 0x1
    push strict byte -1
    call print_video_text_at
    add esp, 0xc
    push strict dword frame_state_b13
    jmp short .branch_3724d

.branch_3722e:
    mov eax, 0xd
    call set_text_color
    push strict dword frame_state_af6
    push ecx
    push strict byte -1
    call print_video_text_at
    add esp, 0xc
    push strict dword frame_state_b30

.branch_3724d:
    push strict byte 0x2
    push strict byte -1
    call print_video_text_at
    add esp, 0xc

.branch_37259:
    mov edx, [esp]
    test edx, edx
    setz al
    and eax, strict dword 0xff
    cwde
    call prompt_video_settings
    call getch
    cmp eax, 0x9
    jc short .branch_3729c
    cmp eax, 0x9
    jna near .branch_37453
    cmp eax, 0xd
    jc near .branch_3748b
    jna near .branch_37459
    cmp eax, 0x1b
    jz near .branch_3746d
    jmp near .branch_3748b

.branch_3729c:
    test eax, eax
    jnz near .branch_3748b
    call getch
    cmp eax, 0x4b
    jc short .branch_372c5
    jna short .branch_372d3
    cmp eax, 0x4d
    jc near .branch_3748b
    jna short .branch_372e6
    cmp eax, 0x50
    jz short .branch_372fa
    jmp near .branch_3748b

.branch_372c5:
    cmp eax, 0x48
    jz near .branch_373da
    jmp near .branch_3748b

.branch_372d3:
    cmp edx, 0x1
    jnz near .branch_3748b
    xor ebp, ebp
    mov [esp], ebp
    jmp near .branch_3748b

.branch_372e6:
    test edx, edx
    jnz near .branch_3748b
    mov dword [esp], 0x1
    jmp near .branch_3748b

.branch_372fa:
    test edx, edx
    jna short .branch_37308
    cmp edx, 0x1
    jz short .branch_3732a
    jmp near .branch_3748b

.branch_37308:
    mov ecx, [frame_state_12d70]
    inc ecx
    mov [frame_state_12d70], ecx
    cmp ecx, 0x6
    jl near .branch_3748b
    xor eax, eax
    mov [frame_state_12d70], eax
    jmp near .branch_3748b

.branch_3732a:
    mov dx, [frame_state_173d54]
    inc edx
    mov bx, [frame_state_173d56]
    mov [frame_state_173d54], dx
    cmp dx, bx
    jl short .branch_3734e
    mov eax, ebx
    dec eax
    mov [frame_state_173d54], ax

.branch_3734e:
    mov eax, [frame_state_12d70]
    cmp eax, 0x5
    ja near .branch_3748b
    jmp dword near [cs:eax*4 + video_mode_dispatch - 0x10000]
.load_first_mode_dimensions:
    movsx eax, word [frame_state_173d54]
    movsx edx, word [nosplit eax*4 + frame_state_12d54]
    movsx eax, word [nosplit eax*4 + frame_state_12d56]
    movsx edx, word [nosplit edx*2 + frame_state_12d48]
    movsx eax, word [nosplit eax*2 + frame_state_12d4e]

.branch_3738b:
    mov [frame_state_12d74], edx
    jmp near .branch_37486
.load_second_mode_dimensions:
    movsx eax, word [frame_state_173d54]
    movsx edx, word [nosplit eax*4 + frame_state_12d68]
    movsx eax, word [nosplit eax*4 + frame_state_12d6a]
    movsx edx, word [nosplit edx*2 + frame_state_12d60]
    movsx eax, word [nosplit eax*2 + frame_state_12d64]
    jmp short .branch_3738b
.use_default_dimensions:
    mov edx, 0x140
    mov ebx, 0xc8
    mov [frame_state_12d74], edx
    mov [frame_state_12d78], ebx
    jmp near .branch_3748b

.branch_373da:
    test edx, edx
    jna short .branch_373e8
    cmp edx, 0x1
    jz short .branch_3740c
    jmp near .branch_3748b

.branch_373e8:
    mov ebp, [frame_state_12d70]
    dec ebp
    mov [frame_state_12d70], ebp
    test ebp, ebp
    jnl near .branch_3748b
    mov dword [frame_state_12d70], 0x5
    jmp near .branch_3748b

.branch_3740c:
    mov cx, [frame_state_173d54]
    dec ecx
    mov [frame_state_173d54], cx
    test cx, cx
    jnl short .branch_37429
    xor edx, edx
    mov [frame_state_173d54], dx

.branch_37429:
    mov eax, [frame_state_12d70]
    cmp eax, 0x5
    ja short .branch_3748b
    jmp dword near [cs:eax*4 + video_width_dispatch - 0x10000]
.restore_default_dimensions:
    mov ebx, 0x140
    mov ecx, 0xc8
    mov [frame_state_12d74], ebx
    mov [frame_state_12d78], ecx
    jmp short .branch_3748b

.branch_37453:
    xor byte [esp], 0x1
    jmp short .branch_3748b

.branch_37459:
    mov eax, [frame_state_12d70]
    xor esi, esi
    cmp eax, 0x5
    ja short .branch_3748b
    jmp dword near [cs:eax*4 + video_height_dispatch - 0x10000]

.branch_3746d:
    movsx eax, word [esp + 0x8]
    mov [frame_state_12d70], eax
    movsx eax, di
    mov [frame_state_12d74], eax
    movsx eax, word [esp + 0x4]
    xor esi, esi

.branch_37486:
    mov [frame_state_12d78], eax

.branch_3748b:
    test esi, esi
    jnz near .branch_371ed
    xor eax, eax
    call set_background_color
    mov eax, 0xe
    call set_text_color
    mov eax, 0x2
    call clear_screen
    add esp, 0xc
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

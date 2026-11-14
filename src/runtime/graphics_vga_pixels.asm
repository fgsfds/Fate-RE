; Address planar and packed VGA pixels and install the VGA mode parameters.
BITS 32
ORG 0x70539

set_and_query_bios_mode equ 0x72180
apply_graphics_mode_state equ 0x6fe1e

current_buffer_selector equ 0x289226
current_buffer_offset equ 0x289228
pixel_address equ 0x2891ec
pixel_selector equ 0x2891f0
pixel_color equ 0x2891f2
pixel_mask_and_width equ 0x2891f4
pixel_bit_offset equ 0x2891f6
two_plane_color_map equ 0x16ec4
graphics_buffer_offset equ 0x16d0d
graphics_buffer_selector equ 0x16cfd

address_planar_pixel_320:
    push ecx
    push esi
    mov esi, eax
    movsx ecx, dx
    imul eax, ecx, 0x28
.store_pixel:
    movsx ecx, si
    sar ecx, 3
    add eax, ecx
    mov word [pixel_color], bx
    movzx eax, ax
    and esi, 7
    add eax, dword [current_buffer_offset]
    movsx ecx, si
    mov dword [pixel_address], eax
    mov eax, 0x80
    mov dx, word [current_buffer_selector]
    sar eax, cl
    mov word [pixel_selector], dx
    shl eax, 8
    mov word [pixel_bit_offset], si
    mov word [pixel_mask_and_width], ax
    pop esi
    pop ecx
    ret

address_planar_pixel_640:
    push ecx
    push esi
    mov esi, eax
    movsx ecx, dx
    imul eax, ecx, 0x50
    jmp short address_planar_pixel_320.store_pixel

address_two_plane_pixel:
    push ecx
    push esi
    mov esi, eax
    movsx ecx, dx
    imul ecx, ecx, 0x50
    cwde
    sar eax, 3
    add eax, ecx
    movzx eax, ax
    and esi, 7
    add eax, dword [current_buffer_offset]
    movsx ecx, si
    mov dword [pixel_address], eax
    mov eax, 0x80
    sar eax, cl
    shl eax, 8
    mov dx, word [current_buffer_selector]
    mov word [pixel_mask_and_width], ax
    movsx eax, bx
    mov word [pixel_bit_offset], si
    movzx ax, byte [eax + two_plane_color_map]
    mov word [pixel_selector], dx
    mov word [pixel_color], ax
    pop esi
    pop ecx
    ret

set_vga_graphics_mode:
    push ebx
    push ecx
    push edx
    mov edx, eax
    cwde
    call set_and_query_bios_mode
    cmp ax, dx
    jne near .rejected
    cmp dx, 0x11
    jne short .check_mode_12
    push 0
    push 0
    push dword [graphics_buffer_offset]
    movsx eax, word [graphics_buffer_selector]
    push eax
    mov edx, 0x1e0
    mov ebx, 2
    push 1
    mov ecx, 1
.width_640:
    mov eax, 0x280
    jmp short .apply
.check_mode_12:
    cmp dx, 0x12
    jne short .mode_13
    push 1
    push 0
    push dword [graphics_buffer_offset]
    movsx eax, word [graphics_buffer_selector]
    push eax
    mov edx, 0x1e0
    mov ebx, 0x10
    push 1
    mov ecx, 4
    jmp short .width_640
.mode_13:
    push 0
    push 0
    push dword [graphics_buffer_offset]
    movsx eax, word [graphics_buffer_selector]
    push eax
    mov edx, 0xc8
    mov ebx, 0x100
    push 1
    mov ecx, 8
    mov eax, 0x140
.apply:
    call apply_graphics_mode_state
    mov eax, 1
    pop edx
    pop ecx
    pop ebx
    ret
.rejected:
    xor eax, eax
    pop edx
    pop ecx
    pop ebx
    ret

address_vga_mono_pixel:
    push ecx
    mov ecx, eax
    movsx eax, dx
    imul edx, eax, 0x50
    movsx eax, cx
    and cl, 7
    xor ch, ch
    sar eax, 3
    mov word [pixel_bit_offset], cx
    add eax, edx
    mov dx, word [current_buffer_selector]
    add eax, dword [current_buffer_offset]
    mov word [pixel_selector], dx
    mov dl, byte [pixel_bit_offset]
    mov dword [pixel_address], eax
    inc dl
    mov al, 0xfe
    mov cl, dl
    o16 ror al, cl
    movzx ax, al
    shl eax, 8
    inc eax
    mov cl, dl
    mov word [pixel_mask_and_width], ax
    mov al, bl
    o16 ror al, cl
    movzx ax, al
    mov word [pixel_color], ax
    pop ecx
    ret

address_vga_byte_pixel:
    push ecx
    mov ecx, eax
    movsx eax, dx
    imul edx, eax, 0x140
    mov word [pixel_bit_offset], 0
    movsx eax, cx
    mov word [pixel_color], bx
    add eax, edx
    mov dx, word [current_buffer_selector]
    add eax, dword [current_buffer_offset]
    mov word [pixel_selector], dx
    mov dword [pixel_address], eax
    pop ecx
    ret

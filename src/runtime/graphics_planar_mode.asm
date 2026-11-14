; Set planar BIOS modes and program VGA drawing state.
BITS 32
ORG 0x7037c

set_and_query_bios_mode equ 0x72180
apply_graphics_mode_state equ 0x6fe1e

graphics_buffer_offset equ 0x16d0d
graphics_buffer_selector equ 0x16cfd
graphics_page_count equ 0x289208
graphics_device equ 0x289212
two_plane_device equ 0x17008
palette_size equ 0x289204
bitmap_bits_per_pixel equ 0x289206
drawing_action equ 0x16c9f
planar_action_bits equ 0x16ec0

set_planar_graphics_mode:
    push ebx
    push ecx
    push edx
    push esi
    mov esi, eax
    cwde
    call set_and_query_bios_mode
    cmp ax, si
    jne near .rejected
    cmp si, 0xd
    jne short .check_mode_0e
    push 1
    push 0x200
    push dword [graphics_buffer_offset]
    movsx eax, word [graphics_buffer_selector]
    push eax
    mov edx, 0xc8
    mov ebx, 0x10
    push 8
    mov ecx, 4
    mov eax, 0x140
    jmp near .apply_mode
.check_mode_0e:
    cmp si, 0xe
    jne short .check_mode_0f
    push 1
    push 0x400
    push dword [graphics_buffer_offset]
    movsx eax, word [graphics_buffer_selector]
    push eax
    mov edx, 0xc8
    mov ebx, 0x10
    push 4
    mov ecx, 4
.width_640:
    mov eax, 0x280
    jmp short .apply_mode
.check_mode_0f:
    cmp si, 0xf
    jne short .mode_10
    push 1
    push 0x800
    push dword [graphics_buffer_offset]
    movsx eax, word [graphics_buffer_selector]
    push eax
    mov edx, 0x15e
    mov ebx, 4
    push 2
    mov ecx, 2
    jmp short .width_640
.mode_10:
    push 1
    push 0x800
    push dword [graphics_buffer_offset]
    movsx eax, word [graphics_buffer_selector]
    push eax
    mov edx, 0x15e
    mov ebx, 0x10
    push 2
    mov ecx, 4
    mov eax, 0x280
.apply_mode:
    call apply_graphics_mode_state
    mov eax, 0x1200
    mov ebx, 0x10
    xor ecx, ecx
    xor edx, edx
    push bp
    int 0x10
    pop bp
    test bl, 0xff
    jne short .reset_plane_mask
    movsx eax, word [graphics_page_count]
    cdq
    shl edx, 2
    db 0x1b, 0xc2 ; SBB EAX, EDX, register-destination encoding.
    sar eax, 2
    cmp eax, 1
    jge short .store_page_count
    mov eax, 1
.store_page_count:
    mov word [graphics_page_count], ax
    cmp si, 0xf
    je short .select_two_plane_device
    cmp si, 0x10
    jne short .reset_plane_mask
.select_two_plane_device:
    mov dword [graphics_device], two_plane_device
    mov word [palette_size], 4
    mov word [bitmap_bits_per_pixel], 2
.reset_plane_mask:
    mov edx, 0x3c4
    mov eax, 0xf02
    out dx, ax
    mov eax, 1
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
.rejected:
    xor eax, eax
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

begin_planar_drawing:
    push edx
    mov edx, 0x3ce
    mov eax, 0x205
.set_write_mode:
    out dx, ax
    movsx eax, word [drawing_action]
    movzx eax, byte [eax + planar_action_bits]
    shl eax, 8
    add eax, 3
    out dx, ax
    pop edx
    ret

begin_interleaved_planar_drawing:
    push edx
    mov edx, 0x3ce
    mov eax, 0x1205
    jmp short begin_planar_drawing.set_write_mode

end_planar_drawing:
    push edx
    mov edx, 0x3ce
    mov eax, 5
.reset_registers:
    out dx, ax
    mov eax, 0xff08
    out dx, ax
    mov eax, 0xf07
    out dx, ax
    mov eax, 3
    out dx, ax
    pop edx
    ret

end_interleaved_planar_drawing:
    push edx
    mov edx, 0x3ce
    mov eax, 0x1005
    jmp short end_planar_drawing.reset_registers

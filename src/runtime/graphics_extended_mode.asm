; Set an extended video mode using the adapter-specific BIOS and register paths.
BITS 32
ORG 0x70744

allocate_graphics_dos_buffer equ 0x72d63
call_graphics_real_mode_interrupt equ 0x72e20
free_graphics_dos_buffer equ 0x72df4
bank_shift equ 0x289248

extended_mode_table:
    dd set_extended_graphics_mode.query_vbe_window - 0x10000
    dd set_extended_graphics_mode.set_6f_mode - 0x10000
    dd set_extended_graphics_mode.set_mode_and_unlock_graphics - 0x10000
    dd set_extended_graphics_mode.set_mode_and_update_ati - 0x10000
    dd set_extended_graphics_mode.set_mode_and_check - 0x10000
    dd set_extended_graphics_mode.set_mode_and_check - 0x10000
    dd set_extended_graphics_mode.set_mode_and_check - 0x10000
    dd set_extended_graphics_mode.set_mode_and_map_graphics_window - 0x10000
    dd set_extended_graphics_mode.set_mode_and_enable_extensions - 0x10000
    dd set_extended_graphics_mode.set_mode_and_check - 0x10000
    dd set_extended_graphics_mode.set_vbe_mode_with_retry - 0x10000
    dd set_extended_graphics_mode.set_mode_and_update_graphics - 0x10000

set_extended_graphics_mode:
    push ebx
    push ecx
    push esi
    push edi
    push es
    enter 0x10c, 0
    mov esi, edx
    dec eax
    cmp ax, strict word 0xb
    ja near .success
    movzx eax, ax
    jmp dword cs:[eax*4 + extended_mode_table - 0x10000]
.query_vbe_window:
    mov eax, 0x100
    lea edx, [ebp - 0xc]
    call allocate_graphics_dos_buffer
    test ax, ax
    je near .done
    push 0
    movsx eax, word [ebp - 0xc]
    mov edx, 0x4f01
    push eax
    movsx ecx, si
    push 0
    xor ebx, ebx
    mov eax, 0x10
    call call_graphics_real_mode_interrupt
    mov dword [ebp - 4], eax
    cmp ax, strict word 0x4f
    jne short .release_mode_info
    mov edi, dword [ebp - 6]
    mov ebx, dword [ebp - 0xa]
    mov ecx, 2
.copy_window_word:
    movsx eax, cx
    mov es, edi
    db 0x66, 0x26, 0x8b, 0x14, 0x43 ; MOV DX, ES:[EBX + EAX*2], original prefix order.
    inc ecx
    mov word [ebp + eax*2 - 0x10c], dx
    cmp cx, 4
    jle short .copy_window_word
.release_mode_info:
    lea eax, [ebp - 0xc]
    call free_graphics_dos_buffer
    cmp word [ebp - 4], 0x4f
    je short .validate_vbe_window
.failure:
    xor eax, eax
    jmp near .done
.validate_vbe_window:
    cmp word [ebp - 0x106], 0x40
    jne short .failure
    cmp word [ebp - 0x104], 0xa000
    jne short .failure
    mov eax, 0x4f02
    mov ebx, esi
    xor ecx, ecx
    xor edx, edx
    push bp
    int 0x10
    pop bp
    cmp ax, strict word 0x4f
    jne short .failure
    mov eax, 0x40
    movzx ecx, word [ebp - 0x108]
    cdq
    mov byte [bank_shift], 0
    idiv ecx
.count_bank_shift:
    cmp ax, strict word 1
    jle near .success
    inc byte [bank_shift]
    sar ax, 1
    jmp short .count_bank_shift
.set_6f_mode:
    mov eax, 0x6f05
    mov ebx, edx
    xor ecx, ecx
    xor edx, edx
    push bp
    int 0x10
    pop bp
    mov eax, 0x6f04
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    push bp
    int 0x10
    pop bp
    xor ah, ah
    movsx edx, ax
    movsx eax, si
    cmp edx, eax
    jne near .failure
    mov edx, 0x3c4
    mov eax, 0xea06
    out dx, ax
    cmp si, 0x66
    jne short .check_bank_shift_16
    mov al, 0xff
    out dx, al
    mov edx, 0x3c5
    sub eax, eax
    in al, dx
    or al, 0x10
    cwde
    out dx, al
.check_bank_shift_16:
    cmp si, 0x65
    jne short .set_bank_shift_ff
.set_bank_shift_16:
    mov byte [bank_shift], 0x10
    jmp near .success
.set_bank_shift_ff:
    mov byte [bank_shift], 0xff
    jmp near .success
.set_mode_and_unlock_graphics:
    mov eax, edx
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    push bp
    int 0x10
    pop bp
    mov eax, 0xf00
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    push bp
    int 0x10
    pop bp
    and al, 0x7f
    xor ah, ah
    movsx edx, ax
    movsx eax, si
    cmp edx, eax
    jne near .failure
    mov edx, 0x3ce
    mov eax, 0x50f
.write_graphics_word:
    out dx, ax
    jmp near .success
.set_mode_and_update_ati:
    mov eax, edx
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    push bp
    int 0x10
    pop bp
    mov eax, 0xf00
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    push bp
    int 0x10
    pop bp
    and al, 0x7f
    xor ah, ah
    movsx edx, ax
    movsx eax, si
    cmp edx, eax
    jne near .failure
    mov edx, 0x1ce
    mov al, 0xbe
    out dx, al
    mov edx, 0x1cf
    sub eax, eax
    in al, dx
    and al, 0xf7
    xor ah, ah
    cwde
    shl eax, 8
    mov edx, 0x1ce
    add eax, 0xbe
    jmp short .write_graphics_word
.set_mode_and_check:
    mov eax, esi
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    push bp
    int 0x10
    pop bp
    mov eax, 0xf00
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    push bp
    int 0x10
    pop bp
    and al, 0x7f
    xor ah, ah
    movsx edx, si
    cwde
    cmp eax, edx
    je near .success
    jmp near .failure
.set_vbe_mode_with_retry:
    mov eax, 0x4f02
    mov ebx, edx
    xor ecx, ecx
    xor edx, edx
    push bp
    int 0x10
    pop bp
    cmp ax, strict word 0x4f
    je short .select_vbe_bank_shift
    mov eax, 0x4f02
    mov ebx, esi
    xor ecx, ecx
    xor edx, edx
    inc bh
    push bp
    int 0x10
    pop bp
    cmp ax, strict word 0x4f
    jne near .failure
.select_vbe_bank_shift:
    cmp si, 0x104
    je near .set_bank_shift_16
    jmp near .set_bank_shift_ff
.set_mode_and_map_graphics_window:
    mov eax, edx
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    push bp
    int 0x10
    pop bp
    mov eax, 0xf00
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    push bp
    int 0x10
    pop bp
    and al, 0x7f
    xor ah, ah
    movsx edx, si
    cwde
    cmp eax, edx
    jne near .failure
    mov edx, 0x3c4
    mov al, 0xb
    out dx, al
    mov edx, 0x3c5
    sub eax, eax
    in al, dx
    mov edx, 0x3ce
    mov al, 6
    out dx, al
    mov edx, 0x3cf
    sub eax, eax
    in al, dx
    and al, 0xf3
    xor ah, ah
    or al, 4
    jmp near .write_graphics_byte
.set_mode_and_enable_extensions:
    mov eax, edx
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    push bp
    int 0x10
    pop bp
    mov eax, 0xf00
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    push bp
    int 0x10
    pop bp
    and al, 0x7f
    xor ah, ah
    movsx edx, si
    cwde
    cmp eax, edx
    jne near .failure
    mov edx, 0x46e8
    mov al, 0x18
    out dx, al
    mov edx, 0x103
    mov al, 0x80
    out dx, al
    mov edx, 0x46e8
    mov al, 8
    out dx, al
    mov edx, 0x3d6
    mov al, 0xb
    out dx, al
    mov edx, 0x3d7
    sub eax, eax
    in al, dx
    or al, 1
    cwde
    out dx, al
    cmp si, 0x61
    je short .set_bank_shift_4
    cmp si, 0x72
    jne short .set_bank_shift_2
.set_bank_shift_4:
    mov byte [bank_shift], 4
    jmp short .set_mode_and_update_graphics
.set_bank_shift_2:
    mov byte [bank_shift], 2
.set_mode_and_update_graphics:
    mov eax, esi
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    push bp
    int 0x10
    pop bp
    mov eax, 0xf00
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    push bp
    int 0x10
    pop bp
    and al, 0x7f
    xor ah, ah
    movsx edx, ax
    movsx eax, si
    cmp edx, eax
    jne near .failure
    mov edx, 0x3ce
    mov al, 0xb
    out dx, al
    mov edx, 0x3cf
    sub eax, eax
    in al, dx
    and al, 0xfe
    xor ah, ah
.write_graphics_byte:
    cwde
    out dx, al
.success:
    mov eax, 1
.done:
    leave
    pop es
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

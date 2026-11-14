; Classify BIOS display combinations and probe legacy CRT controllers.
BITS 32
ORG 0x7139e

probe_video_adapter equ 0x72ed2
bios_data_offset equ 0x16d01
bios_data_selector equ 0x16cf7

detect_display_adapters:
    push ebx
    push ecx
    push edx
    push es
    mov eax, 0x1a00
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    push bp
    int 0x10
    pop bp
    xor ah, ah
    cmp ax, strict word 0x1a
    jne near .fallback
    mov eax, 0x1a00
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    push bp
    int 0x10
    pop bp
    movsx eax, bx
    sar eax, 8
    mov dl, bl
    mov dh, al
    cmp bl, 0xc
    ja near .fallback
    cmp bl, 1
    jne short .check_secondary_mono
    call detect_mono_adapter
    mov dl, al
.check_secondary_mono:
    cmp dh, 1
    jne short .check_ega
    call detect_mono_adapter
    mov dh, al
.check_ega:
    cmp dl, 4
    je short .read_ega_flags
    cmp dh, 4
    jne short .check_primary_vga
.read_ega_flags:
    mov eax, dword [bios_data_offset]
    mov es, word [bios_data_selector]
    add eax, 0x88
    mov al, byte es:[eax]
    and al, 0xf
    cmp al, 3
    jne short .check_color_ega
    mov dh, al
.check_color_ega:
    cmp al, 9
    jne short .check_primary_vga
    mov dl, 3
.check_primary_vga:
    cmp dl, 7
    je short .probe_primary_vga
    cmp dl, 8
    jne short .check_secondary_vga
.probe_primary_vga:
    call probe_video_adapter
    test ax, ax
    je short .pack_result
    add dl, 9
    jmp short .pack_result
.check_secondary_vga:
    cmp dh, 7
    je short .probe_secondary_vga
    cmp dh, 8
    jne short .pack_result
.probe_secondary_vga:
    call probe_video_adapter
    test ax, ax
    je short .pack_result
    mov dh, 9
.pack_result:
    movzx ax, dh
    shl eax, 8
    movzx dx, dl
    add eax, edx
    pop es
    pop edx
    pop ecx
    pop ebx
    ret
.fallback:
    call detect_legacy_display_adapters
    pop es
    pop edx
    pop ecx
    pop ebx
    ret

detect_legacy_display_adapters:
    push ebx
    push ecx
    push edx
    push es
    enter 8, 0
    mov eax, 0x1200
    mov ebx, 0x10
    xor ecx, ecx
    xor edx, edx
    push bp
    int 0x10
    pop bp
    xor ch, ch
    cmp cx, 0xc
    jge near .fallback_color
    mov eax, 0x1200
    mov ebx, 0x10
    xor cl, cl
    xor edx, edx
    push bp
    int 0x10
    pop bp
    movsx eax, bx
    sar eax, 8
    xor bh, bh
    cmp ax, strict word 1
    jg short .probe_color
    cmp bx, 3
    jle short .check_ega_mono
.probe_color:
    call detect_color_adapter
    mov byte [ebp - 4], al
    jmp short .probe_mono
.check_ega_mono:
    test ax, ax
    jne short .dual_ega
    mov eax, dword [bios_data_offset]
    mov es, word [bios_data_selector]
    add eax, 0x88
    mov al, byte es:[eax]
    and al, 0xf
    cmp al, 3
    je short .set_ega_color
    cmp al, 9
    jne short .set_ega_mono
.set_ega_color:
    mov byte [ebp - 4], 3
    jmp short .probe_mono
.set_ega_mono:
    mov byte [ebp - 4], 4
    jmp short .probe_mono
.dual_ega:
    call detect_color_adapter
    mov byte [ebp - 8], 5
    mov byte [ebp - 4], al
    jmp short .query_current_mode
.fallback_color:
    call detect_color_adapter
    mov byte [ebp - 4], al
.probe_mono:
    call detect_mono_adapter
    mov byte [ebp - 8], al
.query_current_mode:
    mov eax, 0xf00
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    push bp
    int 0x10
    pop bp
    and al, 0x7f
    cmp al, 7
    je short .mono_active
    cmp al, 0xb
    je short .mono_active
    cmp al, 0xf
    jne short .color_active
.mono_active:
    movzx ax, byte [ebp - 4]
    movzx bx, byte [ebp - 8]
    jmp short .pack_result
.color_active:
    movzx ax, byte [ebp - 8]
    movzx bx, byte [ebp - 4]
.pack_result:
    shl eax, 8
    add eax, ebx
    leave
    pop es
    pop edx
    pop ecx
    pop ebx
    ret

detect_mono_adapter:
    push ebx
    push ecx
    push edx
    mov eax, 0x3b4
    call probe_crtc_cursor_register
    test ax, ax
    je near .absent
    mov edx, 0x3ba
    sub eax, eax
    in al, dx
    mov ecx, eax
    xor ebx, ebx
    and cl, 0x80
    xor ch, ah
    jmp short .check_sample_count
.sample_status:
    mov edx, 0x3ba
    sub eax, eax
    in al, dx
    mov edx, eax
    and edx, strict dword 0x80
    movsx eax, cx
    cmp edx, eax
    je short .advance_sample
    mov edx, 0x3ba
    sub eax, eax
    in al, dx
    and al, 0x70
    xor ah, ah
    test ax, ax
    jne short .check_status_bit
    mov edx, 0xd
    jmp short .done
.check_status_bit:
    test al, 0x10
    jne short .status_bit_set
    mov edx, 0xe
    jmp short .done
.status_bit_set:
    mov edx, 0xf
    jmp short .done
.advance_sample:
    inc ebx
.check_sample_count:
    cmp bx, 0x8000
    jb short .sample_status
    mov edx, 1
    jmp short .done
.absent:
    xor edx, edx
.done:
    mov eax, edx
    pop edx
    pop ecx
    pop ebx
    ret

detect_color_adapter:
    mov eax, 0x3d4
    call probe_crtc_cursor_register
    test ax, ax
    je short .done
    mov eax, 2
.done:
    ret

probe_crtc_cursor_register:
    push ebx
    push ecx
    push edx
    enter 4, 0
    mov ebx, eax
    movsx edx, ax
    inc ebx
    mov al, 0xf
    movsx ebx, bx
    out dx, al
    mov edx, ebx
    sub eax, eax
    in al, dx
    mov word [ebp - 4], ax
    mov al, 0x5a
    out dx, al
    jmp short .delay_1
.delay_1:
    jmp short .delay_2
.delay_2:
    jmp short .read_back
.read_back:
    sub eax, eax
    in al, dx
    mov ecx, eax
    movzx eax, byte [ebp - 4]
    out dx, al
    cmp cx, 0x5a
    sete al
    movzx ax, al
    leave
    pop edx
    pop ecx
    pop ebx
    ret

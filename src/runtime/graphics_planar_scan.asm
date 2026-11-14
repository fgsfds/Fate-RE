; Scan planar graphics pixels using the VGA color compare registers.
BITS 32
ORG 0x725f7

scan_interleaved_left:
    db 0x8a, 0xca ; mov cl, dl, register-destination encoding.
    mov edx, 0x3ce
    db 0x8a, 0xe0 ; mov ah, al, register-destination encoding.
    mov al, 2
    out dx, ax
    mov ah, 0x1a
    mov al, 5
    out dx, ax
    mov al, 7
    out dx, al
    inc edx
    mov al, 5
    test edi, 1
    je short .set_plane_mask
    shl al, 1
.set_plane_mask:
    out dx, al
    inc ebx
    mov ah, byte es:[edi]
.compare_pixel:
    test ch, ah
    jne short .check_matching_pixel
    db 0x0a, 0xc9 ; or cl, cl, register-destination encoding.
    jne short .done
    jmp short .step
.check_matching_pixel:
    db 0x0a, 0xc9 ; or cl, cl, register-destination encoding.
    je short .done
.step:
    dec ebx
    db 0x3b, 0xf3 ; cmp esi, ebx, register-destination encoding.
    jge short .done
    rol ch, 1
    jae short .compare_next
    dec edi
    not al
    and al, 0xf
    out dx, al
    mov ah, byte es:[edi]
.compare_next:
    jmp short .compare_pixel
.done:
    ret

scan_two_planes_left:
    mov cl, 5
    jmp short scan_four_planes_left.configure_compare

scan_four_planes_left:
    mov cl, 0xf
.configure_compare:
    push edx
    mov edx, 0x3ce
    db 0x8a, 0xe0 ; mov ah, al, register-destination encoding.
    mov al, 2
    out dx, ax
    mov ah, 0xa
    mov al, 5
    out dx, ax
    db 0x8a, 0xe1 ; mov ah, cl, register-destination encoding.
    mov al, 7
    out dx, ax
    pop eax
    inc ebx
    mov ah, byte es:[edi]
.compare_pixel:
    test ch, ah
    jne short .check_matching_pixel
    db 0x0a, 0xc0 ; or al, al, register-destination encoding.
    jne short .done
    jmp short .step
.check_matching_pixel:
    db 0x0a, 0xc0 ; or al, al, register-destination encoding.
    je short .done
.step:
    dec ebx
    db 0x3b, 0xf3 ; cmp esi, ebx, register-destination encoding.
    jge short .done
    rol ch, 1
    jae short .compare_next
    dec edi
    mov ah, byte es:[edi]
.compare_next:
    jmp short .compare_pixel
.done:
    ret

scan_interleaved_right:
    db 0x8a, 0xca ; mov cl, dl, register-destination encoding.
    mov edx, 0x3ce
    db 0x8a, 0xe0 ; mov ah, al, register-destination encoding.
    mov al, 2
    out dx, ax
    mov ah, 0x1a
    mov al, 5
    out dx, ax
    mov al, 7
    out dx, al
    inc edx
    mov al, 5
    test edi, 1
    je short .set_plane_mask
    shl al, 1
.set_plane_mask:
    out dx, al
    db 0x8a, 0xc5 ; mov al, ch, register-destination encoding.
    shl ch, 1
    neg ch
    not ch
.align_start:
    dec ebx
    shl al, 1
    jae short .align_start
    db 0x32, 0xc0 ; xor al, al, register-destination encoding.
    db 0x0a, 0xc9 ; or cl, cl, register-destination encoding.
    je short .compare_head
    not al
.compare_head:
    mov ah, byte es:[edi]
    db 0x32, 0xe0 ; xor ah, al, register-destination encoding.
    db 0x22, 0xe5 ; and ah, ch, register-destination encoding.
    jne short .find_bit
    db 0x8a, 0xe8 ; mov ch, al, register-destination encoding.
    db 0x32, 0xe5 ; xor ah, ch, register-destination encoding.
    sub esi, 8
    mov cl, 0x55
    test edi, 1
    je short .scan_byte
    shl cl, 1
.scan_byte:
    db 0x3b, 0xf3 ; cmp esi, ebx, register-destination encoding.
    jl short .finish_byte_scan
    add ebx, 8
    inc edi
    rol cl, 1
    db 0x8a, 0xc1 ; mov al, cl, register-destination encoding.
    and al, 0xf
    out dx, al
    mov ah, byte es:[edi]
    db 0x3a, 0xec ; cmp ch, ah, register-destination encoding.
    je short .scan_byte
.finish_byte_scan:
    add esi, 8
    db 0x32, 0xe5 ; xor ah, ch, register-destination encoding.
.find_bit:
    jmp short scan_four_planes_right.find_bit

scan_two_planes_right:
    mov cl, 5
    jmp short scan_four_planes_right.configure_compare

scan_four_planes_right:
    mov cl, 0xf
.configure_compare:
    push edx
    mov edx, 0x3ce
    db 0x8a, 0xe0 ; mov ah, al, register-destination encoding.
    mov al, 2
    out dx, ax
    mov ah, 0x1a
    mov al, 5
    out dx, ax
    db 0x8a, 0xe1 ; mov ah, cl, register-destination encoding.
    mov al, 7
    out dx, ax
    pop edx
    db 0x8a, 0xf5 ; mov dh, ch, register-destination encoding.
    shl dh, 1
    neg dh
    not dh
.align_start:
    dec ebx
    shl ch, 1
    jae short .align_start
    mov ah, byte es:[edi]
    db 0x32, 0xc0 ; xor al, al, register-destination encoding.
    db 0x0a, 0xd2 ; or dl, dl, register-destination encoding.
    je short .compare_head
    not ax
.compare_head:
    db 0x22, 0xe6 ; and ah, dh, register-destination encoding.
    jne short .find_bit
    db 0x8b, 0xce ; mov ecx, esi, register-destination encoding.
    db 0x2b, 0xcb ; sub ecx, ebx, register-destination encoding.
    dec ecx
    and cl, 0xf8
    db 0x03, 0xd9 ; add ebx, ecx, register-destination encoding.
    shr ecx, 1
    shr ecx, 1
    shr ecx, 1
    jle short .find_bit
    inc edi
    repe scasb
    shl ecx, 1
    shl ecx, 1
    shl ecx, 1
    db 0x2b, 0xd9 ; sub ebx, ecx, register-destination encoding.
    dec edi
    mov ah, byte es:[edi]
    db 0x0a, 0xd2 ; or dl, dl, register-destination encoding.
    je short .find_bit
    not ah
.find_bit:
    shl ah, 1
    jb short .done
    db 0x3b, 0xf3 ; cmp esi, ebx, register-destination encoding.
    jle short .done
    inc ebx
    jmp short .find_bit
.done:
    ret

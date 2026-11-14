; Byte-per-pixel graphics operations and video bank selection.
BITS 32
ORG 0x72764

plot_xor equ 0x71dc5
plot_or equ 0x71ddf
pattern_transparent equ 0x16c95
drawing_action equ 0x16c9f
bank_shift equ 0x289248
current_bank equ 0x289249

    db and_byte_pixel.fragment_end - and_byte_pixel
and_byte_pixel:
    and byte es:[edi], al
.fragment_end:
    ret

    db replace_byte_pixel.fragment_end - replace_byte_pixel
replace_byte_pixel:
    mov byte es:[edi], al
.fragment_end:
    ret

    db step_byte_up_320.fragment_end - step_byte_up_320
step_byte_up_320:
    sub edi, 0x140
.fragment_end:
    ret

    db step_byte_down_320.fragment_end - step_byte_down_320
step_byte_down_320:
    add edi, 0x140
.fragment_end:
    ret

    db step_byte_left.fragment_end - step_byte_left
step_byte_left:
    dec edi
.fragment_end:
    ret

    db step_byte_right.fragment_end - step_byte_right
step_byte_right:
    inc edi
.fragment_end:
    ret

read_byte_pixel:
    mov al, byte es:[edi]
    db 0x32, 0xe4 ; xor ah, ah, register-destination encoding.
    ret

byte_pixel_action_table:
    dd replace_byte_pixel - 0x10000
    dd plot_xor - 0x10000
    dd and_byte_pixel - 0x10000
    dd plot_or - 0x10000

draw_byte_span:
    movzx ebx, word ss:[drawing_action]
    db 0x0b, 0xdb ; or ebx, ebx, register-destination encoding.
    jne short .select_action
    rep stosb
    jmp short .done
.select_action:
    mov ebx, dword cs:[ebx*4 + byte_pixel_action_table - 0x10000]
.draw_next:
    call ebx
    inc edi
    loop .draw_next
.done:
    ret

draw_patterned_byte_span:
    db 0x8a, 0xd1 ; mov dl, cl, register-destination encoding.
    db 0x8a, 0xcf ; mov cl, bh, register-destination encoding.
    rol bl, cl
    db 0x8a, 0xca ; mov cl, dl, register-destination encoding.
    db 0x8a, 0xd3 ; mov dl, bl, register-destination encoding.
    movzx ebx, word ss:[drawing_action]
    mov ebx, dword cs:[ebx*4 + byte_pixel_action_table - 0x10000]
    db 0x66, 0x36, 0x83, 0x3d ; CMP word SS:[pattern_transparent], 0, original prefix order.
    dd pattern_transparent
    db 0
    je short .save_color
.transparent_next:
    rol dl, 1
    jae short .advance_transparent
    call ebx
.advance_transparent:
    inc edi
    loop .transparent_next
    jmp short .done
.save_color:
    db 0x8a, 0xf0 ; mov dh, al, register-destination encoding.
.opaque_next:
    rol dl, 1
    jae short .background
    db 0x8a, 0xc6 ; mov al, dh, register-destination encoding.
    jmp short .draw_opaque
.background:
    db 0x32, 0xc0 ; xor al, al, register-destination encoding.
.draw_opaque:
    call ebx
    inc edi
    loop .opaque_next
.done:
    ret

blit_byte_pixels:
    push ds
    mov ds, esi
    db 0x8b, 0xf0 ; mov esi, eax, register-destination encoding.
    db 0x66, 0x36, 0x83, 0x3d ; CMP word SS:[drawing_action], 0, original prefix order.
    dd drawing_action
    db 0
    jne short .apply_action
    rep movsb
    jmp short .done
.apply_action:
    push ebx
    movzx ebx, word ss:[drawing_action]
    mov ebx, dword cs:[ebx*4 + byte_pixel_action_table - 0x10000]
.next:
    lodsb
    call ebx
    inc edi
    loop .next
    pop ebx
.done:
    pop ds
    ret

copy_byte_pixels:
    push ds
    mov ds, esi
    db 0x8b, 0xf0 ; mov esi, eax, register-destination encoding.
    rep movsb
    pop ds
    ret

scan_byte_pixels_left:
    db 0x8b, 0xcb ; mov ecx, ebx, register-destination encoding.
    db 0x2b, 0xce ; sub ecx, esi, register-destination encoding.
    inc ecx
    inc ecx
    std
    db 0x0a, 0xd2 ; or dl, dl, register-destination encoding.
    je short .scan_different
.scan_matching:
    dec ecx
    je short .finish_matching
    scasb
    jne short .finish_matching
    jmp short .scan_matching
.finish_matching:
    jmp short .finish
.scan_different:
    dec ecx
    je short .finish
    scasb
    je short .finish
    jmp short .scan_different
.finish:
    cld
    db 0x03, 0xf1 ; add esi, ecx, register-destination encoding.
    db 0x8b, 0xde ; mov ebx, esi, register-destination encoding.
    ret

scan_byte_pixels_right:
    db 0x8b, 0xce ; mov ecx, esi, register-destination encoding.
    db 0x2b, 0xcb ; sub ecx, ebx, register-destination encoding.
    inc ecx
    inc ecx
    cld
    db 0x0a, 0xd2 ; or dl, dl, register-destination encoding.
    je short .scan_different
    repe scasb
    jmp short .finish
.scan_different:
    repne scasb
.finish:
    db 0x2b, 0xf1 ; sub esi, ecx, register-destination encoding.
    db 0x8b, 0xde ; mov ebx, esi, register-destination encoding.
    ret

select_vbe_bank:
    cmp al, byte ss:[current_bank]
    je short .done
    mov byte ss:[current_bank], al
    push ebx
    push ecx
    push edx
    mov cl, byte ss:[bank_shift]
    shl al, cl
    db 0x32, 0xe4 ; xor ah, ah, register-destination encoding.
    db 0x66, 0x8b, 0xd0 ; mov dx, ax, register-destination encoding.
    mov ax, 0x4f05
    db 0x66, 0x33, 0xdb ; xor bx, bx, register-destination encoding.
    int 0x10
    pop edx
    pop ecx
    pop ebx
.done:
    ret

select_sequencer_bank:
    cmp al, byte ss:[current_bank]
    je short .done
    mov byte ss:[current_bank], al
    db 0x8a, 0xe0 ; mov ah, al, register-destination encoding.
    push edx
    cmp byte ss:[bank_shift], 0x10
    jne short .extended_bank
    mov dx, 0x3c4
    mov al, 0xf6
    out dx, al
    inc dx
    in al, dx
    and al, 0xf0
    db 0x0a, 0xc4 ; or al, ah, register-destination encoding.
    shl ah, 1
    shl ah, 1
    db 0x0a, 0xc4 ; or al, ah, register-destination encoding.
    out dx, al
    jmp short .restore
.extended_bank:
    mov dx, 0x3cc
    in al, dx
    and al, 0xdf
    and ah, 2
    shl ah, 1
    shl ah, 1
    shl ah, 1
    shl ah, 1
    db 0x0a, 0xc4 ; or al, ah, register-destination encoding.
    mov dx, 0x3c2
    out dx, al
    mov dx, 0x3c4
    mov al, 0xf9
    mov ah, byte ss:[current_bank]
    and ah, 1
    out dx, ax
    mov al, 0xf6
    out dx, al
    inc dx
    in al, dx
    and al, 0xf0
    mov ah, byte ss:[current_bank]
    and ah, 0xc
    db 0x0a, 0xc4 ; or al, ah, register-destination encoding.
    shr ah, 1
    shr ah, 1
    db 0x0a, 0xc4 ; or al, ah, register-destination encoding.
    out dx, al
.restore:
    pop edx
.done:
    ret

select_graphics_controller_bank:
    cmp al, byte ss:[current_bank]
    je short .done
    mov byte ss:[current_bank], al
    db 0x8a, 0xe0 ; mov ah, al, register-destination encoding.
    shl ah, 1
    shl ah, 1
    shl ah, 1
    shl ah, 1
    mov al, 9
    push edx
    mov dx, 0x3ce
    out dx, ax
    pop edx
.done:
    ret

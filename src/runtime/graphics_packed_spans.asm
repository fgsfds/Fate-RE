; Write and scan packed one-bit and two-bit graphics spans.
BITS 32
ORG 0x71ebb

pixel_action_table equ 0x71eab - 0x10000
pattern_transparent equ 0x16c95
drawing_action equ 0x16c9f

draw_mono_span:
    push ebp
    push esi
    db 0x0a, 0xc0 ; or al, al, register-destination encoding.
    jne short .set_color
    db 0x32, 0xdb ; xor bl, bl, register-destination encoding.
    jmp short .set_write_mask
.set_color:
    mov bl, 0xff
.set_write_mask:
    mov bh, 0xff
    jmp short draw_patterned_mono_span.render

draw_patterned_mono_span:
    push ebp
    push esi
    db 0x66, 0x36, 0x83, 0x3d ; CMP word SS:[pattern_transparent], 0, original prefix order.
    dd pattern_transparent
    db 0
    jne short .use_pattern_mask
    mov bh, 0xff
    jmp short .filter_color
.use_pattern_mask:
    db 0x8a, 0xfb ; mov bh, bl, register-destination encoding.
.filter_color:
    db 0x0a, 0xc0 ; or al, al, register-destination encoding.
    jne short .render
    db 0x8a, 0xd8 ; mov bl, al, register-destination encoding.
.render:
    movzx esi, word ss:[drawing_action]
    mov esi, dword cs:[esi*4 + pixel_action_table]
    db 0x8b, 0xe9 ; mov ebp, ecx, register-destination encoding.
    db 0x0a, 0xf6 ; or dh, dh, register-destination encoding.
    je short .whole_bytes
    db 0x8a, 0xce ; mov cl, dh, register-destination encoding.
    mov ah, 0x80
    shr ah, cl
    db 0x32, 0xed ; xor ch, ch, register-destination encoding.
.accumulate_first_mask:
    db 0x0a, 0xec ; or ch, ah, register-destination encoding.
    dec ebp
    je short .draw_first
    shr ah, 1
    jae short .accumulate_first_mask
.draw_first:
    db 0x8a, 0xc3 ; mov al, bl, register-destination encoding.
    db 0x22, 0xc5 ; and al, ch, register-destination encoding.
    db 0x22, 0xef ; and ch, bh, register-destination encoding.
    not ch
    call esi
    inc edi
.whole_bytes:
    db 0x8b, 0xd5 ; mov edx, ebp, register-destination encoding.
    mov cl, 3
    shr edx, cl
    je short .trailing_bits
    db 0x8a, 0xc3 ; mov al, bl, register-destination encoding.
    db 0x8a, 0xef ; mov ch, bh, register-destination encoding.
    not ch
    db 0x66, 0x36, 0x83, 0x3d ; CMP word SS:[drawing_action], 0, original prefix order.
    dd drawing_action
    db 0
    jne short .draw_next_byte
    db 0x0a, 0xed ; or ch, ch, register-destination encoding.
    jne short .draw_next_byte
    db 0x8b, 0xca ; mov ecx, edx, register-destination encoding.
    cld
    rep stosb
    jmp short .trailing_bits
.draw_next_byte:
    call esi
    inc edi
    dec edx
    je short .trailing_bits
    jmp short .draw_next_byte
.trailing_bits:
    and ebp, 7
    je short .done
    mov ecx, 8
    db 0x2b, 0xcd ; sub ecx, ebp, register-destination encoding.
    mov ch, 0xff
    shl ch, cl
    db 0x8a, 0xc3 ; mov al, bl, register-destination encoding.
    db 0x22, 0xc5 ; and al, ch, register-destination encoding.
    db 0x22, 0xef ; and ch, bh, register-destination encoding.
    not ch
    call esi
.done:
    pop esi
    pop ebp
    ret

two_bit_color_expansion:
    db 0x00, 0x55, 0xaa, 0xff

draw_two_bit_span:
    push ebp
    push esi
    db 0x8b, 0xe9 ; mov ebp, ecx, register-destination encoding.
    db 0x8a, 0xe6 ; mov ah, dh, register-destination encoding.
    mov ebx, two_bit_color_expansion - 0x10000
    cs xlatb
    db 0x8a, 0xd0 ; mov dl, al, register-destination encoding.
    db 0x8a, 0xf0 ; mov dh, al, register-destination encoding.
    mov ebx, strict dword 0xffff
    jmp near draw_patterned_two_bit_span.render

draw_patterned_two_bit_span:
    push ebp
    push esi
    db 0x8b, 0xe9 ; mov ebp, ecx, register-destination encoding.
    db 0x8a, 0xe6 ; mov ah, dh, register-destination encoding.
    mov ecx, 8
    db 0x33, 0xf6 ; xor esi, esi, register-destination encoding.
.expand_pattern:
    shr bl, 1
    jae short .rotate_mask
    or esi, 3
.rotate_mask:
    ror si, 1
    ror si, 1
    loop .expand_pattern
    db 0x8a, 0xcf ; mov cl, bh, register-destination encoding.
    mov ebx, two_bit_color_expansion - 0x10000
    cs xlatb
    db 0x8a, 0xd0 ; mov dl, al, register-destination encoding.
    db 0x8a, 0xf0 ; mov dh, al, register-destination encoding.
    db 0x23, 0xd6 ; and edx, esi, register-destination encoding.
    db 0x66, 0x36, 0x83, 0x3d ; CMP word SS:[pattern_transparent], 0, original prefix order.
    dd pattern_transparent
    db 0
    jne short .use_pattern_mask
    mov ebx, strict dword 0xffff
    jmp short .align_pattern
.use_pattern_mask:
    db 0x8b, 0xde ; mov ebx, esi, register-destination encoding.
.align_pattern:
    cmp cl, 3
    jle short .render
    xchg dh, dl
    xchg bh, bl
.render:
    movzx esi, word ss:[drawing_action]
    mov esi, dword cs:[esi*4 + pixel_action_table]
    db 0x0a, 0xe4 ; or ah, ah, register-destination encoding.
    je short .whole_bytes
    db 0x8a, 0xcc ; mov cl, ah, register-destination encoding.
    mov ah, 0xc0
    shr ah, cl
    db 0x32, 0xed ; xor ch, ch, register-destination encoding.
.accumulate_first_mask:
    db 0x0a, 0xec ; or ch, ah, register-destination encoding.
    dec ebp
    je short .draw_first
    shr ah, 1
    shr ah, 1
    jae short .accumulate_first_mask
.draw_first:
    db 0x8a, 0xc6 ; mov al, dh, register-destination encoding.
    db 0x22, 0xc5 ; and al, ch, register-destination encoding.
    db 0x22, 0xef ; and ch, bh, register-destination encoding.
    not ch
    call esi
    inc edi
    xchg dh, dl
    xchg bh, bl
.whole_bytes:
    push ebp
    shr ebp, 1
    shr ebp, 1
    je short .trailing_pixels
    db 0x8a, 0xc6 ; mov al, dh, register-destination encoding.
    db 0x8a, 0xef ; mov ch, bh, register-destination encoding.
    not ch
    db 0x66, 0x36, 0x83, 0x3d ; CMP word SS:[drawing_action], 0, original prefix order.
    dd drawing_action
    db 0
    jne short .draw_next_byte
    cmp ebx, strict dword 0xffff
    jne short .draw_next_byte
    db 0x3a, 0xd6 ; cmp dl, dh, register-destination encoding.
    jne short .draw_next_byte
    db 0x8b, 0xcd ; mov ecx, ebp, register-destination encoding.
    cld
    rep stosb
    jmp short .trailing_pixels
.draw_next_byte:
    call esi
    inc edi
    xchg dh, dl
    xchg bh, bl
    dec ebp
    je short .trailing_pixels
    db 0x8a, 0xc6 ; mov al, dh, register-destination encoding.
    db 0x8a, 0xef ; mov ch, bh, register-destination encoding.
    not ch
    jmp short .draw_next_byte
.trailing_pixels:
    pop ebp
    and ebp, 3
    je short .done
    mov ecx, 8
    db 0x2b, 0xcd ; sub ecx, ebp, register-destination encoding.
    db 0x2b, 0xcd ; sub ecx, ebp, register-destination encoding.
    mov ch, 0xff
    shl ch, cl
    db 0x8a, 0xc6 ; mov al, dh, register-destination encoding.
    db 0x22, 0xc5 ; and al, ch, register-destination encoding.
    db 0x22, 0xef ; and ch, bh, register-destination encoding.
    not ch
    call esi
.done:
    pop esi
    pop ebp
    ret

scan_packed_pixels_left:
    db 0x8a, 0xe2 ; mov ah, dl, register-destination encoding.
    inc ebx
    not ch
    mov dl, byte es:[edi]
.compare_pixel:
    db 0x8a, 0xf2 ; mov dh, dl, register-destination encoding.
    db 0x22, 0xf5 ; and dh, ch, register-destination encoding.
    db 0x3a, 0xf0 ; cmp dh, al, register-destination encoding.
    jne short .different
    db 0x0a, 0xe4 ; or ah, ah, register-destination encoding.
    je short .done
    jmp short .step
.different:
    db 0x0a, 0xe4 ; or ah, ah, register-destination encoding.
    jne short .done
.step:
    dec ebx
    db 0x3b, 0xf3 ; cmp esi, ebx, register-destination encoding.
    jge short .done
    rol al, cl
    rol ch, cl
    jae short .compare_next
    dec edi
    mov dl, byte es:[edi]
.compare_next:
    jmp short .compare_pixel
.done:
    ret

scan_mono_pixels_right:
    not ch
    db 0x8a, 0xf5 ; mov dh, ch, register-destination encoding.
    shl dh, 1
    neg dh
    not dh
.align_start:
    dec ebx
    shl ch, 1
    jae short .align_start
    db 0x0a, 0xc0 ; or al, al, register-destination encoding.
    je short .prepare_color
    mov al, 0xff
.prepare_color:
    not al
    mov ah, byte es:[edi]
    db 0x32, 0xe0 ; xor ah, al, register-destination encoding.
    db 0x0a, 0xd2 ; or dl, dl, register-destination encoding.
    je short .test_first
    not ax
.test_first:
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
    db 0x32, 0xe0 ; xor ah, al, register-destination encoding.
.find_bit:
    shl ah, 1
    jb short .done
    db 0x3b, 0xf3 ; cmp esi, ebx, register-destination encoding.
    jle short .done
    inc ebx
    jmp short .find_bit
.done:
    ret

scan_two_bit_pixels_right:
    db 0x8a, 0xe0 ; mov ah, al, register-destination encoding.
    rol ah, cl
    db 0x0a, 0xc4 ; or al, ah, register-destination encoding.
    db 0x8a, 0xe0 ; mov ah, al, register-destination encoding.
    rol ah, cl
    rol ah, cl
    db 0x0a, 0xc4 ; or al, ah, register-destination encoding.
    db 0x8b, 0xcb ; mov ecx, ebx, register-destination encoding.
    and ecx, 3
    db 0x2b, 0xd9 ; sub ebx, ecx, register-destination encoding.
    dec ebx
    shl cl, 1
    mov dh, 0xff
    shr dh, cl
    db 0x0a, 0xd2 ; or dl, dl, register-destination encoding.
    je short .compare_byte
    mov ch, 0xaa
.compare_byte:
    mov ah, byte es:[edi]
    db 0x32, 0xe0 ; xor ah, al, register-destination encoding.
    not ah
    db 0x8a, 0xcc ; mov cl, ah, register-destination encoding.
    and cl, 0xaa
    and ah, 0x55
    shl ah, 1
    db 0x22, 0xe1 ; and ah, cl, register-destination encoding.
    db 0x32, 0xe5 ; xor ah, ch, register-destination encoding.
    db 0x22, 0xe6 ; and ah, dh, register-destination encoding.
    jne short .find_pixel
    db 0x3b, 0xde ; cmp ebx, esi, register-destination encoding.
    jl short .next_byte
    db 0x8b, 0xde ; mov ebx, esi, register-destination encoding.
    ret
.next_byte:
    inc edi
    add ebx, 4
    mov dh, 0xff
    jmp short .compare_byte
.find_pixel:
    add esi, 4
.next_pixel:
    shl ah, 1
    jb short .done
    shl ah, 1
    db 0x3b, 0xf3 ; cmp esi, ebx, register-destination encoding.
    jle short .done
    inc ebx
    jmp short .next_pixel
.done:
    ret

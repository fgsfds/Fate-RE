; Capture planar bitmap data and draw solid or patterned VGA spans.
BITS 32
ORG 0x72422

two_plane_color_map equ 0x6221b
pattern_transparent equ 0x16c95
drawing_action equ 0x16c9f

capture_interleaved_planes:
    push ebp
    push ds
    call prepare_planar_capture
    mov ah, 2
.select_pair:
    push ebp
    push esi
    db 0x32, 0xc0 ; xor al, al, register-destination encoding.
    ror esi, 1
    db 0x12, 0xc4 ; adc al, ah, register-destination encoding.
    rol esi, 1
    out dx, al
    mov bh, byte [esi]
    inc esi
.next_byte:
    db 0x32, 0xc0 ; xor al, al, register-destination encoding.
    ror esi, 1
    db 0x12, 0xc4 ; adc al, ah, register-destination encoding.
    out dx, al
    rol esi, 1
    mov bl, byte [esi]
    inc esi
    db 0x8a, 0xeb ; mov ch, bl, register-destination encoding.
    shl ebx, cl
    mov byte es:[edi], bh
    db 0x8a, 0xfd ; mov bh, ch, register-destination encoding.
    inc edi
    sub ebp, 8
    jg short .next_byte
    pop esi
    pop ebp
    sub ah, 2
    jge short .select_pair
    pop ds
    pop ebp
    ret

capture_even_planes:
    push ebp
    push ds
    call prepare_planar_capture
    mov al, 2
    call capture_plane
    mov al, 0
    call capture_plane
    pop ds
    pop ebp
    ret

capture_four_planes:
    push ebp
    push ds
    call prepare_planar_capture
    mov bl, 3
.next_plane:
    db 0x8a, 0xc3 ; mov al, bl, register-destination encoding.
    call capture_plane
    dec bl
    jge short .next_plane
    pop ds
    pop ebp
    ret

prepare_planar_capture:
    mov ds, esi
    db 0x8b, 0xf0 ; mov esi, eax, register-destination encoding.
    db 0x8b, 0xe9 ; mov ebp, ecx, register-destination encoding.
    db 0x8a, 0xca ; mov cl, dl, register-destination encoding.
    mov edx, 0x3ce
    mov al, 4
    out dx, al
    inc edx
    ret

capture_plane:
    push ebp
    push esi
    out dx, al
    db 0x0a, 0xc9 ; or cl, cl, register-destination encoding.
    jne short .load_first
    db 0x8b, 0xcd ; mov ecx, ebp, register-destination encoding.
    add ecx, 7
    shr ecx, 1
    shr ecx, 1
    shr ecx, 1
    rep movsb
    jmp short .done
.load_first:
    mov ah, byte [esi]
    inc esi
.shift_next:
    mov al, byte [esi]
    inc esi
    db 0x8a, 0xf8 ; mov bh, al, register-destination encoding.
    shl eax, cl
    mov byte es:[edi], ah
    inc edi
    db 0x8a, 0xe7 ; mov ah, bh, register-destination encoding.
    sub ebp, 8
    jg short .shift_next
.done:
    pop esi
    pop ebp
    ret

draw_planar_span:
    mov ebx, two_plane_color_map
    cs xlatb
    db 0x8a, 0xfe ; mov bh, dh, register-destination encoding.
    mov edx, 0x3ce
    db 0x0a, 0xff ; or bh, bh, register-destination encoding.
    je short .whole_bytes
    xchg bh, cl
    mov bl, 0x80
    shr bl, cl
    db 0x8a, 0xcf ; mov cl, bh, register-destination encoding.
    db 0x32, 0xe4 ; xor ah, ah, register-destination encoding.
.accumulate_mask:
    db 0x0a, 0xe3 ; or ah, bl, register-destination encoding.
    shr bl, 1
    loopne .accumulate_mask
    db 0x8a, 0xf8 ; mov bh, al, register-destination encoding.
    mov al, 8
    out dx, ax
    db 0x8a, 0xc7 ; mov al, bh, register-destination encoding.
    xchg byte es:[edi], bh
    inc edi
.whole_bytes:
    db 0x8a, 0xf8 ; mov bh, al, register-destination encoding.
    db 0x8a, 0xd9 ; mov bl, cl, register-destination encoding.
    shr ecx, 1
    shr ecx, 1
    shr ecx, 1
    je short .tail
    mov al, 8
    mov ah, 0xff
    out dx, ax
    db 0x66, 0x36, 0x83, 0x3d ; CMP word SS:[drawing_action], 0, original prefix order.
    dd drawing_action
    db 0
    jne short .exchange_byte
    db 0x8a, 0xc7 ; mov al, bh, register-destination encoding.
    cld
    rep stosb
    jmp short .tail
.exchange_byte:
    db 0x8a, 0xc7 ; mov al, bh, register-destination encoding.
    xchg byte es:[edi], al
    inc edi
    loop .exchange_byte
.tail:
    and bl, 7
    je short .done
    mov al, 8
    mov ah, 0xff
    db 0x8a, 0xcb ; mov cl, bl, register-destination encoding.
    shr ah, cl
    not ah
    out dx, ax
    xchg byte es:[edi], bh
.done:
    db 0x8a, 0xf3 ; mov dh, bl, register-destination encoding.
    ret

draw_patterned_planar_span:
    push ebx
    mov ebx, two_plane_color_map
    cs xlatb
    pop ebx
    push ebp
    db 0x8a, 0xe6 ; mov ah, dh, register-destination encoding.
    db 0x8a, 0xf8 ; mov bh, al, register-destination encoding.
    db 0x8b, 0xe9 ; mov ebp, ecx, register-destination encoding.
    mov edx, 0x3ce
    db 0x0a, 0xe4 ; or ah, ah, register-destination encoding.
    je short .whole_bytes
    db 0x8a, 0xcc ; mov cl, ah, register-destination encoding.
    mov al, 0x80
    shr al, cl
    db 0x32, 0xe4 ; xor ah, ah, register-destination encoding.
.accumulate_mask:
    db 0x0a, 0xe0 ; or ah, al, register-destination encoding.
    dec ebp
    je short .write_head
    shr al, 1
    jae short .accumulate_mask
.write_head:
    db 0x8a, 0xec ; mov ch, ah, register-destination encoding.
    mov al, 8
    db 0x22, 0xe3 ; and ah, bl, register-destination encoding.
    out dx, ax
    db 0x8a, 0xc7 ; mov al, bh, register-destination encoding.
    xchg byte es:[edi], al
    db 0x66, 0x36, 0x83, 0x3d ; CMP word SS:[pattern_transparent], 0, original prefix order.
    dd pattern_transparent
    db 0
    jne short .advance_head
    mov al, 8
    db 0x8a, 0xe5 ; mov ah, ch, register-destination encoding.
    not ah
    db 0x0a, 0xe3 ; or ah, bl, register-destination encoding.
    not ah
    out dx, ax
    db 0x32, 0xc0 ; xor al, al, register-destination encoding.
    xchg byte es:[edi], al
.advance_head:
    inc edi
.whole_bytes:
    db 0x8a, 0xe3 ; mov ah, bl, register-destination encoding.
    db 0x8b, 0xcd ; mov ecx, ebp, register-destination encoding.
    shr ecx, 1
    shr ecx, 1
    shr ecx, 1
    je short .tail
    db 0x66, 0x36, 0x83, 0x3d ; CMP word SS:[pattern_transparent], 0, original prefix order.
    dd pattern_transparent
    db 0
    jne short .set_pattern_mask
    push edi
    push ecx
    push eax
    not ah
    mov al, 8
    out dx, ax
.clear_byte:
    db 0x32, 0xc0 ; xor al, al, register-destination encoding.
    xchg byte es:[edi], al
    inc edi
    loop .clear_byte
    pop eax
    pop ecx
    pop edi
.set_pattern_mask:
    mov al, 8
    out dx, ax
.write_byte:
    db 0x8a, 0xc7 ; mov al, bh, register-destination encoding.
    xchg byte es:[edi], al
    inc edi
    loop .write_byte
.tail:
    and ebp, 7
    je short .done
    mov al, 8
    db 0x8b, 0xcd ; mov ecx, ebp, register-destination encoding.
    mov ch, 0xff
    shr ch, cl
    not ch
    db 0x22, 0xe5 ; and ah, ch, register-destination encoding.
    out dx, ax
    xchg byte es:[edi], bh
    db 0x66, 0x36, 0x83, 0x3d ; CMP word SS:[pattern_transparent], 0, original prefix order.
    dd pattern_transparent
    db 0
    jne short .done
    not ah
    db 0x22, 0xe5 ; and ah, ch, register-destination encoding.
    out dx, ax
    db 0x32, 0xc0 ; xor al, al, register-destination encoding.
    xchg byte es:[edi], al
.done:
    pop ebp
    ret

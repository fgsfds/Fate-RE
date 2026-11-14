; Upload planar bitmap pixels and restore the VGA sequencer plane mask.
BITS 32
ORG 0x7229f

drawing_action equ 0x16c9f

write_interleaved_planes:
    push ebp
    push ds
    call prepare_planar_write
    mov ah, 4
.select_first:
    db 0x8a, 0xc4 ; mov al, ah, register-destination encoding.
    test edi, 1
    je short .save_plane_state
    shl al, 1
.save_plane_state:
    push ecx
    push ebp
    push edi
    push esi
    call write_plane_head
    db 0x8a, 0xee ; mov ch, dh, register-destination encoding.
.select_next:
    db 0x8a, 0xc4 ; mov al, ah, register-destination encoding.
    test edi, 1
    je short .write_byte
    shl al, 1
.write_byte:
    mov edx, 0x3c5
    out dx, al
    db 0x8a, 0xf5 ; mov dh, ch, register-destination encoding.
    mov dl, byte [esi]
    inc esi
    db 0x8a, 0xea ; mov ch, dl, register-destination encoding.
    shl edx, cl
    sub ebp, 8
    cmp ebp, 8
    jl short .finish_plane
    xchg byte es:[edi], dh
    inc edi
    jmp short .select_next
.finish_plane:
    call write_plane_tail
    pop esi
    db 0x03, 0xf3 ; add esi, ebx, register-destination encoding.
    pop edi
    pop ebp
    pop ecx
    shr ah, 1
    shr ah, 1
    jne short .select_first
.restore_plane_mask:
    mov edx, 0x3c4
    mov ah, 0xf
    mov al, 2
    out dx, ax
    pop ds
    pop ebp
    ret

write_even_planes:
    push ebp
    push ds
    call prepare_planar_write
    mov al, 4
    call write_plane
    mov al, 1
    call write_plane
    jmp short write_interleaved_planes.restore_plane_mask

write_four_planes:
    push ebp
    push ds
    call prepare_planar_write
    mov ah, 8
.next:
    db 0x8a, 0xc4 ; mov al, ah, register-destination encoding.
    call write_plane
    shr ah, 1
    jae short .next
    jmp short write_interleaved_planes.restore_plane_mask

prepare_planar_write:
    mov ds, esi
    db 0x8b, 0xf0 ; mov esi, eax, register-destination encoding.
    db 0x8b, 0xe9 ; mov ebp, ecx, register-destination encoding.
    db 0x8a, 0xce ; mov cl, dh, register-destination encoding.
    db 0x8a, 0xea ; mov ch, dl, register-destination encoding.
    mov edx, 0x3ce
    mov al, 5
    mov ah, 0
    out dx, ax
    mov al, 8
    out dx, al
    mov edx, 0x3c4
    mov al, 2
    out dx, al
    ret

write_plane:
    push ecx
    push ebp
    push edi
    push esi
    call write_plane_head
    cmp cl, 0
    jne short .shift_byte
    db 0x8b, 0xcd ; mov ecx, ebp, register-destination encoding.
    and ebp, 7
    shr ecx, 1
    shr ecx, 1
    shr ecx, 1
    dec ecx
    jle short .finish
    dec esi
    db 0x66, 0x36, 0x83, 0x3d ; CMP word SS:[drawing_action], 0, original prefix order.
    dd drawing_action
    db 0
    jne short .exchange_byte
    rep movsb
    jmp short .load_tail
.exchange_byte:
    mov al, byte [esi]
    inc esi
    xchg byte es:[edi], al
    inc edi
    loop .exchange_byte
.load_tail:
    db 0x0b, 0xed ; or ebp, ebp, register-destination encoding.
    je short .finish_aligned
    mov dh, byte [esi]
.finish_aligned:
    jmp short .finish
.shift_byte:
    mov al, byte [esi]
    inc esi
    db 0x8a, 0xd0 ; mov dl, al, register-destination encoding.
    shl edx, cl
    sub ebp, 8
    cmp ebp, 8
    jl short .finish
    xchg byte es:[edi], dh
    inc edi
    db 0x8a, 0xf0 ; mov dh, al, register-destination encoding.
    jmp short .shift_byte
.finish:
    call write_plane_tail
    pop esi
    db 0x03, 0xf3 ; add esi, ebx, register-destination encoding.
    pop edi
    pop ebp
    pop ecx
    ret

write_plane_head:
    mov edx, 0x3c5
    out dx, al
    mov al, 0xff
    shr al, cl
    db 0x8a, 0xd1 ; mov dl, cl, register-destination encoding.
    db 0x32, 0xf6 ; xor dh, dh, register-destination encoding.
    db 0x03, 0xea ; add ebp, edx, register-destination encoding.
    cmp ebp, 8
    jge short .set_mask
    xchg ecx, ebp
    mov ch, 0xff
    shr ch, cl
    not ch
    db 0x22, 0xc5 ; and al, ch, register-destination encoding.
    db 0x8b, 0xcd ; mov ecx, ebp, register-destination encoding.
    mov ebp, 8
.set_mask:
    mov edx, 0x3cf
    out dx, al
    mov dh, byte [esi]
    inc esi
    mov dl, byte [esi]
    push edx
    xchg cl, ch
    shl edx, cl
    xchg cl, ch
    shr edx, cl
    xchg byte es:[edi], dh
    inc edi
    mov edx, 0x3cf
    mov al, 0xff
    out dx, al
    pop edx
    xchg cl, ch
    db 0x2a, 0xcd ; sub cl, ch, register-destination encoding.
    jge short .advance_source
    add cl, 8
    jmp short .done
.advance_source:
    inc esi
    db 0x8a, 0xf2 ; mov dh, dl, register-destination encoding.
.done:
    ret

write_plane_tail:
    db 0x0b, 0xed ; or ebp, ebp, register-destination encoding.
    je short .done
    db 0x8b, 0xcd ; mov ecx, ebp, register-destination encoding.
    mov al, 0xff
    shr al, cl
    not al
    db 0x8a, 0xee ; mov ch, dh, register-destination encoding.
    mov dx, 0x3cf
    out dx, al
    xchg byte es:[edi], ch
.done:
    ret

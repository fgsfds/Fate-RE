; Transfer packed bitmap bits with selectable masked and whole-byte operations.
BITS 32
ORG 0x73b48

masked_byte_op equ 0x199ac
byte_run_op equ 0x199b0

leading_masks:
    db 0xff, 0x7f, 0x3f, 0x1f, 0x0f, 0x07, 0x03
trailing_masks:
    db 0x01, 0x80, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc, 0xfe
    db 0xff, 0x01, 0x03, 0x07, 0x0f, 0x1f, 0x3f, 0x7f, 0xff

replace_masked_byte:
    db 0x22, 0xc5 ; and al, ch, register-destination encoding.
    mov ah, byte es:[edi]
    db 0xa, 0xe5 ; or ah, ch, register-destination encoding.
    db 0x32, 0xe5 ; xor ah, ch, register-destination encoding.
    db 0xa, 0xc4 ; or al, ah, register-destination encoding.
    mov byte es:[edi], al
    ret

replace_byte_run:
    cmp cl, 8
    jne short .unaligned
    xchg ecx, ebx
    rep movsb
    xchg ecx, ebx
    jmp short .done
.unaligned:
    lodsw
    dec esi
    xchg al, ah
    shr ax, cl
    stosb
    dec ebx
    jne short .unaligned
.done:
    ret

and_masked_byte:
    db 0x22, 0xc5 ; and al, ch, register-destination encoding.
    db 0x8a, 0xe5 ; mov ah, ch, register-destination encoding.
    not ah
    db 0xa, 0xc4 ; or al, ah, register-destination encoding.
    and byte es:[edi], al
    ret

and_byte_run:
    lodsw
    dec esi
    xchg al, ah
    shr ax, cl
    and byte es:[edi], al
    inc edi
    dec ebx
    jne short and_byte_run
    ret

or_masked_byte:
    db 0x22, 0xc5 ; and al, ch, register-destination encoding.
    or byte es:[edi], al
    ret

or_byte_run:
    lodsw
    dec esi
    xchg al, ah
    shr ax, cl
    or byte es:[edi], al
    inc edi
    dec ebx
    jne short or_byte_run
    ret

xor_masked_byte:
    db 0x22, 0xc5 ; and al, ch, register-destination encoding.
    xor byte es:[edi], al
    ret

xor_byte_run:
    lodsw
    dec esi
    xchg al, ah
    shr ax, cl
    xor byte es:[edi], al
    inc edi
    dec ebx
    jne short xor_byte_run
    ret

select_bitmap_replace:
    mov dword ss:[masked_byte_op], replace_masked_byte - 0x10000
    mov dword ss:[byte_run_op], replace_byte_run - 0x10000
    ret

select_bitmap_and:
    mov dword ss:[masked_byte_op], and_masked_byte - 0x10000
    mov dword ss:[byte_run_op], and_byte_run - 0x10000
    ret

select_bitmap_or:
    mov dword ss:[masked_byte_op], or_masked_byte - 0x10000
    mov dword ss:[byte_run_op], or_byte_run - 0x10000
    ret

select_bitmap_xor:
    mov dword ss:[masked_byte_op], xor_masked_byte - 0x10000
    mov dword ss:[byte_run_op], xor_byte_run - 0x10000
    ret

blit_bitmap_bits:
    db 0x33, 0xdb ; xor ebx, ebx, register-destination encoding.
    db 0x8a, 0xde ; mov bl, dh, register-destination encoding.
    mov bh, byte cs:[ebx + leading_masks - 0x10000]
    db 0x2a, 0xda ; sub bl, dl, register-destination encoding.
    add bl, 8
    xchg ebx, ecx
    test dh, dh
    je short .whole_bytes
    mov ax, word [esi]
    xchg al, ah
    shr ax, cl
    db 0x2, 0xde ; add bl, dh, register-destination encoding.
    adc bh, 0
    sub ebx, 8
    jae short .advance_first
    add ebx, 8
    db 0x2, 0xd3 ; add dl, bl, register-destination encoding.
    db 0x2a, 0xd6 ; sub dl, dh, register-destination encoding.
    cmp dl, 8
    jb short .merge_short_span
    inc esi
    sub dl, 8
.merge_short_span:
    db 0x8a, 0xf3 ; mov dh, bl, register-destination encoding.
    and ch, byte cs:[ebx + trailing_masks - 0x10000]
    jmp dword ss:[masked_byte_op]
.advance_first:
    add dl, 8
    db 0x2a, 0xd6 ; sub dl, dh, register-destination encoding.
    cmp dl, 8
    jb short .merge_first
    inc esi
    sub dl, 8
.merge_first:
    call dword ss:[masked_byte_op]
    inc edi
.whole_bytes:
    mov cl, 8
    db 0x2a, 0xca ; sub cl, dl, register-destination encoding.
    db 0x8a, 0xf3 ; mov dh, bl, register-destination encoding.
    shr ebx, 1
    shr ebx, 1
    shr ebx, 1
    je short .tail
    call dword ss:[byte_run_op]
.tail:
    and dh, 7
    je short .done
    db 0x8a, 0xde ; mov bl, dh, register-destination encoding.
    mov ch, byte cs:[ebx + trailing_masks - 0x10000]
    mov ax, word [esi]
    xchg al, ah
    shr ax, cl
    call dword ss:[masked_byte_op]
    or dl, 0xf8
    db 0x2, 0xd6 ; add dl, dh, register-destination encoding.
    adc esi, 0
    and dl, 7
    inc edi
.done:
    ret

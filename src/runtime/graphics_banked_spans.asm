; Draw, copy, and scan byte pixels across 64 KiB bank boundaries.
BITS 32
ORG 0x72b82

draw_byte_span equ 0x7279a
draw_patterned_byte_span equ 0x727b8
blit_byte_pixels equ 0x727fa
copy_byte_pixels equ 0x72828
current_bank equ 0x289249
select_bank equ 0x2891e8

draw_banked_span:
    movzx ebx, di
    db 0x66, 0x03, 0xd9 ; add bx, cx, register-destination encoding.
    jae short .draw
    je short .draw
    push ebx
    movzx ecx, di
    neg cx
    push edi
    call draw_byte_span
    pop edi
    db 0x66, 0x33, 0xff ; xor di, di, register-destination encoding.
    pop ecx
    push eax
    mov al, byte ss:[current_bank]
    inc al
    call dword [select_bank]
    pop eax
.draw:
    jmp near draw_byte_span

draw_patterned_banked_span:
    push esi
    movzx esi, di
    db 0x66, 0x03, 0xf1 ; add si, cx, register-destination encoding.
    jae short .draw
    je short .draw
    push esi
    movzx ecx, di
    neg cx
    push edi
    call draw_patterned_byte_span
    pop edi
    db 0x66, 0x33, 0xff ; xor di, di, register-destination encoding.
    db 0x8a, 0xda ; mov bl, dl, register-destination encoding.
    db 0x32, 0xff ; xor bh, bh, register-destination encoding.
    pop ecx
    push eax
    mov al, byte ss:[current_bank]
    inc al
    call dword [select_bank]
    pop eax
.draw:
    call draw_patterned_byte_span
    pop esi
    ret

blit_banked_pixels:
    push ebx
    movzx ebx, di
    db 0x66, 0x03, 0xd9 ; add bx, cx, register-destination encoding.
    jae short .blit
    je short .blit
    push ebx
    movzx ecx, di
    neg cx
    push esi
    push edi
    call blit_byte_pixels
    pop edi
    db 0x66, 0x33, 0xff ; xor di, di, register-destination encoding.
    db 0x8b, 0xc6 ; mov eax, esi, register-destination encoding.
    pop esi
    pop ecx
    push eax
    mov al, byte ss:[current_bank]
    inc al
    call dword [select_bank]
    pop eax
.blit:
    call blit_byte_pixels
    pop ebx
    ret

capture_banked_pixels:
    push ebx
    movzx ebx, ax
    db 0x66, 0x03, 0xd9 ; add bx, cx, register-destination encoding.
    jae short .capture
    je short .capture
    push ebx
    movzx ecx, ax
    neg cx
    push esi
    push eax
    call copy_byte_pixels
    pop eax
    db 0x66, 0x33, 0xc0 ; xor ax, ax, register-destination encoding.
    pop esi
    pop ecx
    push eax
    mov al, byte ss:[current_bank]
    inc al
    call dword [select_bank]
    pop eax
.capture:
    call copy_byte_pixels
    pop ebx
    ret

scan_banked_pixels_left:
    inc ebx
.compare:
    cmp al, byte es:[edi]
    jne short .different
    db 0x0a, 0xd2 ; or dl, dl, register-destination encoding.
    je short .done
    jmp short .step
.different:
    db 0x0a, 0xd2 ; or dl, dl, register-destination encoding.
    jne short .done
.step:
    dec ebx
    db 0x3b, 0xde ; cmp ebx, esi, register-destination encoding.
    jle short .done
    sub di, 1
    jae short .next
    push eax
    mov al, byte ss:[current_bank]
    dec al
    call dword [select_bank]
    pop eax
.next:
    jmp short .compare
.done:
    ret

scan_banked_pixels_right:
    dec ebx
.compare:
    cmp al, byte es:[edi]
    jne short .different
    db 0x0a, 0xd2 ; or dl, dl, register-destination encoding.
    je near .done
    jmp short .step
.different:
    db 0x0a, 0xd2 ; or dl, dl, register-destination encoding.
    jne near .done
.step:
    inc ebx
    db 0x3b, 0xde ; cmp ebx, esi, register-destination encoding.
    jge short .done
    add di, 1
    jae short .next
    push eax
    mov al, byte ss:[current_bank]
    inc al
    call dword [select_bank]
    pop eax
.next:
    jmp short .compare
.done:
    ret

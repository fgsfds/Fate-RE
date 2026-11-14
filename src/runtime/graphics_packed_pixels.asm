; Packed-pixel graphics fragments, reads, and bitmap dispatch.
; Line fragment entries follow a length byte. Their final RET is excluded from the copy.
BITS 32
ORG 0x71dc4

drawing_action equ 0x16c9f
blit_bitmap_bits equ 0x73c2d
select_bitmap_replace equ 0x73bd1
select_bitmap_xor equ 0x73c16
select_bitmap_and equ 0x73be8
select_bitmap_or equ 0x73bff

    db plot_xor.fragment_end - plot_xor
plot_xor:
    xor byte es:[edi], al
.fragment_end:
    ret

    db plot_and.fragment_end - plot_and
plot_and:
    db 0x0a, 0xc5 ; or al, ch, register-destination encoding.
    and byte es:[edi], al
    db 0x32, 0xc5 ; xor al, ch, register-destination encoding.
.fragment_end:
    ret

    db plot_replace.fragment_end - plot_replace
plot_replace:
    mov ah, byte es:[edi]
    db 0x22, 0xe5 ; and ah, ch, register-destination encoding.
    db 0x0a, 0xe0 ; or ah, al, register-destination encoding.
    mov byte es:[edi], ah
.fragment_end:
    ret

    db plot_or.fragment_end - plot_or
plot_or:
    or byte es:[edi], al
.fragment_end:
    ret

    db shift_right_variable.fragment_end - shift_right_variable
shift_right_variable:
    ror al, cl
    ror ch, cl
    sbb edi, -1
.fragment_end:
    ret

    db shift_right_one.fragment_end - shift_right_one
shift_right_one:
    ror al, 1
    ror ch, 1
    sbb edi, -1
.fragment_end:
    ret

    db shift_left_variable.fragment_end - shift_left_variable
shift_left_variable:
    rol al, cl
    rol ch, cl
    adc edi, -1
.fragment_end:
    ret

    db shift_left_one.fragment_end - shift_left_one
shift_left_one:
    rol al, 1
    rol ch, 1
    adc edi, -1
.fragment_end:
    ret

    db step_cga_up.fragment_end - step_cga_up
step_cga_up:
    push ebx
    db 0x66, 0x8b, 0xdf ; mov bx, di, register-destination encoding.
    and bx, 0x8000
    and di, 0x7fff
    sub di, 0x2000
    jae short .restore_bank
    add di, 0x3fb0
.restore_bank:
    db 0x66, 0x0b, 0xfb ; or di, bx, register-destination encoding.
    pop ebx
.fragment_end:
    ret

    db step_cga_up_alternate.fragment_end - step_cga_up_alternate
step_cga_up_alternate:
    push ebx
    db 0x66, 0x8b, 0xdf ; mov bx, di, register-destination encoding.
    and bx, 0x8000
    and di, 0x7fff
    sub di, 0x1fb0
    jae short .restore_bank
    add di, 0x3fb0
.restore_bank:
    db 0x66, 0x0b, 0xfb ; or di, bx, register-destination encoding.
    pop ebx
.fragment_end:
    ret

read_mono_pixel:
    mov al, byte es:[edi]
    sub cl, 7
    neg cl
    shr al, cl
    and al, 1
    db 0x32, 0xe4 ; xor ah, ah, register-destination encoding.
    ret

read_two_bit_pixel:
    mov al, byte es:[edi]
    sub cl, 6
    neg cl
    shr al, cl
    and al, 3
    db 0x32, 0xe4 ; xor ah, ah, register-destination encoding.
    ret

blit_two_bit_with_action:
    shl ecx, 1
    push ds
    mov ds, esi
    db 0x8b, 0xf0 ; mov esi, eax, register-destination encoding.
    call select_bitmap_action
    call blit_bitmap_bits
    call select_bitmap_replace
    pop ds
    ret

blit_two_bit:
    shl ecx, 1
    push ds
    mov ds, esi
    db 0x8b, 0xf0 ; mov esi, eax, register-destination encoding.
    call blit_bitmap_bits
    pop ds
    ret

bitmap_action_table:
    dd select_bitmap_replace - 0x10000
    dd select_bitmap_xor - 0x10000
    dd select_bitmap_and - 0x10000
    dd select_bitmap_or - 0x10000

select_bitmap_action:
    movzx ebx, word ss:[drawing_action]
    jmp dword cs:[ebx*4 + bitmap_action_table - 0x10000]

pixel_action_table:
    dd plot_replace - 0x10000
    dd plot_xor - 0x10000
    dd plot_and - 0x10000
    dd plot_or - 0x10000

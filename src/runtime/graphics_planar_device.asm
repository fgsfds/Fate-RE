; BIOS mode selection and planar graphics device fragments.
BITS 32
ORG 0x72136

    times 193 db 0 ; BIOS mode support and setting are supplied by matching C

    db step_interleaved_up.fragment_end - step_interleaved_up
step_interleaved_up:
    add di, 0x6000
    jns short .finish
    sub di, 0x7fa6
.finish:
    sub di, 0x5a
.fragment_end:
    ret

    db step_interleaved_down.fragment_end - step_interleaved_down
step_interleaved_down:
    sub di, 0x6000
    jns short .finish
    add di, 0x7fa6
.finish:
    add di, 0x5a
.fragment_end:
    ret

two_plane_color_map:
    db 0, 3, 12, 15

    db 3 ; Fragment length for the C-replaced planar callback below.
    times 4 db 0 ; Reserved for step_up_80 in graphics_planar_steps.c.

    db 3 ; Fragment length for the C-replaced planar callback below.
    times 4 db 0 ; Reserved for step_down_80 in graphics_planar_steps.c.

    db 3 ; Fragment length for the C-replaced planar callback below.
    times 4 db 0 ; Reserved for step_up_40 in graphics_planar_steps.c.

    db 3 ; Fragment length for the C-replaced planar callback below.
    times 4 db 0 ; Reserved for step_down_40 in graphics_planar_steps.c.

    db step_planar_right.fragment_end - step_planar_right
step_planar_right:
    rol ch, 1
    sbb edi, 0
.fragment_end:
    ret

    db step_planar_left.fragment_end - step_planar_left
step_planar_left:
    ror ch, 1
    adc edi, 0
.fragment_end:
    ret

    db plot_planar_pixel.fragment_end - plot_planar_pixel
plot_planar_pixel:
    push edx
    db 0x8a, 0xc8 ; mov cl, al, register-destination encoding.
    mov al, 8
    mov edx, 0x3ce
    db 0x8a, 0xe5 ; mov ah, ch, register-destination encoding.
    out dx, ax
    db 0x8a, 0xc1 ; mov al, cl, register-destination encoding.
    xchg byte es:[edi], cl
    pop edx
.fragment_end:
    ret

read_even_planes:
    push ebx
    mov ebx, 0x202
    jmp short read_four_planes.read

read_interleaved_planes:
    push ebx
    mov ebx, 0x202
    test edi, 1
    je short .select
    inc bh
.select:
    jmp short read_four_planes.read

read_four_planes:
    push ebx
    mov ebx, 0x301
.read:
    push edx
    mov edx, 0x3ce
    mov ch, 0x80
    shr ch, cl
    mov al, 4
    out dx, al
    inc edx
    db 0x32, 0xc9 ; xor cl, cl, register-destination encoding.
    db 0x8a, 0xc7 ; mov al, bh, register-destination encoding.
.next:
    shl cl, 1
    out dx, al
    test byte es:[edi], ch
    je short .advance
    or cl, 1
.advance:
    db 0x2a, 0xc3 ; sub al, bl, register-destination encoding.
    jge short .next
    db 0x8a, 0xc1 ; mov al, cl, register-destination encoding.
    db 0x32, 0xe4 ; xor ah, ah, register-destination encoding.
    pop edx
    pop ebx
    ret

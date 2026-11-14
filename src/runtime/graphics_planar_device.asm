; BIOS mode selection and planar graphics device fragments.
BITS 32
ORG 0x72136

detect_display_adapters equ 0x7139e
adapter_mode_masks equ 0x1995c
bios_data_offset equ 0x16d01
bios_data_selector equ 0x16cf7
preserve_display equ 0x199a4

bios_mode_supported:
    push ebx
    push ecx
    push edx
    mov edx, eax
    xor dh, ah
    call detect_display_adapters
    mov ecx, eax
    cwde
    and dl, 0x7f
    sar eax, 8
    xor ch, ch
    mov ebx, eax
    mov eax, ecx
    movsx ecx, dx
    mov edx, 1
    cwde
    shl edx, cl
    test dword [eax*4 + adapter_mode_masks], edx
    jne short .supported
    movsx eax, bx
    test dword [eax*4 + adapter_mode_masks], edx
    je short .unsupported
.supported:
    mov eax, 1
    pop edx
    pop ecx
    pop ebx
    ret
.unsupported:
    xor eax, eax
    pop edx
    pop ecx
    pop ebx
    ret

set_and_query_bios_mode:
    push ebx
    push ecx
    push edx
    push es
    push fs
    mov ebx, eax
    cwde
    call bios_mode_supported
    test ax, ax
    je short .query
    mov eax, dword [bios_data_offset]
    mov es, word [bios_data_selector]
    add eax, 0x10
    push es
    pop fs
    mov edx, eax
    and byte es:[eax], 0xcf
    cmp bx, 7
    je short .monochrome
    cmp bx, 0xf
    jne short .color
.monochrome:
    or byte fs:[edx], 0x30
    jmp short .preserve_display
.color:
    or byte es:[eax], 0x20
.preserve_display:
    cmp word [preserve_display], 0
    je short .set
    or bl, 0x80
.set:
    mov eax, ebx
    xor ecx, ecx
    xor edx, edx
    xor ebx, ebx
    push bp
    int 0x10
    pop bp
.query:
    mov eax, 0xf00
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    push bp
    int 0x10
    pop bp
    and al, 0x7f
    xor ah, ah
    pop fs
    pop es
    pop edx
    pop ecx
    pop ebx
    ret

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

    db step_up_80.fragment_end - step_up_80
step_up_80:
    sub edi, 0x50
.fragment_end:
    ret

    db step_down_80.fragment_end - step_down_80
step_down_80:
    add edi, 0x50
.fragment_end:
    ret

    db step_up_40.fragment_end - step_up_40
step_up_40:
    sub edi, 0x28
.fragment_end:
    ret

    db step_down_40.fragment_end - step_down_40
step_down_40:
    add edi, 0x28
.fragment_end:
    ret

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

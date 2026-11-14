; Service the HMI driver cursor, mix queued samples and write the output ring.
BITS 32
ORG 0x66b75

mix_buffer_bytes equ 0x16c14
mix_buffer_end equ 0x16c10
previous_sample equ 0x16c1c
current_sample equ 0x16c0c
mix_flags equ 0x16c30
left_gain equ 0x16c3c
right_gain equ 0x16c40
fractional_step equ 0x16c24
source_step equ 0x16c28
source_step_rounded equ 0x16c2c
mix_dispatch equ 0x5bdb9
selected_mixer equ 0x16c48
sample_end equ 0x16c20
mix_cursor equ 0x16c18
output_flags equ 0x16c38
output_dispatch equ 0x5dcfd

service_audio_driver:
    push ebp
    db 0x8b, 0xec ; MOV EBP, ESP, register-destination encoding.
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov eax, dword [ebp + 8]
    db 0x8b, 0xe8 ; MOV EBP, EAX, register-destination encoding.
    cmp dword [ebp + 0x34], 0
    je short .read_dma_position
    push es
    db 0x33, 0xd2 ; XOR EDX, EDX, register-destination encoding.
    mov edi, dword [ebp + 0x3c]
    push ds
    pop es
    db 0x33, 0xc0 ; XOR EAX, EAX, register-destination encoding.
    push fs
    push eax
    call far [ebp + 0x34]
    add esp, 8
    pop es
    movzx ebx, ax
    cmp ebx, dword [ebp + 0x20]
    jne short .check_cursor_zero
    nop
    nop
    nop
    nop
    jmp near .return

.read_dma_position:
    db 0x33, 0xc0 ; XOR EAX, EAX, register-destination encoding.
    mov edx, 0xc
    out dx, al
    jmp short .read_dma_low

.read_dma_low:
    mov edx, dword [ebp + 0x18]
    in al, dx
    jmp short .save_dma_low

.save_dma_low:
    xchg al, ah
    in al, dx
    jmp short .assemble_dma_count

.assemble_dma_count:
    xchg al, ah
    inc eax
    cmp edx, 7
    jbe short .check_dma_count
    db 0x03, 0xc0 ; ADD EAX, EAX, register-destination encoding.

.check_dma_count:
    cmp eax, dword [ebp + 0x44]
    jbe short .compute_dma_cursor
    db 0x33, 0xc0 ; XOR EAX, EAX, register-destination encoding.
    mov edx, 0xc
    out dx, al
    jmp short .load_dma_limit

.load_dma_limit:
    mov eax, dword [ebp + 0x44]
    dec eax
    mov edx, dword [ebp + 0x18]
    out dx, al
    jmp short .write_dma_high

.write_dma_high:
    xchg al, ah
    out dx, al
    jmp short .restore_dma_count

.restore_dma_count:
    xchg al, ah

.compute_dma_cursor:
    mov ebx, dword [ebp + 0x44]
    db 0x2b, 0xd8 ; SUB EBX, EAX, register-destination encoding.
    and ebx, 0xfffc

.check_cursor_zero:
    db 0x0b, 0xdb ; OR EBX, EBX, register-destination encoding.
    jne short .check_cursor_change
    add ebx, 0x20

.check_cursor_change:
    cmp ebx, dword [ebp + 0x20]
    je near .return
    mov dword [ebp + 0x1c], ebx
    mov eax, dword [ebp + 0x1c]
    sub eax, dword [ebp + 0x20]
    jae short .save_sample_count
    mov eax, dword [ebp + 0x44]
    sub eax, dword [ebp + 0x20]
    add eax, dword [ebp + 0x1c]

.save_sample_count:
    mov dword [ebp + 0x24], eax
    cmp dword [ebp + 0xc], 0x10
    je short .compute_mix_bytes
    shl eax, 1

.compute_mix_bytes:
    shl eax, 1
    mov dword [mix_buffer_bytes], eax
    add eax, dword [ebp + 0x48]
    dec eax
    mov dword [ebp + 0x4c], eax
    mov dword [mix_buffer_end], eax
    mov edi, dword [ebp + 0x48]
    mov ecx, dword [mix_buffer_bytes]
    add ecx, 0x20
    db 0x33, 0xc0 ; XOR EAX, EAX, register-destination encoding.
    cld
    push ecx
    shr ecx, 2
    rep stosd
    pop ecx
    and ecx, 3
    rep stosb
    mov eax, dword [ebp + 0x1c]
    mov dword [ebp + 0x20], eax
    mov dword [ebp + 0x54], 0
    mov dword [previous_sample], 0
    mov esi, dword [ebp + 0x30]
    db 0x0b, 0xf6 ; OR ESI, ESI, register-destination encoding.
    je near .select_output_format

.visit_sample:
    mov dword [current_sample], esi
    test dword [esi + 0x20], 0x4000
    jne near .unlink_finished_sample
    inc dword [ebp + 0x54]
    mov edi, dword [ebp + 0x48]

.mix_sample:
    mov dword [mix_flags], 0
    test dword [esi + 0x40], 0x8000
    je short .check_source_signedness
    nop
    nop
    nop
    nop
    or dword [mix_flags], 1

.check_source_signedness:
    test dword [esi + 0x40], 0x4000
    je short .check_pan
    nop
    nop
    nop
    nop
    or dword [mix_flags], 0x40

.check_pan:
    cmp dword [esi + 0x44], 0x8000
    jne short .compute_pan
    mov eax, dword [esi + 0x2c]
    and eax, 0x7fff
    mov dword [left_gain], eax
    mov eax, dword [esi + 0x2c]
    shr eax, 0x10
    and eax, 0x7fff
    mov dword [right_gain], eax
    jmp short .check_gain

.compute_pan:
    mov ebx, 0x7fff
    mov ecx, 0x7fff
    test dword [esi + 0x44], 0x8000
    jne short .pan_right
    mov ecx, dword [esi + 0x44]
    jmp short .scale_channels

.pan_right:
    mov ebx, 0xffff
    sub ebx, dword [esi + 0x44]

.scale_channels:
    db 0x33, 0xd2 ; XOR EDX, EDX, register-destination encoding.
    mov eax, dword [esi + 0x2c]
    imul bx
    db 0x03, 0xd2 ; ADD EDX, EDX, register-destination encoding.
    mov dword [left_gain], edx
    db 0x33, 0xd2 ; XOR EDX, EDX, register-destination encoding.
    mov eax, dword [esi + 0x2c]
    imul cx
    db 0x03, 0xd2 ; ADD EDX, EDX, register-destination encoding.
    mov dword [right_gain], edx

.check_gain:
    cmp dword [left_gain], 0x7ff0
    jb short .enable_gain_scaling
    cmp dword [right_gain], 0x7ff0
    jae short .check_source_width

.enable_gain_scaling:
    or dword [mix_flags], 0x20

.check_source_width:
    cmp dword [esi + 0x38], 8
    je short .check_source_channels
    or dword [mix_flags], 2

.check_source_channels:
    cmp dword [esi + 0x3c], 1
    je short .check_output_channels
    or dword [mix_flags], 8

.check_output_channels:
    cmp dword [ebp + 8], 1
    je short .check_resampling
    or dword [mix_flags], 4

.check_resampling:
    db 0x33, 0xc0 ; XOR EAX, EAX, register-destination encoding.
    mov edx, dword [esi + 0x34]
    cmp edx, dword [ebp + 4]
    je short .select_sample_mixer
    mov ecx, dword [ebp + 4]
    shl ecx, 0x10
    div ecx
    db 0x8b, 0xd8 ; MOV EBX, EAX, register-destination encoding.
    shr ebx, 0x10
    shl eax, 0x10
    mov dword [fractional_step], eax
    db 0x8b, 0xc3 ; MOV EAX, EBX, register-destination encoding.
    inc ebx
    test dword [mix_flags], 8
    je short .check_step_width
    shl eax, 1
    shl ebx, 1

.check_step_width:
    test dword [mix_flags], 2
    je short .save_step
    nop
    nop
    nop
    nop
    shl eax, 1
    shl ebx, 1

.save_step:
    mov word [source_step], ax
    mov word [source_step_rounded], bx
    or dword [mix_flags], 0x10

.select_sample_mixer:
    mov eax, dword [mix_flags]
    shl eax, 2
    add eax, mix_dispatch
    mov eax, dword [eax]
    mov dword [selected_mixer], eax
    mov eax, dword [esi]
    add eax, dword [esi + 0xc]
    mov dword [sample_end], eax
    mov esi, dword [esi + 4]
    mov ecx, 0x80000000
    push ebp
    db 0x33, 0xc0 ; XOR EAX, EAX, register-destination encoding.
    db 0x33, 0xdb ; XOR EBX, EBX, register-destination encoding.
    call dword [selected_mixer]
    pop ebp
    mov dword [mix_cursor], edi
    db 0x8b, 0xfe ; MOV EDI, ESI, register-destination encoding.
    mov esi, dword [current_sample]
    db 0x8b, 0xc7 ; MOV EAX, EDI, register-destination encoding.
    sub eax, dword [esi + 4]
    add dword [esi + 4], eax
    add dword [esi + 0x58], eax
    mov eax, dword [esi + 4]
    cmp eax, dword [sample_end]
    jb near .check_voice_limit
    cmp dword [esi + 0x30], -1
    je near .loop_sample
    cmp dword [esi + 0x30], 0
    je short .mark_sample_finished
    nop
    nop
    nop
    nop
    dec dword [esi + 0x30]
    jmp near .loop_sample

.mark_sample_finished:
    or dword [esi + 0x20], 0x4000
    cmp dword [esi + 0x5c], 0
    je near .check_voice_limit
    mov dword [esi], 0
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    push esi
    call dword [esi + 0x5c]
    add esp, 4
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    cmp dword [esi], 0
    je near .check_voice_limit
    and dword [esi + 0x20], 0xffffbfff
    jmp short .loop_sample
    nop
    nop
    nop

.unlink_finished_sample:
    mov dword [esi + 0x20], 0
    cmp dword [esi + 0x60], 0
    je short .mark_sample_inactive
    nop
    nop
    nop
    nop
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    push esi
    call dword [esi + 0x60]
    add esp, 4
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx

.mark_sample_inactive:
    and dword [esi + 0x20], 0xffff7fff
    or dword [esi + 0x20], 0x2000
    cmp dword [previous_sample], 0
    jne short .link_previous_to_next
    mov eax, dword [esi + 0xec]
    mov dword [ebp + 0x30], eax
    jmp short .advance_sample
    nop
    nop
    nop

.link_previous_to_next:
    mov eax, dword [esi + 0xec]
    mov edi, dword [previous_sample]
    mov dword [edi + 0xec], eax
    jmp short .advance_sample
    nop
    nop
    nop

.loop_sample:
    mov eax, dword [esi]
    mov dword [esi + 4], eax
    mov edi, dword [mix_cursor]
    cmp edi, dword [ebp + 0x4c]
    jb near .mix_sample

.check_voice_limit:
    mov eax, dword [ebp + 0x54]
    cmp eax, dword [ebp + 0x14]
    jae short .select_output_format
    nop
    nop
    nop
    nop
    mov dword [previous_sample], esi

.advance_sample:
    mov esi, dword [esi + 0xec]
    db 0x0b, 0xf6 ; OR ESI, ESI, register-destination encoding.
    jne near .visit_sample

.select_output_format:
    db 0x33, 0xc0 ; XOR EAX, EAX, register-destination encoding.
    test dword [ebp + 0x10], 0x8000
    je short .check_output_unsigned
    nop
    nop
    nop
    nop
    or eax, 2

.check_output_unsigned:
    test dword [ebp + 0x10], 0x4000
    je short .check_output_width
    nop
    nop
    nop
    nop
    or eax, 8

.check_output_width:
    cmp dword [ebp + 0xc], 8
    je short .check_output_stereo
    and eax, 0xfffffffd
    or eax, 1

.check_output_stereo:
    cmp dword [ebp + 8], 1
    je short .check_multiple_voices
    or eax, 4

.check_multiple_voices:
    cmp dword [ebp + 0x54], 1
    jbe short .select_output_mixer
    or eax, 0x10

.select_output_mixer:
    mov dword [output_flags], eax
    shl eax, 2
    add eax, output_dispatch
    mov eax, dword [eax]
    mov dword [selected_mixer], eax
    mov edi, dword [ebp + 0x28]
    mov esi, dword [ebp + 0x48]
    mov ecx, dword [mix_buffer_bytes]
    shr ecx, 2
    db 0x8b, 0xd1 ; MOV EDX, ECX, register-destination encoding.
    cmp dword [ebp + 8], 1
    je short .compute_output_bytes
    shr ecx, 1

.compute_output_bytes:
    cmp dword [ebp + 0xc], 0x10
    jne short .check_buffer_wrap
    shl edx, 1

.check_buffer_wrap:
    db 0x8b, 0xc7 ; MOV EAX, EDI, register-destination encoding.
    db 0x03, 0xc2 ; ADD EAX, EDX, register-destination encoding.
    cmp eax, dword [ebp + 0x40]
    jb short .write_contiguous
    nop
    nop
    nop
    nop
    db 0x8b, 0xc2 ; MOV EAX, EDX, register-destination encoding.
    mov ecx, dword [ebp + 0x40]
    sub ecx, dword [ebp + 0x28]
    db 0x2b, 0xc1 ; SUB EAX, ECX, register-destination encoding.
    push eax
    cmp dword [ebp + 0xc], 8
    je short .scale_first_channels
    shr ecx, 1

.scale_first_channels:
    cmp dword [ebp + 8], 1
    je short .write_first_part
    shr ecx, 1

.write_first_part:
    call dword [selected_mixer]
    pop ecx
    mov edi, dword [ebp + 0x3c]
    db 0x0b, 0xc9 ; OR ECX, ECX, register-destination encoding.
    je short .save_output_cursor
    cmp dword [ebp + 0xc], 8
    je short .scale_second_channels
    shr ecx, 1

.scale_second_channels:
    cmp dword [ebp + 8], 1
    je short .write_second_part
    shr ecx, 1

.write_second_part:
    call dword [selected_mixer]
    jmp short .save_output_cursor

.write_contiguous:
    call dword [selected_mixer]

.save_output_cursor:
    mov dword [ebp + 0x28], edi
    cmp dword [ebp + 0x54], 0
    jne short .return
    mov eax, dword [ebp + 0x3c]
    add eax, dword [ebp + 0x1c]
    add eax, dword [ebp + 0x2c]
    cmp eax, dword [ebp + 0x40]
    jb short .save_silent_cursor
    nop
    nop
    nop
    nop
    sub eax, dword [ebp + 0x44]

.save_silent_cursor:
    mov dword [ebp + 0x28], eax

.return:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop ebp
    ret

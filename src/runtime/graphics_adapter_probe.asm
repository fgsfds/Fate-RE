; Detect the video adapter through ROM signatures, BIOS calls and VGA registers.
BITS 32
ORG 0x72ed2

allocate_graphics_dos_buffer equ 0x72d63
free_graphics_dos_buffer equ 0x72df4
call_graphics_real_mode_interrupt equ 0x72e20
adapter_override equ 0x289236
video_rom_offset equ 0x16d11
video_rom_selector equ 0x16cff
vga_rom_signature equ 0x1efc
numbered_rom_signature equ 0x1f01
oak_rom_signature equ 0x1f0b
trident_rom_signature equ 0x1f0f

probe_video_adapter:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push es
    enter 0x20, 0
    cmp word [adapter_override], 0
    je short .check_display_bios
    mov ax, word [adapter_override]
    jmp near .done
.check_display_bios:
    mov eax, 0x1a00
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    push bp
    int 0x10
    pop bp
    cmp al, 0x1a
    jne near .unknown
    mov edi, vga_rom_signature
    mov eax, 4
    mov esi, dword [video_rom_offset]
    mov dx, word [video_rom_selector]
    mov ecx, ds
    add esi, 0x7d
    push ds
    push es
    xchg ecx, eax
    mov ds, edx
    mov es, eax
    or ecx, ecx
    repe cmpsb
    je short .restore_first_segments
    sbb ecx, ecx
    sbb ecx, -1
.restore_first_segments:
    pop es
    pop ds
    test ecx, ecx
    jne short .check_numbered_signature
    mov eax, 3
    jmp near .done
.check_numbered_signature:
    mov edi, numbered_rom_signature
    mov eax, 9
    mov esi, dword [video_rom_offset]
    mov dx, word [video_rom_selector]
    mov ecx, ds
    add esi, 0x31
    push ds
    push es
    xchg ecx, eax
    mov ds, edx
    mov es, eax
    or ecx, ecx
    repe cmpsb
    je short .restore_second_segments
    sbb ecx, ecx
    sbb ecx, -1
.restore_second_segments:
    pop es
    pop ds
    test ecx, ecx
    jne short .prepare_oak_search
    mov eax, 4
    jmp near .done
.prepare_oak_search:
    mov dword [ebp - 8], 0x200
    mov edx, dword [video_rom_offset]
    mov ax, word [video_rom_selector]
    mov dword [ebp - 0x18], edx
    jmp short .check_oak_search
.scan_for_oak:
    movsx ecx, word [ebp - 8]
    mov edi, dword [ebp - 0x18]
    mov edx, eax
    mov al, 0x4f
    push es
    jecxz .oak_search_miss
    mov es, edx
    repne scasb
    jne short .oak_search_miss
    dec edi
    mov ecx, es
    db 0x66, 0xa9 ; TEST AX consumes the alternate entry as its immediate.
.oak_search_miss:
    mov edi, ecx
    pop es
    mov dword [ebp - 0xc], ecx
    mov ebx, edi
    test edi, edi
    jne short .compare_oak
    test cx, cx
    je short .prepare_trident_search
.compare_oak:
    mov esi, oak_rom_signature
    mov eax, 3
    mov edx, ds
    push ds
    push es
    xchg ecx, eax
    mov ds, edx
    mov es, eax
    or ecx, ecx
    repe cmpsb
    je short .restore_oak_segments
    sbb ecx, ecx
    sbb ecx, -1
.restore_oak_segments:
    pop es
    pop ds
    test ecx, ecx
    jne short .advance_oak_search
    mov eax, 7
    jmp near .done
.advance_oak_search:
    mov edx, ebx
    movsx eax, word [ebp - 8]
    sub edx, dword [ebp - 0x18]
    inc ebx
    sub eax, edx
    mov dword [ebp - 0x18], ebx
    mov dword [ebp - 8], eax
    mov eax, dword [ebp - 0xc]
.check_oak_search:
    cmp word [ebp - 8], 0
    jg short .scan_for_oak
.prepare_trident_search:
    mov dword [ebp - 4], 0x200
    mov eax, dword [video_rom_offset]
    mov dx, word [video_rom_selector]
    mov dword [ebp - 0x14], eax
    jmp short .check_trident_search
.scan_for_trident:
    movsx ecx, word [ebp - 4]
    mov edi, dword [ebp - 0x14]
    mov al, 0x54
    push es
    jecxz .trident_search_miss
    mov es, edx
    repne scasb
    jne short .trident_search_miss
    dec edi
    mov ecx, es
    db 0x66, 0xa9 ; TEST AX consumes the alternate entry as its immediate.
.trident_search_miss:
    mov edi, ecx
    pop es
    mov dword [ebp - 0x10], ecx
    mov ebx, edi
    test edi, edi
    jne short .compare_trident
    test cx, cx
    je short .check_rom_pointer_signature
.compare_trident:
    mov esi, trident_rom_signature
    mov eax, 7
    mov edx, ds
    push ds
    push es
    xchg ecx, eax
    mov ds, edx
    mov es, eax
    or ecx, ecx
    repe cmpsb
    je short .restore_trident_segments
    sbb ecx, ecx
    sbb ecx, -1
.restore_trident_segments:
    pop es
    pop ds
    test ecx, ecx
    jne short .advance_trident_search
    mov eax, 8
    jmp near .done
.advance_trident_search:
    movsx eax, word [ebp - 4]
    mov edx, ebx
    inc ebx
    sub edx, dword [ebp - 0x14]
    mov dword [ebp - 0x14], ebx
    sub eax, edx
    mov edx, dword [ebp - 0x10]
    mov dword [ebp - 4], eax
.check_trident_search:
    cmp word [ebp - 4], 0
    jg short .scan_for_trident
.check_rom_pointer_signature:
    mov eax, dword [video_rom_offset]
    mov es, word [video_rom_selector]
    add eax, 0x37
    db 0x66, 0x26, 0x8b, 0x00 ; MOV AX, ES:[EAX], original prefix order.
    cwde
    add eax, dword [video_rom_offset]
    cmp byte es:[eax], 0x77
    jne short .query_6f_bios
    cmp byte es:[eax + 1], 0x11
    jne short .query_6f_bios
    cmp byte es:[eax + 2], 0x99
    jne short .query_6f_bios
    cmp byte es:[eax + 3], 0x66
    jne short .query_6f_bios
    mov eax, 0xa
    jmp near .done
.query_6f_bios:
    mov eax, 0x6f00
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    push bp
    int 0x10
    pop bp
    cmp bx, 0x5637
    jne short .query_5f_bios
    mov eax, 2
    jmp near .done
.query_5f_bios:
    mov eax, 0x5f00
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    push bp
    int 0x10
    pop bp
    xor ah, ah
    cmp ax, strict word 0x5f
    jne short .probe_crtc_id
    mov eax, 9
    jmp near .done
.probe_crtc_id:
    mov edx, 0x3d4
    mov al, 0x38
    out dx, al
    mov edx, 0x3d5
    mov al, 0x48
    out dx, al
    mov edx, 0x3d4
    mov al, 0x30
    out dx, al
    mov edx, 0x3d5
    sub eax, eax
    in al, dx
    shr eax, 4
    cmp ax, strict word 8
    je short .crtc_id_found
    cmp ax, strict word 9
    je short .crtc_id_found
    cmp ax, strict word 0xa
    jne short .probe_segment_register
.crtc_id_found:
    mov eax, 0xb
    jmp near .done
.probe_segment_register:
    mov edx, 0x3cd
    sub eax, eax
    in al, dx
    mov ebx, eax
    mov al, 0x55
    xor cl, cl
    out dx, al
    sub eax, eax
    in al, dx
    cmp eax, 0x55
    jne short .restore_segment_register
    mov al, 0xaa
    out dx, al
    sub eax, eax
    in al, dx
    cmp eax, strict dword 0xaa
    jne short .restore_segment_register
    mov cl, 1
.restore_segment_register:
    mov edx, 0x3cd
    movsx eax, bx
    out dx, al
    test cl, cl
    je short .query_12ff_bios
    mov edx, 0x3d4
    mov al, 0x33
    out dx, al
    mov edx, 0x3d5
    sub eax, eax
    in al, dx
    mov esi, eax
    mov al, 5
    out dx, al
    sub eax, eax
    in al, dx
    mov ebx, eax
    movsx eax, si
    out dx, al
    cmp bl, 5
    jne short .segment_register_only
    mov eax, 6
    jmp near .done
.segment_register_only:
    mov eax, 5
    jmp near .done
.query_12ff_bios:
    mov eax, 0x12ff
    mov ebx, 0x80
    xor ch, ch
    xor edx, edx
    push bp
    int 0x10
    pop bp
    cmp ax, strict word 2
    jl short .query_vbe
    cmp ax, strict word 0x31
    jg short .query_vbe
    mov eax, 0xc
    jmp near .done
.query_vbe:
    mov eax, 0x100
    lea edx, [ebp - 0x20]
    call allocate_graphics_dos_buffer
    test ax, ax
    je short .unknown
    mov es, word [ebp - 0x1a]
    push 0
    movsx eax, word [ebp - 0x20]
    mov edx, 0x4f00
    push eax
    xor ebx, ebx
    xor ecx, ecx
    push 0
    mov eax, 0x10
    mov esi, dword [ebp - 0x1e]
    call call_graphics_real_mode_interrupt
    cmp ax, strict word 0x4f
    jne short .invalid_vbe_signature
    cmp byte es:[esi], 0x56
    jne short .invalid_vbe_signature
    cmp byte es:[esi + 1], 0x45
    jne short .invalid_vbe_signature
    cmp byte es:[esi + 2], 0x53
    jne short .invalid_vbe_signature
    cmp byte es:[esi + 3], 0x41
    jne short .invalid_vbe_signature
    mov dl, 1
    jmp short .release_vbe_buffer
.invalid_vbe_signature:
    xor dl, dl
.release_vbe_buffer:
    lea eax, [ebp - 0x20]
    call free_graphics_dos_buffer
    test dl, dl
    je short .unknown
    mov eax, 1
    jmp short .done
.unknown:
    xor eax, eax
.done:
    leave
    pop es
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

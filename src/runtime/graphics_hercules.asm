; Program Hercules graphics and calculate four-bank monochrome pixel addresses.
BITS 32
ORG 0x701e9

detect_display_adapters equ 0x7139e
apply_graphics_mode_state equ 0x6fe1e

bios_data_offset equ 0x16d01
bios_data_selector equ 0x16cf7
hercules_crtc_registers equ 0x16e64
mono_video_offset equ 0x16d05
mono_video_selector equ 0x16cf9
pixel_bit_offset equ 0x2891f6
current_buffer_selector equ 0x289226
pixel_selector equ 0x2891f0
current_buffer_offset equ 0x289228
pixel_address equ 0x2891ec
pixel_mask_and_width equ 0x2891f4
pixel_color equ 0x2891f2

program_hercules_graphics:
    push ecx
    push edx
    push edi
    push es
    push fs
    mov eax, dword [bios_data_offset]
    mov es, word [bios_data_selector]
    add eax, 0x10
    mov edx, 0x3bf
    or byte es:[eax], 0x30
    mov al, 1
    out dx, al
    mov edx, 0x3b8
    mov al, 2
    xor edi, edi
    out dx, al
.write_crtc_register:
    movsx eax, di
    movzx edx, byte [eax + hercules_crtc_registers]
    shl edx, 8
    add eax, edx
    mov edx, 0x3b4
    inc edi
    out dx, ax
    cmp di, 0xc
    jl short .write_crtc_register
    mov ecx, 0x8000
    mov edi, dword [mono_video_offset]
    mov dx, word [mono_video_selector]
    xor al, al
    push es
    push edi
    mov es, edx
    mov ah, al
    shr ecx, 1
    db 0xf2, 0x66, 0xab ; REPNE STOSW, original prefix order.
    adc ecx, ecx
    repne stosb
    pop edi
    pop es
    mov edx, 0x3b8
    mov al, 0xa
    out dx, al
    mov eax, dword [bios_data_offset]
    mov es, word [bios_data_selector]
    lea edx, [eax + 0x49]
    mov byte es:[edx], 0xb
    lea edx, [eax + 0x4a]
    push es
    pop fs
    mov byte es:[edx], 0x5a
    lea edx, [eax + 0x84]
    add eax, 0x50
    mov byte fs:[edx], 0x18
    db 0x66, 0x26, 0xc7, 0, 0, 0 ; MOV word ES:[EAX], 0, original prefix order.
    pop fs
    pop es
    pop edi
    pop edx
    pop ecx
    ret

set_hercules_mode:
    push ebx
    push ecx
    push edx
    call detect_display_adapters
    mov edx, eax
    cwde
    xor dh, dh
    sar eax, 8
    cmp dx, 0xd
    jl short .check_secondary_adapter
    cmp dx, 0xf
    jle short .apply_mode
.check_secondary_adapter:
    cmp ax, strict word 0xd
    jl short .unsupported
    cmp ax, strict word 0xf
    jg short .unsupported
.apply_mode:
    call program_hercules_graphics
    push 2
    push 0
    push dword [mono_video_offset]
    movsx eax, word [mono_video_selector]
    push eax
    mov edx, 0x15e
    mov ebx, 2
    push 1
    mov ecx, 1
    mov eax, 0x2d0
    call apply_graphics_mode_state
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

address_hercules_pixel:
    push ecx
    push esi
    mov esi, eax
    mov ecx, edx
    movsx eax, dx
    sar eax, 2
    imul edx, eax, 0x5a
    mov eax, ecx
    mov ecx, 3
    and al, 3
    xor ah, ah
    ror ax, cl
    cwde
    add edx, eax
    movsx eax, si
    and esi, 7
    sar eax, 3
    mov word [pixel_bit_offset], si
    add eax, edx
    mov dx, word [current_buffer_selector]
    movzx eax, ax
    mov word [pixel_selector], dx
    add eax, dword [current_buffer_offset]
    mov dl, byte [pixel_bit_offset]
    mov dword [pixel_address], eax
    inc dl
    mov al, 0xfe
    mov cl, dl
    o16 ror al, cl
    movzx ax, al
    shl eax, 8
    or al, 1
    mov cl, dl
    mov word [pixel_mask_and_width], ax
    mov al, bl
    o16 ror al, cl
    movzx ax, al
    mov word [pixel_color], ax
    pop esi
    pop ecx
    ret

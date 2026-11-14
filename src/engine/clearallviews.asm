; Clear display pages or banks for the selected video backend.
BITS 32
ORG 0x5d0aa

qsetmode equ 0x140ba
stereofps equ 0x14014
video_mode equ 0x286b24
stereo_buffer equ 0x13ff0
video_backend equ 0x2891db
display_page_bytes equ 0x286b70
frameplace equ 0x286b74
display_page_count equ 0x287e80
presentation_width equ 0x287e90
presentation_height equ 0x287e8c
clearallviews_dispatch_offset equ 0x4d08a
shared_restore equ 0x4abbf
select_display_page equ 0x4417c
faketimerhandler equ 0x31ec4

clearallviews_:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    mov ebx, eax
    cmp dword [qsetmode], 0xc8
    jne near shared_restore
    shl eax, 8
    add ebx, eax
    mov eax, ebx
    shl eax, 0x10
    mov ecx, dword [stereofps]
    add ebx, eax
    test ecx, ecx
    je short .dispatch_video_backend
    cmp dword [video_mode], 6
    jne short .fill_stereo_buffer
    mov edx, 0x3d4
    xor esi, esi
    jmp short .check_stereo_vga_bank

.erase_stereo_vga_bank:
    mov eax, esi
    shl eax, 8
    mov ecx, 0x4000
    add eax, 0x35
    mov edi, 0xa0000
    out dx, ax
    xor eax, eax
    inc esi
    rep stosd

.check_stereo_vga_bank:
    cmp esi, 4
    jl short .erase_stereo_vga_bank

.fill_stereo_buffer:
    mov ecx, 0x7d00
    mov edi, dword [stereo_buffer]
    mov eax, ebx

.fill_dwords_and_service_timer:
    rep stosd
    jmp near .service_timer

.dispatch_video_backend:
    mov al, byte [video_backend]
    cmp al, 7
    ja near .service_timer
    and eax, 0xff
    jmp dword cs:[eax*4 + clearallviews_dispatch_offset]

.clear_vga_planes:
    mov eax, 0xf02
    mov edx, 0x3c4
    mov ecx, 0x4000
    mov edi, 0xa0000
    out dx, ax
    xor eax, eax
    jmp short .fill_dwords_and_service_timer

.clear_paged_display:
    xor esi, esi
    jmp short .check_display_page

.select_and_erase_page:
    mov eax, esi
    call select_display_page
    mov ecx, dword [display_page_bytes]
    mov edi, dword [frameplace]
    xor eax, eax
    cmp ecx, 4
    jae short .branch_0d0
    test cl, 1
    je short .branch_0c9
    stosb

.branch_0c9:
    shr ecx, 1
    db 0xf3                       ; REP precedes the operand-size prefix
    stosw
    jmp short .advance_display_page

.branch_0d0:
    test edi, 1
    je short .branch_0da
    stosb
    dec ecx

.branch_0da:
    test edi, 2
    je short .branch_0e7
    stosw
    sub ecx, 2

.branch_0e7:
    mov ebx, ecx
    shr ecx, 2
    rep stosd
    test bl, 2
    je short .branch_0f5
    stosw

.branch_0f5:
    test bl, 1
    je short .advance_display_page
    stosb

.advance_display_page:
    inc esi

.check_display_page:
    cmp esi, dword [display_page_count]
    jl short .select_and_erase_page

.clear_linear_frame:
    mov ecx, dword [presentation_width]
    imul ecx, dword [presentation_height]
    mov edi, dword [frameplace]
    xor eax, eax
    sar ecx, 2
    jmp near .fill_dwords_and_service_timer

.clear_port_3cd_banks:
    mov edx, 0x3cd
    xor esi, esi
    jmp short .check_port_3cd_bank

.erase_port_3cd_bank:
    mov ecx, 0x3e80
    mov eax, esi
    mov edi, 0xa0000
    out dx, al
    xor eax, esi
    rep stosd
    inc esi

.check_port_3cd_bank:
    cmp esi, 4
    jl short .erase_port_3cd_bank
    jmp short .service_timer

.clear_graphics_controller_banks:
    mov edx, 0x3ce
    xor esi, esi
    jmp short .check_graphics_controller_bank

.erase_graphics_controller_bank:
    mov eax, esi
    shl eax, 0xc
    mov ecx, 0x3e80
    add eax, 9
    mov edi, 0xa0000
    out dx, ax
    xor eax, eax
    inc esi
    rep stosd

.check_graphics_controller_bank:
    cmp esi, 4
    jl short .erase_graphics_controller_bank
    jmp short .service_timer

.clear_crtc_banks:
    mov edx, 0x3d4
    xor esi, esi
    jmp short .check_crtc_bank

.erase_crtc_bank:
    mov eax, esi
    shl eax, 8
    mov ecx, 0x3e80
    add eax, 0x35
    mov edi, 0xa0000
    out dx, ax
    xor eax, eax
    inc esi
    rep stosd

.check_crtc_bank:
    cmp esi, 4
    jl short .erase_crtc_bank

.service_timer:
    call faketimerhandler
    jmp near shared_restore

; Check the engine signature, initialize the selected video mode and set the viewport.
BITS 32
ORG 0x4a480

engine_signature_failure equ 0x1a31
engine_signature equ 0x1a53
unsupported_chained_mode_message equ 0x1ad3
chainstat equ 0x14003
engine_14004 equ 0x14004
current_brightness equ 0x14018
qsetmode equ 0x140ba
engine_14187 equ 0x14187
print_diagnostic equ 0x40bb4
initialize_vesa_mode equ 0x43d0c
restore_ebp_edi_esi_edx_ecx_ebx equ 0x4abbe
setview equ 0x56f0a
sub_5994a equ 0x5994a
setbrightness equ 0x59bee
sub_5c7a1 equ 0x5c7a1
sub_5d0aa equ 0x5d0aa
runtime_exit equ 0x60353
setvlinebpl equ 0x74090
engine_1db560 equ 0x1db560
palette equ 0x27c0a0
engine_2863cc equ 0x2863cc
view_height equ 0x286af4
half_view_width equ 0x286b08
video_mode equ 0x286b24
engine_286b38 equ 0x286b38
chainplace equ 0x286b4c
frame_state_286b50 equ 0x286b50
bytesperline equ 0x286b64
video_page_count equ 0x286b78
ylookup equ 0x286bb0
display_page_count equ 0x287e80
ydim equ 0x287e8c
xdim equ 0x287e90
video_backend equ 0x2891db

initialize_video_mode:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    cmp dword [qsetmode], strict dword 0xc8
    jz near restore_ebp_edi_esi_edx_ecx_ebx
    mov ecx, 0x20
    mov edi, engine_1db560
    mov esi, engine_signature
    mov ebx, engine_1db560
    rep movsd
    xor eax, eax
    mov ecx, 0x20

.branch_4a4b3:
    mov edx, [ebx + ecx*4-0x4]
    ror edx, cl
    adc eax, edx
    bswap eax
    loop .branch_4a4b3
    cmp eax, strict dword 0x56c764d4
    jz short .branch_4a4e1
    mov eax, 0x3
    int byte 0x10
    push strict dword engine_signature_failure
    call print_diagnostic
    add esp, 0x4
    xor eax, eax
    call runtime_exit

.branch_4a4e1:
    mov ebx, [video_mode]
    cmp ebx, 0x6
    jz short .branch_4a4f1
    cmp ebx, 0x7
    jnz short .branch_4a518

.branch_4a4f1:
    mov eax, 0x13
    int byte 0x10
    cmp dword [video_mode], 0x6
    jnz short .branch_4a506
    call sub_5994a

.branch_4a506:
    xor esi, esi
    mov eax, [xdim]
    mov [engine_286b38], esi
    jmp near .branch_4a712

.branch_4a518:
    xor esi, esi
    mov ah, [video_backend]
    mov [frame_state_286b50], esi
    test ah, ah
    jnz near .branch_4a5a4
    mov eax, 0x13
    int byte 0x10
    mov edx, [ydim]
    mov eax, [xdim]
    call sub_5c7a1
    test eax, eax
    jnl short .branch_4a572
    mov eax, 0x3
    int byte 0x10
    mov edi, [ydim]
    push edi
    mov ebp, [xdim]
    push ebp
    push strict dword unsupported_chained_mode_message
    call print_diagnostic
    add esp, 0xc
    xor eax, eax
    call runtime_exit

.branch_4a572:
    mov eax, 0xa0000
    mov edx, 0x3c4
    mov [chainplace], eax
    mov eax, 0x2
    out dx, al
    cmp byte [chainstat], 0x0
    jz short .branch_4a59a
    mov eax, [xdim]
    sar eax, byte 0x2
    jmp short .branch_4a59f

.branch_4a59a:
    mov eax, [xdim]

.branch_4a59f:
    mov [bytesperline], eax

.branch_4a5a4:
    xor eax, eax
    mov al, [video_backend]
    cmp eax, 0x1
    jnz short .branch_4a5c0
    mov edx, [ydim]
    mov eax, [xdim]
    call initialize_vesa_mode

.branch_4a5c0:
    xor eax, eax
    mov al, [video_backend]
    cmp eax, 0x2
    jnz short .branch_4a5f3
    mov edx, 0x140
    mov ebx, 0xc8
    mov eax, 0x13
    mov [xdim], edx
    mov [ydim], ebx
    int byte 0x10
    mov eax, [xdim]
    mov [bytesperline], eax

.branch_4a5f3:
    xor eax, eax
    mov al, [video_backend]
    cmp eax, 0x3
    jnz short .branch_4a63c
    mov ecx, 0x140
    mov esi, 0xc8
    mov eax, 0x13
    mov [xdim], ecx
    mov [ydim], esi
    int byte 0x10
    mov eax, [frame_state_286b50]
    mov edi, [frame_state_286b50]
    shl eax, byte 0x4
    mov edx, 0x3cd
    add eax, edi
    out dx, al
    mov eax, [xdim]
    mov [bytesperline], eax

.branch_4a63c:
    xor eax, eax
    mov al, [video_backend]
    cmp eax, 0x4
    jnz short .branch_4a6b0
    mov ebp, 0x140
    mov eax, 0xc8
    mov edx, 0x3ce
    mov [ydim], eax
    mov eax, 0x13
    mov [xdim], ebp
    int byte 0x10
    mov eax, 0x50f
    out dx, ax
    mov eax, 0x8529
    mov edx, 0x3d4
    out dx, ax
    mov eax, 0x4806
    mov edx, 0x3c4
    out dx, ax
    mov eax, 0x2f
    mov edx, 0x3d4
    out dx, ax
    mov eax, [frame_state_286b50]
    shl eax, byte 0xc
    mov edx, 0x3ce
    add eax, 0x9
    out dx, ax
    mov eax, [xdim]
    mov [bytesperline], eax

.branch_4a6b0:
    xor eax, eax
    mov al, [video_backend]
    cmp eax, 0x5
    jnz short .branch_4a717
    mov edx, 0x140
    mov ebx, 0xc8
    mov eax, 0x13
    mov [xdim], edx
    mov [ydim], ebx
    int byte 0x10
    mov eax, 0x4838
    mov edx, 0x3d4
    out dx, ax
    mov eax, 0xa539
    out dx, ax
    mov eax, 0x31
    out dx, al
    mov edx, 0x3d5
    in al, dx
    or al, 0x9
    out dx, al
    mov eax, [frame_state_286b50]
    shl eax, byte 0x8
    mov edx, 0x3d4
    add eax, 0x35
    out dx, ax
    mov eax, [xdim]

.branch_4a712:
    mov [bytesperline], eax

.branch_4a717:
    mov eax, [bytesperline]
    call setvlinebpl
    xor edx, edx
    mov esi, [bytesperline]
    mov edi, [ydim]
    xor eax, eax
    jmp short .branch_4a73d

.branch_4a733:
    mov [nosplit eax*4 + ylookup], edx
    inc eax
    add edx, esi

.branch_4a73d:
    cmp eax, edi
    jng short .branch_4a733
    mov ebp, 0x1
    mov dh, [chainstat]
    mov [display_page_count], ebp
    test dh, dh
    jz short .branch_4a760
    mov eax, [engine_14004]
    mov [display_page_count], eax

.branch_4a760:
    xor eax, eax
    mov al, [video_backend]
    cmp eax, 0x1
    jnz short .branch_4a780
    mov eax, [video_page_count]
    cmp eax, 0x8
    jl short .branch_4a77b
    mov eax, 0x8

.branch_4a77b:
    mov [display_page_count], eax

.branch_4a780:
    xor eax, eax
    mov al, [video_backend]
    cmp eax, 0x3
    jl short .branch_4a796
    mov dword [display_page_count], 0x4

.branch_4a796:
    mov ecx, [ydim]
    mov ebx, [xdim]
    xor edx, edx
    xor eax, eax
    dec ecx
    dec ebx
    call setview
    xor eax, eax
    call sub_5d0aa
    xor eax, eax
    mov edx, palette
    mov al, [current_brightness]
    call setbrightness
    cmp dword [engine_14187], 0x0
    jnl short .branch_4a7e4
    mov eax, [half_view_width]
    mov [engine_14187], eax
    mov eax, [view_height]
    sar eax, 1
    mov [engine_2863cc], eax

.branch_4a7e4:
    mov dword [qsetmode], 0xc8
    jmp near restore_ebp_edi_esi_edx_ecx_ebx

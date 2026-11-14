; Present the current frame and update page, sprite and timer state.
BITS 32
ORG 0x4b496

software_framebuffer equ 0x13ff0
chainstat equ 0x14003
engine_14004 equ 0x14004
transarea equ 0x14008
engine_1400c equ 0x1400c
new_frame_flag equ 0x14010
page_flip_enabled equ 0x14014
qsetmode equ 0x140ba
permanent_sprite_tail equ 0x140cb
frame_state_140cf equ 0x140cf
faketimerhandler equ 0x31ec4
page_present_dispatch equ 0x3b47e
sub_40f2d equ 0x40f2d
select_vesa_draw_page equ 0x4417c
sub_44220 equ 0x44220
restore_ebp_edi_esi_edx_ecx_ebx equ 0x4abbe
draw_rotated_sprite equ 0x573ac
sub_59b58 equ 0x59b58
permanent_sprite_queue equ 0x191750
frame_state_191754 equ 0x191754
frame_state_191758 equ 0x191758
frame_state_19175c equ 0x19175c
frame_state_19175e equ 0x19175e
frame_state_191760 equ 0x191760
frame_state_191761 equ 0x191761
frame_state_191762 equ 0x191762
frame_state_191763 equ 0x191763
frame_state_191764 equ 0x191764
frame_state_191768 equ 0x191768
frame_state_19176c equ 0x19176c
frame_state_191770 equ 0x191770
pageoffset equ 0x286a74
video_mode equ 0x286b24
frame_state_286b34 equ 0x286b34
engine_286b38 equ 0x286b38
frame_state_286b44 equ 0x286b44
frame_state_286b48 equ 0x286b48
chainplace equ 0x286b4c
frame_state_286b50 equ 0x286b50
skip_bank_switch equ 0x286b54
draw_page_address equ 0x286b74
use_software_framebuffer equ 0x286b84
save_state_287e74 equ 0x287e74
display_page_count equ 0x287e80
totalclock equ 0x287e88
ydim equ 0x287e8c
xdim equ 0x287e90
video_backend equ 0x2891db

nextpage:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 0x8
    mov eax, [qsetmode]
    cmp eax, strict dword 0x15e
    jc short .branch_4b4d5
    mov edx, [pageoffset]
    sar edx, byte 0xb
    shl edx, byte 0x8
    add edx, 0xc
    cmp eax, strict dword 0x15e
    jna near .branch_4ba6c
    cmp eax, strict dword 0x1e0
    jz near .branch_4ba92
    jmp near .branch_4babb

.branch_4b4d5:
    cmp eax, strict dword 0xc8
    jnz near .branch_4babb
    cmp dword [page_flip_enabled], 0x0
    jz short .branch_4b54a
    cmp dword [video_mode], 0x6
    jnz short .branch_4b50e
    mov edx, [software_framebuffer]
    mov eax, [engine_286b38]
    call sub_59b58

.branch_4b502:
    xor byte [engine_286b38], 0x1
    jmp near .branch_4babb

.branch_4b50e:
    cmp dword [engine_286b38], 0x0
    jnz short .branch_4b502
    mov ebx, [software_framebuffer]
    mov ebp, [frame_state_286b44]
    lea edx, [ebx + 0x10000]
    mov esi, 0xfa00
    add ebx, ebp
    xor ecx, ecx

.branch_4b532:
    mov eax, [edx + ecx]
    shl eax, byte 0x4
    add eax, [ebx + ecx]
    mov [ecx + 0xa0000], eax
    add ecx, 0x4
    cmp ecx, esi
    jc short .branch_4b532
    jmp short .branch_4b502

.branch_4b54a:
    mov ebp, [frame_state_140cf]
    jmp near .branch_4b5f4

.branch_4b555:
    mov eax, ebp
    shl eax, byte 0x3
    add eax, ebp
    shl eax, byte 0x2
    mov dl, [eax + frame_state_191763]
    and dl, 0x80
    and edx, strict dword 0xff
    jnz near .branch_4b5ed
    mov dl, [eax + frame_state_191763]
    and dl, 0x7f
    mov ebx, [display_page_count]
    and edx, strict dword 0xff
    cmp edx, ebx
    jz short .branch_4b5ed
    test edx, edx
    jz short .branch_4b5ed
    mov ecx, [eax + frame_state_191770]
    push ecx
    mov esi, [eax + frame_state_19176c]
    push esi
    mov edi, [eax + frame_state_191768]
    push edi
    mov edx, [eax + frame_state_191764]
    push edx
    xor edx, edx
    mov dl, [eax + frame_state_191762]
    push edx
    xor edx, edx
    mov dl, [eax + frame_state_191761]
    push edx
    movsx edx, byte [eax + frame_state_191760]
    mov ebx, [eax + frame_state_191758]
    push edx
    movsx edx, word [eax + frame_state_19175e]
    movsx ecx, word [eax + frame_state_19175c]
    push edx
    mov edx, [eax + frame_state_191754]
    mov eax, [eax + permanent_sprite_queue]
    call draw_rotated_sprite

.branch_4b5ed:
    inc ebp
    and ebp, strict dword 0x1ff

.branch_4b5f4:
    cmp ebp, [permanent_sprite_tail]
    jnz near .branch_4b555
    mov al, [video_backend]
    cmp al, 0x5
    ja near .branch_4b95a
    xor edx, edx
    mov dl, al
    mov eax, [frame_state_286b50]
    shl eax, byte 0xe
    add eax, 0xc
    jmp dword near [cs:edx*4 + page_present_dispatch]
    cmp byte [chainstat], 0x0
    jz short .branch_4b68c
    mov eax, [chainplace]
    and eax, strict dword 0xff00
    mov edx, 0x3d4
    add eax, 0xc
    out dx, ax
    mov eax, [frame_state_286b48]
    mov esi, [chainplace]
    add esi, eax
    add eax, esi
    mov [chainplace], esi
    cmp eax, strict dword 0xb0000
    jl short .branch_4b667
    mov dword [chainplace], 0xa0000

.branch_4b667:
    cmp dword [engine_14004], 0x2
    jnz near .branch_4b95a
    mov dx, 0x3da

.branch_4b678:
    in al, dx
    test al, 0x8
    jnz short .branch_4b678

.branch_4b67d:
    in al, dx
    test al, 0x8
    jz short .branch_4b67d
    call faketimerhandler
    jmp near .branch_4b95a

.branch_4b68c:
    mov eax, 0x2
    mov edx, 0x3c4
    mov ecx, 0xa0000
    out dx, al
    xor ebp, ebp
    mov edx, 0x3c5
    mov eax, [draw_page_address]
    mov [esp], ecx
    mov [esp + 0x4], eax
    jmp near .branch_4b863

.branch_4b6b4:
    mov eax, 0x1
    mov edi, [esp]
    out dx, al
    mov ecx, [xdim]
    mov esi, [esp + 0x4]
    sar ecx, byte 0x3
    shr ecx, 1
    jnc short .branch_4b6e6
    mov al, [esi + 0x8]
    mov ah, [esi + 0xc]
    shl eax, byte 0x10
    mov al, [esi]
    mov ah, [esi + 0x4]
    mov [edi], eax
    add esi, 0x10
    add edi, 0x4
    test ecx, ecx

.branch_4b6e6:
    jz short .branch_4b714

.branch_4b6e8:
    mov al, [esi + 0x8]
    mov bl, [esi + 0x18]
    mov ah, [esi + 0xc]
    mov bh, [esi + 0x1c]
    shl eax, byte 0x10
    add edi, 0x8
    shl ebx, byte 0x10
    mov al, [esi]
    mov bl, [esi + 0x10]
    mov ah, [esi + 0x4]
    mov bh, [esi + 0x14]
    add esi, 0x20
    mov [edi-0x8], eax
    dec ecx
    mov [edi-0x4], ebx
    jnz short .branch_4b6e8

.branch_4b714:
    mov eax, 0x2
    mov esi, [esp + 0x4]
    mov edi, [esp]
    out dx, al
    mov ecx, [xdim]
    inc esi
    sar ecx, byte 0x3
    shr ecx, 1
    jnc short .branch_4b747
    mov al, [esi + 0x8]
    mov ah, [esi + 0xc]
    shl eax, byte 0x10
    mov al, [esi]
    mov ah, [esi + 0x4]
    mov [edi], eax
    add esi, 0x10
    add edi, 0x4
    test ecx, ecx

.branch_4b747:
    jz short .branch_4b775

.branch_4b749:
    mov al, [esi + 0x8]
    mov bl, [esi + 0x18]
    mov ah, [esi + 0xc]
    mov bh, [esi + 0x1c]
    shl eax, byte 0x10
    add edi, 0x8
    shl ebx, byte 0x10
    mov al, [esi]
    mov bl, [esi + 0x10]
    mov ah, [esi + 0x4]
    mov bh, [esi + 0x14]
    add esi, 0x20
    mov [edi-0x8], eax
    dec ecx
    mov [edi-0x4], ebx
    jnz short .branch_4b749

.branch_4b775:
    mov eax, 0x4
    mov esi, [esp + 0x4]
    mov edi, [esp]
    out dx, al
    mov ecx, [xdim]
    add esi, 0x2
    sar ecx, byte 0x3
    shr ecx, 1
    jnc short .branch_4b7aa
    mov al, [esi + 0x8]
    mov ah, [esi + 0xc]
    shl eax, byte 0x10
    mov al, [esi]
    mov ah, [esi + 0x4]
    mov [edi], eax
    add esi, 0x10
    add edi, 0x4
    test ecx, ecx

.branch_4b7aa:
    jz short .branch_4b7d8

.branch_4b7ac:
    mov al, [esi + 0x8]
    mov bl, [esi + 0x18]
    mov ah, [esi + 0xc]
    mov bh, [esi + 0x1c]
    shl eax, byte 0x10
    add edi, 0x8
    shl ebx, byte 0x10
    mov al, [esi]
    mov bl, [esi + 0x10]
    mov ah, [esi + 0x4]
    mov bh, [esi + 0x14]
    add esi, 0x20
    mov [edi-0x8], eax
    dec ecx
    mov [edi-0x4], ebx
    jnz short .branch_4b7ac

.branch_4b7d8:
    mov eax, 0x8
    mov esi, [esp + 0x4]
    mov edi, [esp]
    out dx, al
    mov ecx, [xdim]
    add esi, 0x3
    sar ecx, byte 0x3
    shr ecx, 1
    jnc short .branch_4b80d
    mov al, [esi + 0x8]
    mov ah, [esi + 0xc]
    shl eax, byte 0x10
    mov al, [esi]
    mov ah, [esi + 0x4]
    mov [edi], eax
    add esi, 0x10
    add edi, 0x4
    test ecx, ecx

.branch_4b80d:
    jz short .branch_4b83b

.branch_4b80f:
    mov al, [esi + 0x8]
    mov bl, [esi + 0x18]
    mov ah, [esi + 0xc]
    mov bh, [esi + 0x1c]
    shl eax, byte 0x10
    add edi, 0x8
    shl ebx, byte 0x10
    mov al, [esi]
    mov bl, [esi + 0x10]
    mov ah, [esi + 0x4]
    mov bh, [esi + 0x14]
    add esi, 0x20
    mov [edi-0x8], eax
    dec ecx
    mov [edi-0x4], ebx
    jnz short .branch_4b80f

.branch_4b83b:
    mov eax, [xdim]
    mov ecx, [esp + 0x4]
    add eax, eax
    add ebp, 0x2
    add ecx, eax
    mov eax, [xdim]
    mov esi, [esp]
    sar eax, 1
    mov [esp + 0x4], ecx
    add esi, eax
    call faketimerhandler
    mov [esp], esi

.branch_4b863:
    cmp ebp, [ydim]
    jl near .branch_4b6b4
    jmp near .branch_4b95a
    mov eax, [frame_state_286b50]
    call sub_44220
    mov ebx, [skip_bank_switch]
    test ebx, ebx
    jnz short .branch_4b8b1
    mov eax, [transarea]
    mov ecx, [engine_1400c]
    shl eax, byte 0x3
    cmp eax, ecx
    setg al
    and eax, strict dword 0xff
    mov [transarea], ebx
    mov [engine_1400c], ebx
    mov [use_software_framebuffer], eax

.branch_4b8b1:
    mov ebp, [frame_state_286b50]
    inc ebp
    mov edx, [display_page_count]
    mov [frame_state_286b50], ebp
    cmp ebp, edx
    jl short .branch_4b8d0
    xor ebx, ebx
    mov [frame_state_286b50], ebx

.branch_4b8d0:
    mov eax, [frame_state_286b50]
    call select_vesa_draw_page
    jmp near .branch_4b95a
    mov ecx, 0x3e80
    mov edi, 0xa0000
    mov esi, [draw_page_address]
    rep movsd
    jmp short .branch_4b95a
    mov edx, 0x3d4
    out dx, ax
    mov eax, [frame_state_286b50]
    inc eax
    and eax, 0x3
    mov [frame_state_286b50], eax
    mov edx, [frame_state_286b50]
    shl eax, byte 0x4
    add eax, edx
    mov edx, 0x3cd
    out dx, al
    jmp short .branch_4b95a
    mov edx, 0x3d4
    out dx, ax
    mov eax, [frame_state_286b50]
    inc eax
    and eax, 0x3
    mov [frame_state_286b50], eax
    shl eax, byte 0xc
    mov edx, 0x3ce
    add eax, 0x9
    jmp short .branch_4b958
    mov edx, 0x3d4
    out dx, ax
    mov eax, [frame_state_286b50]
    inc eax
    and eax, 0x3
    mov [frame_state_286b50], eax
    shl eax, byte 0x8
    add eax, 0x35

.branch_4b958:
    out dx, ax

.branch_4b95a:
    mov ebp, [frame_state_140cf]
    jmp near .branch_4b9f7

.branch_4b965:
    mov eax, ebp
    shl eax, byte 0x3
    add eax, ebp
    shl eax, byte 0x2
    mov dl, [eax + frame_state_191763]
    and dl, 0x80
    and edx, strict dword 0xff
    jz short .branch_4b9f0
    mov dl, [eax + frame_state_191763]
    and dl, 0x7f
    and edx, strict dword 0xff
    cmp edx, 0x2
    jl short .branch_4b9f0
    mov edx, [eax + frame_state_191770]
    push edx
    mov ebx, [eax + frame_state_19176c]
    push ebx
    mov ecx, [eax + frame_state_191768]
    push ecx
    mov esi, [eax + frame_state_191764]
    xor edx, edx
    push esi
    mov dl, [eax + frame_state_191762]
    push edx
    xor edx, edx
    mov dl, [eax + frame_state_191761]
    push edx
    movsx edx, byte [eax + frame_state_191760]
    mov ebx, [eax + frame_state_191758]
    push edx
    movsx edx, word [eax + frame_state_19175e]
    movsx ecx, word [eax + frame_state_19175c]
    push edx
    mov edx, [eax + frame_state_191754]
    mov eax, [eax + permanent_sprite_queue]
    call draw_rotated_sprite

.branch_4b9f0:
    inc ebp
    and ebp, strict dword 0x1ff

.branch_4b9f7:
    cmp ebp, [permanent_sprite_tail]
    jnz near .branch_4b965
    mov ebp, [frame_state_140cf]
    mov edi, [permanent_sprite_tail]
    jmp short .branch_4ba66

.branch_4ba11:
    mov eax, ebp
    shl eax, byte 0x3
    add eax, ebp
    shl eax, byte 0x2
    mov dl, [eax + frame_state_191763]
    and dl, 0x7f
    and edx, strict dword 0xff
    test edx, edx
    jng short .branch_4ba34
    dec byte [eax + frame_state_191763]

.branch_4ba34:
    mov eax, ebp
    shl eax, byte 0x3
    add eax, ebp
    mov al, [nosplit eax*4 + frame_state_191763]
    and al, 0x7f
    and eax, strict dword 0xff
    jnz short .branch_4ba5f
    mov eax, [frame_state_140cf]
    cmp ebp, eax
    jnz short .branch_4ba5f
    inc eax
    and eax, strict dword 0x1ff
    mov [frame_state_140cf], eax

.branch_4ba5f:
    inc ebp
    and ebp, strict dword 0x1ff

.branch_4ba66:
    cmp ebp, edi
    jnz short .branch_4ba11
    jmp short .branch_4babb

.branch_4ba6c:
    mov eax, edx
    mov edx, 0x3d4
    out dx, ax
    mov dx, 0x3da

.branch_4ba79:
    in al, dx
    test al, 0x8
    jnz short .branch_4ba79

.branch_4ba7e:
    in al, dx
    test al, 0x8
    jz short .branch_4ba7e
    mov eax, 0x37000
    mov ebx, [pageoffset]
    sub eax, ebx
    jmp short .branch_4bab6

.branch_4ba92:
    mov eax, edx
    mov edx, 0x3d4
    out dx, ax
    mov dx, 0x3da

.branch_4ba9f:
    in al, dx
    test al, 0x8
    jnz short .branch_4ba9f

.branch_4baa4:
    in al, dx
    test al, 0x8
    jz short .branch_4baa4
    mov eax, 0x61800
    mov edx, [pageoffset]
    sub eax, edx

.branch_4bab6:
    mov [pageoffset], eax

.branch_4babb:
    call faketimerhandler
    mov eax, [frame_state_286b34]
    add eax, 0x8
    cmp eax, [totalclock]
    jng short .branch_4badd
    mov eax, [totalclock]
    cmp eax, [frame_state_286b34]
    jnl short .branch_4baec

.branch_4badd:
    mov eax, [totalclock]
    mov [frame_state_286b34], eax
    call sub_40f2d

.branch_4baec:
    mov ecx, 0x1
    mov esi, [save_state_287e74]
    add esi, ecx
    mov [new_frame_flag], ecx
    mov [save_state_287e74], esi
    add esp, 0x8
    jmp near restore_ebp_edi_esi_edx_ecx_ebx

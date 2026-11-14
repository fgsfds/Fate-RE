; Save renderer state and redirect the view into a tile.
BITS 32
ORG 0x5d2f4

tilesizx equ 0x1f2020
view_stack_depth equ 0x14190
tilesizy equ 0x1f4020
saved_tile_width equ 0x190300
saved_tile_height equ 0x190310
stereo_mode equ 0x14004
saved_stereo_mode equ 0x1902d0
chainstat equ 0x14003
saved_chainstat equ 0x190340
video_backend equ 0x2891db
saved_video_backend equ 0x190320
waloff equ 0x1ffca0
frameplace equ 0x286b74
window_left equ 0x286b9c
saved_startumost equ 0x1a31e0
saved_window_left equ 0x1902f0
window_top equ 0x286b94
saved_window_top equ 0x1902c0
window_right equ 0x286b98
saved_window_right equ 0x1902e0
window_bottom equ 0x286b90
saved_frameplace equ 0x190330
saved_window_bottom equ 0x190350
startumost equ 0x1f13a0
saved_startdmost equ 0x1a7060
startdmost equ 0x1f8020
ylookup equ 0x286bb0
setview equ 0x56f0a
setaspect equ 0x5708a
setvlinebpl equ 0x74090
setviewtotile_restore equ 0x54374

setviewtotile_:
    push ecx
    push esi
    push edi
    push ebp
    push edx
    push ebx
    movsx edx, ax
    mov ebx, dword [esp + 4]
    mov word [nosplit edx*2 + tilesizx], bx
    mov ebx, dword [esp]
    mov eax, dword [view_stack_depth]
    mov word [nosplit edx*2 + tilesizy], bx
    mov ebx, dword [esp + 4]
    mov dword [eax*4 + saved_tile_width], ebx
    mov ebx, dword [esp]
    mov dword [eax*4 + saved_tile_height], ebx
    mov ebx, dword [stereo_mode]
    mov dword [eax*4 + saved_stereo_mode], ebx
    xor ebx, ebx
    mov dword [stereo_mode], ebx
    mov bl, byte [chainstat]
    mov dword [eax*4 + saved_chainstat], ebx
    xor bl, bl
    mov byte [chainstat], bl
    xor ebx, ebx
    mov bl, byte [video_backend]
    mov dword [eax*4 + saved_video_backend], ebx
    mov bh, 2
    mov edx, dword [edx*4 + waloff]
    mov byte [video_backend], bh
    mov ebx, dword [frameplace]
    mov dword [frameplace], edx
    mov edx, dword [window_left]
    mov edi, saved_startumost
    mov dword [eax*4 + saved_window_left], edx
    mov edx, dword [window_top]
    mov ecx, dword [window_left]
    mov dword [eax*4 + saved_window_top], edx
    mov edx, dword [window_right]
    mov esi, dword [window_left]
    mov dword [eax*4 + saved_window_right], edx
    mov edx, dword [window_bottom]
    mov dword [eax*4 + saved_frameplace], ebx
    mov dword [eax*4 + saved_window_bottom], edx
    mov eax, dword [window_right]
    add esi, esi
    sub eax, ecx
    add edi, esi
    add eax, eax
    add esi, startumost
    lea ecx, [eax + 2]
    mov ebx, dword [esp]
    test cl, 1
    je short .copy_upper_words
    movsb

.copy_upper_words:
    shr ecx, 2
    jae short .copy_upper_dwords
    movsw

.copy_upper_dwords:
    rep movsd
    mov eax, dword [window_right]
    mov esi, dword [window_left]
    dec ebx
    sub eax, esi
    mov edi, saved_startdmost
    add eax, eax
    add esi, esi
    lea ecx, [eax + 2]
    add edi, esi
    add esi, startdmost
    xor edx, edx
    test cl, 1
    je short .copy_lower_words
    movsb

.copy_lower_words:
    shr ecx, 2
    jae short .copy_lower_dwords
    movsw

.copy_lower_dwords:
    rep movsd
    mov ecx, dword [esp + 4]
    xor eax, eax
    dec ecx
    mov ebp, dword [esp]
    call setview
    mov eax, 0x10000
    mov edi, dword [esp + 4]
    call setaspect
    xor edx, edx
    xor eax, eax
    jmp short .check_tile_row

.write_tile_row_offset:
    mov dword [eax*4 + ylookup], edx
    inc eax
    add edx, ebp

.check_tile_row:
    cmp eax, edi
    jle short .write_tile_row_offset
    mov eax, dword [esp]
    call setvlinebpl
    inc dword [view_stack_depth]
    jmp near setviewtotile_restore

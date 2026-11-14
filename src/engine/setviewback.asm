; Restore the preceding view and rebuild its row offsets.
BITS 32
ORG 0x5d46d

view_stack_depth equ 0x14190
saved_window_bottom equ 0x190350
saved_window_right equ 0x1902e0
saved_window_top equ 0x1902c0
saved_window_left equ 0x1902f0
window_right equ 0x286b98
window_left equ 0x286b9c
startumost equ 0x1f13a0
saved_startumost equ 0x1a31e0
startdmost equ 0x1f8020
saved_startdmost equ 0x1a7060
saved_stereo_mode equ 0x1902d0
stereo_mode equ 0x14004
saved_chainstat equ 0x190340
chainstat equ 0x14003
saved_video_backend equ 0x190320
saved_frameplace equ 0x190330
video_backend equ 0x2891db
frameplace equ 0x286b74
saved_tile_width equ 0x190300
bytesperline equ 0x286b64
ylookup equ 0x286bb0
setviewback_restore equ 0x4abbe
setview equ 0x56f0a
setvlinebpl equ 0x74090

setviewback_:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov edx, dword [view_stack_depth]
    test edx, edx
    jle near setviewback_restore
    lea ebx, [edx - 1]
    mov dword [view_stack_depth], ebx
    mov eax, ebx
    mov ecx, dword [ebx*4 + saved_window_bottom]
    mov ebx, dword [ebx*4 + saved_window_right]
    mov edx, dword [eax*4 + saved_window_top]
    mov eax, dword [eax*4 + saved_window_left]
    call setview
    mov eax, dword [window_right]
    sub eax, dword [window_left]
    add eax, eax
    lea ecx, [eax + 2]
    mov eax, dword [window_left]
    mov edi, startumost
    add eax, eax
    mov esi, saved_startumost
    add edi, eax
    add esi, eax
    test cl, 1
    je short .restore_upper_words
    movsb

.restore_upper_words:
    shr ecx, 2
    jae short .restore_upper_dwords
    movsw

.restore_upper_dwords:
    rep movsd
    mov ecx, dword [window_right]
    mov esi, dword [window_left]
    mov edi, startdmost
    sub ecx, esi
    lea eax, [esi + esi]
    add ecx, ecx
    mov esi, saved_startdmost
    add ecx, 2
    add edi, eax
    add esi, eax
    test cl, 1
    je short .restore_lower_words
    movsb

.restore_lower_words:
    shr ecx, 2
    jae short .restore_lower_dwords
    movsw

.restore_lower_dwords:
    rep movsd
    mov eax, dword [view_stack_depth]
    mov edx, dword [eax*4 + saved_stereo_mode]
    mov dword [stereo_mode], edx
    mov dl, byte [eax*4 + saved_chainstat]
    mov edi, dword [view_stack_depth]
    mov byte [chainstat], dl
    mov dl, byte [eax*4 + saved_video_backend]
    mov eax, dword [eax*4 + saved_frameplace]
    mov byte [video_backend], dl
    mov dword [frameplace], eax
    test edi, edi
    jne short .compare_nested_tile_widths
    mov ecx, dword [saved_tile_width]
    jmp short .restore_row_offsets

.compare_nested_tile_widths:
    mov eax, edi
    shl eax, 2
    mov edx, dword [eax + saved_tile_width - 4]
    mov ebp, dword [eax + saved_tile_width]
    cmp edx, ebp
    jle short .use_current_tile_width
    mov ecx, edx
    jmp short .restore_row_offsets

.use_current_tile_width:
    mov ecx, ebp

.restore_row_offsets:
    mov ebx, dword [bytesperline]
    xor edx, edx
    xor eax, eax
    jmp short .check_row

.write_row_offset:
    mov dword [eax*4 + ylookup], edx
    inc eax
    add edx, ebx

.check_row:
    cmp eax, ecx
    jle short .write_row_offset
    mov eax, dword [bytesperline]
    call setvlinebpl
    jmp near setviewback_restore

; Draw horizontal spans through the active device and classify clipped points.
BITS 32
ORG 0x735c4

graphics_error equ 0x16c66
drawing_color equ 0x16c80
fill_pattern equ 0x16c84
fill_pattern_enabled equ 0x16c94
pattern_origin_x equ 0x16c97
pattern_origin_y equ 0x16c99
screen_address equ 0x2891ec
drawing_action equ 0x2891f6
graphics_device equ 0x289212
clip_left equ 0x289216
clip_right equ 0x289218
clip_top equ 0x28921a
clip_bottom equ 0x28921c

draw_graphics_span:
    push ecx
    push esi
    push edi
    push es
    enter 4, 0
    push ebx
    test bx, bx
    jle near .done
    mov ecx, dword [graphics_device]
    movsx ebx, word [drawing_color]
    movsx edi, ax
    movsx esi, dx
    mov eax, edi
    mov edx, esi
    call dword [ecx + 0x10]
    cmp byte [fill_pattern_enabled], 0
    jne short .patterned
    movsx edx, word [drawing_action]
    mov eax, dword [ecx + 0x38]
    xor ebx, ebx
    movsx ecx, word [ebp - 8]
    mov dword [ebp - 4], eax
    shl edx, 8
    jmp short .draw
.patterned:
    movsx eax, word [pattern_origin_x]
    sub edi, eax
    mov eax, edi
    cdq
    xor eax, edx
    sub eax, edx
    mov ebx, eax
    xor bh, ah
    movsx eax, word [pattern_origin_y]
    and bl, 7
    sub esi, eax
    movsx ebx, bx
    mov eax, esi
    shl ebx, 8
    cdq
    xor eax, edx
    sub eax, edx
    movsx esi, word [ebp - 8]
    and al, 7
    mov edx, dword [ecx + 0x3c]
    xor ah, ah
    mov dword [ebp - 4], edx
    movsx ecx, ax
    movsx edx, word [drawing_action]
    movzx eax, byte [ecx + fill_pattern]
    shl edx, 8
    mov ecx, esi
    add ebx, eax
.draw:
    movsx eax, word [drawing_color]
    les edi, [screen_address]
    call dword [ebp - 4]
.done:
    leave
    pop es
    pop edi
    pop esi
    pop ecx
    ret

draw_clipped_graphics_span:
    push ecx
    mov ecx, ebx
    cmp bx, word [clip_top]
    jl short .done
    cmp bx, word [clip_bottom]
    jg short .done
    cmp ax, word [clip_left]
    jge short .clamp_right
    mov ax, word [clip_left]
.clamp_right:
    cmp dx, word [clip_right]
    jle short .draw
    mov dx, word [clip_right]
.draw:
    sub edx, eax
    inc edx
    cwde
    movsx ebx, dx
    movsx edx, cx
    call draw_graphics_span
.done:
    pop ecx
    ret

graphics_point_outcode:
    push ebx
    mov ebx, eax
    xor al, al
    cmp bx, word [clip_left]
    jge short .check_right
    mov al, 8
    jmp short .check_top
.check_right:
    cmp bx, word [clip_right]
    jle short .check_top
    mov al, 4
.check_top:
    cmp dx, word [clip_top]
    jge short .check_bottom
    or al, 1
    jmp short .publish
.check_bottom:
    cmp dx, word [clip_bottom]
    jle short .publish
    or al, 2
.publish:
    test al, al
    je short .done
    mov word [graphics_error], 2
.done:
    pop ebx
    ret

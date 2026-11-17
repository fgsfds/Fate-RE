; Draw horizontal spans through the active device.
BITS 32
ORG 0x735c4

drawing_color equ 0x16c80
fill_pattern equ 0x16c84
fill_pattern_enabled equ 0x16c94
pattern_origin_x equ 0x16c97
pattern_origin_y equ 0x16c99
screen_address equ 0x2891ec
drawing_action equ 0x2891f6
graphics_device equ 0x289212

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

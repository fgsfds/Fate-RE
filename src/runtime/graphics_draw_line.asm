; Clip and draw solid or patterned lines using the active graphics device.
BITS 32
ORG 0x71c23

clip_graphics_line equ 0x7376b
begin_graphics_device equ 0x70052
end_graphics_device equ 0x7005b
execute_graphics_line_kernel equ 0x73988
drawing_color equ 0x16c80
line_pattern equ 0x16c9b
graphics_device equ 0x289212
drawing_action equ 0x16c9f
screen_pixel_mask equ 0x2891f2
screen_pixel_shift equ 0x2891f4
screen_selector equ 0x2891f0
screen_address equ 0x2891ec

draw_clipped_solid_line:
    push ebp
    mov ebp, esp
    push eax
    push edx
    push ebx
    push ecx
    lea eax, [ebp - 4]
    lea edx, [ebp - 8]
    lea ebx, [ebp - 0xc]
    lea ecx, [ebp - 0x10]
    call clip_graphics_line
    test ax, ax
    jne short .done
    push strict dword 0xffff
    movsx ecx, word [ebp - 0x10]
    movsx ebx, word [ebp - 0xc]
    movsx eax, word [drawing_color]
    movsx edx, word [ebp - 8]
    push eax
    movsx eax, word [ebp - 4]
    call dispatch_device_line
.done:
    leave
    ret

draw_clipped_patterned_line:
    push esi
    push edi
    enter 4, 0
    push eax
    push edx
    push ebx
    push ecx
    lea ebx, [ebp - 0x10]
    lea ecx, [ebp - 0x14]
    mov dword [ebp - 4], eax
    mov edi, edx
    lea eax, [ebp - 8]
    lea edx, [ebp - 0xc]
    mov si, word [line_pattern]
    call clip_graphics_line
    test ax, ax
    jne near .rejected
    cmp si, -1
    je short .draw
    mov eax, dword [ebp - 8]
    cmp ax, word [ebp - 4]
    jne short .adjust_phase
    cmp di, word [ebp - 0xc]
    je short .draw
.adjust_phase:
    movsx edx, word [ebp - 8]
    movsx eax, word [ebp - 4]
    sub edx, eax
    mov eax, edx
    cdq
    xor eax, edx
    sub eax, edx
    mov ebx, eax
    mov ecx, eax
    movsx edx, di
    movsx eax, word [ebp - 0xc]
    sub eax, edx
    cdq
    xor eax, edx
    sub eax, edx
    cmp bx, ax
    jge short .rotate_pattern
    mov ecx, eax
.rotate_pattern:
    and cl, 0xf
    mov eax, esi
    xor ch, ch
    rol ax, cl
    mov esi, eax
.draw:
    movsx ecx, word [ebp - 0x14]
    movzx eax, si
    movsx ebx, word [ebp - 0x10]
    push eax
    movsx eax, word [drawing_color]
    movsx edx, word [ebp - 0xc]
    push eax
    movsx eax, word [ebp - 8]
    call dispatch_device_line
    mov eax, 1
    leave
    pop edi
    pop esi
    ret
.rejected:
    xor eax, eax
    leave
    pop edi
    pop esi
    ret

dispatch_device_line:
    push esi
    push edi
    enter 0x10, 0
    mov edi, eax
    mov dword [ebp - 0x10], edx
    mov dword [ebp - 4], ebx
    mov dword [ebp - 0xc], ecx
    call begin_graphics_device
    movsx ebx, word [ebp + 0x10]
    mov ecx, dword [graphics_device]
    movsx eax, word [drawing_action]
    movsx edx, dx
    mov esi, dword [ecx + eax*4 + 0x24]
    movsx eax, di
    call dword [ecx + 0x10]
    mov edx, dword [ebp - 4]
    sub edx, edi
    test dx, dx
    jge short .positive_x
    neg edx
    mov eax, dword [ecx + 0x18]
    jmp short .choose_y_step
.positive_x:
    mov eax, dword [ecx + 0x20]
.choose_y_step:
    mov ebx, dword [ebp - 0xc]
    sub ebx, dword [ebp - 0x10]
    test bx, bx
    jge short .positive_y
    neg ebx
    mov ecx, dword [ecx + 0x14]
    jmp short .double_deltas
.positive_y:
    mov ecx, dword [ecx + 0x1c]
.double_deltas:
    mov edi, ebx
    add edi, ebx
    mov dword [ebp - 8], edi
    mov edi, edx
    add edi, edx
    cmp dx, bx
    jge short .x_major
    push esi
    push eax
    push ecx
    movsx eax, di
    push eax
    movsx eax, word [ebp - 8]
    jmp short .draw
.x_major:
    push esi
    push ecx
    push eax
    movsx eax, word [ebp - 8]
    push eax
    movsx eax, di
.draw:
    movsx ebx, word [screen_pixel_mask]
    push eax
    movsx eax, word [screen_pixel_shift]
    mov dx, word [screen_selector]
    push eax
    movsx ecx, word [ebp + 0x14]
    mov eax, dword [screen_address]
    call execute_graphics_line_kernel
    call end_graphics_device
    leave
    pop edi
    pop esi
    ret 8

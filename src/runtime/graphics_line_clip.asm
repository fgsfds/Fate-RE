; Clip general and axis-aligned lines against the active graphics rectangle.
BITS 32
ORG 0x73703

graphics_point_outcode equ 0x736bf

clip_left equ 0x289216
clip_right equ 0x289218
clip_top equ 0x28921a
clip_bottom equ 0x28921c

intersect_clip_edge:
    push esi
    push edi
    enter 0xc, 0
    mov esi, eax
    mov edi, edx
    mov dword [ebp - 4], ecx
    mov eax, ebx
    cwde
    movsx ebx, word [esi]
    sub eax, ebx
    cdq
    xor eax, edx
    sub eax, edx
    movsx edx, word [ebp - 4]
    mov ebx, eax
    mov ecx, eax
    movsx eax, word [edi]
    sub edx, eax
    lea eax, [edx + edx]
    mov dword [ebp - 8], eax
    movsx eax, word [esi]
    mov dword [ebp - 0xc], eax
    movsx eax, word [ebp + 0x10]
    sub eax, dword [ebp - 0xc]
    cdq
    xor eax, edx
    sub eax, edx
    imul eax, dword [ebp - 8]
    test eax, eax
    jle short .round_negative
    add eax, ebx
    jmp short .divide
.round_negative:
    sub eax, ebx
.divide:
    cdq
    add ecx, ecx
    idiv ecx
    mov ebx, eax
    movsx eax, word [edi]
    add eax, ebx
    mov word [edi], ax
    mov eax, dword [ebp + 0x10]
    mov word [esi], ax
    leave
    pop edi
    pop esi
    ret 4

clip_graphics_line:
    push esi
    push edi
    enter 0x10, 0
    mov esi, eax
    mov edi, edx
    mov dword [ebp - 0x10], ebx
    mov dword [ebp - 0xc], ecx
    movsx edx, word [edx]
    movsx eax, word [eax]
    call graphics_point_outcode
    mov byte [ebp - 4], al
    movsx edx, word [ecx]
    movsx eax, word [ebx]
.classify_second:
    call graphics_point_outcode
    mov byte [ebp - 8], al
.compare_outcodes:
    movzx edx, byte [ebp - 4]
    movzx eax, byte [ebp - 8]
    test edx, eax
    jne near .result
    mov al, byte [ebp - 4]
    cmp al, byte [ebp - 8]
    je near .result
    test al, al
    jne near .adjust_first
    test byte [ebp - 8], 1
    je short .second_bottom
    mov edx, dword [ebp - 0x10]
    movsx eax, word [clip_top]
.prepare_second_horizontal_edge:
    movsx ecx, word [esi]
    push eax
    movsx ebx, word [edi]
    mov eax, dword [ebp - 0xc]
    jmp short .intersect_second
.second_bottom:
    test byte [ebp - 8], 2
    je short .second_right
    mov edx, dword [ebp - 0x10]
    movsx eax, word [clip_bottom]
    jmp short .prepare_second_horizontal_edge
.second_right:
    test byte [ebp - 8], 4
    je short .second_left
    mov edx, dword [ebp - 0xc]
    movsx eax, word [clip_right]
    movsx ecx, word [edi]
    push eax
    movsx ebx, word [esi]
    mov eax, dword [ebp - 0x10]
    jmp short .intersect_second
.second_left:
    test byte [ebp - 8], 8
    je short .refresh_second
    mov edx, dword [ebp - 0xc]
    movsx eax, word [clip_left]
    movsx ecx, word [edi]
    push eax
    movsx ebx, word [esi]
    mov eax, dword [ebp - 0x10]
.intersect_second:
    call intersect_clip_edge
.refresh_second:
    mov edx, dword [ebp - 0xc]
    mov eax, dword [ebp - 0x10]
    movsx edx, word [edx]
    movsx eax, word [eax]
    jmp near .classify_second
.adjust_first:
    test al, 1
    je short .first_bottom
    mov ecx, dword [ebp - 0x10]
    mov ebx, dword [ebp - 0xc]
    movsx eax, word [clip_top]
.prepare_first_horizontal_edge:
    mov edx, esi
    push eax
    movsx ecx, word [ecx]
    movsx ebx, word [ebx]
    mov eax, edi
    jmp short .intersect_first
.first_bottom:
    test al, 2
    je short .first_right
    mov ecx, dword [ebp - 0x10]
    mov ebx, dword [ebp - 0xc]
    movsx eax, word [clip_bottom]
    jmp short .prepare_first_horizontal_edge
.first_right:
    test al, 4
    je short .first_left
    mov ecx, dword [ebp - 0xc]
    mov ebx, dword [ebp - 0x10]
    movsx eax, word [clip_right]
    mov edx, edi
    push eax
    movsx ecx, word [ecx]
    movsx ebx, word [ebx]
    mov eax, esi
    jmp short .intersect_first
.first_left:
    test al, 8
    je short .refresh_first
    mov ecx, dword [ebp - 0xc]
    mov ebx, dword [ebp - 0x10]
    movsx eax, word [clip_left]
    mov edx, edi
    push eax
    movsx ecx, word [ecx]
    movsx ebx, word [ebx]
    mov eax, esi
.intersect_first:
    call intersect_clip_edge
.refresh_first:
    movsx edx, word [edi]
    movsx eax, word [esi]
    call graphics_point_outcode
    mov byte [ebp - 4], al
    jmp near .compare_outcodes
.result:
    movzx ax, byte [ebp - 4]
    movzx dx, byte [ebp - 8]
.return_outcode:
    and eax, edx
    leave
    pop edi
    pop esi
    ret

clamp_point_edge:
    test bl, 1
    je short .bottom
    mov ax, word [clip_top]
    mov word [edx], ax
    ret
.bottom:
    test bl, 2
    je short .right
    mov ax, word [clip_bottom]
    mov word [edx], ax
    ret
.right:
    test bl, 4
    je short .left
    mov dx, word [clip_right]
    mov word [eax], dx
    ret
.left:
    test bl, 8
    je short .done
    mov dx, word [clip_left]
    mov word [eax], dx
.done:
    ret

clip_axis_aligned_line:
    push esi
    push edi
    enter 0xc, 0
    push eax
    mov esi, edx
    mov edi, ebx
    movsx eax, word [eax]
    movsx edx, word [edx]
    call graphics_point_outcode
    mov byte [ebp - 8], al
    movsx edx, word [ecx]
    movsx eax, word [ebx]
.classify_second:
    call graphics_point_outcode
    mov byte [ebp - 4], al
.compare_outcodes:
    movzx eax, byte [ebp - 8]
    movzx ebx, byte [ebp - 4]
    mov dword [ebp - 0xc], eax
    test ebx, eax
    jne short .result
    mov al, byte [ebp - 8]
    cmp al, byte [ebp - 4]
    je short .result
    test al, al
    jne short .adjust_first
    mov eax, edi
    mov edx, ecx
    call clamp_point_edge
    movsx edx, word [ecx]
    movsx eax, word [edi]
    jmp short .classify_second
.adjust_first:
    mov eax, dword [ebp - 0x10]
    mov ebx, dword [ebp - 0xc]
    mov edx, esi
    call clamp_point_edge
    mov eax, dword [ebp - 0x10]
    movsx eax, word [eax]
    movsx edx, word [esi]
    call graphics_point_outcode
    mov byte [ebp - 8], al
    jmp short .compare_outcodes
.result:
    movzx ax, byte [ebp - 8]
    movzx dx, byte [ebp - 4]
    jmp near clip_graphics_line.return_outcode

; Assemble and execute the device line fragments in a stack buffer.
BITS 32
ORG 0x73988

graphics_error equ 0x16c66
graphics_stack_limit equ 0x71b86

execute_graphics_line_kernel:
    push esi
    push edi
    push es
    enter 0x28, 0
    mov esi, dword [ebp + 0x28]
    mov dword [ebp - 0x10], edx
    mov dword [ebp - 0x1c], eax
    mov dword [ebp - 0x18], ebx
    mov dword [ebp - 0x14], ecx
    mov al, byte [esi - 1]
    mov byte [ebp - 4], al
    mov eax, dword [ebp + 0x24]
    mov al, byte [eax - 1]
    mov byte [ebp - 0xc], al
    mov eax, dword [ebp + 0x20]
    mov al, byte [eax - 1]
    movzx dx, byte [ebp - 0xc]
    mov byte [ebp - 8], al
    movzx ax, byte [ebp - 4]
    add edx, eax
    movzx ax, byte [ebp - 8]
    add eax, edx
    add eax, strict dword 0x1c
    and al, 0xfc
    mov edx, eax
    mov eax, esp
    mov ebx, eax
    call graphics_stack_limit
    sub ebx, eax
    movsx eax, dx
    sub ebx, eax
    cmp ebx, 0x100
    ja short .allocate
    mov word [graphics_error], 0xfffb
    jmp near .done
.allocate:
    add eax, 3
    and al, 0xfc
    sub esp, eax
    mov eax, esp
    movsx ecx, cx
    mov ebx, esp
    mov dword [ebp - 0x24], eax
    mov dword [ebp - 0x28], eax
    cmp ecx, -1
    je short .copy_plot_fragment
    lea ebx, [eax + 1]
    mov byte [eax], 0x66
    mov byte [ebx], 0xd1
    inc ebx
    mov byte [ebx], 0xc3
    inc ebx
    mov byte [ebx], 0x73
    inc ebx
    mov al, byte [ebp - 4]
    mov byte [ebx], al
    inc ebx
.copy_plot_fragment:
    movzx eax, byte [ebp - 4]
    mov edx, ds
    mov dword [ebp - 0x20], eax
    mov eax, ebx
    movzx ecx, dx
    mov eax, esi
    mov edx, cs
    mov edi, ebx
    movzx eax, dx
    mov edx, ecx
    mov ecx, dword [ebp - 0x20]
    add ebx, dword [ebp - 0x20]
    push ds
    push es
    mov ds, eax
    mov es, edx
    mov eax, ecx
    shr ecx, 2
    repne movsd
    db 0x8a, 0xc8 ; mov cl, al, register-destination encoding.
    and cl, 3
    repne movsb
    pop es
    pop ds
    mov al, byte [ebp - 8]
    mov byte [ebx], 0x4a
    inc ebx
    add al, byte [ebp - 0xc]
    mov byte [ebx], 0x7c
    inc ebx
    add al, 0x10
    mov edx, ds
    mov byte [ebx], al
    movzx eax, byte [ebp - 8]
    inc ebx
    mov dword [ebp - 0x20], eax
    mov eax, ebx
    mov esi, dword [ebp + 0x20]
    mov eax, dword [ebp + 0x20]
    movzx ecx, dx
    mov edx, cs
    mov edi, ebx
    movzx eax, dx
    mov edx, ecx
    mov ecx, dword [ebp - 0x20]
    add ebx, dword [ebp - 0x20]
    push ds
    push es
    mov ds, eax
    mov es, edx
    mov eax, ecx
    shr ecx, 2
    repne movsd
    db 0x8a, 0xc8 ; mov cl, al, register-destination encoding.
    and cl, 3
    repne movsb
    pop es
    pop ds
    mov byte [ebx], 0x81
    inc ebx
    mov byte [ebx], 0xee
    inc ebx
    movsx eax, word [ebp + 0x1c]
    mov dword [ebx], eax
    add ebx, 4
    mov al, byte [ebp - 0x28]
    mov byte [ebx], 0x7f
    inc ebx
    sub al, bl
    dec al
    mov byte [ebx], al
    inc ebx
    mov byte [ebx], 0x81
    inc ebx
    mov byte [ebx], 0xc6
    inc ebx
    movsx eax, word [ebp + 0x18]
    mov edx, ds
    mov dword [ebx], eax
    movzx eax, byte [ebp - 0xc]
    add ebx, 4
    mov dword [ebp - 0x20], eax
    mov eax, ebx
    mov esi, dword [ebp + 0x24]
    mov eax, dword [ebp + 0x24]
    movzx ecx, dx
    mov edx, cs
    mov edi, ebx
    movzx eax, dx
    mov edx, ecx
    mov ecx, dword [ebp - 0x20]
    add ebx, dword [ebp - 0x20]
    push ds
    push es
    mov ds, eax
    mov es, edx
    mov eax, ecx
    shr ecx, 2
    repne movsd
    db 0x8a, 0xc8 ; mov cl, al, register-destination encoding.
    and cl, 3
    repne movsb
    pop es
    pop ds
    mov al, byte [ebp - 0x28]
    movsx esi, word [ebp + 0x18]
    movsx ecx, word [ebp + 0x14]
    mov byte [ebx], 0xeb
    inc ebx
    mov edi, dword [ebp - 0x1c]
    sub al, bl
    sar esi, 1
    dec al
    mov edx, esi
    mov byte [ebx], al
    inc ebx
    movsx eax, word [ebp - 0x18]
    mov byte [ebx], 0xc3
    movsx ebx, word [ebp - 0x14]
    mov es, word [ebp - 0x10]
    call dword [ebp - 0x24]
.done:
    leave
    pop es
    pop edi
    pop esi
    ret 0x18

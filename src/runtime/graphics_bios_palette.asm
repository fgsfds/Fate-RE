; Marshal RGB entries and call the BIOS using a conventional-memory buffer.
BITS 32
ORG 0x72cbd

dos_extender_type equ 0x1449a
memset_ equ 0x61350

upload_bios_palette:
    push ebx
    push ecx
    push esi
    push edi
    push es
    push fs
    enter 0x10, 0
    mov ecx, eax
    mov esi, edx
    movsx eax, dx
    lea edx, [ebp - 0x10]
    lea eax, [eax + eax*2]
    call allocate_graphics_dos_buffer
    test ax, ax
    je near .done
    lfs eax, [ebp - 0xe]
    xor edi, edi
    mov dword [ebp - 4], eax
    jmp short .check_count
.copy_color:
    mov edx, dword [ecx]
    mov eax, edx
    and eax, 0xff0000
    shr eax, 0x10
    mov dword [ebp - 8], eax
    movsx eax, di
    lea eax, [eax + eax*2]
    push fs
    pop es
    add eax, dword [ebp - 4]
    mov bl, byte [ebp - 8]
    mov byte es:[eax + 2], bl
    mov ebx, edx
    xor bl, dl
    movzx ebx, bx
    sar ebx, 8
    add ecx, 4
    mov dword [ebp - 8], ebx
    mov byte es:[eax], dl
    mov dh, byte [ebp - 8]
    inc edi
    mov byte es:[eax + 1], dh
.check_count:
    cmp di, si
    jl short .copy_color
    push 0
    movsx eax, word [ebp - 0x10]
    mov edx, 0x1012
    push eax
    movsx ecx, si
    push 0
    xor ebx, ebx
    mov eax, 0x10
    call call_graphics_real_mode_interrupt
    lea eax, [ebp - 0x10]
    call free_graphics_dos_buffer
    mov eax, 1
.done:
    leave
    pop fs
    pop es
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

allocate_graphics_dos_buffer:
    push ebx
    push ecx
    mov ecx, edx
    add eax, 0xf
    cdq
    shl edx, 4
    db 0x1b, 0xc2 ; sbb eax, edx, register-destination encoding.
    sar eax, 4
    cmp byte [dos_extender_type], 1
    jne short .dos_extender
    mov ebx, eax
    mov ax, 0x100
    int 0x31
    jae short .pack_dpmi_result
    sub ax, ax
    sub dx, dx
.pack_dpmi_result:
    shl eax, 0x10
    mov ax, dx
    mov edx, eax
    test eax, eax
    je short .failure
    mov dword [ecx + 2], 0
    shr edx, 0x10
    mov word [ecx + 6], ax
    mov eax, 1
    mov word [ecx], dx
    pop ecx
    pop ebx
    ret
.dos_extender:
    cmp byte [dos_extender_type], 2
    jb short .failure
    cmp byte [dos_extender_type], 8
    ja short .failure
    mov ebx, eax
    mov ax, 0x25c0
    int 0x21
    jae short .check_segment
    sub ax, ax
.check_segment:
    test ax, ax
    je short .done
    mov word [ecx], ax
    movzx eax, ax
    mov word [ecx + 6], 0x34
    shl eax, 4
    mov dword [ecx + 2], eax
    mov eax, 1
    pop ecx
    pop ebx
    ret
.failure:
    xor eax, eax
.done:
    pop ecx
    pop ebx
    ret

free_graphics_dos_buffer:
    push ebx
    push ecx
    push edx
    cmp byte [dos_extender_type], 1
    jne short .dos_extender
    mov dx, word [eax + 6]
    mov eax, dword [eax + 2]
    mov ebx, edx
    mov ax, 0x101
    int 0x31
    pop edx
    pop ecx
    pop ebx
    ret
.dos_extender:
    mov cx, word [eax]
    mov ax, 0x25c1
    int 0x21
    pop edx
    pop ecx
    pop ebx
    ret

call_graphics_real_mode_interrupt:
    push esi
    push edi
    push es
    push fs
    enter 0x48, 0
    push eax
    mov edi, edx
    mov esi, ebx
    cmp byte [dos_extender_type], 1
    jne short .dos_extender
    lea eax, [ebp - 0x48]
    mov ebx, 0x32
    xor edx, edx
    call memset_
    movsx eax, di
    mov dword [ebp - 0x2c], eax
    movsx eax, si
    mov bl, byte [ebp - 0x4c]
    mov dword [ebp - 0x38], eax
    movsx eax, cx
    push ds
    pop es
    mov dword [ebp - 0x30], eax
    movsx eax, word [ebp + 0x18]
    xor bh, bh
    mov dword [ebp - 0x34], eax
    mov eax, dword [ebp + 0x1c]
    lea edi, [ebp - 0x48]
    mov word [ebp - 0x26], ax
    movsx eax, word [ebp + 0x20]
    xor ecx, ecx
    mov dword [ebp - 0x48], eax
    mov ax, 0x300
    int 0x31
    mov eax, dword [ebp - 0x2c]
    jmp short .done
.dos_extender:
    lea eax, [ebp - 0x14]
    mov ebx, 0x12
    xor edx, edx
    call memset_
    movsx ecx, cx
    mov eax, dword [ebp - 0x4c]
    lea edx, [ebp - 0x14]
    mov word [ebp - 0x14], ax
    movsx eax, di
    push ds
    pop fs
    mov dword [ebp - 0xa], eax
    movsx eax, word [ebp + 0x18]
    movsx ebx, si
    mov dword [ebp - 6], eax
    mov eax, dword [ebp + 0x1c]
    movsx edi, word [ebp + 0x20]
    mov word [ebp - 0x10], ax
    push ds
    push fs
    pop ds
    mov ax, 0x2511
    int 0x21
    pop ds
.done:
    leave
    pop fs
    pop es
    pop edi
    pop esi
    ret 0xc

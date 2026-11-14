; Read, replace, and upload BIOS graphics palette entries.
BITS 32
ORG 0x716fc

upload_bios_palette equ 0x72cbd
palette_size equ 0x289204
adapter_class equ 0x28920c
graphics_error equ 0x16c66
video_mode equ 0x28920a
graphics_active equ 0x16c65
ega_component_bits equ 0x1738c
legacy_rgb_palette equ 0x17390

replace_palette_entry:
    push ebx
    push ecx
    mov ebx, edx
    test ax, ax
    jl short .invalid_index
    cmp ax, word [palette_size]
    jl short .check_adapter
.invalid_index:
    mov word [graphics_error], 0xfffc
.failure:
    mov eax, 0xffffffff
    pop ecx
    pop ebx
    ret
.check_adapter:
    cmp word [adapter_class], 4
    jge short .replace
    mov word [graphics_error], 0xffff
    jmp short .failure
.replace:
    movsx edx, ax
    mov eax, edx
    call read_palette_entry
    mov ecx, eax
    mov eax, edx
    mov edx, ebx
    call write_palette_entry
    mov eax, ecx
    pop ecx
    pop ebx
    ret

upload_palette_entries:
    push ebx
    push esi
    push edi
    mov ebx, eax
    mov edi, edx
    cmp word [adapter_class], 5
    je short .fallback
    movsx edx, dx
    call upload_bios_palette
    test ax, ax
    jne short .done
.fallback:
    xor esi, esi
    jmp short .check_count
.write_next:
    movsx eax, si
    mov edx, dword [ebx + eax*4]
    call write_palette_entry
    inc esi
.check_count:
    cmp si, di
    jl short .write_next
.done:
    pop edi
    pop esi
    pop ebx
    ret

replace_palette:
    push edx
    cmp word [adapter_class], 4
    jl short .unsupported
    cmp word [video_mode], 7
    je short .unsupported
    cmp word [video_mode], 0xf
    jne short .choose_count
.unsupported:
    mov word [graphics_error], 0xffff
    xor eax, eax
    pop edx
    ret
.choose_count:
    cmp byte [graphics_active], 0
    je short .text_mode
    mov dx, word [palette_size]
    jmp short .upload
.text_mode:
    mov edx, 0x10
.upload:
    movsx edx, dx
    call upload_palette_entries
    mov eax, 0xffffffff
    pop edx
    ret

write_palette_entry:
    push ebx
    push ecx
    push esi
    push edi
    mov ecx, eax
    mov eax, edx
    mov edi, edx
    xor dl, dl
    movzx edx, dx
    mov bx, word [adapter_class]
    sar edx, 8
    and edi, 0xff0000
    mov esi, edx
    mov edx, eax
    shr edi, 0x10
    xor dh, dh
    cmp bx, 5
    jb short .check_ega
    jbe short .write_ega
    cmp bx, 7
    jbe short .write_dac
.unsupported:
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret
.check_ega:
    cmp bx, 4
    jne near .done
.write_dac:
    mov eax, 0x1010
    shl esi, 8
    shl edx, 8
    add edi, esi
    mov ebx, ecx
    mov ecx, edi
    jmp near .interrupt
.write_ega:
    mov bx, word [video_mode]
    cmp bx, 0xd
    je short .lookup_legacy_index
    cmp bx, 0xe
    jne short .quantize_ega_color
.lookup_legacy_index:
    call find_legacy_palette_index
    mov edx, eax
    cmp ax, strict word 7
    jle short .write_attribute
    or dl, 0x10
    mov eax, edx
    jmp short .write_attribute
.quantize_ega_color:
    shr si, 4
    movzx eax, si
    movzx ax, byte [eax + ega_component_bits]
    mov ebx, eax
    shr di, 4
    add ebx, eax
    movzx eax, di
    movzx ax, byte [eax + ega_component_bits]
    shr dx, 4
    add ebx, eax
    movzx eax, dx
    movzx ax, byte [eax + ega_component_bits]
    shl eax, 2
    add eax, ebx
.write_attribute:
    mov ebx, eax
    xor edx, edx
    shl ebx, 8
    mov eax, 0x1000
    add ebx, ecx
    xor ecx, ecx
.interrupt:
    push bp
    int 0x10
    pop bp
.done:
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

read_palette_entry:
    push ebx
    push ecx
    push edx
    mov edx, eax
    mov ax, word [adapter_class]
    cmp ax, strict word 5
    jb short .check_ega
    jbe short .clear_result
    cmp ax, strict word 7
    jbe short .read_dac
    jmp short .done
.check_ega:
    cmp ax, strict word 4
    jne short .done
.read_dac:
    mov eax, 0x1015
    movsx ebx, dx
    push ebp
    int 0x10
    pop ebp
    xchg cl, ch
    movzx eax, cx
    shl eax, 8
    db 0x8a, 0xc6 ; mov al, dh, register-destination encoding.
    mov ebx, eax
    jmp short .done
.clear_result:
    xor ebx, ebx
.done:
    mov eax, ebx
    pop edx
    pop ecx
    pop ebx
    ret

find_legacy_palette_index:
    push ebx
    push edx
    xor ebx, ebx
    jmp short .check_index
.compare_color:
    movsx edx, bx
    cmp eax, dword [edx*4 + legacy_rgb_palette]
    jne short .advance
    mov eax, ebx
    pop edx
    pop ebx
    ret
.advance:
    inc ebx
.check_index:
    cmp bx, 0x10
    jl short .compare_color
    and al, 0xf
    xor ah, ah
    pop edx
    pop ebx
    ret

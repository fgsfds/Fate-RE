BITS 32
ORG 0x71914

drawing_action equ 0x16c9f
fill_pattern equ 0x16c84
fill_pattern_enabled equ 0x16c94
default_fill_pattern equ 0x16c8c
drawing_color equ 0x16c80
graphics_available equ 0x6ffe6
palette_size equ 0x289204

drawing_action_table:
    dd get_drawing_action.replace - 0x10000
    dd get_drawing_action.xor - 0x10000
    dd get_drawing_action.and - 0x10000
    dd get_drawing_action.or - 0x10000

get_drawing_action:
    mov ax, word [drawing_action]
    cmp ax, strict word 3
    ja short .replace
    movzx eax, ax
    jmp dword cs:[eax*4 + drawing_action_table - 0x10000]
.replace:
    mov eax, 3
    ret
.xor:
    mov eax, 4
    ret
.and:
    mov eax, 1
    ret
.or:
    xor eax, eax
    ret

set_drawing_action:
    push edx
    mov edx, eax
    call get_drawing_action
    cmp dx, 1
    jb short .check_zero
    jbe short .and
    cmp dx, 3
    jbe short .replace
    cmp dx, 4
    je short .xor
    jmp short .replace
.check_zero:
    test dx, dx
    je short .or
    jmp short .replace
.xor:
    mov word [drawing_action], 1
    pop edx
    ret
.and:
    mov word [drawing_action], 2
    pop edx
    ret
.or:
    mov word [drawing_action], 3
    pop edx
    ret
.replace:
    mov word [drawing_action], 0
    pop edx
    ret

get_fill_pattern:
    push ecx
    push esi
    push edi
    test eax, eax
    je short .check_pattern
    mov esi, fill_pattern
    mov ecx, 8
    mov edi, eax
    push es
    push edi
    push ds
    pop es
    repne movsb
    pop edi
    pop es
.check_pattern:
    cmp byte [fill_pattern_enabled], 0
    jne short .done
    xor eax, eax
.done:
    pop edi
    pop esi
    pop ecx
    ret

set_fill_pattern:
    push ecx
    push esi
    push edi
    test eax, eax
    jne short .copy_custom
    mov edi, fill_pattern
    mov esi, default_fill_pattern
    mov ecx, 8
    mov byte [fill_pattern_enabled], 0
    push es
    push edi
    push ds
    pop es
    repne movsb
    pop edi
    pop es
    pop edi
    pop esi
    pop ecx
    ret
.copy_custom:
    mov edi, fill_pattern
    mov ecx, 8
    mov esi, eax
    push es
    push edi
    push ds
    pop es
    repne movsb
    pop edi
    pop es
    mov ecx, 8
    mov esi, edi
    mov edi, default_fill_pattern
    push es
    mov eax, ds
    mov es, eax
    xor eax, eax
    repe cmpsb
    je short .restore_es
    sbb eax, eax
    sbb eax, -1
.restore_es:
    pop es
    test eax, eax
    jne short .enable
    mov byte [fill_pattern_enabled], 0
    pop edi
    pop esi
    pop ecx
    ret
.enable:
    mov byte [fill_pattern_enabled], 1
    pop edi
    pop esi
    pop ecx
    ret

get_drawing_color:
    mov ax, word [drawing_color]
    ret

set_drawing_color:
    push edx
    mov edx, eax
    call graphics_available
    test ax, ax
    je short .unavailable
    movsx eax, dx
    call replace_drawing_color
    pop edx
    ret
.unavailable:
    mov eax, 0xffffffff
    pop edx
    ret

replace_drawing_color:
    push ebx
    push edx
    mov edx, eax
    mov bx, word [palette_size]
    dec ebx
    and edx, ebx
    mov ax, word [drawing_color]
    mov word [drawing_color], dx
    pop edx
    pop ebx
    ret

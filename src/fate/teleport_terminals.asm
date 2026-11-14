; Check the current level terminals and schedule a teleport when the lists are clear.
BITS 32
ORG 0x13d9f

absolute_long equ 0x602c3
delete_sprite equ 0x50a09
apply_terminal_special_case equ 0x38800
report_error equ 0x26a03
current_level equ 0x7f87e
terminal_x equ 0x3e74
terminal_y equ 0x3e78
terminal_destination_x equ 0x3e7c
terminal_destination_y equ 0x3e80
terminal_destination_level equ 0x3e84
terminal_destination_entry equ 0x3e88
player_x equ 0x5ad9c
player_y equ 0x5ad5c
projectile_list equ 0x7053c
projectile_count equ 0x2bee
moving_sprite_count equ 0x2be8
float_sprite_count equ 0x2bec
pending_effect_count equ 0x7dee0
destination_x equ 0x7a998
destination_y equ 0x7a99c
destination_level equ 0x2040
destination_entry equ 0x7deee
special_case_flag equ 0x6793d
status_right_tenths equ 0x6319c
special_case_counter equ 0x77118
terminal_error equ 0x268

check_teleport_terminals:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp, 0x64
    xor ebx, ebx
    jmp near .check_terminal_count

.check_terminal:
    movsx ecx, byte [current_level]
    mov eax, ecx
    shl eax, 3
    add ecx, eax
    mov eax, edx
    shl eax, 2
    sub eax, edx
    shl ecx, 4
    shl eax, 3
    add eax, ecx
    mov edx, dword [eax + terminal_x]
    cmp edx, -1
    je near .return
    mov esi, dword [player_x]
    mov ecx, dword [eax + terminal_y]
    mov eax, edx
    sub eax, esi
    call absolute_long
    cmp eax, strict dword 0x100
    jge near .advance_terminal
    mov edi, dword [player_y]
    mov eax, ecx
    sub eax, edi
    call absolute_long
    cmp eax, strict dword 0x100
    jge near .advance_terminal
    mov edx, 1
    jmp short .check_projectile_count

.delete_projectile:
    movsx eax, dx
    movsx eax, word [nosplit eax*2 + projectile_list]
    call delete_sprite
    inc edx

.check_projectile_count:
    cmp dx, word [projectile_count]
    jle short .delete_projectile
    movsx edx, word [moving_sprite_count]
    movsx eax, word [float_sprite_count]
    xor esi, esi
    add edx, eax
    movsx eax, word [pending_effect_count]
    mov word [projectile_count], si
    add eax, edx
    jne short .advance_terminal
    movsx ecx, byte [current_level]
    movsx esi, bx
    mov edi, ecx
    mov eax, esi
    shl edi, 3
    shl eax, 2
    add edi, ecx
    sub eax, esi
    shl edi, 4
    mov edx, dword [edi + eax*8 + terminal_destination_x]
    mov dword [destination_x], edx
    mov edx, dword [edi + eax*8 + terminal_destination_y]
    mov dword [destination_y], edx
    mov dl, byte [edi + eax*8 + terminal_destination_level]
    mov ax, word [edi + eax*8 + terminal_destination_entry]
    mov byte [destination_level], dl
    mov word [destination_entry], ax
    cmp ecx, 5
    jne short .advance_terminal
    cmp esi, 1
    jne short .advance_terminal
    mov byte [special_case_flag], 1
    xor eax, eax
    mov dword [status_right_tenths], ebp
    mov dword [special_case_counter], eax
    call apply_terminal_special_case

.advance_terminal:
    inc ebx

.check_terminal_count:
    movsx edx, bx
    cmp edx, 5
    jl near .check_terminal
    mov eax, terminal_error
    call report_error

.return:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

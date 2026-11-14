; Restore and save level modifications around the GAMEDATA file.
BITS 32
ORG 0x10120

read_game_data equ 0x2f46b
write_game_data equ 0x309a3
format_string equ 0x601f3
append_string equ 0x60223
run_dos_command equ 0x6025a
report_error equ 0x26a03

restore_extension equ 0x58
restore_copy_prefix equ 0x5f
restore_space equ 0x65
restore_mod_extension equ 0x67
restore_copy_options equ 0x6c
restore_copy_error equ 0x79
save_extension equ 0xa0
save_copy_prefix equ 0xa7
save_mod_extension_and_space equ 0xad
save_copy_options equ 0xb3
save_copy_error equ 0xc0
level_names equ 0x2041
copy_error_buffer equ 0x67e3c
modified_levels equ 0x7dea2
current_level equ 0x7f87e

restore_level_modifications:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    sub esp, 0x58
    mov edx, eax
    call read_game_data
    push edx
    push strict dword restore_extension
    lea eax, [esp+0x58]
    push eax
    mov ebx, 1
    call format_string
    add esp, 12
.next_level:
    movsx eax, byte [current_level]
    cmp ebx, eax
    je near .advance
    cmp byte [ebx+modified_levels], 0
    je near .advance
    mov eax, ebx
    shl eax, 2
    mov edi, esp
    add eax, ebx
    mov ecx, level_names
    shl eax, 2
    mov esi, restore_copy_prefix
    add ecx, eax
    mov eax, esp
    mov edx, ecx
    movsd
    movsw
    call append_string
    lea edx, [esp+0x50]
    mov eax, esp
    call append_string
    mov edx, restore_space
    mov eax, esp
    call append_string
    mov eax, esp
    mov edx, ecx
    call append_string
    mov edx, restore_mod_extension
    mov eax, esp
    call append_string
    mov edx, restore_copy_options
    mov eax, esp
    call append_string
    mov eax, esp
    call run_dos_command
    test eax, eax
    je short .advance
    push eax
    push strict dword restore_copy_error
    push copy_error_buffer
    call format_string
    add esp, 12
    mov eax, copy_error_buffer
    call report_error
.advance:
    inc ebx
    cmp ebx, 25
    jle near .next_level
    xor eax, eax
    add esp, 0x58
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

save_level_modifications:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    sub esp, 0x58
    mov edx, eax
    push eax
    push save_extension
    lea eax, [esp+0x58]
    push eax
    call format_string
    add esp, 12
    mov eax, edx
    mov ebx, 1
    call write_game_data
.next_level:
    movsx eax, byte [current_level]
    cmp ebx, eax
    je near .advance
    cmp byte [ebx+modified_levels], 0
    je short .advance
    mov eax, ebx
    shl eax, 2
    mov edi, esp
    add eax, ebx
    mov ecx, level_names
    shl eax, 2
    mov esi, save_copy_prefix
    add ecx, eax
    mov eax, esp
    mov edx, ecx
    movsd
    movsw
    call append_string
    mov edx, save_mod_extension_and_space
    mov eax, esp
    call append_string
    mov eax, esp
    mov edx, ecx
    call append_string
    lea edx, [esp+0x50]
    mov eax, esp
    call append_string
    mov edx, save_copy_options
    mov eax, esp
    call append_string
    mov eax, esp
    call run_dos_command
    test eax, eax
    je short .advance
    push eax
    push save_copy_error
    push copy_error_buffer
    call format_string
    add esp, 12
    mov eax, copy_error_buffer
    call report_error
.advance:
    inc ebx
    cmp ebx, 25
    jle near .next_level
    xor eax, eax
    add esp, 0x58
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

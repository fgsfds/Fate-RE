; Read save slot preview.
BITS 32
ORG 0x39cfa

preview_filename_buffer equ 0xd19
preview_filename_format equ 0xd21
menu_restore_without_ebp equ 0x39482
format_string equ 0x601f3
memset equ 0x61350
open equ 0x61368
lseek equ 0x615b6
read equ 0x615f7
close equ 0x6219a
weapon_state_1f9c9e equ 0x1f9c9e
weapon_state_203c98 equ 0x203c98

read_save_slot_preview:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    mov edx, [weapon_state_203c98]
    mov ecx, preview_filename_buffer
    test edx, edx
    jnz short .branch_39d21
    movzx esi, byte [weapon_state_1f9c9e]
    cmp esi, strict dword 0xff
    jnz near menu_restore_without_ebp

.branch_39d21:
    push eax
    push strict dword preview_filename_format
    push ecx
    mov esi, [weapon_state_203c98]
    call format_string
    add esp, 0xc
    push strict dword 0x202
    push ecx
    call open
    mov ecx, eax
    add esp, 0x8
    mov edi, eax
    cmp eax, -1
    jz short .branch_39d82
    xor ebx, ebx
    xor edx, edx
    call lseek
    mov ebx, 0xfa00
    mov edx, esi
    mov eax, ecx
    call read
    test eax, eax
    jnz short .branch_39d76
    mov ebx, 0xfa00
    mov eax, esi
    xor edx, edx
    call memset

.branch_39d76:
    mov eax, edi
    call close
    jmp near menu_restore_without_ebp

.branch_39d82:
    mov ebx, 0xfa00
    mov eax, esi
    xor edx, edx
    call memset
    jmp near menu_restore_without_ebp

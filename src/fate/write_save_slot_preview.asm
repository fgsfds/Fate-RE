; Write save slot preview.
BITS 32
ORG 0x39c8b

preview_filename_buffer equ 0xd19
preview_filename_format equ 0xd21
format_string equ 0x601f3
open equ 0x61368
lseek equ 0x615b6
close equ 0x6219a
write equ 0x62a97
weapon_state_1f9c9e equ 0x1f9c9e
weapon_state_203c98 equ 0x203c98

write_save_slot_preview:
    push ebx
    push ecx
    push edx
    mov edx, [weapon_state_203c98]
    mov ecx, preview_filename_buffer
    test edx, edx
    jnz short .branch_39cab
    mov dl, [weapon_state_1f9c9e]
    cmp edx, strict dword 0xff
    jnz short .branch_39cf6

.branch_39cab:
    push eax
    push strict dword preview_filename_format
    push ecx
    call format_string
    add esp, 0xc
    push strict dword 0x180
    push strict dword 0x222
    push ecx
    call open
    mov ecx, eax
    add esp, 0xc
    cmp eax, -1
    jz short .branch_39cf6
    xor ebx, ebx
    xor edx, edx
    call lseek
    mov ebx, 0xfa00
    mov edx, [weapon_state_203c98]
    mov eax, ecx
    call write
    mov eax, ecx
    call close

.branch_39cf6:
    pop edx
    pop ecx
    pop ebx
    ret

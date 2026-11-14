; Draw save slot preview.
BITS 32
ORG 0x39c45

rotatesprite equ 0x57181
weapon_state_203c98 equ 0x203c98
presentation_height equ 0x287e8c
presentation_width equ 0x287e90

draw_save_slot_preview:
    push ebx
    push ecx
    push edx
    cmp dword [weapon_state_203c98], 0x0
    jz short .branch_39c87
    mov eax, [presentation_height]
    dec eax
    push eax
    mov eax, [presentation_width]
    dec eax
    push eax
    push strict byte 0x0
    push strict byte 0x0
    push strict byte 0x16
    push strict byte 0x0
    push strict byte 0x0
    mov ecx, 0x200
    mov ebx, 0x6d60
    push strict dword 0xffe
    mov edx, 0x180000
    mov eax, 0xe0000
    call rotatesprite

.branch_39c87:
    pop edx
    pop ecx
    pop ebx
    ret

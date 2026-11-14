; Edit save slot name.
BITS 32
ORG 0x39890

frame_state_d13 equ 0xd13
frame_state_3d04 equ 0x3d04
frame_state_1314e equ 0x1314e
presentation_reset equ 0x36246
presentation_input equ 0x3625c
trim_and_uppercase equ 0x383a0
draw_menu_frame equ 0x39511
format_string equ 0x601f3
strcpy equ 0x60333
memset equ 0x61350
toupper equ 0x62dce
frame_state_173fc0 equ 0x173fc0
frame_state_1740c8 equ 0x1740c8

edit_save_slot_name:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    sub esp, 0x28
    push eax
    mov ebp, edx
    mov eax, [frame_state_1740c8]
    mov eax, [nosplit eax*4 + frame_state_173fc0]
    mov edx, [eax + 0x3]
    lea eax, [esp + 0x18]
    call strcpy
    lea edx, [esp + 0x18]
    lea eax, [esp + 0x4]
    call strcpy
    lea eax, [esp + 0x4]
    mov ebx, 0x11
    call trim_and_uppercase
    xor edx, edx
    lea eax, [esp + 0x4]
    call memset
    lea eax, [esp + 0x4]
    push eax
    mov eax, [frame_state_1740c8]
    mov eax, [nosplit eax*4 + frame_state_173fc0]
    push strict dword frame_state_d13
    mov edx, [eax + 0x3]
    push edx
    call format_string
    add esp, 0xc
    lea edi, [esp + 0x4]
    xor esi, esi
    call presentation_reset

.branch_39906:
    mov ah, 0x1
    push strict dword frame_state_173fc0
    movsx ebx, word [esp + 0x4]
    mov edx, 0xa
    mov ecx, ebp
    mov [frame_state_1314e], ah
    mov eax, [frame_state_1740c8]
    call draw_menu_frame
    xor dl, dl
    mov [frame_state_1314e], dl
    call presentation_input
    mov edx, eax
    test eax, eax
    jz short .branch_39906
    mov ebx, [frame_state_1740c8]
    shl ebx, byte 0x2
    cmp eax, 0xe
    jc short .branch_39953
    jna short .branch_39971
    cmp eax, 0x1c
    jz short .branch_39981
    jmp short .branch_399a9

.branch_39953:
    cmp eax, 0x1
    jnz short .branch_399a9
    mov eax, [ebx + frame_state_173fc0]
    lea edx, [esp + 0x18]
    mov eax, [eax + 0x3]
    call strcpy
    xor eax, eax
    jmp near .branch_399f9

.branch_39971:
    test esi, esi
    jng short .branch_399d2
    mov byte [edi + esi], 0x0
    mov byte [edi + esi-0x1], 0x0
    dec esi
    jmp short .branch_399d2

.branch_39981:
    cmp byte [edi], 0x0
    jnz short .branch_399a2
    lea eax, [esp + 0x18]
    push eax
    mov eax, [ebx + frame_state_173fc0]
    push strict dword frame_state_d13
    mov ebx, [eax + 0x3]
    push ebx
    call format_string
    add esp, 0xc

.branch_399a2:
    mov eax, 0x1
    jmp short .branch_399f9

.branch_399a9:
    mov bl, [edx + frame_state_3d04]
    test bl, bl
    jz short .branch_399d2
    xor eax, eax
    mov al, bl
    call toupper
    mov edx, eax
    mov eax, esi
    inc esi
    mov [edi + eax], dl
    cmp esi, 0x11
    jl short .branch_399ce
    mov esi, 0x10

.branch_399ce:
    mov byte [edi + esi], 0x0

.branch_399d2:
    lea eax, [esp + 0x4]
    push eax
    mov eax, [frame_state_1740c8]
    mov eax, [nosplit eax*4 + frame_state_173fc0]
    push strict dword frame_state_d13
    mov ecx, [eax + 0x3]
    push ecx
    call format_string
    add esp, 0xc
    jmp near .branch_39906

.branch_399f9:
    add esp, 0x2c
    pop ebp
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

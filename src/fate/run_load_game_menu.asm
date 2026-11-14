; Run load game menu.
BITS 32
ORG 0x39f1f

frame_state_c19 equ 0xc19
preview_filename_buffer equ 0xd19
preview_filename_format equ 0xd21
save_names_filename equ 0xd2b
frame_state_1303a equ 0x1303a
frame_state_1314d equ 0x1314d
run_menu_loop equ 0x3963b
read_save_slot_preview equ 0x39cfa
allocache equ 0x40c73
setviewtotile equ 0x5d2f4
setviewback equ 0x5d46d
format_string equ 0x601f3
open equ 0x61368
lseek equ 0x615b6
read equ 0x615f7
close equ 0x6219a
access equ 0x63130
frame_state_173fc0 equ 0x173fc0
frame_state_1740c8 equ 0x1740c8
frame_state_174104 equ 0x174104
weapon_state_1f9c9e equ 0x1f9c9e
weapon_state_203c98 equ 0x203c98

run_load_game_menu:
    push ebx
    push ecx
    push edx
    push esi
    push strict dword 0x202
    push strict dword save_names_filename
    mov esi, preview_filename_buffer
    call open
    mov ecx, eax
    add esp, 0x8
    cmp eax, -1
    jz short .branch_39f62
    xor ebx, ebx
    xor edx, edx
    call lseek
    mov ebx, 0xaa
    mov edx, frame_state_1303a
    mov eax, ecx
    call read
    mov eax, ecx
    call close

.branch_39f62:
    xor edx, edx

.branch_39f64:
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    shl eax, byte 0x2
    mov ebx, frame_state_174104
    add eax, edx
    add ebx, eax
    mov [nosplit edx*4 + frame_state_173fc0], ebx
    mov ebx, edx
    shl ebx, byte 0x4
    mov ecx, frame_state_1303a
    add ebx, edx
    add ecx, ebx
    mov ebx, [nosplit edx*4 + frame_state_173fc0]
    mov [ebx + 0x3], ecx
    mov ebx, [nosplit edx*4 + frame_state_173fc0]
    mov byte [ebx], 0x1
    mov ebx, [nosplit edx*4 + frame_state_173fc0]
    mov word [ebx + 0x1], 0x6
    mov ebx, [nosplit edx*4 + frame_state_173fc0]
    mov dword [ebx + 0x7], 0x0
    mov ebx, [nosplit edx*4 + frame_state_173fc0]
    mov dword [ebx + 0xb], 0x0
    mov eax, [nosplit edx*4 + frame_state_173fc0]
    inc edx
    mov word [eax + 0x13], 0x0
    cmp edx, 0xa
    jl short .branch_39f64
    mov ah, 0xff
    mov edx, [weapon_state_203c98]
    mov [weapon_state_1f9c9e], ah
    test edx, edx
    jnz short .branch_3a002
    mov ebx, weapon_state_1f9c9e
    mov edx, 0xfa00
    mov eax, weapon_state_203c98
    call allocache

.branch_3a002:
    mov dl, 0x1
    mov ebx, [frame_state_1740c8]
    mov [frame_state_1314d], dl
    cmp ebx, 0xa
    jl short .branch_3a01d
    xor ecx, ecx
    mov [frame_state_1740c8], ecx

.branch_3a01d:
    mov ebx, 0x140
    mov eax, [frame_state_1740c8]
    mov edx, 0xc8
    call read_save_slot_preview
    mov eax, 0xffe
    call setviewtotile
    call setviewback
    mov eax, [frame_state_1740c8]
    mov eax, [nosplit eax*4 + frame_state_173fc0]
    mov ecx, frame_state_c19
    mov dword [eax + 0x7], 0xffe
    mov ebx, 0x83d
    mov eax, [frame_state_1740c8]
    push strict dword frame_state_173fc0
    mov edx, 0xa
    mov eax, [nosplit eax*4 + frame_state_173fc0]
    movsx ebx, bx
    mov dword [eax + 0xb], 0x6000
    mov eax, frame_state_1740c8
    call run_menu_loop
    test eax, eax
    jz short .branch_3a0b2
    mov ebx, [frame_state_1740c8]
    push ebx
    push strict dword preview_filename_format
    push esi
    call format_string
    add esp, 0xc
    xor edx, edx
    mov eax, esi
    call access
    cmp eax, -1
    jnz short .branch_3a0b7
    mov ebx, eax
    jmp short .branch_3a0b7

.branch_3a0b2:
    mov ebx, 0xffffffff

.branch_3a0b7:
    mov cl, 0x1
    xor dh, dh
    mov eax, ebx
    mov [frame_state_1314d], dh
    mov [weapon_state_1f9c9e], cl
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

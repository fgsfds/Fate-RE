; Run save game menu.
BITS 32
ORG 0x39d95

frame_state_c23 equ 0xc23
save_names_filename equ 0xd2b
save_names_open_error equ 0xd37
frame_state_1303a equ 0x1303a
report_error equ 0x26a03
menu_restore_without_ebp equ 0x39482
run_menu_loop equ 0x3963b
edit_save_slot_name equ 0x39890
render_save_slot_preview equ 0x39a02
write_save_slot_preview equ 0x39c8b
allocache equ 0x40c73
open equ 0x61368
lseek equ 0x615b6
read equ 0x615f7
close equ 0x6219a
write equ 0x62a97
frame_state_173fc0 equ 0x173fc0
frame_state_1740c8 equ 0x1740c8
frame_state_174104 equ 0x174104
weapon_state_1f9c9e equ 0x1f9c9e
weapon_state_203c98 equ 0x203c98

run_save_game_menu:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push strict dword 0x180
    push strict dword 0x222
    push strict dword save_names_filename
    mov ecx, 0x1
    call open
    mov esi, eax
    add esp, 0xc
    mov edi, eax
    cmp eax, -1
    jz short .branch_39ddb
    xor ebx, ebx
    xor edx, edx
    call lseek
    mov ebx, 0xaa
    mov edx, frame_state_1303a
    mov eax, esi
    call read
    jmp short .branch_39de5

.branch_39ddb:
    mov eax, save_names_open_error
    call report_error

.branch_39de5:
    xor edx, edx

.branch_39de7:
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
    mov esi, frame_state_1303a
    add ebx, edx
    add esi, ebx
    mov ebx, [nosplit edx*4 + frame_state_173fc0]
    mov [ebx + 0x3], esi
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
    jl short .branch_39de7
    mov ah, 0xff
    mov edx, [weapon_state_203c98]
    mov [weapon_state_1f9c9e], ah
    test edx, edx
    jnz short .branch_39e85
    mov ebx, weapon_state_1f9c9e
    mov edx, 0xfa00
    mov eax, weapon_state_203c98
    call allocache

.branch_39e85:
    movsx eax, word [frame_state_1740c8]
    call render_save_slot_preview
    cmp dword [frame_state_1740c8], 0xa
    jl short .branch_39ea2
    xor esi, esi
    mov [frame_state_1740c8], esi

.branch_39ea2:
    test ecx, ecx
    jz short .branch_39f09
    mov esi, 0x83d
    push strict dword frame_state_173fc0
    mov ecx, frame_state_c23
    mov edx, 0xa
    movsx esi, si
    mov eax, frame_state_1740c8
    mov ebx, esi
    call run_menu_loop
    mov ecx, eax
    test eax, eax
    jz short .branch_39ea2
    mov edx, frame_state_c23
    mov eax, esi
    call edit_save_slot_name
    test eax, eax
    jz short .branch_39f05
    mov eax, edi
    xor ebx, ebx
    xor edx, edx
    call lseek
    mov ebx, 0xaa
    mov edx, frame_state_1303a
    mov eax, edi
    call write
    mov eax, [frame_state_1740c8]
    call write_save_slot_preview

.branch_39f05:
    xor ecx, ecx
    jmp short .branch_39ea2

.branch_39f09:
    mov eax, edi
    mov dl, 0x1
    call close
    mov [weapon_state_1f9c9e], dl
    mov eax, ecx
    jmp near menu_restore_without_ebp

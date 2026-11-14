; Update actors on the current board, then run its level script.
BITS 32
ORG 0x1e74c

actor_enabled equ 0x7ecb6
actor_board equ 0x7eac1
current_board equ 0x7f87e
player_sector equ 0x5acfc
player_z equ 0x5ad1c
player_y equ 0x5ad5c
player_x equ 0x5ad9c
update_actor equ 0x14610

%macro board_script 1
    call %1
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
%endmacro

level_script_table:
%assign board_case 0x1e820
%rep 25
    dd board_case - 0x10000
%assign board_case board_case + 10
%endrep

update_board_actors_and_script:
    push ebx
    push ecx
    push edx
    push esi
    xor esi, esi
    jmp short .check_actor

.update_actor:
    movsx ebx, byte [eax + actor_enabled]
    cmp ebx, -1
    je short .advance_actor
    xor ebx, ebx
    movsx ecx, byte [current_board]
    mov bl, [eax + actor_board]
    cmp ebx, ecx
    jne short .advance_actor
    movsx ebx, word [player_sector]
    push ebx
    mov edx, [player_z]
    mov ecx, [player_y]
    push edx
    mov ebx, [player_x]
    xor edx, edx
    call update_actor

.advance_actor:
    inc esi

.check_actor:
    movsx eax, si
    cmp eax, strict dword 500
    jle short .update_actor
    mov al, [current_board]
    dec al
    cmp al, 24
    ja near .return
    and eax, 0xff
    jmp dword [cs:nosplit eax*4 + level_script_table - 0x10000]

    board_script 0x1dae8
    board_script 0x1dae9
    board_script 0x1daea
    board_script 0x1df2e
    board_script 0x1e41d
    board_script 0x1e5d0
    board_script 0x1e5d1
%assign empty_script 0x1e73a
%rep 17
    board_script empty_script
%assign empty_script empty_script + 1
%endrep
    call 0x1e74b
.return:
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

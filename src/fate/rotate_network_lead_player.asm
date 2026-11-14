; Promote a requesting network player to the head of the player list.
BITS 32
ORG 0x2f035

frame_state_5b4 equ 0x5b4
frame_state_5c6 equ 0x5c6
network_enabled equ 0x3c98
event_write_index equ 0x3cdc
board_state_3ce0 equ 0x3ce0
event_read_index equ 0x3ce4
last_tick equ 0x3cea
saved_clock equ 0x3cee
local_player equ 0x13ce2
previous_input equ 0x55b6c
board_state_55b6d equ 0x55b6d
board_state_55b6e equ 0x55b6e
board_state_55b6f equ 0x55b6f
current_input equ 0x5ac3c
board_state_5ac3d equ 0x5ac3d
board_state_5ac3e equ 0x5ac3e
board_state_5ac3f equ 0x5ac3f
player_input_word equ 0x5ac8f
format_string equ 0x601f3
string_length equ 0x60381
weapon_state_7709c equ 0x7709c
actor_clock equ 0x770b8
weapon_state_7aa70 equ 0x7aa70
previous_local_input equ 0x7def4
board_state_7def5 equ 0x7def5
board_state_7def6 equ 0x7def6
board_state_7def7 equ 0x7def7
input_forward equ 0x7def9
input_strafe equ 0x7defa
input_turn equ 0x7defb
input_actions equ 0x7defc
board_state_7f874 equ 0x7f874
next_player equ 0x18fd78
first_player equ 0x19028a
totalclock equ 0x287e88

rotate_network_lead_player:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    cmp byte [network_enabled], 0x0
    jz near .branch_2f1f8
    movsx edx, word [first_player]
    xor eax, eax
    jmp short .branch_2f073

.branch_2f052:
    mov ecx, edx
    mov ebx, edx
    mov bx, [ecx + ebx*4 + player_input_word]
    xor bl, bl
    and bh, 0x2
    movsx ebx, bx
    test ebx, ebx
    jz short .branch_2f06b
    inc eax

.branch_2f06b:
    movsx edx, word [nosplit edx*2 + next_player]

.branch_2f073:
    test edx, edx
    jnl short .branch_2f052
    cmp eax, 0x1
    jnz near .branch_2f1f8
    movsx edx, word [first_player]
    movsx eax, word [nosplit edx*2 + next_player]
    jmp near .branch_2f1f0

.branch_2f094:
    mov ecx, eax
    mov ebx, eax
    mov bx, [ecx + ebx*4 + player_input_word]
    xor bl, bl
    and bh, 0x2
    movsx ecx, bx
    lea ebx, [eax + eax]
    test ecx, ecx
    jz near .branch_2f1e7
    mov cx, [ebx + next_player]
    mov [nosplit edx*2 + next_player], cx
    mov dx, [first_player]
    mov [first_player], ax
    mov al, [input_forward]
    inc al
    mov [previous_local_input], al
    mov al, [input_strafe]
    inc al
    mov [board_state_7def5], al
    mov al, [input_turn]
    inc al
    mov [board_state_7def6], al
    mov ax, [input_actions]
    mov [ebx + next_player], dx
    inc eax
    xor edx, edx
    mov [board_state_7def7], ax
    jmp short .branch_2f14c

.branch_2f10b:
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    mov bl, [eax + current_input]
    inc bl
    mov [eax + previous_input], bl
    mov bl, [eax + board_state_5ac3d]
    inc bl
    mov [eax + board_state_55b6d], bl
    mov bl, [eax + board_state_5ac3e]
    inc bl
    mov [eax + board_state_55b6e], bl
    mov bx, [eax + board_state_5ac3f]
    inc ebx
    inc edx
    mov [eax + board_state_55b6f], bx

.branch_2f14c:
    cmp edx, 0x10
    jl short .branch_2f10b
    xor edx, edx
    mov eax, [actor_clock]
    mov [event_read_index], edx
    mov [board_state_3ce0], edx
    mov [event_write_index], edx
    mov [saved_clock], eax
    mov [last_tick], eax
    mov [totalclock], eax
    mov eax, 0x1
    movsx edx, word [first_player]
    movsx ebx, word [local_player]
    jmp short .branch_2f19b

.branch_2f18e:
    cmp ebx, edx
    jz short .branch_2f19f
    inc eax
    movsx edx, word [nosplit edx*2 + next_player]

.branch_2f19b:
    test edx, edx
    jnl short .branch_2f18e

.branch_2f19f:
    cmp eax, 0x1
    jnz short .branch_2f1b6
    mov edi, weapon_state_7aa70
    mov esi, frame_state_5b4
    movsd
    movsd
    movsd
    movsd
    movsw
    jmp short .branch_2f1c9

.branch_2f1b6:
    push eax
    push strict dword frame_state_5c6
    push strict dword weapon_state_7aa70
    call format_string
    add esp, 0xc

.branch_2f1c9:
    mov eax, weapon_state_7aa70
    call string_length
    mov [board_state_7f874], al
    mov eax, [totalclock]
    add eax, 0x78
    mov [weapon_state_7709c], eax
    jmp short .branch_2f1f8

.branch_2f1e7:
    mov edx, eax
    movsx eax, word [ebx + next_player]

.branch_2f1f0:
    test eax, eax
    jnl near .branch_2f094

.branch_2f1f8:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

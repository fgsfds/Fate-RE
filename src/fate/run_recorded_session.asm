; Replay recorded inputs and render gameplay until the session ends.
BITS 32
ORG 0x2e350

frame_state_3caa equ 0x3caa
frame_state_3cab equ 0x3cab
frame_state_3cd6 equ 0x3cd6
timer_enabled equ 0x3ce9
last_tick equ 0x3cea
saved_clock equ 0x3cee
listener_index equ 0x3cfa
board_filename equ 0x1e5ac
prepare_loaded_board equ 0x27a8c
render_gameplay_frame equ 0x2c48d
snapshot_input equ 0x2d1bd
process_gameplay_frame equ 0x2d23e
frame_state_2db6c equ 0x2db6c
frame_state_2db6d equ 0x2db6d
frame_state_2db6e equ 0x2db6e
frame_state_2db6f equ 0x2db6f
initialize_board_entry equ 0x2e14f
shutdown_subsystem_d equ 0x2f258
shutdown_subsystem_c equ 0x34860
shutdown_subsystem_b equ 0x34bf6
shutdown_subsystem_e equ 0x4124c
shutdown_subsystem_a equ 0x4164f
shutdown_engine equ 0x4b390
sub_4c0b0 equ 0x4c0b0
current_input equ 0x5ac3c
board_state_5ac3d equ 0x5ac3d
board_state_5ac3e equ 0x5ac3e
board_state_5ac3f equ 0x5ac3f
runtime_exit equ 0x60353
player_mode equ 0x62f1c
key_state equ 0x6793c
special_case_flag equ 0x6793d
actor_clock equ 0x770b8
recorded_frame_count equ 0x770d0
next_player equ 0x18fd78
first_player equ 0x19028a
totalclock equ 0x287e88

run_recorded_session:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebx, [recorded_frame_count]
    xor ah, ah
    xor edx, edx
    mov [timer_enabled], ah
    mov [frame_state_3cd6], edx

.check_quit:
    cmp byte [special_case_flag], 0x0
    jnz near .branch_2e4f8

.check_simulation_clock:
    mov eax, [actor_clock]
    add eax, 0x3
    cmp eax, [totalclock]
    jg near .render_interpolated_frame
    cmp ebx, [recorded_frame_count]
    jl short .start_input_frame
    mov eax, board_filename
    call prepare_loaded_board
    movsx ebx, word [first_player]
    jmp short .branch_2e3b8

.initialize_player:
    movsx eax, bx
    call initialize_board_entry
    movsx ebx, word [nosplit ebx*2 + next_player]

.branch_2e3b8:
    test ebx, ebx
    jnl short .initialize_player
    call sub_4c0b0
    xor ebp, ebp
    xor ebx, ebx
    mov [last_tick], ebp
    mov [saved_clock], ebp

.start_input_frame:
    movsx esi, word [first_player]
    xor edi, edi
    jmp short .branch_2e431

.branch_2e3dc:
    mov ecx, ebx
    mov eax, edi
    shl ecx, byte 0x2
    shl eax, byte 0x2
    add ecx, ebx
    add eax, edi
    add ecx, ecx
    lea edx, [ecx + eax]
    mov eax, esi
    shl eax, byte 0x2
    add eax, esi
    mov cl, [edx + frame_state_2db6c]
    mov [eax + current_input], cl
    mov cl, [edx + frame_state_2db6d]
    inc edi
    mov [eax + board_state_5ac3d], cl
    mov cl, [edx + frame_state_2db6e]
    mov dx, [edx + frame_state_2db6f]
    mov [eax + board_state_5ac3e], cl
    movsx esi, word [nosplit esi*2 + next_player]
    mov [eax + board_state_5ac3f], dx

.branch_2e431:
    test esi, esi
    jnl short .branch_2e3dc
    call snapshot_input
    call process_gameplay_frame
    inc ebx
    jmp near .check_simulation_clock

.render_interpolated_frame:
    mov edx, [totalclock]
    mov esi, [actor_clock]
    sub edx, esi
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    mov edx, eax
    shl eax, byte 0x4
    add eax, edx
    mov edx, eax
    shl eax, byte 0x8
    add edx, eax
    movsx eax, word [listener_index]
    call render_gameplay_frame
    xor eax, eax
    mov al, [frame_state_3cab]
    cmp byte [eax + key_state], 0x0
    jna short .branch_2e4b2
    xor cl, cl
    mov [eax + key_state], cl
    movsx eax, word [listener_index]
    mov ax, [nosplit eax*2 + next_player]
    mov [listener_index], ax
    test ax, ax
    jnl short .branch_2e4b2
    mov ax, [first_player]
    mov [listener_index], ax

.branch_2e4b2:
    xor eax, eax
    mov al, [frame_state_3caa]
    cmp byte [eax + key_state], 0x0
    jna near .check_quit
    xor dl, dl
    mov [eax + key_state], dl
    movsx eax, word [listener_index]
    inc byte [eax + player_mode]
    xor edx, edx
    mov dl, [eax + player_mode]
    cmp edx, 0x3
    jng near .check_quit
    mov byte [eax + player_mode], 0x1
    jmp near .check_quit

.branch_2e4f8:
    call shutdown_subsystem_a
    call shutdown_subsystem_b
    call shutdown_subsystem_c
    call shutdown_subsystem_d
    call shutdown_engine
    call shutdown_subsystem_e
    mov eax, 0x3
    int byte 0x10
    xor eax, eax
    call runtime_exit
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

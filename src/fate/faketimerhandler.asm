; Build a simulation tick from local input and the active multiplayer mode.
BITS 32
ORG 0x31ec4

last_tick equ 0x3cea
clock equ 0x287e88
timer_enabled equ 0x3ce9
local_player equ 0x13ce2
first_player equ 0x19028a
network_enabled equ 0x3c98
local_input equ 0x7def9
current_input equ 0x5ac3c
player_count equ 0x13ce0
packet equ 0x1d92c
previous_input equ 0x55b6c
next_player equ 0x18fd78
event_write_index equ 0x3cdc
event_read_index equ 0x3ce4
event_queue equ 0x1f7fc
second_player_cycle_key equ 0x679f1
second_player_selection equ 0x770c0
second_player_forward equ 0x770f0
second_player_strafe equ 0x770dc
second_player_turn equ 0x770d8
second_player_input equ 0x7defe
second_player_key_0 equ 0x67981
second_player_key_1 equ 0x67983
second_player_key_2 equ 0x67985
second_player_key_3 equ 0x67973
second_player_key_10 equ 0x6798c
second_player_key_11 equ 0x6798e
previous_local_input equ 0x7def4
receive_packets equ 0x32407
output_queue_depth equ 0x436fa
collect_input equ 0x2d51a
send_packet equ 0x424ec
snapshot_input equ 0x2d1bd

faketimerhandler_:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov eax, dword [last_tick]
    add eax, 3
    cmp eax, dword [clock]
    jg near .done
    cmp byte [timer_enabled], 0
    je near .done
    mov dword [last_tick], eax
    ; Poll receives before testing serial backpressure.
    call receive_packets
    call output_queue_depth
    cmp eax, 0x10
    jge near .done
    call collect_input
    mov ax, word [local_player]
    cmp ax, word [first_player]
    je short .record_local_input
    cmp byte [network_enabled], 0
    jne near .send_client_delta
.record_local_input:
    movsx edx, word [local_player]
    mov eax, edx
    shl eax, 2
    add eax, edx
    mov dl, byte [local_input]
    mov byte [eax + current_input], dl
    mov dl, byte [local_input+1]
    mov byte [eax + current_input+1], dl
    mov dl, byte [local_input+2]
    mov byte [eax + current_input+2], dl
    mov dx, word [local_input+3]
    mov ch, byte [network_enabled]
    mov word [eax + current_input+3], dx
    test ch, ch
    je near .check_second_player
    ; Host packet type 0 packs four change flags per player.
    movsx esi, word [player_count]
    xor dh, dh
    inc esi
    mov byte [packet], dh
    sar esi, 1
    mov edx, 1
    inc esi
    jmp short .test_mask_clear
.clear_packet_mask:
    inc edx
    xor bl, bl
    mov byte [edx + packet-1], bl
.test_mask_clear:
    cmp edx, esi
    jl short .clear_packet_mask
    mov edx, 8
    movsx edi, word [first_player]
    jmp near .test_player
.pack_player_delta:
    mov eax, edi
    shl eax, 2
    add eax, edi
    mov cl, byte [eax + current_input]
    mov ch, byte [eax + previous_input]
    xor ebx, ebx
    cmp cl, ch
    je short .check_strafe
    mov ebx, 1
    mov byte [esi + packet], cl
    add esi, ebx
.check_strafe:
    mov eax, edi
    shl eax, 2
    add eax, edi
    mov cl, byte [eax + current_input+1]
    cmp cl, byte [eax + previous_input+1]
    je short .check_turn
    inc esi
    or bl, 2
    mov byte [esi + packet-1], cl
.check_turn:
    mov eax, edi
    shl eax, 2
    add eax, edi
    mov cl, byte [eax + current_input+2]
    cmp cl, byte [eax + previous_input+2]
    je short .check_action_word
    inc esi
    or bl, 4
    mov byte [esi + packet-1], cl
.check_action_word:
    mov eax, edi
    shl eax, 2
    add eax, edi
    mov cx, word [eax + current_input+3]
    cmp cx, word [eax + previous_input+3]
    je short .store_player_mask
    inc esi
    mov cl, byte [eax + current_input+3]
    movsx eax, word [eax + current_input+3]
    mov byte [esi + packet-1], cl
    sar eax, 8
    inc esi
    and eax, 0xff
    or bl, 8
    mov byte [esi + packet-1], al
.store_player_mask:
    mov cl, dl
    mov eax, edx
    and cl, 7
    sar eax, 3
    shl bl, cl
    or byte [eax + packet], bl
    mov eax, edi
    shl eax, 2
    add eax, edi
    mov bl, byte [eax + current_input]
    mov byte [eax + previous_input], bl
    mov bl, byte [eax + current_input+1]
    mov byte [eax + previous_input+1], bl
    mov bl, byte [eax + current_input+2]
    add edx, 4
    mov byte [eax + previous_input+2], bl
    mov bx, word [eax + current_input+3]
    movsx edi, word [nosplit edi*2 + next_player]
    mov word [eax + previous_input+3], bx
.test_player:
    test edi, edi
    jge near .pack_player_delta
; Append queued two-byte events and advance the wrapping read index.
.append_events:
    mov eax, dword [event_write_index]
    mov edi, dword [event_read_index]
    cmp eax, edi
    je short .start_recipients
    movsx eax, word [nosplit edi*2 + event_queue]
    sar eax, 8
    add esi, 2
    and eax, 0xff
    mov byte [esi + packet-1], al
    lea eax, [edi + 1]
    mov dl, byte [nosplit edi*2 + event_queue]
    and eax, 0xff
    mov byte [esi + packet-2], dl
    mov dword [event_read_index], eax
    jmp short .append_events
.start_recipients:
    movsx edi, word [first_player]
    jmp short .test_recipient
.send_host_packet:
    mov edx, packet
    mov ebx, esi
    mov eax, edi
    call send_packet
.test_recipient:
    movsx edi, word [nosplit edi*2 + next_player]
    test edi, edi
    jge short .send_host_packet
    jmp near .snapshot
; Local two-player mode builds a second record from its input globals.
.check_second_player:
    movsx eax, word [player_count]
    cmp eax, 2
    jne near .snapshot
    cmp byte [second_player_cycle_key], 0
    jbe short .cycle_complete
    mov byte [second_player_cycle_key], ch
    mov ebx, dword [second_player_selection]
    inc ebx
    mov dword [second_player_selection], ebx
    cmp ebx, 3
    jl short .cycle_complete
    xor esi, esi
    mov dword [second_player_selection], esi
.cycle_complete:
    mov edi, dword [second_player_forward]
    cmp edi, -0x78
    jle short .clamp_forward_floor
    mov eax, edi
    jmp short .test_forward_ceiling
.clamp_forward_floor:
    mov eax, 0xffffff88
.test_forward_ceiling:
    cmp eax, 0x77
    jge short .store_forward_ceiling
    mov ebp, dword [second_player_forward]
    cmp ebp, -0x78
    jle short .clamp_forward_again
    mov eax, ebp
    jmp short .store_forward
.clamp_forward_again:
    mov eax, 0xffffff88
    jmp short .store_forward
.store_forward_ceiling:
    mov eax, 0x77
.store_forward:
    mov byte [second_player_input], al
    mov eax, dword [second_player_strafe]
    cmp eax, -0x78
    jg short .test_strafe_ceiling
    mov eax, 0xffffff88
.test_strafe_ceiling:
    cmp eax, 0x77
    jge short .store_strafe_ceiling
    mov edx, dword [second_player_strafe]
    cmp edx, -0x78
    jle short .clamp_strafe_again
    mov eax, edx
    jmp short .store_strafe
.clamp_strafe_again:
    mov eax, 0xffffff88
    jmp short .store_strafe
.store_strafe_ceiling:
    mov eax, 0x77
.store_strafe:
    mov ebx, dword [second_player_turn]
    mov byte [second_player_input+1], al
    cmp ebx, -0x70
    jle short .clamp_turn_floor
    mov eax, ebx
    jmp short .test_turn_ceiling
.clamp_turn_floor:
    mov eax, 0xffffff90
.test_turn_ceiling:
    cmp eax, 0x6f
    jge short .store_turn_ceiling
    mov ecx, dword [second_player_turn]
    cmp ecx, -0x70
    jle short .clamp_turn_again
    mov eax, ecx
    jmp short .store_turn
.clamp_turn_again:
    mov eax, 0xffffff90
    jmp short .store_turn
.store_turn_ceiling:
    mov eax, 0x6f
.store_turn:
    mov byte [second_player_input+2], al
    mov ax, word [second_player_selection]
    shl eax, 0xd
    mov word [second_player_input+3], ax
    xor eax, eax
    mov al, byte [second_player_key_0]
    mov bx, word [second_player_input+3]
    or ebx, eax
    mov word [second_player_input+3], bx
    xor eax, eax
    mov al, byte [second_player_key_1]
    mov ecx, ebx
    add eax, eax
    or ecx, eax
    mov word [second_player_input+3], cx
    mov dl, byte [second_player_input+4]
    or dl, 1
    xor eax, eax
    mov byte [second_player_input+4], dl
    mov al, byte [second_player_key_2]
    mov si, word [second_player_input+3]
    shl eax, 2
    or esi, eax
    mov word [second_player_input+3], si
    xor eax, eax
    mov al, byte [second_player_key_3]
    shl eax, 3
    mov edi, esi
    or edi, eax
    mov word [second_player_input+3], di
    xor eax, eax
    mov al, byte [second_player_key_10]
    shl eax, 0xa
    mov edx, edi
    or edx, eax
    mov word [second_player_input+3], dx
    xor eax, eax
    mov al, byte [second_player_key_11]
    shl eax, 0xb
    mov ebx, edx
    or ebx, eax
    movsx eax, word [local_player]
    mov ax, word [nosplit eax*2 + next_player]
    mov word [second_player_input+3], bx
    test ax, ax
    jge short .second_player_index_ready
    mov ax, word [first_player]
.second_player_index_ready:
    movsx edx, ax
    mov eax, edx
    shl eax, 2
    add eax, edx
    mov dl, byte [second_player_input]
    mov byte [eax + current_input], dl
    mov dl, byte [second_player_input+1]
    mov byte [eax + current_input+1], dl
    mov dl, byte [second_player_input+2]
    mov byte [eax + current_input+2], dl
    mov dx, word [second_player_input+3]
    mov word [eax + current_input+3], dx
.snapshot:
    call snapshot_input
    jmp near .done
; Client packet type 1 tracks the two action bytes independently.
.send_client_delta:
    mov bl, 1
    mov esi, 2
    mov al, byte [local_input]
    mov byte [packet], bl
    xor bh, bh
    mov cl, byte [previous_local_input]
    mov byte [packet+1], bh
    cmp al, cl
    je short .check_local_strafe
    mov esi, 3
    mov byte [packet+2], al
    mov byte [previous_local_input], al
    mov byte [packet+1], bl
.check_local_strafe:
    mov al, byte [local_input+1]
    cmp al, byte [previous_local_input+1]
    je short .check_local_turn
    mov byte [esi + packet], al
    mov dl, byte [packet+1]
    mov byte [previous_local_input+1], al
    or dl, 2
    inc esi
    mov byte [packet+1], dl
.check_local_turn:
    mov al, byte [local_input+2]
    cmp al, byte [previous_local_input+2]
    je short .check_local_actions
    mov byte [esi + packet], al
    mov bl, byte [packet+1]
    mov byte [previous_local_input+2], al
    or bl, 4
    inc esi
    mov byte [packet+1], bl
.check_local_actions:
    movsx edx, word [local_input+3]
    movsx eax, word [previous_local_input+3]
    xor eax, edx
    test al, 0xff
    je short .check_local_action_high
    mov al, byte [local_input+3]
    mov byte [esi + packet], al
    mov bh, byte [packet+1]
    or bh, 8
    inc esi
    mov byte [packet+1], bh
.check_local_action_high:
    movsx eax, word [local_input+3]
    movsx edx, word [previous_local_input+3]
    xor edx, eax
    test dh, 0xff
    je short .send_client_packet
    sar eax, 8
    and eax, 0xff
    mov byte [esi + packet], al
    mov cl, byte [packet+1]
    or cl, 0x10
    inc esi
    mov byte [packet+1], cl
.send_client_packet:
    mov edx, packet
    mov ax, word [local_input+3]
    mov ebx, esi
    mov word [previous_local_input+3], ax
    movsx eax, word [first_player]
    call send_packet
.done:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

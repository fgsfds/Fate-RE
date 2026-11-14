; Receive multiplayer packets and update queued player input.
BITS 32
ORG 0x32407

network_enabled equ 0x3c98
weapon_state_3cda equ 0x3cda
event_write_index equ 0x3cdc
board_state_3ce0 equ 0x3ce0
event_read_index equ 0x3ce4
last_tick equ 0x3cea
player_count equ 0x13ce0
local_player equ 0x13ce2
packet equ 0x1d92c
frame_state_1d92d equ 0x1d92d
frame_state_1d92e equ 0x1d92e
frame_state_1e5fa equ 0x1e5fa
frame_state_1e5fc equ 0x1e5fc
frame_state_1f7fa equ 0x1f7fa
frame_state_20a1c equ 0x20a1c
snapshot_input equ 0x2d1bd
send_packet equ 0x424ec
receive_packet equ 0x42985
current_input equ 0x5ac3c
board_state_5ac3d equ 0x5ac3d
board_state_5ac3e equ 0x5ac3e
board_state_5ac3f equ 0x5ac3f
random_value equ 0x602d0
special_case_flag equ 0x6793d
weapon_state_7709c equ 0x7709c
frame_state_7aa71 equ 0x7aa71
board_state_7f874 equ 0x7f874
next_player equ 0x18fd78
first_player equ 0x19028a
totalclock equ 0x287e88

receive_packets:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    sub esp, 0x10
    cmp byte [network_enabled], 0x0
    jz near .branch_32792
    xor edx, edx
    mov [esp + 0x8], edx

.branch_32422:
    mov edx, packet
    lea eax, [esp + 0xc]
    call receive_packet
    mov [esp + 0x4], ax
    test ax, ax
    jng near .branch_3275f
    mov al, [packet]
    cmp al, 0x2
    jc short .branch_32461
    jna near .branch_326c3
    cmp al, 0x5
    jc short .branch_32422
    jna near .branch_3270c
    cmp al, 0xff
    jz near .branch_32753
    jmp short .branch_32422

.branch_32461:
    test al, al
    ja near .branch_325f5
    movsx eax, word [player_count]
    inc eax
    mov edx, 0x8
    sar eax, 1
    movsx ebx, word [first_player]
    inc eax
    jmp near .branch_32523

.branch_32485:
    mov ecx, edx
    sar ecx, byte 0x3
    movzx esi, byte [ecx + packet]
    mov ecx, edx
    and ecx, 0x7
    sar esi, cl
    mov [esp], esi
    test byte [esp], 0x1
    jz short .branch_324b6
    mov ecx, ebx
    shl ecx, byte 0x2
    lea esi, [ebx + ecx]
    mov cl, [eax + packet]
    inc eax
    mov [esi + current_input], cl

.branch_324b6:
    test byte [esp], 0x2
    jz short .branch_324d1
    mov ecx, ebx
    shl ecx, byte 0x2
    lea esi, [ebx + ecx]
    mov cl, [eax + packet]
    inc eax
    mov [esi + board_state_5ac3d], cl

.branch_324d1:
    test byte [esp], 0x4
    jz short .branch_324ec
    mov ecx, ebx
    shl ecx, byte 0x2
    lea esi, [ebx + ecx]
    mov cl, [eax + packet]
    inc eax
    mov [esi + board_state_5ac3e], cl

.branch_324ec:
    test byte [esp], 0x8
    jz short .branch_32518
    xor ecx, ecx
    mov cl, [eax + frame_state_1d92d]
    movzx si, byte [eax + packet]
    shl ecx, byte 0x8
    add esi, ecx
    mov ecx, ebx
    shl ecx, byte 0x2
    add ecx, ebx
    add eax, 0x2
    mov [ecx + board_state_5ac3f], si

.branch_32518:
    add edx, 0x4
    movsx ebx, word [nosplit ebx*2 + next_player]

.branch_32523:
    test ebx, ebx
    jnl near .branch_32485

.branch_3252b:
    movsx edx, word [esp + 0x4]
    cmp eax, edx
    jz short .branch_32579
    xor ebx, ebx
    mov edx, [board_state_3ce0]
    mov bl, [eax + packet]
    mov [nosplit edx*2 + frame_state_1e5fc], bx
    xor ebx, ebx
    mov bl, [eax + frame_state_1d92d]
    mov di, [nosplit edx*2 + frame_state_1e5fc]
    shl ebx, byte 0x8
    inc edx
    add edi, ebx
    mov [nosplit edx*2 + frame_state_1e5fa], di
    and edx, strict dword 0xff
    add eax, 0x2
    mov [board_state_3ce0], edx
    jmp short .branch_3252b

.branch_32579:
    mov eax, [event_write_index]
    mov ecx, [event_read_index]
    cmp eax, ecx
    jz short .branch_325e2
    cmp ecx, [board_state_3ce0]
    jz short .branch_325e2
    xor esi, esi
    mov [weapon_state_3cda], si

.branch_32599:
    mov eax, [event_read_index]
    inc eax
    mov cx, [weapon_state_3cda]
    mov dx, [nosplit eax*2 + frame_state_1f7fa]
    mov bx, [nosplit eax*2 + frame_state_1e5fa]
    and eax, strict dword 0xff
    xor edx, ebx
    mov [event_read_index], eax
    or ecx, edx
    mov eax, [event_write_index]
    mov edi, [event_read_index]
    mov [weapon_state_3cda], cx
    cmp eax, edi
    jz short .branch_325e2
    cmp edi, [board_state_3ce0]
    jnz short .branch_32599

.branch_325e2:
    mov esi, [esp + 0x8]
    inc esi
    call snapshot_input
    mov [esp + 0x8], esi
    jmp near .branch_32422

.branch_325f5:
    xor edx, edx
    mov dl, [frame_state_1d92d]
    mov eax, 0x2
    test dl, 0x1
    jz short .branch_32624
    movsx ebx, word [esp + 0xc]
    mov eax, ebx
    shl eax, byte 0x2
    add eax, ebx
    mov bl, [frame_state_1d92e]
    mov [eax + current_input], bl
    mov eax, 0x3

.branch_32624:
    test dl, 0x2
    jz short .branch_32642
    movsx ecx, word [esp + 0xc]
    mov ebx, ecx
    shl ebx, byte 0x2
    add ebx, ecx
    mov cl, [eax + packet]
    inc eax
    mov [ebx + board_state_5ac3d], cl

.branch_32642:
    test dl, 0x4
    jz short .branch_32660
    movsx ecx, word [esp + 0xc]
    mov ebx, ecx
    shl ebx, byte 0x2
    add ebx, ecx
    mov cl, [eax + packet]
    inc eax
    mov [ebx + board_state_5ac3e], cl

.branch_32660:
    test dl, 0x8
    jz short .branch_3268c
    movsx ecx, word [esp + 0xc]
    mov ebx, ecx
    shl ebx, byte 0x2
    add ebx, ecx
    mov cx, [ebx + board_state_5ac3f]
    movzx si, byte [eax + packet]
    xor cl, cl
    or ecx, esi
    inc eax
    mov [ebx + board_state_5ac3f], cx

.branch_3268c:
    test dl, 0x10
    jz near .branch_32422
    movsx ebx, word [esp + 0xc]
    mov edx, ebx
    shl edx, byte 0x2
    add edx, ebx
    mov bx, [edx + board_state_5ac3f]
    mov al, [eax + packet]
    xor bh, bh
    xor ah, ah
    shl eax, byte 0x8
    or eax, ebx
    mov [edx + board_state_5ac3f], ax
    jmp near .branch_32422

.branch_326c3:
    mov al, [esp + 0x4]
    dec al
    mov [board_state_7f874], al
    xor eax, eax
    mov al, [board_state_7f874]
    dec eax
    jmp short .branch_326e5

.branch_326d8:
    dec eax
    mov dl, [eax + frame_state_1d92e]
    mov [eax + frame_state_7aa71], dl

.branch_326e5:
    test eax, eax
    jnl short .branch_326d8
    xor eax, eax
    mov al, [board_state_7f874]
    shl eax, byte 0x4
    mov edx, [totalclock]
    add edx, strict dword 0x168
    add edx, eax
    mov [weapon_state_7709c], edx
    jmp near .branch_32422

.branch_3270c:
    movsx eax, word [esp + 0xc]
    mov dl, [frame_state_1d92d]
    mov cx, [first_player]
    mov [eax + frame_state_20a1c], dl
    cmp cx, [esp + 0xc]
    jnz near .branch_32422
    xor eax, eax
    mov al, dl
    cmp eax, 0x2
    jnz near .branch_32422
    mov ebx, 0x2
    mov edx, packet
    movsx eax, cx
    call send_packet
    jmp near .branch_32422

.branch_32753:
    mov byte [special_case_flag], 0x1
    jmp near .branch_32422

.branch_3275f:
    mov ax, [local_player]
    cmp ax, [first_player]
    jz short .branch_32792
    mov eax, [esp + 0x8]
    xor ah, ah
    and al, 0x1
    cwde
    test eax, eax
    jnz short .branch_32792
    call random_value
    test al, 0x1
    jz short .branch_3278c
    inc dword [last_tick]
    jmp short .branch_32792

.branch_3278c:
    dec dword [last_tick]

.branch_32792:
    add esp, 0x10
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

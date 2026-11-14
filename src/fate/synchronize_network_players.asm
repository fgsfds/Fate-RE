; Exchange readiness packets with the lead player.
BITS 32
ORG 0x33af0

player_count equ 0x13ce0
local_player equ 0x13ce2
packet equ 0x1d92c
packet_ready_stage equ 0x1d92d
peer_ready_stage equ 0x20a1c
receive_packets equ 0x32407
send_packet equ 0x424ec
next_player equ 0x18fd78
first_player equ 0x19028a
totalclock equ 0x287e88

synchronize_network_players:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 0x4
    movsx eax, word [player_count]
    cmp eax, 0x2
    jl near .branch_33be1
    mov ax, [local_player]
    mov dx, [first_player]
    cmp ax, dx
    jnz near .branch_33beb
    mov dword [esp], 0x1
    jmp near .branch_33bd7

.branch_33b2b:
    movsx ecx, word [first_player]
    jmp short .branch_33b3c

.branch_33b34:
    xor bl, bl
    mov [ecx + peer_ready_stage], bl

.branch_33b3c:
    movsx ecx, word [nosplit ecx*2 + next_player]
    test ecx, ecx
    jnl short .branch_33b34
    mov esi, [totalclock]
    mov ebp, [esp]
    mov edi, [esp]
    sub esi, 0x8

.branch_33b57:
    call receive_packets
    lea eax, [esi + 0x8]
    cmp eax, [totalclock]
    jg short .branch_33baf
    mov esi, [totalclock]
    mov bh, 0x5
    mov al, [esp]
    movsx ecx, word [first_player]
    mov [packet], bh
    mov [packet_ready_stage], al
    jmp short .branch_33ba3

.branch_33b86:
    xor eax, eax
    mov al, [ecx + peer_ready_stage]
    cmp eax, edi
    jz short .branch_33ba3
    mov ebx, 0x2
    mov edx, packet
    mov eax, ecx
    call send_packet

.branch_33ba3:
    movsx ecx, word [nosplit ecx*2 + next_player]
    test ecx, ecx
    jnl short .branch_33b86

.branch_33baf:
    movsx ecx, word [first_player]
    jmp short .branch_33bc4

.branch_33bb8:
    xor eax, eax
    mov al, [ecx + peer_ready_stage]
    cmp eax, ebp
    jnz short .branch_33bd0

.branch_33bc4:
    movsx ecx, word [nosplit ecx*2 + next_player]
    test ecx, ecx
    jnl short .branch_33bb8

.branch_33bd0:
    test ecx, ecx
    jnl short .branch_33b57
    inc dword [esp]

.branch_33bd7:
    cmp dword [esp], 0x2
    jng near .branch_33b2b

.branch_33be1:
    add esp, 0x4
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

.branch_33beb:
    movsx eax, dx
    xor dl, dl
    mov [eax + peer_ready_stage], dl

.branch_33bf6:
    movsx eax, word [first_player]
    mov al, [eax + peer_ready_stage]
    and eax, strict dword 0xff
    cmp eax, 0x2
    jz short .branch_33be1
    call receive_packets
    movsx eax, word [first_player]
    xor ecx, ecx
    mov cl, [eax + peer_ready_stage]
    cmp ecx, 0x1
    jnz short .branch_33bf6
    xor dh, dh
    mov ebx, 0x2
    mov [eax + peer_ready_stage], dh
    mov edx, packet
    call send_packet
    jmp short .branch_33bf6

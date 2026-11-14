; Broadcast network ready.
BITS 32
ORG 0x4367c

transport equ 0x13cde
player_count equ 0x13ce0
local_player equ 0x13ce2
send_packet equ 0x424ec
next_player equ 0x18fd78
first_player equ 0x19028a

broadcast_network_ready:
    push ebx
    push ecx
    push edx
    sub esp, 0x10
    movsx eax, word [player_count]
    cmp eax, 0x1
    jng short .branch_436f3
    cmp byte [transport], 0x0
    jna short .branch_436f3
    xor eax, eax
    mov dl, 0xff
    mov al, [transport]
    mov [esp], dl
    cmp eax, 0x5
    jnl short .branch_436bb
    mov ebx, 0x1
    mov edx, esp
    mov eax, 0xffffffff
    call send_packet
    jmp short .branch_436f3

.branch_436bb:
    mov al, [local_player]
    movsx ecx, word [first_player]
    mov [esp + 0x1], al
    jmp short .branch_436ef

.branch_436cd:
    movsx eax, word [local_player]
    cmp ecx, eax
    jz short .branch_436e7
    mov ebx, 0x2
    mov edx, esp
    movsx eax, cx
    call send_packet

.branch_436e7:
    movsx ecx, word [nosplit ecx*2 + next_player]

.branch_436ef:
    test ecx, ecx
    jnl short .branch_436cd

.branch_436f3:
    add esp, 0x10
    pop edx
    pop ecx
    pop ebx
    ret

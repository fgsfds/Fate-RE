; Handle network control packet.
BITS 32
ORG 0x432c1

transport equ 0x13cde
player_count equ 0x13ce0
local_player equ 0x13ce2
initialize_network_peer_state equ 0x42319
network_control_return equ 0x42486
uninitialize_network_peer_state equ 0x4248f
send_packet equ 0x424ec
frame_state_186d48 equ 0x186d48
frame_state_186d87 equ 0x186d87
next_player equ 0x18fd78
frame_state_18fd7a equ 0x18fd7a
frame_state_18fe08 equ 0x18fe08
frame_state_18fe30 equ 0x18fe30
first_player equ 0x19028a

handle_network_control_packet:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    sub esp, 0x4
    mov esi, eax
    mov edi, edx
    mov al, [edx]
    cmp al, 0xfe
    jc short .branch_432e6
    jna near .branch_434dc
    cmp al, 0xff
    jz near .branch_43571
    jmp near network_control_return

.branch_432e6:
    cmp al, 0xfd
    jnz near network_control_return
    xor eax, eax
    mov al, [transport]
    cmp eax, 0x5
    jnl short .branch_43371
    xor eax, eax
    mov al, [edx + 0x2]
    mov edx, eax
    xor eax, eax
    shl edx, byte 0x8
    mov al, [edi + 0x1]
    add edx, eax
    xor eax, eax
    mov al, [edi + 0x3]
    shl eax, byte 0x10
    add edx, eax
    xor eax, eax
    mov al, [edi + 0x4]
    mov ebx, 0x1
    shl eax, byte 0x18
    xor ecx, ecx
    add edx, eax
    mov eax, 0xffffffff
    mov [frame_state_18fe08], edx
    mov edx, edi
    mov byte [edi], 0xfe
    call send_packet
    mov edi, 0x1
    mov eax, 0xffffffff
    mov edx, 0x2
    mov [local_player], cx
    mov [first_player], cx
    mov [next_player], di
    mov [frame_state_18fd7a], ax
    mov [player_count], dx
    jmp near network_control_return

.branch_43371:
    jl near network_control_return
    xor eax, eax
    mov al, [edx + 0x2]
    mov edx, eax
    xor eax, eax
    shl edx, byte 0x8
    mov al, [edi + 0x1]
    add eax, edx
    xor edx, edx
    mov dl, [edi + 0x3]
    shl edx, byte 0x10
    add edx, eax
    xor eax, eax
    mov al, [edi + 0x4]
    shl eax, byte 0x18
    lea ebp, [edx + eax]
    cmp ebp, [frame_state_18fe30]
    jz near network_control_return
    lea edx, [edi + 0x5]
    mov eax, ebp
    call initialize_network_peer_state
    mov ax, [local_player]
    mov dx, [first_player]
    cmp ax, dx
    jz short .branch_433ec
    movsx edx, dx
    cmp ebp, [nosplit edx*4 + frame_state_186d48]
    jnz near network_control_return
    mov eax, edx
    mov dx, [local_player]
    cmp dx, [nosplit eax*2 + next_player]
    jnz near network_control_return

.branch_433ec:
    mov ecx, 0x1
    xor esi, esi
    mov byte [edi], 0xfe
    mov [esp], esi
    jmp near .branch_4348b

.branch_433fe:
    shl eax, byte 0x2
    mov ebx, [eax + frame_state_186d48]
    cmp ebx, strict dword 0x7fffffff
    jz near .branch_43488
    cmp ebp, ebx
    jz short .branch_43488
    mov edx, ecx
    mov bl, [eax + frame_state_186d48]
    mov [edx + edi], bl
    mov edx, [eax + frame_state_186d48]
    sar edx, byte 0x8
    and edx, strict dword 0xff
    inc ecx
    mov bl, dl
    mov edx, ecx
    mov [edx + edi], bl
    mov edx, [eax + frame_state_186d48]
    sar edx, byte 0x10
    and edx, strict dword 0xff
    inc ecx
    mov bl, dl
    mov edx, ecx
    mov [edx + edi], bl
    mov eax, [eax + frame_state_186d48]
    sar eax, byte 0x18
    and eax, strict dword 0xff
    inc ecx
    mov dl, al
    mov eax, ecx
    mov ebx, [esp]
    inc ecx
    mov [edi + eax], dl
    xor edx, edx
    jmp short .branch_43483

.branch_4346e:
    mov eax, ebx
    shl eax, byte 0x2
    inc edx
    sub eax, ebx
    mov esi, ecx
    mov al, [edx + eax*4 + frame_state_186d87]
    inc ecx
    mov [edi + esi], al

.branch_43483:
    cmp edx, 0xa
    jl short .branch_4346e

.branch_43488:
    inc dword [esp]

.branch_4348b:
    mov eax, [esp]
    cmp eax, 0x10
    jl near .branch_433fe
    mov eax, 0xffffffff
    movsx ebx, cx
    mov edx, edi
    call send_packet
    xor edx, edx
    mov [esp], edx
    jmp short .branch_434cf

.branch_434ad:
    cmp ebp, [nosplit eax*4 + frame_state_186d48]
    jnz short .branch_434c9
    movsx eax, word [esp]
    movsx ebx, cx
    mov edx, edi
    call send_packet
    jmp near network_control_return

.branch_434c9:
    lea ebx, [eax + 0x1]
    mov [esp], ebx

.branch_434cf:
    mov eax, [esp]
    cmp eax, 0x10
    jl short .branch_434ad
    jmp near network_control_return

.branch_434dc:
    xor eax, eax
    mov al, [transport]
    cmp eax, 0x5
    jnl short .branch_43521
    mov edx, 0x1
    mov esi, 0xffffffff
    mov edi, 0x2
    xor ebx, ebx
    mov [local_player], dx
    mov [first_player], bx
    mov [next_player], dx
    mov [frame_state_18fd7a], si
    mov [player_count], di
    jmp near network_control_return

.branch_43521:
    jl near network_control_return
    mov ecx, 0x1

.branch_4352c:
    movsx eax, si
    cmp ecx, eax
    jnl near network_control_return
    xor edx, edx
    mov dl, [ecx + edi + 0x1]
    mov ebx, edx
    xor edx, edx
    shl ebx, byte 0x8
    mov dl, [ecx + edi]
    add ebx, edx
    xor edx, edx
    mov dl, [ecx + edi + 0x2]
    shl edx, byte 0x10
    mov al, [ecx + edi + 0x3]
    add edx, ebx
    and eax, strict dword 0xff
    shl eax, byte 0x18
    add eax, edx
    lea edx, [ecx + 0x4]
    add edx, edi
    call initialize_network_peer_state
    add ecx, 0xe
    jmp short .branch_4352c

.branch_43571:
    xor eax, eax
    mov al, [transport]
    cmp eax, 0x5
    jl near network_control_return
    xor eax, eax
    mov al, [edx + 0x1]
    call uninitialize_network_peer_state
    jmp near network_control_return

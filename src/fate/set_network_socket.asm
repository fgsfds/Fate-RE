; Set network socket.
BITS 32
ORG 0x43734

transport equ 0x13cde
frame_state_13e64 equ 0x13e64
frame_state_186d92 equ 0x186d92
frame_state_186d93 equ 0x186d93
frame_state_18fdce equ 0x18fdce
frame_state_18fdcf equ 0x18fdcf
frame_state_18fde4 equ 0x18fde4

set_network_socket:
    push ebx
    push ecx
    push edx
    push esi
    mov esi, eax
    xor eax, eax
    mov al, [transport]
    cmp eax, 0x5
    jnl short .branch_43752
    mov [frame_state_13e64], si
    jmp near .branch_43803

.branch_43752:
    mov ebx, 0x1
    movsx edx, word [frame_state_13e64]
    xor ecx, ecx
    xor eax, eax
    int byte 0x7a
    mov ebx, 0x1
    movsx edx, si
    xor ecx, ecx
    xor eax, eax
    mov [frame_state_13e64], si
    int byte 0x7a
    mov eax, 0xff
    movsx edx, word [frame_state_13e64]
    xor ecx, ecx
    xor ebx, ebx
    int byte 0x7a
    test al, 0xff
    jz short .branch_43799
    mov eax, 0xfffffffe
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

.branch_43799:
    mov al, [frame_state_13e64]
    mov [frame_state_18fdce], al
    movsx eax, word [frame_state_13e64]
    sar eax, byte 0x8
    mov [frame_state_18fdcf], al
    mov eax, [frame_state_18fde4]
    mov dl, [frame_state_18fdce]
    mov [eax + 0xa], dl
    movsx eax, word [frame_state_13e64]
    sar eax, byte 0x8
    mov dl, al
    mov eax, [frame_state_18fde4]
    mov [eax + 0xb], dl
    mov cl, [frame_state_13e64]
    xor edx, edx
    jmp short .branch_437fe

.branch_437de:
    mov eax, edx
    shl eax, byte 0x2
    movsx ebx, word [frame_state_13e64]
    sub eax, edx
    sar ebx, byte 0x8
    mov [nosplit eax*4 + frame_state_186d92], cl
    inc edx
    mov [nosplit eax*4 + frame_state_186d93], bl

.branch_437fe:
    cmp edx, 0x10
    jl short .branch_437de

.branch_43803:
    xor eax, eax
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

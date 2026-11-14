; Shutdown network.
BITS 32
ORG 0x4164f

transport equ 0x13cde
player_count equ 0x13ce0
frame_state_13e64 equ 0x13e64
network_return equ 0x4164e
shutdown_serial_network equ 0x41cde

shutdown_network:
    cmp word [player_count], 0x0
    jng short network_return
    xor eax, eax
    mov al, [transport]
    cmp eax, 0x1
    jl short .branch_4166f
    cmp eax, 0x4
    jg short .branch_4166f
    call shutdown_serial_network

.branch_4166f:
    xor eax, eax
    mov al, [transport]
    cmp eax, 0x5
    jl short network_return
    push ebx
    push ecx
    push edx
    mov ebx, 0x1
    movsx edx, word [frame_state_13e64]
    xor ecx, ecx
    xor eax, eax
    int byte 0x7a
    pop edx
    pop ecx
    pop ebx
    ret

; Advance menu animation.
BITS 32
ORG 0x390c7

frame_state_12de0 equ 0x12de0
frame_state_12de4 equ 0x12de4
frame_state_13150 equ 0x13150
dispatch_period equ 0x35422
totalclock equ 0x287e88

advance_menu_animation:
    push ebx
    push ecx
    push edx
    push esi
    push ebp
    mov eax, [totalclock]
    cmp eax, [frame_state_13150]
    jng short .branch_3913b
    mov eax, [frame_state_12de0]
    mov ebx, [frame_state_12de4]
    mov ecx, [frame_state_12de0]
    add eax, strict dword 0x825
    inc ebx
    inc ecx
    mov [frame_state_12de4], ebx
    mov [frame_state_12de0], ecx
    cmp eax, strict dword 0x827
    jl short .branch_3910c
    xor esi, esi
    mov [frame_state_12de0], esi

.branch_3910c:
    cmp dword [frame_state_12de4], 0x4
    jl short .branch_3911d
    xor ebp, ebp
    mov [frame_state_12de4], ebp

.branch_3911d:
    mov eax, 0x10
    call dispatch_period
    mov edx, [totalclock]
    add eax, edx
    mov [frame_state_13150], eax
    mov eax, 0x1
    jmp short .branch_3913d

.branch_3913b:
    xor eax, eax

.branch_3913d:
    pop ebp
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

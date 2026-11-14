; Apply crush view kick.
BITS 32
ORG 0x40b49

frame_state_13bb4 equ 0x13bb4
player_horizon equ 0x62f8c
frame_state_17ab14 equ 0x17ab14
frame_state_17ab18 equ 0x17ab18

apply_crush_view_kick:
    push edx
    mov al, [frame_state_13bb4]
    cmp al, 0x1
    jc short .branch_40b7f
    jna short .branch_40b6d
    cmp al, 0x2
    jnz short .branch_40b7f
    mov eax, [frame_state_17ab14]
    mov [player_horizon], eax
    xor ah, ah
    mov [frame_state_13bb4], ah
    pop edx
    ret

.branch_40b6d:
    mov eax, [frame_state_17ab18]
    mov dl, 0x2
    mov [player_horizon], eax
    mov [frame_state_13bb4], dl

.branch_40b7f:
    pop edx
    ret

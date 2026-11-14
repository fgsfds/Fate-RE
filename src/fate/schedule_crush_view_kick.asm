; Schedule crush view kick.
BITS 32
ORG 0x40b14

frame_state_13bb4 equ 0x13bb4
player_horizon equ 0x62f8c
frame_state_17ab14 equ 0x17ab14
frame_state_17ab18 equ 0x17ab18

schedule_crush_view_kick:
    push edx
    test ax, ax
    jnl short .branch_40b47
    cmp byte [frame_state_13bb4], 0x0
    jnz short .branch_40b47
    mov dh, 0x1
    cwde
    mov [frame_state_13bb4], dh
    neg eax
    mov edx, [player_horizon]
    sar eax, byte 0x8
    add eax, edx
    add eax, 0x4
    mov [frame_state_17ab14], edx
    mov [frame_state_17ab18], eax

.branch_40b47:
    pop edx
    ret

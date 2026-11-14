; Set audio level a.
BITS 32
ORG 0x356dc

frame_state_12cdc equ 0x12cdc

set_audio_level_a:
    push ecx
    mov [frame_state_12cdc], eax
    cmp eax, 0x10
    jng short .branch_356f1
    mov dword [frame_state_12cdc], 0x10

.branch_356f1:
    cmp dword [frame_state_12cdc], 0x0
    jnl short .branch_35702
    xor ecx, ecx
    mov [frame_state_12cdc], ecx

.branch_35702:
    pop ecx
    ret

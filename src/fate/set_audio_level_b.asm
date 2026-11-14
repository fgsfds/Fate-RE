; Set audio level b.
BITS 32
ORG 0x3570a

frame_state_12ce0 equ 0x12ce0

set_audio_level_b:
    push ecx
    mov [frame_state_12ce0], eax
    cmp eax, 0x10
    jng short .branch_3571f
    mov dword [frame_state_12ce0], 0x10

.branch_3571f:
    cmp dword [frame_state_12ce0], 0x0
    jnl short .branch_35730
    xor ecx, ecx
    mov [frame_state_12ce0], ecx

.branch_35730:
    pop ecx
    ret

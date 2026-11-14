; Set audio flag a.
BITS 32
ORG 0x3569c

frame_state_12cd4 equ 0x12cd4

set_audio_flag_a:
    push ebx
    test eax, eax
    jna short .branch_356a8
    cmp eax, 0x1
    jz short .branch_356b2
    pop ebx
    ret

.branch_356a8:
    xor ebx, ebx
    mov [frame_state_12cd4], ebx
    pop ebx
    ret

.branch_356b2:
    mov [frame_state_12cd4], eax
    pop ebx
    ret

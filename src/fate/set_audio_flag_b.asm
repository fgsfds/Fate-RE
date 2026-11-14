; Set audio flag b.
BITS 32
ORG 0x356b9

frame_state_12cd8 equ 0x12cd8

set_audio_flag_b:
    push ebx
    test eax, eax
    jna short .branch_356c5
    cmp eax, 0x1
    jz short .branch_356cf
    pop ebx
    ret

.branch_356c5:
    xor ebx, ebx
    mov [frame_state_12cd8], ebx
    pop ebx
    ret

.branch_356cf:
    mov [frame_state_12cd8], eax
    pop ebx
    ret

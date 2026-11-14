; Restore text video mode.
BITS 32
ORG 0x36ac2

frame_state_12d70 equ 0x12d70
frame_state_12d74 equ 0x12d74
frame_state_12d78 equ 0x12d78
restore_engine_video_mode equ 0x4b04e

restore_text_video_mode:
    push ebx
    push edx
    mov ebx, [frame_state_12d78]
    xor eax, eax
    mov edx, [frame_state_12d74]
    mov al, [frame_state_12d70]
    call restore_engine_video_mode
    pop edx
    pop ebx
    ret

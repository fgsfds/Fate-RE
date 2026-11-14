; Video mode name.
BITS 32
ORG 0x36bf4

frame_state_12d30 equ 0x12d30

video_mode_name:
    mov eax, [nosplit eax*4 + frame_state_12d30]
    ret

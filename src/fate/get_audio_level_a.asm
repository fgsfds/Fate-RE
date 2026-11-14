; Get audio level a.
BITS 32
ORG 0x356d6

frame_state_12cdc equ 0x12cdc

get_audio_level_a:
    mov eax, [frame_state_12cdc]
    ret

; Get audio level b.
BITS 32
ORG 0x35704

frame_state_12ce0 equ 0x12ce0

get_audio_level_b:
    mov eax, [frame_state_12ce0]
    ret

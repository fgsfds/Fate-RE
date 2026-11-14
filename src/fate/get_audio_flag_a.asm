; Get audio flag a.
BITS 32
ORG 0x35683

frame_state_12cd4 equ 0x12cd4

get_audio_flag_a:
    cmp dword [frame_state_12cd4], 0x1
    setz al
    and eax, strict dword 0xff
    ret

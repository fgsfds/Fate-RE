; Get audio flag b.
BITS 32
ORG 0x35693

frame_state_12cd8 equ 0x12cd8
audio_flag_test_return equ 0x3568a

get_audio_flag_b:
    cmp dword [frame_state_12cd8], 0x1
    jmp short audio_flag_test_return

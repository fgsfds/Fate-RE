; Shutdown cd audio.
BITS 32
ORG 0x37a68

request_cd_disk_info equ 0x3784f
stop_cd_driver_playback equ 0x37a85
close equ 0x6219a
frame_state_173f96 equ 0x173f96

shutdown_cd_audio:
    call stop_cd_driver_playback
    movsx eax, word [frame_state_173f96]
    call request_cd_disk_info
    movsx eax, word [frame_state_173f96]
    jmp near close

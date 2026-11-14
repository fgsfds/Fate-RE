; Stop cd music.
BITS 32
ORG 0x37dee

cd_stopped_message equ 0xb9b
stop_cd_driver_playback equ 0x37a85
format_string equ 0x601f3
error_buffer equ 0x67e3c

stop_cd_music:
    call stop_cd_driver_playback
    push strict dword cd_stopped_message
    push strict dword error_buffer
    call format_string
    add esp, 0x8
    ret

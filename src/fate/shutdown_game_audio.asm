; Shut down the digital audio driver and close the sound archive.
BITS 32
ORG 0x34bf6

frame_state_12cd0 equ 0x12cd0
timer_remove_callback equ 0x60fa7
audio_system_shutdown equ 0x617d9
audio_driver_shutdown equ 0x61ca3
close equ 0x6219a
sound_archive_handle equ 0x1714e0
frame_state_1714e8 equ 0x1714e8
audio_enabled equ 0x171602

shutdown_game_audio:
    push ebx
    push edx
    cmp byte [audio_enabled], 0x0
    jz short .branch_34c33
    mov eax, [frame_state_1714e8]
    mov ebx, 0x1
    call timer_remove_callback
    mov eax, [frame_state_12cd0]
    mov edx, ebx
    call audio_driver_shutdown
    call audio_system_shutdown
    mov edx, [sound_archive_handle]
    cmp edx, -1
    jz short .branch_34c33
    mov eax, edx
    call close

.branch_34c33:
    pop edx
    pop ebx
    ret

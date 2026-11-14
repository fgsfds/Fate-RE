; Previous cd track.
BITS 32
ORG 0x37e4e

selected_cd_track equ 0x12d7c
set_track_and_play equ 0x37e26
play_selected_track equ 0x37e2b
first_cd_track equ 0x173f8e
last_cd_track equ 0x173f9a

previous_cd_track:
    push edx
    mov edx, [selected_cd_track]
    dec edx
    movsx eax, word [first_cd_track]
    mov [selected_cd_track], edx
    cmp eax, edx
    jng short play_selected_track
    movsx eax, word [last_cd_track]
    jmp short set_track_and_play

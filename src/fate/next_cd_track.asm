; Next cd track.
BITS 32
ORG 0x37e06

selected_cd_track equ 0x12d7c
active_cd_track equ 0x12d80
play_cd_track equ 0x37b22
first_cd_track equ 0x173f8e
last_cd_track equ 0x173f9a
frame_state_173faa equ 0x173faa

next_cd_track:
    push edx
    mov edx, [selected_cd_track]
    inc edx
    movsx eax, word [last_cd_track]
    mov [selected_cd_track], edx
    cmp eax, edx
    jnl short .play_selected_track
    movsx eax, word [first_cd_track]
    mov [selected_cd_track], eax

.play_selected_track:
    xor eax, eax
    mov al, [selected_cd_track]
    xor edx, edx
    call play_cd_track
    mov ax, [selected_cd_track]
    mov [frame_state_173faa], dx
    mov [active_cd_track], ax
    pop edx
    ret

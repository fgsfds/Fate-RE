; Toggle cd pause.
BITS 32
ORG 0x37d62

cd_paused_message equ 0xb80
cd_resumed_message equ 0xb8a
selected_cd_track equ 0x12d7c
active_cd_track equ 0x12d80
stop_cd_driver_playback equ 0x37a85
play_cd_track equ 0x37b22
resume_cd_driver_playback equ 0x37cd5
format_string equ 0x601f3
error_buffer equ 0x67e3c
frame_state_173faa equ 0x173faa

toggle_cd_pause:
    push edx
    push edi
    mov dx, [active_cd_track]
    test dx, dx
    jz short .branch_37d9e
    call stop_cd_driver_playback
    push strict dword cd_paused_message
    mov edx, 0x1
    xor eax, eax
    push strict dword error_buffer
    mov [active_cd_track], ax
    mov [frame_state_173faa], dx

.branch_37d93:
    call format_string
    add esp, 0x8
    pop edi
    pop edx
    ret

.branch_37d9e:
    cmp word [frame_state_173faa], 0x0
    jz short .branch_37dcc
    mov edi, 0x1
    mov [frame_state_173faa], dx
    mov [active_cd_track], di
    call resume_cd_driver_playback
    push strict dword cd_resumed_message
    push strict dword error_buffer
    jmp short .branch_37d93

.branch_37dcc:
    xor eax, eax
    mov al, [selected_cd_track]
    call play_cd_track
    mov ax, [selected_cd_track]
    mov [frame_state_173faa], dx
    mov [active_cd_track], ax
    pop edi
    pop edx
    ret

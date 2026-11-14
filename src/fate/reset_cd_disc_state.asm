; Reset cd disc state.
BITS 32
ORG 0x37e70

cd_reset_message equ 0xbac
selected_cd_track equ 0x12d7c
active_cd_track equ 0x12d80
request_cd_disk_info equ 0x3784f
read_cd_track_info equ 0x3786d
read_cd_track_start equ 0x378d8
format_string equ 0x601f3
error_buffer equ 0x67e3c
first_cd_track equ 0x173f8e
frame_state_173f96 equ 0x173f96
last_cd_track equ 0x173f9a
frame_state_173faa equ 0x173faa

reset_cd_disc_state:
    push ebx
    push edx
    movsx eax, word [frame_state_173f96]
    call request_cd_disk_info
    movsx eax, word [frame_state_173f96]
    call read_cd_track_info
    movsx ebx, word [first_cd_track]
    jmp short .branch_37ea4

.branch_37e93:
    xor edx, edx
    movsx eax, word [frame_state_173f96]
    mov dl, bl
    call read_cd_track_start
    inc ebx

.branch_37ea4:
    movsx eax, word [last_cd_track]
    cmp ebx, eax
    jng short .branch_37e93
    push strict dword cd_reset_message
    movsx eax, word [first_cd_track]
    xor edx, edx
    push strict dword error_buffer
    mov [selected_cd_track], eax
    mov [active_cd_track], dx
    mov [frame_state_173faa], dx
    call format_string
    add esp, 0x8
    pop edx
    pop ebx
    ret

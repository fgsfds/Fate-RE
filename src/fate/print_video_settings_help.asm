; Print video settings help.
BITS 32
ORG 0x3707f

frame_state_a51 equ 0xa51
frame_state_a53 equ 0xa53
frame_state_a66 equ 0xa66
frame_state_a7e equ 0xa7e
frame_state_12d30 equ 0x12d30
frame_state_12d70 equ 0x12d70
frame_state_12d74 equ 0x12d74
frame_state_12d78 equ 0x12d78
print_video_text equ 0x36adf
set_cursor_enabled equ 0x6f5bd

print_video_settings_help:
    push ebx
    push ecx
    push edx
    mov eax, 0x1
    call set_cursor_enabled
    push strict dword frame_state_a51
    call print_video_text
    mov eax, [frame_state_12d70]
    add esp, 0x4
    mov edx, [nosplit eax*4 + frame_state_12d30]
    push edx
    push strict dword frame_state_a53
    call print_video_text
    add esp, 0x8
    mov ebx, [frame_state_12d78]
    push ebx
    mov ecx, [frame_state_12d74]
    push ecx
    push strict dword frame_state_a66
    call print_video_text
    add esp, 0xc
    push strict dword frame_state_a51
    call print_video_text
    add esp, 0x4
    push strict dword frame_state_a7e
    call print_video_text
    add esp, 0x4
    pop edx
    pop ecx
    pop ebx
    ret

; Initialize video console.
BITS 32
ORG 0x36b6a

frame_state_9cb equ 0x9cb
frame_state_9d1 equ 0x9d1
frame_state_9db equ 0x9db
print_video_text_at equ 0x36b0e
set_video_mode equ 0x6ec8a
set_background_color equ 0x6f1bf
set_text_color equ 0x6f25d
set_text_window equ 0x6f2e7
clear_screen equ 0x6f42c

initialize_video_console:
    push ebx
    push ecx
    push edx
    mov eax, 0x3
    mov ecx, 0x50
    call set_video_mode
    mov eax, 0x7
    mov ebx, 0x2
    call set_background_color
    mov eax, 0xf
    mov edx, 0x1
    call set_text_color
    mov eax, edx
    call set_text_window
    mov eax, 0x2
    call clear_screen
    push strict dword frame_state_9cb
    push strict dword frame_state_9d1
    push strict dword frame_state_9db
    push strict byte 0x1
    push strict byte -1
    mov ecx, 0x50
    mov ebx, 0x19
    call print_video_text_at
    add esp, 0x14
    xor eax, eax
    mov edx, 0x1
    call set_background_color
    mov eax, 0x2
    call set_text_window
    mov eax, 0x2
    call clear_screen
    pop edx
    pop ecx
    pop ebx
    ret

; Initialize game subsystems.
BITS 32
ORG 0x3b272

art_archive_filename equ 0x131c
slime_allocation_error equ 0x1329
network_enabled equ 0x3c98
frame_state_3c99 equ 0x3c99
frame_state_13ba8 equ 0x13ba8
frame_state_13ba9 equ 0x13ba9
frame_state_13baa equ 0x13baa
frame_state_13bab equ 0x13bab
frame_state_13bac equ 0x13bac
frame_state_13bad equ 0x13bad
frame_state_13baf equ 0x13baf
report_error equ 0x26a03
initialize_ripple_tables equ 0x2eaa2
install_keyboard_interrupt equ 0x2f1fe
initialize_game_timer equ 0x34811
load_sound_archive equ 0x34956
initialize_game_audio equ 0x34a5a
initialize_sound_slots equ 0x34b13
load_video_settings equ 0x36952
save_video_settings equ 0x36a16
restore_text_video_mode equ 0x36ac2
initialize_video_console equ 0x36b6a
print_video_settings_help equ 0x3707f
open_text_archive equ 0x3803e
sub_41542 equ 0x41542
allocate_permanent_tile equ 0x4bc8e
load_art_files equ 0x4bd46
sub_5440e equ 0x5440e
engine_1ed1a0 equ 0x1ed1a0
frame_state_1ed1a2 equ 0x1ed1a2
engine_289150 equ 0x289150

initialize_game_subsystems:
    push ebx
    push ecx
    push edx
    call load_sound_archive
    call initialize_sound_slots
    call sub_5440e
    call initialize_video_console
    xor eax, eax
    call load_video_settings
    xor eax, eax
    mov dl, 0x1
    call save_video_settings
    call print_video_settings_help
    call restore_text_video_mode
    mov ah, 0x1
    xor ebx, ebx
    mov [frame_state_13bad], ah
    call install_keyboard_interrupt
    mov [frame_state_13bac], dl
    call initialize_game_timer
    mov [frame_state_13bab], dl
    xor eax, eax
    xor edx, edx
    mov al, [network_enabled]
    mov dl, [frame_state_3c99]
    mov ecx, 0x1
    call sub_41542
    mov bl, 0x1
    xor edx, edx
    mov [frame_state_13ba8], bl
    call initialize_game_audio
    mov eax, art_archive_filename
    mov [frame_state_13ba9], bl
    mov [engine_1ed1a0], dx
    mov [frame_state_1ed1a2], dx
    mov [engine_289150], cx
    call load_art_files
    mov ebx, 0x80
    mov eax, 0x122
    mov edx, ebx
    call allocate_permanent_tile
    test eax, eax
    jnz short .branch_3b32f
    mov eax, slime_allocation_error
    call report_error

.branch_3b32f:
    xor cl, cl
    mov [frame_state_13baa], cl
    mov ch, 0x1
    call open_text_archive
    mov [frame_state_13baf], ch
    call initialize_ripple_tables
    pop edx
    pop ecx
    pop ebx
    ret

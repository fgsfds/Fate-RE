; Initialize digital audio and register its timer callback.
BITS 32
ORG 0x34a5a

audio_system_init_error equ 0x789
audio_driver_init_error equ 0x7b6
audio_callback_error equ 0x7e3
audio_configuration_error equ 0x814
frame_state_12cd0 equ 0x12cd0
report_error equ 0x26a03
read_audio_configuration equ 0x3488d
timer_register_callback equ 0x60c51
audio_system_init equ 0x6177d
audio_system_shutdown equ 0x617d9
audio_driver_init equ 0x61840
frame_state_1714e8 equ 0x1714e8
frame_state_1714ec equ 0x1714ec
frame_state_1714f0 equ 0x1714f0
frame_state_171530 equ 0x171530
frame_state_1715f0 equ 0x1715f0
frame_state_1715f4 equ 0x1715f4
audio_enabled equ 0x171602

initialize_game_audio:
    push ebx
    push edx
    call read_audio_configuration
    test eax, eax
    jz near .branch_34afe
    mov eax, [frame_state_1715f0]
    cmp eax, -1
    jl short .branch_34a82
    test eax, eax
    jg short .branch_34a82
    xor dl, dl
    mov [audio_enabled], dl
    pop edx
    pop ebx
    ret

.branch_34a82:
    xor edx, edx
    xor eax, eax
    call audio_system_init
    test eax, eax
    jz short .branch_34a99
    mov eax, audio_system_init_error
    call report_error

.branch_34a99:
    mov edx, 0x2b11
    mov ebx, 0x2000
    mov eax, frame_state_1714ec
    mov [frame_state_1714f0], edx
    mov edx, frame_state_12cd0
    mov [frame_state_171530], ebx
    call audio_driver_init
    test eax, eax
    jz short .branch_34ad1
    call audio_system_shutdown
    mov eax, audio_driver_init_error
    call report_error

.branch_34ad1:
    mov ebx, frame_state_1714e8
    mov eax, 0x28
    mov edx, [frame_state_1715f4]
    call timer_register_callback
    test eax, eax
    jz short .branch_34af4
    mov eax, audio_callback_error
    call report_error

.branch_34af4:
    mov byte [audio_enabled], 0x1
    pop edx
    pop ebx
    ret

.branch_34afe:
    xor ah, ah
    mov [audio_enabled], ah
    mov eax, audio_configuration_error
    call report_error
    pop edx
    pop ebx
    ret

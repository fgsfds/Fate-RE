; Run audio menu.
BITS 32
ORG 0x3af2b

frame_state_12d6 equ 0x12d6
get_audio_flag_a equ 0x35683
get_audio_flag_b equ 0x35693
set_audio_flag_a equ 0x3569c
set_audio_flag_b equ 0x356b9
get_audio_level_a equ 0x356d6
set_audio_level_a equ 0x356dc
get_audio_level_b equ 0x35704
set_audio_level_b equ 0x3570a
run_menu_loop equ 0x3963b
frame_state_1745e8 equ 0x1745e8
frame_state_1745ec equ 0x1745ec
frame_state_1745f0 equ 0x1745f0
frame_state_1745f4 equ 0x1745f4
frame_state_1745fc equ 0x1745fc

    nop

audio_dispatch:
    dd run_audio_menu.menu_case_3af99 - 0x10000
    dd run_audio_menu.menu_case_3af99 - 0x10000
    dd run_audio_menu.menu_case_3aff4 - 0x10000
    dd run_audio_menu.menu_case_3b00c - 0x10000
    dd run_audio_menu.menu_case_3b027 - 0x10000

run_audio_menu:
    push ebx
    push ecx
    push edx
    call get_audio_flag_a
    mov ebx, [frame_state_1745f0]
    mov [ebx + 0x7], eax
    call get_audio_flag_b
    mov ebx, [frame_state_1745f4]
    mov [ebx + 0x7], eax
    call get_audio_level_a
    mov ebx, eax
    mov eax, [frame_state_1745e8]
    mov [eax + 0x7], ebx
    call get_audio_level_b
    mov ebx, [frame_state_1745ec]
    mov [ebx + 0x7], eax
    mov eax, [frame_state_1745e8]
    mov dword [eax + 0xb], 0x10
    mov eax, [frame_state_1745ec]
    mov edx, 0x1
    mov dword [eax + 0xb], 0x10

.branch_3af99:
.menu_case_3af99:
    test edx, edx
    jz near .branch_3b02e
    mov ebx, 0x821
    push strict dword frame_state_1745e8
    mov ecx, frame_state_12d6
    mov edx, 0x5
    mov eax, frame_state_1745fc
    movsx ebx, bx
    call run_menu_loop
    mov edx, eax
    test eax, eax
    jz short .branch_3af99
    mov eax, [frame_state_1745e8]
    mov eax, [eax + 0x7]
    call set_audio_level_a
    mov eax, [frame_state_1745ec]
    mov eax, [eax + 0x7]
    call set_audio_level_b
    mov eax, [frame_state_1745fc]
    cmp eax, 0x4
    ja short .branch_3af99
    jmp dword near [cs:eax*4 + audio_dispatch - 0x10000]
.menu_case_3aff4:
    mov eax, [frame_state_1745f0]
    xor byte [eax + 0x7], 0x1
    mov eax, [frame_state_1745f0]
    mov eax, [eax + 0x7]
    call set_audio_flag_a
    jmp short .branch_3af99
.menu_case_3b00c:
    mov eax, [frame_state_1745f4]
    xor byte [eax + 0x7], 0x1
    mov eax, [frame_state_1745f4]
    mov eax, [eax + 0x7]
    call set_audio_flag_b
    jmp near .branch_3af99
.menu_case_3b027:
    xor edx, edx
    jmp near .branch_3af99

.branch_3b02e:
    mov eax, edx
    pop edx
    pop ecx
    pop ebx
    ret

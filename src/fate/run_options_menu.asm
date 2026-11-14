; Run options menu.
BITS 32
ORG 0x397db

frame_state_c4f equ 0xc4f
frame_state_cf7 equ 0xcf7
frame_state_d04 equ 0xd04
save_game_configuration equ 0x38291
run_menu_loop equ 0x3963b
run_settings_menu equ 0x3976c
settings_menu_return equ 0x397d5
sub_3af40 equ 0x3af40
sub_3b05b equ 0x3b05b
frame_state_770f8 equ 0x770f8
frame_state_174010 equ 0x174010
frame_state_1740e8 equ 0x1740e8

    nop

options_dispatch:
    dd run_options_menu.menu_case_39809 - 0x10000
    dd run_options_menu.menu_case_39841 - 0x10000
    dd run_options_menu.menu_case_39835 - 0x10000
    dd run_options_menu.menu_case_3987e - 0x10000
    dd run_options_menu.menu_case_39885 - 0x10000
    dd run_options_menu.menu_case_3988c - 0x10000

run_options_menu:
    push ebx
    push ecx
    push edx
    mov ebx, 0x5
    mov edx, 0x1
    mov [frame_state_1740e8], ebx
    jmp short .branch_39841
.menu_case_39809:
    xor byte [frame_state_770f8], 0x1
    cmp dword [frame_state_770f8], 0x0
    jz short .branch_39827
    mov eax, [frame_state_174010]
    mov dword [eax + 0x3], frame_state_c4f
    jmp short .branch_39841

.branch_39827:
    mov eax, [frame_state_174010]
    mov dword [eax + 0x3], frame_state_d04
    jmp short .branch_39841
.menu_case_39835:
    call sub_3af40

.branch_3983a:
    xor eax, eax
    call save_game_configuration

.branch_39841:
.menu_case_39841:
    test edx, edx
    jz short settings_menu_return
    mov ebx, 0x820
    push strict dword frame_state_174010
    mov ecx, frame_state_cf7
    mov edx, 0x6
    mov eax, frame_state_1740e8
    movsx ebx, bx
    call run_menu_loop
    mov edx, eax
    test eax, eax
    jz short .branch_39841
    mov eax, [frame_state_1740e8]
    cmp eax, 0x5
    ja short .branch_39841
    jmp dword near [cs:eax*4 + options_dispatch - 0x10000]
.menu_case_3987e:
    call run_settings_menu
    jmp short .branch_39841
.menu_case_39885:
    call sub_3b05b
    jmp short .branch_3983a
.menu_case_3988c:
    xor edx, edx
    jmp short .branch_39841

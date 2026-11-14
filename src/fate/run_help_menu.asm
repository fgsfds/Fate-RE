; Run help menu.
BITS 32
ORG 0x3a8ab

frame_state_1156 equ 0x1156
run_menu_loop equ 0x3963b
run_first_help_pages equ 0x3a7b2
run_second_help_pages equ 0x3a800
run_help_submenu equ 0x3a871
frame_state_17456c equ 0x17456c
frame_state_17458c equ 0x17458c

    nop

help_dispatch:
    dd run_help_menu.first_help_page_set - 0x10000
    dd run_help_menu.second_help_page_set - 0x10000
    dd run_help_menu.help_submenu - 0x10000
    dd run_help_menu.leave_menu - 0x10000

run_help_menu:
    push ebx
    push ecx
    push edx
    mov edx, 0x1

.branch_3a8c4:
    test edx, edx
    jz short .branch_3a91a
    mov ebx, 0x820
    push strict dword frame_state_17456c
    mov ecx, frame_state_1156
    mov edx, 0x4
    mov eax, frame_state_17458c
    movsx ebx, bx
    call run_menu_loop
    mov edx, eax
    test eax, eax
    jz short .branch_3a8c4
    mov eax, [frame_state_17458c]
    cmp eax, 0x3
    ja short .branch_3a8c4
    jmp dword near [cs:eax*4 + help_dispatch - 0x10000]
.second_help_page_set:
    call run_first_help_pages
    jmp short .branch_3a8c4
.first_help_page_set:
    call run_second_help_pages
    jmp short .branch_3a8c4
.help_submenu:
    call run_help_submenu
    jmp short .branch_3a8c4
.leave_menu:
    xor edx, edx
    jmp short .branch_3a8c4

.branch_3a91a:
    mov eax, edx
    pop edx
    pop ecx
    pop ebx
    ret

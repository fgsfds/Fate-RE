; Retained resume path shared by table choices 5 and 6.
BITS 32
ORG 0x3a2f3
frame_state_772b8 equ 0x772b8
main_menu_success equ 0x3a204
main_menu_clear_result equ 0x3a332

main_menu_resume:
    cmp dword [frame_state_772b8], 0
    jnz near main_menu_success
    jmp short main_menu_clear_result

; Retained false-path jump after the compiler-generated resume guard.
BITS 32
ORG 0x3a300
main_menu_clear_result equ 0x3a332

main_menu_resume_jump:
    jmp short main_menu_clear_result

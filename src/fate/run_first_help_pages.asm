; Run first help pages.
BITS 32
ORG 0x3a7b2

run_help_page_menu equ 0x3a753
frame_state_174580 equ 0x174580
frame_state_174584 equ 0x174584
frame_state_174594 equ 0x174594

run_first_help_pages:
    push edx
    xor edx, edx

.branch_3a7b5:
    mov eax, [frame_state_174580]
    mov byte [eax], 0x1
    mov eax, [frame_state_174584]
    mov byte [eax], 0x1
    test edx, edx
    jnz short .branch_3a7d7
    mov eax, [frame_state_174584]
    mov byte [eax], 0x0
    mov [frame_state_174594], edx

.branch_3a7d7:
    lea eax, [edx + 0x834]
    call run_help_page_menu
    cmp eax, 0xfffffffffffffffe
    jc short .branch_3a7fc
    jna short .branch_3a7f5
    cmp eax, -1
    jnz short .branch_3a7fc
    test edx, edx
    jnl short .branch_3a7b5
    inc edx
    jmp short .branch_3a7b5

.branch_3a7f5:
    test edx, edx
    jng short .branch_3a7b5
    dec edx
    jmp short .branch_3a7b5

.branch_3a7fc:
    xor eax, eax
    pop edx
    ret

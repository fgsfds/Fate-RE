; Run second help pages.
BITS 32
ORG 0x3a800

run_help_page_menu equ 0x3a753
frame_state_174580 equ 0x174580
frame_state_174584 equ 0x174584
frame_state_174594 equ 0x174594

run_second_help_pages:
    push ebx
    push ecx
    push edx
    mov ebx, 0x1
    xor edx, edx

.branch_3a80a:
    mov eax, [frame_state_174580]
    mov byte [eax], 0x1
    mov eax, [frame_state_174584]
    mov byte [eax], 0x1
    test edx, edx
    jna short .branch_3a825
    cmp edx, 0x2
    jz short .branch_3a837
    jmp short .branch_3a845

.branch_3a825:
    mov eax, [frame_state_174584]
    xor ecx, ecx
    mov byte [eax], 0x0
    mov [frame_state_174594], ecx
    jmp short .branch_3a845

.branch_3a837:
    mov eax, [frame_state_174580]
    mov byte [eax], 0x0
    mov [frame_state_174594], ebx

.branch_3a845:
    lea eax, [edx + 0x835]
    call run_help_page_menu
    cmp eax, 0xfffffffffffffffe
    jc short .branch_3a86b
    jna short .branch_3a864
    cmp eax, -1
    jnz short .branch_3a86b
    cmp edx, 0x2
    jnl short .branch_3a80a
    inc edx
    jmp short .branch_3a80a

.branch_3a864:
    test edx, edx
    jng short .branch_3a80a
    dec edx
    jmp short .branch_3a80a

.branch_3a86b:
    xor eax, eax
    pop edx
    pop ecx
    pop ebx
    ret

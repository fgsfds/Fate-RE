; Run help page menu.
BITS 32
ORG 0x3a753

frame_state_1147 equ 0x1147
run_menu_loop equ 0x3963b
frame_state_174580 equ 0x174580
frame_state_174594 equ 0x174594

run_help_page_menu:
    push ebx
    push ecx
    push edx
    push esi
    mov esi, eax
    mov eax, 0x1

.branch_3a75e:
    cmp eax, 0x1
    jnz short .branch_3a7ad
    push strict dword frame_state_174580
    mov ecx, frame_state_1147
    mov edx, 0x3
    mov eax, frame_state_174594
    movsx ebx, si
    call run_menu_loop
    test eax, eax
    jz short .branch_3a75e
    mov edx, [frame_state_174594]
    cmp edx, 0x1
    jc short .branch_3a797
    jna short .branch_3a7a2
    cmp edx, 0x2
    jz short .branch_3a7a9
    jmp short .branch_3a75e

.branch_3a797:
    test edx, edx
    jnz short .branch_3a75e
    mov eax, 0xffffffff
    jmp short .branch_3a75e

.branch_3a7a2:
    mov eax, 0xfffffffe
    jmp short .branch_3a75e

.branch_3a7a9:
    xor eax, eax
    jmp short .branch_3a75e

.branch_3a7ad:
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

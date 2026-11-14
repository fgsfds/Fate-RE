; Reset display state and set the gameplay viewport.
BITS 32
ORG 0x2e52b

draw_view_border equ 0x346f2
sub_4a480 equ 0x4a480
setview equ 0x56f0a
outp equ 0x6039a
status_minimum_width equ 0x7ded8
presentation_height equ 0x287e8c
presentation_width equ 0x287e90

initialize_board_sprite_state:
    push ebx
    push ecx
    push edx
    push esi
    call sub_4a480
    mov edx, 0xff
    mov eax, 0x3c8
    call outp
    mov eax, 0x3c9
    xor edx, edx
    call outp
    mov eax, 0x3c9
    xor edx, edx
    call outp
    mov eax, 0x3c9
    xor edx, edx
    call outp
    movsx eax, word [status_minimum_width]
    mov edx, [presentation_width]
    cmp eax, edx
    jng short .branch_2e588
    mov ecx, [presentation_height]
    lea ebx, [edx-0x1]
    xor eax, eax
    dec ecx
    xor edx, edx
    jmp short .branch_2e5bd

.branch_2e588:
    mov esi, edx
    mov edx, [presentation_height]
    imul edx, eax
    sub esi, eax
    sar esi, 1
    mov ecx, [presentation_width]
    lea ebx, [esi + eax]
    mov eax, edx
    sar edx, byte 0x1f
    idiv ecx
    mov ecx, eax
    mov edx, [presentation_height]
    sar ecx, 1
    sar edx, 1
    sub edx, ecx
    add eax, edx
    lea ecx, [eax-0x1]
    dec ebx
    mov eax, esi

.branch_2e5bd:
    call setview
    movsx eax, word [status_minimum_width]
    mov esi, [presentation_width]
    cmp eax, esi
    jnl short .branch_2e5f7
    mov eax, [presentation_height]
    push strict byte 0x0
    dec eax
    push eax
    lea eax, [esi-0x1]
    push eax
    push strict byte 0x0
    mov ecx, 0x8
    mov ebx, 0x48
    push strict byte 0x0
    xor edx, edx
    xor eax, eax
    call draw_view_border

.branch_2e5f7:
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

; Draw menu frame.
BITS 32
ORG 0x39511

small_text_return equ 0x386cd
draw_menu_entries equ 0x38ac0
advance_menu_animation equ 0x390c7
draw_menu_selection_marker equ 0x39143
sub_39c45 equ 0x39c45
nextpage equ 0x4b496
rotatesprite equ 0x57181
frame_state_772b8 equ 0x772b8
frame_state_173fc0 equ 0x173fc0
presentation_height equ 0x287e8c
presentation_width equ 0x287e90

draw_menu_frame:
    push esi
    push edi
    push ebp
    sub esp, 0x4
    mov edi, eax
    mov [esp], edx
    mov esi, ebx
    mov ebp, ecx
    call advance_menu_animation
    test eax, eax
    jnz short .branch_39536
    cmp dword [frame_state_772b8], 0x0
    jz near .branch_39633

.branch_39536:
    movsx eax, si
    cmp eax, strict dword 0x820
    jz short .branch_3954e
    cmp eax, strict dword 0x874
    jz short .branch_3954e
    cmp eax, strict dword 0x875
    jnz short .branch_3957a

.branch_3954e:
    mov eax, [presentation_height]
    dec eax
    push eax
    mov eax, [presentation_width]
    dec eax
    push eax
    push strict byte 0x0
    push strict byte 0x0
    push strict dword 0x92
    push strict byte 0x0
    push strict byte 0x0
    mov ebx, 0x10000
    xor ecx, ecx
    push strict dword 0x81f
    jmp near .branch_395ee

.branch_3957a:
    cmp eax, strict dword 0x834
    jl short .branch_395ac
    jg short .branch_395ac

.branch_39583:
    mov eax, [presentation_height]
    dec eax
    push eax
    mov eax, [presentation_width]
    dec eax
    push eax
    push strict byte 0x0
    push strict byte 0x0
    push strict dword 0x92
    push strict byte 0x0
    push strict byte 0x0
    mov ebx, 0x10000
    xor ecx, ecx
    push strict dword 0x821
    jmp short .branch_395ee

.branch_395ac:
    movsx eax, si
    cmp eax, strict dword 0x835
    jl short .branch_395bd
    cmp eax, strict dword 0x837
    jng short .branch_39583

.branch_395bd:
    movsx eax, si
    cmp eax, strict dword 0x83e
    jnz short .branch_395f7
    mov eax, [presentation_height]
    dec eax
    push eax
    mov eax, [presentation_width]
    dec eax
    push eax
    push strict byte 0x0
    push strict byte 0x0
    push strict dword 0x92
    push strict byte 0x0
    push strict byte 0x0
    mov ebx, 0x10000
    xor ecx, ecx
    push strict dword 0x821

.branch_395ee:
    xor edx, edx
    xor eax, eax
    call rotatesprite

.branch_395f7:
    mov ebx, [esp + 0x14]
    mov ecx, ebp
    push ebx
    movsx ebx, si
    movsx esi, word [esp + 0x4]
    mov eax, edi
    mov edx, esi
    call draw_menu_entries
    mov ebx, [esp + 0x14]
    movsx eax, di
    mov edx, esi
    mov ecx, [esp + 0x14]
    call draw_menu_selection_marker
    cmp ecx, frame_state_173fc0
    jnz short .branch_3962e
    call sub_39c45

.branch_3962e:
    call nextpage

.branch_39633:
    add esp, 0x4
    jmp near small_text_return

; Run menu loop.
BITS 32
ORG 0x3963b

frame_state_12dd4 equ 0x12dd4
frame_state_1314d equ 0x1314d
presentation_reset equ 0x36246
small_text_return equ 0x386cd
update_menu_selection equ 0x39235
draw_menu_frame equ 0x39511
sub_39cfa equ 0x39cfa
frame_state_173fc0 equ 0x173fc0
frame_state_174048 equ 0x174048
frame_state_1740f0 equ 0x1740f0
frame_state_1740f4 equ 0x1740f4
frame_state_1740f8 equ 0x1740f8
frame_state_1740fc equ 0x1740fc
frame_state_17455c equ 0x17455c

run_menu_loop:
    push esi
    push edi
    push ebp
    sub esp, 0x8
    mov esi, [esp + 0x18]
    mov [esp], edx
    mov edi, ebx
    mov ebp, ecx
    mov edx, 0xffffffff
    mov ebx, 0x1
    mov [frame_state_1740f4], eax
    mov [frame_state_12dd4], ebx
    xor ecx, ecx
    mov eax, [eax]
    mov [esp + 0x4], edx
    mov [frame_state_1740f0], eax
    mov eax, [esp]
    mov [frame_state_1740fc], ecx
    mov [frame_state_1740f8], eax
    xor eax, eax
    jmp short .branch_396a9

.branch_39680:
    mov ebx, eax
    mov ecx, [esi + ebx*4]
    mov [nosplit eax*4 + frame_state_174048], ecx
    cmp byte [ecx], 0x0
    jz short .branch_396a8
    mov edx, 0x1
    mov cl, al
    mov ebx, [frame_state_1740fc]
    shl edx, cl
    or ebx, edx
    mov [frame_state_1740fc], ebx

.branch_396a8:
    inc eax

.branch_396a9:
    cmp eax, [esp]
    jl short .branch_39680
    call presentation_reset

.branch_396b3:
    mov ecx, [frame_state_12dd4]
    cmp ecx, 0x1
    jnz near .branch_39738
    cmp esi, frame_state_17455c
    jnz short .branch_396e5
    mov eax, [frame_state_1740f0]
    test eax, eax
    jna short .branch_396d9
    cmp eax, ecx
    jz short .branch_396e0
    jmp short .branch_396e5

.branch_396d9:
    mov edi, 0x874
    jmp short .branch_396e5

.branch_396e0:
    mov edi, 0x875

.branch_396e5:
    mov edx, [frame_state_1740f8]
    mov eax, [frame_state_1740f0]
    push esi
    movsx ebx, di
    mov ecx, ebp
    call draw_menu_frame
    call update_menu_selection
    cmp esi, frame_state_173fc0
    jnz short .branch_3972a
    mov edx, [esp + 0x4]
    cmp edx, [frame_state_1740f0]
    jz short .branch_3972a
    xor eax, eax
    mov al, [frame_state_1314d]
    cmp eax, 0x1
    jnz short .branch_3972a
    mov eax, [frame_state_1740f0]
    call sub_39cfa

.branch_3972a:
    mov eax, [frame_state_1740f0]
    mov [esp + 0x4], eax
    jmp near .branch_396b3

.branch_39738:
    cmp ecx, -1
    jnz short .branch_39749
    xor edi, edi
    xor eax, eax
    mov [frame_state_12dd4], edi
    jmp short .branch_3974e

.branch_39749:
    mov eax, 0x1

.branch_3974e:
    add esp, 0x8
    jmp near small_text_return

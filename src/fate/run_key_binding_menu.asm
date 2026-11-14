; Run key binding menu.
BITS 32
ORG 0x3a492

frame_state_d84 equ 0xd84
frame_state_1098 equ 0x1098
frame_state_10a0 equ 0x10a0
frame_state_10b0 equ 0x10b0
frame_state_10bc equ 0x10bc
frame_state_13154 equ 0x13154
frame_state_13558 equ 0x13558
frame_state_1363c equ 0x1363c
key_forward equ 0x1363d
play_sound equ 0x34f79
presentation_input equ 0x3625c
draw_menu_frame equ 0x39511
run_menu_loop equ 0x3963b
validate_key_binding equ 0x3a3b0
format_string equ 0x601f3
frame_state_1741f0 equ 0x1741f0
frame_state_1741f4 equ 0x1741f4
frame_state_17425c equ 0x17425c
frame_state_174268 equ 0x174268

run_key_binding_menu:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    xor ebx, ebx

.branch_3a49a:
    xor eax, eax
    mov al, [ebx + key_forward]
    mov edx, [nosplit eax*4 + frame_state_13154]
    mov eax, ebx
    push edx
    shl eax, byte 0x4
    mov ecx, [nosplit ebx*8 + frame_state_13558]
    sub eax, ebx
    push ecx
    add eax, eax
    push strict dword frame_state_1098
    add eax, frame_state_174268
    mov edx, ebx
    push eax
    xor edx, ebx
    inc ebx
    call format_string
    mov eax, [nosplit ebx*4 + frame_state_1741f0]
    mov dl, [ebx + frame_state_1363c]
    add esp, 0x10
    mov [eax + 0x7], edx
    cmp ebx, 0x19
    jl short .branch_3a49a
    mov edi, 0x1

.branch_3a4ed:
    test edi, edi
    jz near .branch_3a63b
    mov esi, 0x83d
    push strict dword frame_state_1741f4
    mov ecx, frame_state_10a0
    mov edx, 0x19
    mov eax, frame_state_17425c
    movsx ebx, si
    call run_menu_loop
    mov edi, eax
    test eax, eax
    jz short .branch_3a4ed
    mov eax, [frame_state_17425c]
    mov ebx, eax
    mov ebp, [nosplit eax*8 + frame_state_13558]
    shl eax, byte 0x4
    push strict dword frame_state_d84
    sub eax, ebx
    push ebp
    add eax, eax
    push strict dword frame_state_1098
    add eax, frame_state_174268
    push eax
    call format_string
    mov eax, [frame_state_17425c]
    mov eax, [nosplit eax*4 + frame_state_1741f4]
    add esp, 0x10
    mov ebp, [eax + 0x7]

.branch_3a559:
    call presentation_input
    mov ebx, eax
    test eax, eax
    jnz short .branch_3a582
    push strict dword frame_state_1741f4
    mov ecx, frame_state_10b0
    mov edx, 0x19
    mov eax, [frame_state_17425c]
    movsx ebx, si
    call draw_menu_frame
    jmp short .branch_3a559

.branch_3a582:
    mov edx, [frame_state_17425c]
    call validate_key_binding
    cmp eax, 0x1
    jnz short .branch_3a5d9
    mov eax, ebx
    mov ecx, [nosplit eax*4 + frame_state_13154]
    mov eax, [frame_state_17425c]
    push ecx
    mov esi, [nosplit eax*8 + frame_state_13558]
    push esi
    mov esi, eax
    shl eax, byte 0x4
    sub eax, esi
    add eax, eax
    push strict dword frame_state_1098
    add eax, frame_state_174268
    push eax
    call format_string
    mov eax, [frame_state_17425c]
    mov eax, [nosplit eax*4 + frame_state_1741f4]
    add esp, 0x10
    mov [eax + 0x7], ebx
    jmp near .branch_3a4ed

.branch_3a5d9:
    mov eax, 0x9d
    xor ecx, ecx
    xor ebx, ebx
    xor edx, edx
    call play_sound
    push strict dword frame_state_1741f4
    mov ecx, frame_state_10bc
    mov edx, 0x19
    mov eax, [frame_state_17425c]
    movsx ebx, si
    call draw_menu_frame
    mov edx, [nosplit ebp*4 + frame_state_13154]
    mov eax, [frame_state_17425c]
    push edx
    mov ebx, [nosplit eax*8 + frame_state_13558]
    push ebx
    mov ebx, eax
    shl eax, byte 0x4
    sub eax, ebx
    add eax, eax
    push strict dword frame_state_1098
    add eax, frame_state_174268
    push eax
    call format_string
    add esp, 0x10
    jmp near .branch_3a4ed

.branch_3a63b:
    xor ebx, ebx

.branch_3a63d:
    mov eax, [nosplit ebx*4 + frame_state_1741f4]
    inc ebx
    mov al, [eax + 0x7]
    mov [ebx + frame_state_1363c], al
    cmp ebx, 0x19
    jl short .branch_3a63d
    mov eax, edi
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

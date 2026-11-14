; Draw intro screen.
BITS 32
ORG 0x38808

dispatch_ticks equ 0x35415
presentation_reset equ 0x36246
presentation_input equ 0x3625c
restore_saved_registers equ 0x39481
drawrooms equ 0x44796
nextpage equ 0x4b496
drawmasks equ 0x4cc8a
rotatesprite equ 0x57181
player_sector equ 0x5acfc
player_z equ 0x5ad1c
player_y equ 0x5ad5c
player_x equ 0x5ad9c
player_horizon equ 0x62f8c
player_angle equ 0x6308c
totalclock equ 0x287e88
presentation_height equ 0x287e8c
presentation_width equ 0x287e90

draw_intro_screen:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov esi, 0x100
    mov edi, [totalclock]
    mov eax, 0x4
    call dispatch_ticks
    lea ebp, [edi + eax]

.branch_38826:
    cmp ebp, [totalclock]
    jng near .branch_388c4
    cmp esi, strict dword 0x10000
    jnl short .branch_38859
    mov eax, [totalclock]
    sub eax, edi
    shl eax, byte 0x8
    add esi, eax
    mov edi, [totalclock]
    cmp esi, strict dword 0x10000
    jng short .branch_38859
    mov esi, 0x10000

.branch_38859:
    movsx eax, word [player_sector]
    mov ebx, [player_horizon]
    push eax
    movsx ecx, word [player_angle]
    mov edx, [player_y]
    push ebx
    mov eax, [player_x]
    mov ebx, [player_z]
    call drawrooms
    call drawmasks
    mov eax, [presentation_height]
    dec eax
    push eax
    mov eax, [presentation_width]
    dec eax
    push eax
    push strict byte 0x0
    push strict byte 0x0
    push strict byte 0x2
    push strict byte 0x0
    push strict byte 0x0
    mov edx, 0x640000
    mov ebx, esi
    push strict dword 0x83a
    xor ecx, ecx
    mov eax, 0xa00000
    call rotatesprite
    call nextpage
    jmp near .branch_38826

.branch_388c4:
    call presentation_reset

.branch_388c9:
    call presentation_input
    test eax, eax
    jz short .branch_388c9
    jmp near restore_saved_registers

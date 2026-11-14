; Draw animated intro.
BITS 32
ORG 0x388d7

dispatch_ticks equ 0x35415
status_banner_cleanup equ 0x385ec
classify_sector_hit equ 0x3fccb
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
floor_base equ 0x27c3a8
engine_286ba8 equ 0x286ba8
totalclock equ 0x287e88
presentation_height equ 0x287e8c
presentation_width equ 0x287e90

draw_animated_intro:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 0x4
    mov esi, 0x100
    mov edi, [totalclock]
    mov eax, 0x4
    call dispatch_ticks
    lea ebp, [edi + eax]
    mov eax, [engine_286ba8]
    mov [esp], eax
    movsx eax, word [player_sector]
    call classify_sector_hit
    test eax, eax
    jnz short .branch_3892f
    movsx edx, word [player_sector]
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    mov eax, [nosplit eax*8 + floor_base]
    sub eax, strict dword 0x400
    mov [player_z], eax

.branch_3892f:
    cmp ebp, [totalclock]
    jng near .branch_38a09
    cmp esi, strict dword 0x10000
    jnl short .branch_38962
    mov eax, [totalclock]
    sub eax, edi
    shl eax, byte 0x8
    add esi, eax
    mov edi, [totalclock]
    cmp esi, strict dword 0x10000
    jng short .branch_38962
    mov esi, 0x10000

.branch_38962:
    mov ebx, [engine_286ba8]
    add ebx, 0x20
    movsx eax, word [player_sector]
    mov [engine_286ba8], ebx
    call classify_sector_hit
    test eax, eax
    jnz short .branch_38988
    add dword [player_horizon], 0x6

.branch_38988:
    cmp dword [player_horizon], strict dword 0xc8
    jng short .branch_3899e
    mov dword [player_horizon], 0xc8

.branch_3899e:
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
    push strict byte 0x3
    push strict byte 0x0
    push strict byte 0x0
    mov edx, 0x640000
    mov ebx, esi
    push strict dword 0x839
    xor ecx, ecx
    mov eax, 0xa00000
    call rotatesprite
    call nextpage
    jmp near .branch_3892f

.branch_38a09:
    mov eax, [esp]
    mov [engine_286ba8], eax
    jmp near status_banner_cleanup

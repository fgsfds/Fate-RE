; Resolve a teleport destination and update coordinates and angle.
BITS 32
ORG 0x2e7f7

frame_state_5a8 equ 0x5a8
board_state_1ccac equ 0x1ccac
play_positioned_sound equ 0x34f76
get_angle equ 0x4c94c
update_sector equ 0x542c4
krand equ 0x562e5
board_state_7dece equ 0x7dece
walls equ 0x2310a0
engine_2310a4 equ 0x2310a4
engine_2310a8 equ 0x2310a8
engine_2310ac equ 0x2310ac
sectors equ 0x27c3a0
sector_wall_count equ 0x27c3a2
floor_base equ 0x27c3a8
sector_hitag equ 0x27c3c4

resolve_teleport_destination:
    push esi
    push edi
    push ebp
    sub esp, 0x24
    mov esi, [esp + 0x34]
    mov [esp + 0x14], eax
    mov [esp + 0x8], edx
    mov [esp + 0xc], ebx
    mov [esp + 0x10], ecx
    mov eax, [eax]
    mov [esp + 0x4], eax
    mov eax, [edx]
    xor ecx, ecx
    mov [esp], eax
    jmp short .branch_2e882

.branch_2e820:
    mov ax, [nosplit ecx*2 + board_state_1ccac]
    mov dx, [esi]
    cmp ax, dx
    jnz short .branch_2e881
    movsx edx, dx
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    mov ax, [nosplit eax*8 + sector_hitag]
    xor ah, ah
    movsx edi, ax

.branch_2e847:
    movsx eax, word [board_state_7dece]
    inc ecx
    cmp ecx, eax
    jl short .branch_2e855
    xor ecx, ecx

.branch_2e855:
    lea edx, [ecx + ecx]
    movsx ebx, word [edx + board_state_1ccac]
    mov eax, ebx
    shl eax, byte 0x2
    add eax, ebx
    mov ax, [nosplit eax*8 + sector_hitag]
    xor ah, ah
    cwde
    cmp eax, edi
    jnz short .branch_2e847
    mov ax, [edx + board_state_1ccac]
    mov [esi], ax
    jmp short .branch_2e88d

.branch_2e881:
    inc ecx

.branch_2e882:
    movsx eax, word [board_state_7dece]
    cmp ecx, eax
    jl short .branch_2e820

.branch_2e88d:
    movsx edx, word [esi]
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    xor edi, edi
    mov dx, [nosplit eax*8 + sectors]
    mov bx, [nosplit eax*8 + sector_wall_count]
    mov [esp + 0x1c], edx
    add edx, ebx
    mov [esp + 0x18], edi
    mov [esp + 0x20], edx
    mov edx, [esp + 0x1c]
    jmp short .branch_2e8e2

.branch_2e8bd:
    movsx ebx, dx
    mov eax, ebx
    shl eax, byte 0x5
    add edi, [eax + walls]
    mov ebp, [eax + engine_2310a4]
    add [esp + 0x18], ebp
    cmp word [eax + engine_2310ac], 0x0
    jl short .branch_2e8e1
    mov ecx, ebx

.branch_2e8e1:
    inc edx

.branch_2e8e2:
    mov eax, [esp + 0x20]
    cmp dx, ax
    jl short .branch_2e8bd
    movsx ebx, ax
    mov edx, edi
    movsx eax, word [esp + 0x1c]
    sar edx, byte 0x1f
    sub ebx, eax
    mov eax, edi
    idiv ebx
    mov edx, [esp + 0x14]
    mov [edx], eax
    mov eax, [esp + 0x18]
    mov edx, eax
    sar edx, byte 0x1f
    idiv ebx
    mov edx, [esp + 0x8]
    mov [edx], eax
    movsx edx, word [esi]
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    mov eax, [nosplit eax*8 + floor_base]
    mov edx, [esp + 0xc]
    sub eax, strict dword 0x2000
    mov [edx], eax
    mov edx, [esp + 0x8]
    mov eax, [esp + 0x14]
    mov ebx, esi
    mov edx, [edx]
    mov eax, [eax]
    shl ecx, byte 0x5
    call update_sector
    movsx eax, word [ecx + engine_2310a8]
    mov edi, [ecx + walls]
    shl eax, byte 0x5
    mov edx, [ecx + engine_2310a4]
    mov ebx, [eax + walls]
    mov ecx, [eax + engine_2310a4]
    mov eax, [esp + 0x8]
    add edx, ecx
    add edi, ebx
    sar edx, 1
    mov esi, [eax]
    mov eax, [esp + 0x14]
    sar edi, 1
    mov [esp + 0x18], edx
    mov ebp, [eax]
    mov eax, edi
    sub edx, esi
    sub eax, ebp
    call get_angle
    mov edx, [esp + 0x10]
    push strict byte 0x0
    mov [edx], ax
    lea eax, [esp + 0x4]
    push eax
    call krand
    and eax, 0x7f
    lea ecx, [esp + 0xc]
    lea edx, [eax + 0xbc0]
    mov ebx, 0xc0
    mov eax, frame_state_5a8
    call play_positioned_sound
    push strict byte 0x0
    mov eax, [esp + 0xc]
    push eax
    call krand
    and eax, 0x7f
    mov ecx, [esp + 0x1c]
    lea edx, [eax + 0xfc0]
    mov ebx, 0x100
    mov eax, frame_state_5a8
    call play_positioned_sound
    add esp, 0x24
    pop ebp
    pop edi
    pop esi
    ret word 0x4

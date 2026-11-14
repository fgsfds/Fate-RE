; Draw world-space overlays for the overhead map.
BITS 32
ORG 0x3279b

view_state_3ccb equ 0x3ccb
listener_index equ 0x3cfa
projectile_positions equ 0x20a2c
frame_state_20a30 equ 0x20a30
drawline256 equ 0x5446b
rotatesprite equ 0x57181
player_mode equ 0x62f1c
player_sprite equ 0x62f2c
view_state_770bc equ 0x770bc
processed_frame_count equ 0x770d4
engine_1ec920 equ 0x1ec920
engine_1ecd20 equ 0x1ecd20
sprite_visibility equ 0x1ecfa0
picanm equ 0x1ed3a0
tilesizx equ 0x1f2020
tilesizy equ 0x1f4020
next_sprite_in_sector equ 0x1f9ca0
sprite equ 0x2040a0
sintable equ 0x2300a0
walls equ 0x2310a0
engine_2310ae equ 0x2310ae
sectors equ 0x27c3a0
sector_wall_count equ 0x27c3a2
ceil_base equ 0x27c3a4
floor_base equ 0x27c3a8
sector_floor_tile equ 0x27c3b8
engine_27c3bc equ 0x27c3bc
window_bottom equ 0x286b90
window_top equ 0x286b94
window_right equ 0x286b98
window_left equ 0x286b9c
engine_287e7c equ 0x287e7c
presentation_height equ 0x287e8c
presentation_width equ 0x287e90
sector_sprite_head equ 0x28891e
numsectors equ 0x289154

draw_map_overlays:
    push esi
    push edi
    push ebp
    sub esp, strict dword 0xa0
    push eax
    push edx
    push ebx
    push ecx
    movsx eax, cx
    mov edx, eax
    neg edx
    and edx, strict dword 0x7ff
    movsx edx, word [nosplit edx*2 + sintable]
    imul ebx, edx
    mov edx, 0x600
    sub edx, eax
    mov eax, edx
    and eax, strict dword 0x7ff
    mov edx, [esp + 0x4]
    movsx eax, word [nosplit eax*2 + sintable]
    imul edx, eax
    mov [esp + 0x8c], ebx
    mov ebx, [engine_287e7c]
    mov eax, [esp + 0x8c]
    mov [esp + 0x88], edx
    imul ebx
    shrd eax, edx, byte 0x10
    mov ebx, [engine_287e7c]
    mov [esp + 0x84], eax
    mov eax, [esp + 0x88]
    imul ebx
    shrd eax, edx, byte 0x10
    xor edx, edx
    mov [esp + 0x80], eax
    mov [esp + 0x74], edx
    jmp near .branch_32b51

.branch_3282a:
    mov eax, ebx
    shl eax, byte 0x2
    add eax, ebx
    movsx edx, word [nosplit eax*8 + sectors]
    movsx ebx, word [nosplit eax*8 + sector_wall_count]
    lea ecx, [edx + ebx]
    mov ebp, walls
    mov [esp + 0x58], ecx
    mov ebx, [nosplit eax*8 + ceil_base]
    mov [esp + 0x28], edx
    mov [esp + 0x38], ebx
    mov eax, [nosplit eax*8 + floor_base]
    shl edx, byte 0x5
    mov [esp + 0x3c], eax
    add ebp, edx
    jmp near .branch_32b3f

.branch_32871:
    movsx eax, word [ebp + 0xa]
    mov [esp + 0xa4], eax
    test eax, eax
    jl near .branch_32b33
    mov eax, [esp + 0x28]
    mov ecx, [esp + 0x28]
    xor edx, edx
    sar eax, byte 0x3
    and ecx, 0x7
    mov dl, [eax + engine_1ec920]
    mov eax, 0x1
    shl eax, cl
    test edx, eax
    jz near .branch_32b33
    mov eax, [esp + 0xa4]
    cmp eax, [esp + 0x28]
    jng short .branch_328df
    sar eax, byte 0x3
    mov al, [eax + engine_1ec920]
    mov ecx, [esp + 0xa4]
    mov edx, 0x1
    and ecx, 0x7
    and eax, strict dword 0xff
    shl edx, cl
    and eax, edx
    test eax, eax
    jg near .branch_32b33

.branch_328df:
    movsx eax, word [ebp + 0xc]
    mov ecx, eax
    shl ecx, byte 0x2
    add ecx, eax
    shl ecx, byte 0x3
    mov ebx, [esp + 0x38]
    cmp ebx, [ecx + ceil_base]
    jnz short .branch_32921
    mov eax, [ecx + floor_base]
    cmp eax, [esp + 0x3c]
    jnz short .branch_32921
    movsx eax, word [ebp + 0xa]
    shl eax, byte 0x5
    movsx edx, word [ebp + 0xe]
    movsx eax, word [eax + engine_2310ae]
    or eax, edx
    test al, 0x30
    jz near .branch_32b33

.branch_32921:
    mov byte [esp + 0xac], 0x98
    movsx eax, word [listener_index]
    mov al, [eax + player_mode]
    and eax, strict dword 0xff
    cmp eax, 0x2
    jnz near .branch_329f1
    mov edx, [esp + 0x74]
    mov ecx, edx
    shl ecx, byte 0x2
    add ecx, edx
    shl ecx, byte 0x3
    mov eax, [ecx + floor_base]
    cmp eax, [ecx + ceil_base]
    jz short .branch_329a7
    movsx edx, word [ebp + 0xc]
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    shl eax, byte 0x3
    mov edx, [eax + floor_base]
    cmp edx, [eax + ceil_base]
    jz short .branch_329a7
    movsx edx, word [ebp + 0xa]
    shl edx, byte 0x5
    movsx ebx, word [ebp + 0xe]
    movsx edx, word [edx + engine_2310ae]
    or edx, ebx
    test dl, 0x30
    jnz short .branch_329a7
    mov edx, [ecx + floor_base]
    cmp edx, [eax + floor_base]
    jz near .branch_32b33

.branch_329a7:
    movsx edx, word [ebp + 0xc]
    mov ebx, edx
    shl ebx, byte 0x2
    add ebx, edx
    mov edx, [esp + 0x74]
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    shl ebx, byte 0x3
    shl eax, byte 0x3
    mov cx, [ebx + sector_floor_tile]
    cmp cx, [eax + sector_floor_tile]
    jnz near .branch_32b33
    mov al, [eax + engine_27c3bc]
    cmp al, [ebx + engine_27c3bc]
    jnz near .branch_32b33
    mov byte [esp + 0xac], 0xc

.branch_329f1:
    mov esi, [esp + 0xc]
    mov edi, [esp + 0x8]
    mov ebx, [esp + 0x8c]
    mov ecx, [ebp + 0x0]
    mov eax, [ebp + 0x4]
    sub ecx, esi
    sub eax, edi
    mov edi, [esp + 0x88]
    mov esi, eax
    mov [esp + 0xa8], eax
    neg esi
    mov eax, ecx
    imul ebx
    xchg eax, esi
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, byte 0x10
    mov edx, [presentation_width]
    mov edi, [esp + 0x80]
    shl edx, byte 0xb
    mov ebx, [esp + 0x84]
    add eax, edx
    mov esi, ecx
    mov [esp + 0x9c], eax
    mov eax, [esp + 0xa8]
    imul ebx
    xchg eax, esi
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, byte 0x10
    mov edx, [presentation_height]
    shl edx, byte 0xb
    add eax, edx
    mov [esp + 0xa0], eax
    movsx eax, word [ebp + 0x8]
    shl eax, byte 0x5
    mov ebx, [esp + 0x8]
    add eax, walls
    mov edi, [esp + 0x88]
    mov edx, [esp + 0xc]
    mov ecx, [eax]
    mov eax, [eax + 0x4]
    sub ecx, edx
    sub eax, ebx
    mov ebx, [esp + 0x8c]
    mov esi, eax
    mov [esp + 0xa8], eax
    neg esi
    mov eax, ecx
    imul ebx
    xchg eax, esi
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, byte 0x10
    mov edx, [presentation_width]
    mov edi, [esp + 0x80]
    shl edx, byte 0xb
    mov ebx, [esp + 0x84]
    add eax, edx
    mov esi, ecx
    mov [esp + 0x94], eax
    mov eax, [esp + 0xa8]
    imul ebx
    xchg eax, esi
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, byte 0x10
    mov edx, [presentation_height]
    shl edx, byte 0xb
    add eax, edx
    mov [esp + 0x90], eax
    xor eax, eax
    mov ebx, [esp + 0x94]
    mov al, [esp + 0xac]
    mov edx, [esp + 0xa0]
    push eax
    mov ecx, [esp + 0x94]
    mov eax, [esp + 0xa0]
    call drawline256

.branch_32b33:
    mov ecx, [esp + 0x28]
    inc ecx
    add ebp, 0x20
    mov [esp + 0x28], ecx

.branch_32b3f:
    mov eax, [esp + 0x28]
    cmp eax, [esp + 0x58]
    jl near .branch_32871
    inc dword [esp + 0x74]

.branch_32b51:
    mov ebx, [esp + 0x74]
    movsx eax, word [numsectors]
    cmp eax, ebx
    jg near .branch_3282a
    movsx eax, word [listener_index]
    xor ecx, ecx
    movsx eax, word [nosplit eax*2 + player_sprite]
    mov [esp + 0x74], ecx
    mov [esp + 0xa4], eax
    jmp near .branch_33772

.branch_32b85:
    movsx eax, word [nosplit esi*2 + sector_sprite_head]
    jmp near .branch_3375e

.branch_32b92:
    mov eax, ebp
    sar eax, byte 0x3
    mov al, [eax + sprite_visibility]
    mov ecx, ebp
    mov edx, 0x1
    and ecx, 0x7
    and eax, strict dword 0xff
    shl edx, cl
    and eax, edx
    test eax, eax
    jng near .branch_33752
    imul ebp, ebp, 0x2c
    add ebp, sprite
    movsx eax, word [ebp + 0xc]
    test ah, 0x80
    jnz near .branch_33752
    mov ax, [ebp + 0xc]
    xor ah, ah
    and al, 0x1
    mov bl, 0x38
    cwde
    mov [esp + 0xac], bl
    test eax, eax
    jz short .branch_32bec
    mov byte [esp + 0xac], 0xf8

.branch_32bec:
    mov eax, [esp + 0x28]
    cmp eax, [esp + 0xa4]
    jnz short .branch_32c01
    mov byte [esp + 0xac], 0x1f

.branch_32c01:
    movsx eax, word [ebp + 0x1a]
    movsx eax, byte [eax + view_state_3ccb]
    mov [esp + 0xa4], eax
    mov eax, [ebp + 0x0]
    mov [esp + 0x78], eax
    mov eax, [ebp + 0x4]
    mov ecx, [esp + 0xa4]
    mov [esp + 0x7c], eax
    test ecx, ecx
    jl near .branch_32d05
    mov esi, [esp + 0x28]
    mov eax, [processed_frame_count]
    sub eax, esi
    cmp ecx, 0x3
    jc short .branch_32c54
    jna short .branch_32c7c
    cmp ecx, 0x7
    jc near .branch_32cb5
    jna short .branch_32c8d
    cmp ecx, 0xf
    jz short .branch_32c9e
    jmp short .branch_32cb5

.branch_32c54:
    test ecx, ecx
    jna short .branch_32c5f
    cmp ecx, 0x1
    jz short .branch_32c6d
    jmp short .branch_32cb5

.branch_32c5f:
    mov eax, [view_state_770bc]
    mov [esp + 0x98], eax
    jmp short .branch_32cb5

.branch_32c6d:
    and eax, ecx
    mov edx, [view_state_770bc]
    shl eax, byte 0xf
    sar edx, 1
    jmp short .branch_32cac

.branch_32c7c:
    and eax, 0x3
    mov edx, [view_state_770bc]
    shl eax, byte 0xe
    sar edx, byte 0x2
    jmp short .branch_32cac

.branch_32c8d:
    and eax, 0x7
    mov edx, [view_state_770bc]
    shl eax, byte 0xd
    sar edx, byte 0x3
    jmp short .branch_32cac

.branch_32c9e:
    and eax, ecx
    mov edx, [view_state_770bc]
    shl eax, byte 0xc
    sar edx, byte 0x4

.branch_32cac:
    add edx, eax
    mov [esp + 0x98], edx

.branch_32cb5:
    mov eax, [esp + 0x28]
    mov ecx, eax
    shl ecx, byte 0x2
    sub ecx, eax
    mov eax, [esp + 0x78]
    sub eax, [nosplit ecx*4 + projectile_positions]
    mov ebx, [esp + 0x98]
    imul ebx
    shrd eax, edx, byte 0x10
    mov edx, [nosplit ecx*4 + projectile_positions]
    mov esi, [nosplit ecx*4 + frame_state_20a30]
    add edx, eax
    mov eax, [esp + 0x7c]
    sub eax, esi
    mov [esp + 0x78], edx
    imul ebx
    shrd eax, edx, byte 0x10
    mov edx, [nosplit ecx*4 + frame_state_20a30]
    add edx, eax
    mov [esp + 0x7c], edx

.branch_32d05:
    mov ax, [ebp + 0xc]
    xor ah, ah
    and al, 0x30
    cmp ax, strict word 0x10
    jc short .branch_32d28
    jna near .branch_3307e
    cmp ax, strict word 0x20
    jz near .branch_332c0
    jmp near .branch_33752

.branch_32d28:
    test ax, ax
    jnz near .branch_33752
    mov ecx, [esp + 0x78]
    mov eax, [esp + 0xc]
    mov edx, [esp + 0x8]
    sub ecx, eax
    mov eax, [esp + 0x7c]
    mov edi, [esp + 0x88]
    sub eax, edx
    mov ebx, [esp + 0x8c]
    mov esi, eax
    mov [esp + 0xa8], eax
    neg esi
    mov eax, ecx
    imul ebx
    xchg eax, esi
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, byte 0x10
    mov edi, [esp + 0x80]
    mov ebx, [esp + 0x84]
    mov [esp + 0x9c], eax
    mov esi, ecx
    mov eax, [esp + 0xa8]
    imul ebx
    xchg eax, esi
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, byte 0x10
    mov [esp + 0xa0], eax
    movsx eax, word [listener_index]
    xor edx, edx
    mov dl, [eax + player_mode]
    cmp edx, 0x1
    jnz near .branch_32f92
    movsx eax, word [ebp + 0x1c]
    add eax, strict dword 0x200
    and eax, strict dword 0x7ff
    movsx ecx, word [nosplit eax*2 + sintable]
    mov ax, [ebp + 0x1c]
    and ah, 0x7
    cwde
    mov edi, [esp + 0x88]
    movsx eax, word [nosplit eax*2 + sintable]
    mov ebx, [esp + 0x8c]
    sar eax, byte 0x7
    sar ecx, byte 0x7
    mov esi, eax
    mov [esp + 0xa8], eax
    neg esi
    mov eax, ecx
    imul ebx
    xchg eax, esi
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, byte 0x10
    mov ebx, [esp + 0x8c]
    mov [esp + 0x94], eax
    mov esi, ecx
    mov eax, [esp + 0xa8]
    imul ebx
    xchg eax, esi
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, byte 0x10
    mov [esp + 0x90], eax
    movsx eax, word [listener_index]
    mov edx, [esp + 0x28]
    movsx eax, word [nosplit eax*2 + player_sprite]
    cmp eax, edx
    jnz short .branch_32e77
    mov eax, [esp + 0x4]
    shl eax, byte 0x5
    xor ebx, ebx
    mov ecx, eax
    mov [esp + 0x90], eax
    neg ecx
    mov [esp + 0x94], ebx
    mov [esp + 0x90], ecx

.branch_32e77:
    mov eax, [esp + 0x94]
    mov ebx, [engine_287e7c]
    imul ebx
    shrd eax, edx, byte 0x10
    mov ebx, [engine_287e7c]
    mov ebp, eax
    mov eax, [esp + 0x90]
    imul ebx
    shrd eax, edx, byte 0x10
    mov edx, [presentation_height]
    mov esi, [esp + 0xa0]
    shl edx, byte 0xb
    add esi, eax
    mov [esp + 0x2c], edx
    lea ecx, [edx + esi]
    mov ebx, [esp + 0x94]
    mov edx, [esp + 0x9c]
    add edx, ebx
    mov [esp + 0x30], edx
    mov edx, [presentation_width]
    shl edx, byte 0xb
    mov ebx, [esp + 0x30]
    mov [esp + 0x34], edx
    add ebx, edx
    mov edx, [esp + 0xa0]
    sub edx, eax
    mov eax, edx
    mov edx, [esp + 0x2c]
    add edx, eax
    mov eax, [esp + 0x9c]
    sub eax, [esp + 0x94]
    movzx edi, byte [esp + 0xac]
    add eax, [esp + 0x34]
    push edi
    call drawline256
    mov eax, [presentation_width]
    mov ebx, [esp + 0x30]
    shl eax, byte 0xb
    add ebx, eax
    mov edx, [presentation_height]
    mov [esp + 0x34], ebx
    mov ebx, [esp + 0xa0]
    shl edx, byte 0xb
    add ebx, ebp
    lea ecx, [esi + edx]
    add edx, ebx
    mov ebx, [esp + 0x9c]
    sub ebx, [esp + 0x90]
    push edi
    add eax, ebx
    mov ebx, [esp + 0x38]
    call drawline256
    mov eax, [presentation_height]
    shl eax, byte 0xb
    mov ebx, [esp + 0x30]
    lea ecx, [esi + eax]
    mov edx, [presentation_width]
    mov esi, [esp + 0xa0]
    push edi
    sub esi, ebp
    mov edi, [esp + 0x94]
    add esi, eax
    mov eax, [esp + 0xa0]
    shl edx, byte 0xb
    add eax, edi
    add ebx, edx
    add eax, edx
    mov edx, esi
    jmp near .branch_3374d

.branch_32f92:
    mov edx, [esp + 0x74]
    mov ecx, [esp + 0x74]
    xor ebx, ebx
    sar edx, byte 0x3
    and ecx, 0x7
    mov bl, [edx + engine_1ecd20]
    mov edx, 0x1
    shl edx, cl
    and edx, ebx
    test edx, edx
    jng near .branch_33752
    cmp dword [esp + 0x4], 0x60
    jng near .branch_33752
    movsx edx, word [esp]
    movsx ecx, word [ebp + 0x1c]
    mov esi, [esp + 0x28]
    sub ecx, edx
    movsx eax, word [nosplit eax*2 + player_sprite]
    and ecx, strict dword 0x7ff
    cmp eax, esi
    jnz short .branch_32ff8
    xor edi, edi
    xor eax, esi
    xor ecx, ecx
    mov [esp + 0x9c], edi
    mov [esp + 0xa0], eax

.branch_32ff8:
    mov edx, [window_bottom]
    mov ax, [ebp + 0xc]
    push edx
    mov ebx, [window_right]
    xor ah, ah
    push ebx
    mov esi, [window_top]
    and al, 0x2
    push esi
    mov edi, [window_left]
    cwde
    push edi
    sar eax, 1
    push eax
    xor eax, eax
    mov al, [ebp + 0x11]
    push eax
    movsx eax, byte [ebp + 0x10]
    push eax
    movsx eax, word [ebp + 0xe]
    push eax
    xor eax, eax
    mov al, [ebp + 0x15]
    imul eax, [esp + 0x24]
    mov ebx, [engine_287e7c]
    imul ebx
    shrd eax, edx, byte 0x10
    mov ebx, [esp + 0xc0]
    mov edx, [presentation_height]
    shl ebx, byte 0x4
    shl edx, byte 0xf
    mov esi, [esp + 0xbc]
    add edx, ebx
    mov ebx, [presentation_width]
    shl esi, byte 0x4
    shl ebx, byte 0xf
    add esi, ebx
    mov ebx, eax
    mov eax, esi
    call rotatesprite
    jmp near .branch_33752

.branch_3307e:
    mov eax, [esp + 0x78]
    mov [esp + 0x9c], eax
    mov eax, [esp + 0x7c]
    movsx ebx, word [ebp + 0xe]
    mov [esp + 0xa0], eax
    mov eax, [nosplit ebx*4 + picanm]
    sar eax, byte 0x8
    and eax, strict dword 0xff
    movsx edx, al
    movsx eax, byte [ebp + 0x16]
    add eax, edx
    mov dx, [ebp + 0xc]
    xor dh, dh
    and dl, 0x4
    movsx edx, dx
    test edx, edx
    jng short .branch_330c2
    neg eax

.branch_330c2:
    movsx edx, word [ebp + 0x1c]
    mov [esp + 0xa4], edx
    xor edx, edx
    mov dl, [ebp + 0x14]
    mov [esp + 0x98], edx
    mov edx, [esp + 0xa4]
    and edx, strict dword 0x7ff
    mov edi, [esp + 0x98]
    movsx ecx, word [nosplit edx*2 + sintable]
    imul ecx, edi
    mov edx, [esp + 0xa4]
    add edx, strict dword 0x600
    and edx, strict dword 0x7ff
    mov esi, edi
    movsx edx, word [nosplit edx*2 + sintable]
    imul esi, edx
    movsx edx, word [nosplit ebx*2 + tilesizx]
    mov ebp, [esp + 0x9c]
    mov [esp + 0x98], edx
    sar edx, 1
    mov edi, [esp + 0x88]
    add edx, eax
    mov [esp + 0x24], esi
    mov ebx, edx
    mov eax, ecx
    mov [esp + 0xa4], edx
    imul ebx
    shrd eax, edx, byte 0x10
    mov ebx, [esp + 0x98]
    sub ebp, eax
    mov eax, ecx
    mov [esp + 0x9c], ebp
    imul ebx
    shrd eax, edx, byte 0x10
    mov ebx, [esp + 0xa4]
    lea edx, [eax + ebp]
    mov eax, esi
    mov [esp + 0x94], edx
    imul ebx
    shrd eax, edx, byte 0x10
    mov ecx, ebp
    mov edx, [esp + 0xa0]
    mov ebx, [esp + 0x98]
    mov ebp, [esp + 0x8]
    sub edx, eax
    mov eax, esi
    mov [esp + 0xa0], edx
    imul ebx
    shrd eax, edx, byte 0x10
    mov edx, [esp + 0xa0]
    mov ebx, [esp + 0xc]
    mov esi, [esp + 0x8]
    add edx, eax
    mov eax, [esp + 0xa0]
    sub ecx, ebx
    sub eax, esi
    mov ebx, [esp + 0x8c]
    mov esi, eax
    mov [esp + 0xa8], eax
    neg esi
    mov eax, ecx
    mov [esp + 0x90], edx
    imul ebx
    xchg eax, esi
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, byte 0x10
    mov edi, [esp + 0x80]
    mov ebx, [esp + 0x84]
    mov [esp + 0x40], eax
    mov esi, ecx
    mov eax, [esp + 0xa8]
    mov ecx, [esp + 0x94]
    imul ebx
    xchg eax, esi
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, byte 0x10
    mov edi, [esp + 0xc]
    mov ebx, [esp + 0x8c]
    mov [esp + 0x48], eax
    mov eax, [esp + 0x90]
    sub ecx, edi
    sub eax, ebp
    mov edi, [esp + 0x88]
    mov esi, eax
    mov [esp + 0xa8], eax
    neg esi
    mov eax, ecx
    imul ebx
    xchg eax, esi
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, byte 0x10
    mov ebp, eax
    mov [esp + 0x94], eax
    mov edi, [esp + 0x80]
    mov ebx, [esp + 0x84]
    mov eax, [esp + 0xa8]
    mov esi, ecx
    imul ebx
    xchg eax, esi
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, byte 0x10
    xor edx, edx
    mov dl, [esp + 0xac]
    push edx
    mov edx, [presentation_height]
    shl edx, byte 0xb
    mov [esp + 0x94], eax
    lea ecx, [eax + edx]
    mov esi, [esp + 0x4c]
    mov eax, [presentation_width]
    mov edi, [esp + 0x44]
    shl eax, byte 0xb
    add edx, esi
    lea ebx, [eax + ebp]
    add eax, edi
    jmp near .branch_3374d

.branch_332c0:
    movsx eax, word [listener_index]
    mov al, [eax + player_mode]
    and eax, strict dword 0xff
    cmp eax, 0x1
    jnz near .branch_33752
    movsx ebx, word [ebp + 0xe]
    mov eax, [nosplit ebx*4 + picanm]
    sar eax, byte 0x8
    and eax, strict dword 0xff
    movsx edx, al
    movsx eax, byte [ebp + 0x16]
    add eax, edx
    mov edx, [nosplit ebx*4 + picanm]
    sar edx, byte 0x10
    and edx, strict dword 0xff
    movsx esi, byte [ebp + 0x17]
    movsx edx, dl
    add esi, edx
    mov dx, [ebp + 0xc]
    xor dh, dh
    and dl, 0x4
    movsx edx, dx
    test edx, edx
    jng short .branch_33322
    neg eax

.branch_33322:
    mov dx, [ebp + 0xc]
    xor dh, dh
    and dl, 0x8
    movsx edx, dx
    test edx, edx
    jng short .branch_33334
    neg esi

.branch_33334:
    movsx edx, word [ebp + 0x1c]
    mov [esp + 0xa4], edx
    add edx, strict dword 0x200
    and edx, strict dword 0x7ff
    movsx edx, word [nosplit edx*2 + sintable]
    mov [esp + 0x20], edx
    movsx edx, word [nosplit ebx*2 + tilesizx]
    mov [esp + 0x1c], edx
    xor edx, edx
    mov dl, [ebp + 0x14]
    mov [esp + 0x14], edx
    movsx edx, word [nosplit ebx*2 + tilesizy]
    mov [esp + 0x18], edx
    xor edx, edx
    mov dl, [ebp + 0x15]
    mov [esp + 0x10], edx
    mov edx, [esp + 0x1c]
    sar edx, 1
    mov ebp, [esp + 0x14]
    add eax, edx
    imul ebp, eax
    mov eax, [esp + 0x18]
    sar eax, 1
    mov edx, [esp + 0x10]
    add eax, esi
    imul edx, eax
    mov ecx, [esp + 0xa4]
    movsx ecx, word [nosplit ecx*2 + sintable]
    mov ebx, ebp
    mov esi, [esp + 0x20]
    mov edi, edx
    mov eax, ecx
    mov [esp + 0x24], edx
    imul ebx
    xchg eax, esi
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, byte 0x10
    mov edx, [esp + 0x78]
    mov esi, [esp + 0x20]
    mov ebx, [esp + 0x24]
    mov edi, ebp
    neg esi
    add edx, eax
    mov eax, ecx
    mov [esp + 0x9c], edx
    imul ebx
    xchg eax, esi
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, byte 0x10
    mov edx, [esp + 0x7c]
    mov edi, [esp + 0x14]
    add edx, eax
    mov eax, [esp + 0x1c]
    imul eax, edi
    mov [esp + 0x98], eax
    mov ebx, eax
    mov eax, ecx
    mov [esp + 0xa0], edx
    imul ebx
    shrd eax, edx, byte 0x10
    mov edx, [esp + 0x9c]
    sub edx, eax
    mov eax, [esp + 0x20]
    mov [esp + 0x94], edx
    imul ebx
    shrd eax, edx, byte 0x10
    mov edx, [esp + 0xa0]
    mov ebp, [esp + 0x10]
    add edx, eax
    mov eax, [esp + 0x18]
    imul eax, ebp
    mov [esp + 0x98], eax
    mov ebx, eax
    mov eax, [esp + 0x20]
    mov [esp + 0x90], edx
    imul ebx
    shrd eax, edx, byte 0x10
    mov [esp + 0xa4], eax
    neg eax
    mov [esp + 0xa4], eax
    mov eax, [esp + 0x94]
    mov edx, [esp + 0xa4]
    add eax, edx
    mov [esp + 0x4c], eax
    mov eax, [esp + 0x9c]
    add eax, edx
    mov [esp + 0x50], eax
    mov eax, ecx
    imul ebx
    shrd eax, edx, byte 0x10
    mov [esp + 0xa4], eax
    mov ecx, eax
    mov eax, [esp + 0x90]
    neg ecx
    add eax, ecx
    mov ebp, [esp + 0xc]
    mov [esp + 0x44], eax
    mov eax, [esp + 0xa0]
    mov [esp + 0xa4], ecx
    add eax, ecx
    mov ecx, [esp + 0x9c]
    mov [esp + 0x54], eax
    sub ecx, ebp
    mov eax, [esp + 0xa0]
    mov edx, [esp + 0x8]
    mov edi, [esp + 0x88]
    sub eax, edx
    mov ebx, [esp + 0x8c]
    mov esi, eax
    mov [esp + 0xa8], eax
    neg esi
    mov eax, ecx
    imul ebx
    xchg eax, esi
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, byte 0x10
    mov edi, [esp + 0x80]
    mov ebx, [esp + 0x84]
    mov [esp + 0x68], eax
    mov esi, ecx
    mov eax, [esp + 0xa8]
    mov ecx, [esp + 0x94]
    imul ebx
    xchg eax, esi
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, byte 0x10
    mov esi, [esp + 0x8]
    mov edi, [esp + 0x88]
    mov [esp + 0x60], eax
    mov eax, [esp + 0x90]
    mov ebx, [esp + 0x8c]
    sub eax, esi
    sub ecx, ebp
    mov esi, eax
    mov [esp + 0xa8], eax
    neg esi
    mov eax, ecx
    imul ebx
    xchg eax, esi
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, byte 0x10
    mov edi, [esp + 0x80]
    mov ebx, [esp + 0x84]
    mov [esp + 0x70], eax
    mov [esp + 0x94], eax
    mov esi, ecx
    mov eax, [esp + 0xa8]
    mov ecx, [esp + 0x4c]
    imul ebx
    xchg eax, esi
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, byte 0x10
    mov edi, [esp + 0xc]
    mov edx, [esp + 0x8]
    mov ebx, [esp + 0x8c]
    mov ebp, eax
    mov [esp + 0x90], eax
    mov eax, [esp + 0x44]
    sub ecx, edi
    sub eax, edx
    mov edi, [esp + 0x88]
    mov esi, eax
    mov [esp + 0xa8], eax
    neg esi
    mov eax, ecx
    imul ebx
    xchg eax, esi
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, byte 0x10
    mov edi, [esp + 0x80]
    mov ebx, [esp + 0x84]
    mov [esp + 0x5c], eax
    mov esi, ecx
    mov eax, [esp + 0xa8]
    mov ecx, [esp + 0x50]
    imul ebx
    xchg eax, esi
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, byte 0x10
    mov ebx, [esp + 0xc]
    mov esi, [esp + 0x8]
    mov edi, [esp + 0x88]
    mov [esp + 0x6c], eax
    mov eax, [esp + 0x54]
    sub ecx, ebx
    sub eax, esi
    mov ebx, [esp + 0x8c]
    mov esi, eax
    mov [esp + 0xa8], eax
    neg esi
    mov eax, ecx
    imul ebx
    xchg eax, esi
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, byte 0x10
    mov [esp + 0x64], eax
    mov edi, [esp + 0x80]
    mov ebx, [esp + 0x84]
    mov eax, [esp + 0xa8]
    mov esi, ecx
    imul ebx
    xchg eax, esi
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, byte 0x10
    movzx esi, byte [esp + 0xac]
    mov edi, eax
    mov eax, [presentation_width]
    mov ebx, [esp + 0x70]
    shl eax, byte 0xb
    mov edx, [presentation_height]
    add ebx, eax
    shl edx, byte 0xb
    mov [esp + 0x34], ebx
    mov ebx, [esp + 0x60]
    lea ecx, [edx + ebp]
    add edx, ebx
    mov ebx, [esp + 0x68]
    push esi
    add eax, ebx
    mov ebx, [esp + 0x38]
    call drawline256
    mov ecx, [esp + 0x6c]
    mov eax, [presentation_height]
    mov ebx, [esp + 0x5c]
    shl eax, byte 0xb
    push esi
    mov [esp + 0x38], eax
    add ecx, eax
    mov eax, [presentation_width]
    mov edx, [esp + 0x38]
    shl eax, byte 0xb
    add edx, ebp
    mov ebp, [esp + 0x74]
    add ebx, eax
    add eax, ebp
    call drawline256
    mov ebx, [esp + 0x64]
    mov edx, [esp + 0x6c]
    mov eax, [presentation_height]
    mov ebp, [presentation_width]
    push esi
    shl eax, byte 0xb
    shl ebp, byte 0xb
    lea ecx, [edi + eax]
    add edx, eax
    mov eax, [esp + 0x60]
    add ebx, ebp
    add eax, ebp
    call drawline256
    mov ecx, [esp + 0x60]
    mov ebx, [esp + 0x68]
    mov edx, [presentation_height]
    mov eax, [presentation_width]
    push esi
    mov esi, [esp + 0x68]
    shl edx, byte 0xb
    shl eax, byte 0xb
    add ecx, edx
    add ebx, eax
    add edx, edi
    add eax, esi

.branch_3374d:
    call drawline256

.branch_33752:
    mov eax, [esp + 0x28]
    movsx eax, word [nosplit eax*2 + next_sprite_in_sector]

.branch_3375e:
    mov [esp + 0x28], eax
    mov ebp, [esp + 0x28]
    test ebp, ebp
    jnl near .branch_32b92
    inc dword [esp + 0x74]

.branch_33772:
    mov esi, [esp + 0x74]
    movsx eax, word [numsectors]
    cmp eax, esi
    jg near .branch_32b85
    xor edi, edi
    mov [esp + 0x74], edi
    jmp near .branch_3399c

.branch_33790:
    mov eax, ebp
    shl eax, byte 0x2
    add eax, ebp
    movsx edx, word [nosplit eax*8 + sectors]
    movsx eax, word [nosplit eax*8 + sector_wall_count]
    mov ebp, walls
    lea ebx, [edx + eax]
    mov eax, 0xffffffff
    mov [esp + 0x58], ebx
    mov [esp + 0x28], edx
    shl edx, byte 0x5
    mov [esp + 0xa4], eax
    add ebp, edx
    jmp near .branch_3398a

.branch_337cd:
    cmp word [ebp + 0xa], 0x0
    jnl near .branch_3397e
    mov ecx, [esp + 0x28]
    sar eax, byte 0x3
    xor edx, edx
    and ecx, 0x7
    mov dl, [eax + engine_1ec920]
    mov eax, 0x1
    shl eax, cl
    test edx, eax
    jz near .branch_3397e
    movsx eax, word [ebp + 0x10]
    add eax, eax
    cmp word [eax + tilesizx], 0x0
    jz near .branch_3397e
    cmp word [eax + tilesizy], 0x0
    jz near .branch_3397e
    mov eax, [esp + 0x28]
    cmp eax, [esp + 0xa4]
    jnz short .branch_33842
    mov eax, [esp + 0x94]
    mov [esp + 0x9c], eax
    mov eax, [esp + 0x90]
    jmp near .branch_338c1

.branch_33842:
    mov esi, [esp + 0xc]
    mov edi, [esp + 0x8]
    mov ebx, [esp + 0x8c]
    mov ecx, [ebp + 0x0]
    mov eax, [ebp + 0x4]
    sub ecx, esi
    sub eax, edi
    mov edi, [esp + 0x88]
    mov esi, eax
    mov [esp + 0xa8], eax
    neg esi
    mov eax, ecx
    imul ebx
    xchg eax, esi
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, byte 0x10
    mov edx, [presentation_width]
    mov edi, [esp + 0x80]
    shl edx, byte 0xb
    mov ebx, [esp + 0x84]
    add eax, edx
    mov esi, ecx
    mov [esp + 0x9c], eax
    mov eax, [esp + 0xa8]
    imul ebx
    xchg eax, esi
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, byte 0x10
    mov edx, [presentation_height]
    shl edx, byte 0xb
    add eax, edx

.branch_338c1:
    mov [esp + 0xa0], eax
    movsx eax, word [ebp + 0x8]
    mov [esp + 0xa4], eax
    shl eax, byte 0x5
    mov edx, [esp + 0xc]
    add eax, walls
    mov ebx, [esp + 0x8]
    mov edi, [esp + 0x88]
    mov ecx, [eax]
    mov eax, [eax + 0x4]
    sub ecx, edx
    sub eax, ebx
    mov ebx, [esp + 0x8c]
    mov esi, eax
    mov [esp + 0xa8], eax
    neg esi
    mov eax, ecx
    imul ebx
    xchg eax, esi
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, byte 0x10
    mov edx, [presentation_width]
    mov edi, [esp + 0x80]
    shl edx, byte 0xb
    mov ebx, [esp + 0x84]
    add eax, edx
    mov esi, ecx
    mov [esp + 0x94], eax
    mov eax, [esp + 0xa8]
    imul ebx
    xchg eax, esi
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, byte 0x10
    mov edx, [presentation_height]
    push strict byte 0x18
    shl edx, byte 0xb
    mov ebx, [esp + 0x98]
    add eax, edx
    mov edx, [esp + 0xa4]
    mov [esp + 0x94], eax
    mov ecx, eax
    mov eax, [esp + 0xa0]
    call drawline256

.branch_3397e:
    mov ecx, [esp + 0x28]
    inc ecx
    add ebp, 0x20
    mov [esp + 0x28], ecx

.branch_3398a:
    mov eax, [esp + 0x28]
    cmp eax, [esp + 0x58]
    jl near .branch_337cd
    inc dword [esp + 0x74]

.branch_3399c:
    mov ebp, [esp + 0x74]
    movsx eax, word [numsectors]
    cmp eax, ebp
    jg near .branch_33790
    add esp, strict dword 0xb0
    pop ebp
    pop edi
    pop esi
    ret

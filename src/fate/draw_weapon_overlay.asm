; Draw weapon overlay.
BITS 32
ORG 0x37f95

frame_state_12d84 equ 0x12d84
frame_state_12d88 equ 0x12d88
frame_state_12d8c equ 0x12d8c
frame_state_12d90 equ 0x12d90
rotatesprite equ 0x57181
sintable equ 0x2300a0
window_bottom equ 0x286b90
window_top equ 0x286b94
window_right equ 0x286b98
window_left equ 0x286b9c

draw_weapon_overlay:
    push esi
    push edi
    push ebp
    sub esp, 0x4
    mov esi, eax
    mov byte [esp], 0xc0
    test ecx, ecx
    jz short .branch_37fb1
    mov dword [frame_state_12d8c], 0x90
    jmp short .branch_37fbb

.branch_37fb1:
    mov dword [frame_state_12d8c], 0x40

.branch_37fbb:
    test ebx, ebx
    setz al
    mov [frame_state_12d90], al
    mov eax, [frame_state_12d84]
    and eax, strict dword 0x7ff
    movsx eax, word [nosplit eax*2 + sintable]
    mov edx, [frame_state_12d88]
    sar eax, byte 0xb
    imul edx, eax
    mov edi, [window_bottom]
    push edi
    mov ebp, [window_right]
    push ebp
    mov eax, [window_top]
    push eax
    mov ebx, [window_left]
    push ebx
    push strict byte 0x12
    push strict byte 0x0
    movsx eax, byte [esp + 0x18]
    mov ecx, [esp + 0x2c]
    push eax
    mov eax, [esp + 0x34]
    mov ebx, 0x10000
    add edx, eax
    mov eax, [frame_state_12d84]
    push esi
    sar eax, byte 0x8
    add edx, 0x9
    add eax, ecx
    shl edx, byte 0x10
    sub eax, 0x10
    xor ecx, ecx
    shl eax, byte 0x10
    call rotatesprite
    add esp, 0x4
    pop ebp
    pop edi
    pop esi
    ret word 0x8

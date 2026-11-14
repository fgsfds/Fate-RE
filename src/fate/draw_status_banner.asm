; Draw status banner.
BITS 32
ORG 0x3850e

character_types equ 0x1f20
frame_state_12df4 equ 0x12df4
restore_saved_registers equ 0x39481
rotatesprite equ 0x57181
strlen equ 0x60381
status_text equ 0x7711c
window_bottom equ 0x286b90
window_top equ 0x286b94
window_right equ 0x286b98
window_left equ 0x286b9c

draw_status_banner:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 0x4
    mov eax, [status_text]
    call strlen
    mov [esp], eax
    mov eax, [status_text]
    call strlen
    mov edx, [frame_state_12df4]
    mov esi, eax
    imul esi, edx
    mov eax, 0xa0
    shr esi, 1
    sub eax, esi
    xor edi, edi
    mov esi, eax
    jmp near .branch_385e3

.branch_3854b:
    mov eax, [status_text]
    add eax, edi
    mov bl, [eax]
    xor edx, edx
    inc bl
    and ebx, strict dword 0xff
    mov cl, [ebx + character_types]
    and cl, 0xc0
    and ecx, strict dword 0xff
    jz short .branch_38579
    mov dl, [eax]
    add edx, strict dword 0x816
    jmp short .branch_3859a

.branch_38579:
    mov bl, [ebx + character_types]
    and bl, 0x20
    and ebx, strict dword 0xff
    jz short .branch_38594
    mov dl, [eax]
    add edx, strict dword 0x7c9
    jmp short .branch_3859a

.branch_38594:
    add esi, [frame_state_12df4]

.branch_3859a:
    test edx, edx
    jz short .branch_385e2
    mov ebp, [window_bottom]
    push ebp
    mov eax, [window_right]
    push eax
    mov ebx, [window_top]
    push ebx
    mov ecx, [window_left]
    push ecx
    push strict dword 0x92
    push strict byte 0x0
    movsx eax, dx
    push strict byte 0xffffffffffffffc0
    mov ebx, 0x10000
    mov edx, 0x360000
    push eax
    mov eax, esi
    xor ecx, ecx
    shl eax, byte 0x10
    call rotatesprite
    add esi, [frame_state_12df4]

.branch_385e2:
    inc edi

.branch_385e3:
    cmp edi, [esp]
    jl near .branch_3854b
    add esp, 0x4
    jmp near restore_saved_registers

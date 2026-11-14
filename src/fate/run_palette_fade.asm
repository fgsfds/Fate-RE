; Run palette fade.
BITS 32
ORG 0x365ee

fade_level equ 0x12d14
presentation_reset equ 0x36246
presentation_input equ 0x3625c
branch_365ed equ 0x365ed
update_palette_fade equ 0x366f2
frame_state_772b8 equ 0x772b8
frame_state_173d14 equ 0x173d14
frame_state_173d18 equ 0x173d18
frame_state_173d24 equ 0x173d24

run_palette_fade:

.branch_365ee:
    cmp dword [frame_state_173d14], 0x0
    jz short branch_365ed
    mov eax, [frame_state_173d24]
    call .start_fade_in

.branch_36601:
    call presentation_input
    test eax, eax
    jz near .branch_366aa
    cmp dword [frame_state_173d18], 0x0
    jz short .branch_3661e
    mov eax, 0xff
    jmp short .start_fade_out

.branch_3661e:
    cmp dword [frame_state_173d14], 0x0
    jz short branch_365ed
    mov eax, 0xff
    jmp short .start_fade_in

.start_fade_out:
    push ebx
    push ecx
    cmp dword [fade_level], 0x0
    jng short .branch_36651
    mov ebx, 0x1
    mov [frame_state_173d24], eax
    xor ecx, ecx
    mov [frame_state_173d18], ebx
    mov [frame_state_173d14], ecx

.branch_36651:
    cmp dword [frame_state_772b8], 0x0
    jz short .branch_3665f
    call update_palette_fade

.branch_3665f:
    pop ecx
    pop ebx
    ret
    call .start_fade_out
    jmp short .branch_366a5

.start_fade_in:
    push ebx
    push ecx
    cmp dword [fade_level], strict dword 0xff
    jnl short .branch_3668f
    mov ebx, 0x1
    mov [frame_state_173d24], eax
    xor ecx, ecx
    mov [frame_state_173d14], ebx
    mov [frame_state_173d18], ecx

.branch_3668f:
    cmp dword [frame_state_772b8], 0x0
    jz short .branch_3669d
    call update_palette_fade

.branch_3669d:
    pop ecx
    pop ebx
    ret
    call .start_fade_in

.branch_366a5:
    call presentation_reset

.branch_366aa:
    cmp dword [frame_state_173d18], 0x0
    jz near .branch_365ee
    mov eax, [frame_state_173d24]
    call .start_fade_out
    jmp near .branch_36601

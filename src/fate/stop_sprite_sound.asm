; Stop a sound attached to a sprite.
BITS 32
ORG 0x34d0e

sprite_sound_slot_overflow equ 0x8d7
stop_sprite_sample_error equ 0x901
stopped_sprite_message equ 0x924
frame_state_12cd0 equ 0x12cd0
report_error equ 0x26a03
format_string equ 0x601f3
request_sample_stop equ 0x62334
error_buffer equ 0x67e3c
sound_slots equ 0x854dc
audio_enabled equ 0x171602

stop_sprite_sound:
    push ebx
    push edx
    mov ebx, eax
    cmp byte [audio_enabled], 0x0
    jnz short .branch_34d23
    mov eax, 0xffffffff
    pop edx
    pop ebx
    ret

.branch_34d23:
    test ebx, ebx
    jl short .branch_34d2f
    cmp ebx, strict dword 0x1000
    jl short .branch_34d39

.branch_34d2f:
    mov eax, sprite_sound_slot_overflow
    call report_error

.branch_34d39:
    xor edx, edx

.branch_34d3b:
    mov eax, [nosplit edx*4 + sound_slots]
    cmp dword [eax], -1
    jz short .branch_34d4f
    movsx eax, word [eax + 0xe]
    cmp eax, ebx
    jz short .branch_34d55

.branch_34d4f:
    inc edx
    cmp edx, 0x10
    jl short .branch_34d3b

.branch_34d55:
    mov eax, [nosplit edx*4 + sound_slots]
    mov edx, [eax]
    mov eax, [frame_state_12cd0]
    call request_sample_stop
    test eax, eax
    jz short .branch_34d76
    mov eax, stop_sprite_sample_error
    call report_error

.branch_34d76:
    push ebx
    push strict dword stopped_sprite_message
    push strict dword error_buffer
    call format_string
    mov edx, [nosplit ebx*4 + sound_slots]
    mov dword [edx], 0xffffffff
    mov edx, [nosplit ebx*4 + sound_slots]
    mov word [edx + 0xe], 0x0
    mov eax, [nosplit ebx*4 + sound_slots]
    add esp, 0xc
    mov dword [eax + 0x18], 0x0
    mov eax, ebx
    pop edx
    pop ebx
    ret

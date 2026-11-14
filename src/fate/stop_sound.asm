; Stop a sound slot and clear its state.
BITS 32
ORG 0x34c82

sound_slot_overflow equ 0x870
null_sample_handle equ 0x892
stop_sample_error equ 0x8b4
frame_state_12cd0 equ 0x12cd0
report_error equ 0x26a03
request_sample_stop equ 0x62334
sound_slots equ 0x854dc
audio_enabled equ 0x171602

stop_sound:
    push ebx
    push edx
    mov ebx, eax
    cmp byte [audio_enabled], 0x0
    jnz short .branch_34c97
    mov eax, 0xffffffff
    pop edx
    pop ebx
    ret

.branch_34c97:
    test ebx, ebx
    jl short .branch_34ca0
    cmp ebx, 0x10
    jl short .branch_34caa

.branch_34ca0:
    mov eax, sound_slot_overflow
    call report_error

.branch_34caa:
    mov eax, [nosplit ebx*4 + sound_slots]
    cmp dword [eax], -1
    jnz short .branch_34cc0
    mov eax, null_sample_handle
    call report_error

.branch_34cc0:
    mov eax, [nosplit ebx*4 + sound_slots]
    mov edx, [eax]
    mov eax, [frame_state_12cd0]
    call request_sample_stop
    test eax, eax
    jz short .branch_34ce1
    mov eax, stop_sample_error
    call report_error

.branch_34ce1:
    mov edx, [nosplit ebx*4 + sound_slots]
    mov dword [edx], 0xffffffff
    mov edx, [nosplit ebx*4 + sound_slots]
    mov word [edx + 0xe], 0x0
    mov eax, [nosplit ebx*4 + sound_slots]
    mov dword [eax + 0x18], 0x0
    mov eax, ebx
    pop edx
    pop ebx
    ret

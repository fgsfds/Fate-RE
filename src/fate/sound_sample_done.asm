; Clear the sound slot for a completed sample.
BITS 32
ORG 0x34c36

sample_slot_overflow equ 0x84c
report_error equ 0x26a03
sound_callback_return equ 0x34c35
sound_slots equ 0x854dc

sound_sample_done:
    mov edx, [esp + 0x4]
    xor eax, eax

.branch_34c3c:
    mov ebx, [edx + 0x1c]
    cmp eax, ebx
    jnz short .branch_34c6d
    mov ebx, [nosplit ebx*4 + sound_slots]
    mov dword [ebx], 0xffffffff
    mov ebx, [nosplit eax*4 + sound_slots]
    mov word [ebx + 0xe], 0x0
    mov edx, [nosplit eax*4 + sound_slots]
    mov dword [edx + 0x18], 0x0
    jmp short .branch_34c73

.branch_34c6d:
    inc eax
    cmp eax, 0x10
    jl short .branch_34c3c

.branch_34c73:
    cmp eax, 0x10
    jnz short sound_callback_return
    mov eax, sample_slot_overflow
    jmp near report_error

; Print command-line switches and exit.
BITS 32
ORG 0x374b8

frame_state_a51 equ 0xa51
frame_state_b4d equ 0xb4d
frame_state_b69 equ 0xb69
frame_state_12d18 equ 0x12d18
frame_state_12d24 equ 0x12d24
print_video_text equ 0x36adf
runtime_exit equ 0x60353

print_command_line_help:
    push ebx
    push ecx
    push edx
    push strict dword frame_state_a51
    call print_video_text
    add esp, 0x4
    push strict dword frame_state_b4d
    call print_video_text
    add esp, 0x4
    push strict dword frame_state_a51
    xor edx, edx
    call print_video_text
    add esp, 0x4
    jmp short .branch_37504

.branch_374e6:
    mov ebx, [nosplit eax*4 + frame_state_12d24]
    push ebx
    mov ecx, [nosplit eax*4 + frame_state_12d18]
    push ecx
    push strict dword frame_state_b69
    inc edx
    call print_video_text
    add esp, 0xc

.branch_37504:
    movsx eax, dx
    cmp eax, 0x3
    jl short .branch_374e6
    push strict dword frame_state_a51
    call print_video_text
    add esp, 0x4
    xor eax, eax
    call runtime_exit
    pop edx
    pop ecx
    pop ebx
    ret

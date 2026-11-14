; Load video settings.
BITS 32
ORG 0x36952

video_settings_filename equ 0x9c1
frame_state_12d70 equ 0x12d70
frame_state_12d74 equ 0x12d74
frame_state_12d78 equ 0x12d78
apply_video_mode equ 0x37136
open equ 0x61368
lseek equ 0x615b6
read equ 0x615f7
close equ 0x6219a
frame_state_173d38 equ 0x173d38
frame_state_173d3c equ 0x173d3c
frame_state_173d40 equ 0x173d40
frame_state_173d48 equ 0x173d48

load_video_settings:
    push ebx
    push ecx
    push edx
    push esi
    mov ecx, eax
    xor esi, esi
    test eax, eax
    jnz short .branch_36992
    push strict dword 0x202
    push strict dword video_settings_filename
    mov esi, 0x1
    call open
    add esp, 0x8
    mov ecx, eax
    cmp eax, -1
    jnz short .branch_36987
    mov [frame_state_173d48], esi
    jmp near .branch_369fe

.branch_36987:
    xor ebx, ebx
    xor edx, edx
    call lseek
    mov edx, eax

.branch_36992:
    cmp edx, -1
    jnz short .branch_369ab
    mov eax, ecx
    mov ebx, 0x1
    call close
    mov [frame_state_173d48], ebx
    jmp short .branch_369fe

.branch_369ab:
    mov ebx, 0xc
    mov edx, frame_state_173d38
    mov eax, ecx
    call read
    cmp eax, 0xc
    jz short .branch_369d5
    mov eax, ecx
    mov edx, 0x1
    call close
    mov [frame_state_173d48], edx
    jmp short .branch_369fe

.branch_369d5:
    test esi, esi
    jz short .branch_369e0
    mov eax, ecx
    call close

.branch_369e0:
    mov eax, [frame_state_173d38]
    mov [frame_state_12d74], eax
    mov eax, [frame_state_173d3c]
    mov [frame_state_12d78], eax
    mov eax, [frame_state_173d40]
    mov [frame_state_12d70], eax

.branch_369fe:
    cmp dword [frame_state_173d48], 0x0
    jz short .branch_36a0c
    call apply_video_mode

.branch_36a0c:
    mov eax, 0x1
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

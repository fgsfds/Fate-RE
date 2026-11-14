; Load game configuration.
BITS 32
ORG 0x3818c

configuration_filename equ 0xce4
key_forward equ 0x1363d
frame_state_139f4 equ 0x139f4
scale_x equ 0x13a81
frame_state_13b4d equ 0x13b4d
frame_state_13b51 equ 0x13b51
frame_state_13b55 equ 0x13b55
frame_state_13b59 equ 0x13b59
strafe_limit equ 0x13b9f
set_audio_flag_a equ 0x3569c
set_audio_flag_b equ 0x356b9
set_audio_level_a equ 0x356dc
set_audio_level_b equ 0x3570a
open equ 0x61368
lseek equ 0x615b6
read equ 0x615f7
close equ 0x6219a

load_game_configuration:
    push ebx
    push ecx
    push edx
    push esi
    mov ecx, eax
    xor esi, esi
    test eax, eax
    jnz short .branch_381c5
    push strict dword 0x202
    push strict dword configuration_filename
    mov esi, 0x1
    call open
    add esp, 0x8
    mov ecx, eax
    cmp eax, -1
    jz near .branch_3828c
    xor ebx, ebx
    xor edx, edx
    call lseek
    mov edx, eax

.branch_381c5:
    cmp edx, -1
    jnz short .branch_381d8
    mov eax, ecx
    call close
    mov eax, edx
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

.branch_381d8:
    mov ebx, 0x19
    mov edx, key_forward
    mov eax, ecx
    call read
    cmp eax, 0x19
    jz short .branch_381ff

.branch_381ee:
    mov eax, ecx
    call close
    mov eax, 0xffffffff
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

.branch_381ff:
    mov ebx, 0x3
    mov edx, frame_state_139f4
    mov eax, ecx
    call read
    cmp eax, 0x3
    jnz short .branch_381ee
    mov ebx, 0x10
    mov edx, frame_state_13b4d
    mov eax, ecx
    call read
    cmp eax, 0x10
    jnz short .branch_381ee
    mov ebx, 0x8
    mov edx, scale_x
    mov eax, ecx
    call read
    cmp eax, 0x8
    jnz short .branch_381ee
    mov edx, strafe_limit
    mov ebx, eax
    mov eax, ecx
    call read
    cmp eax, 0x8
    jnz short .branch_381ee
    test esi, esi
    jz short .branch_3825f
    mov eax, ecx
    call close

.branch_3825f:
    mov eax, [frame_state_13b55]
    call set_audio_flag_a
    mov eax, [frame_state_13b59]
    call set_audio_flag_b
    mov eax, [frame_state_13b4d]
    call set_audio_level_a
    mov eax, [frame_state_13b51]
    call set_audio_level_b
    mov eax, 0x1

.branch_3828c:
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

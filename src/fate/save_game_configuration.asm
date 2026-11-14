; Save game configuration.
BITS 32
ORG 0x38291

configuration_filename equ 0xce4
key_forward equ 0x1363d
frame_state_139f4 equ 0x139f4
scale_x equ 0x13a81
frame_state_13b4d equ 0x13b4d
frame_state_13b51 equ 0x13b51
frame_state_13b55 equ 0x13b55
frame_state_13b59 equ 0x13b59
strafe_limit equ 0x13b9f
get_audio_flag_a equ 0x35683
get_audio_flag_b equ 0x35693
get_audio_level_a equ 0x356d6
get_audio_level_b equ 0x35704
open equ 0x61368
lseek equ 0x615b6
close equ 0x6219a
write equ 0x62a97
flushall equ 0x62e83

save_game_configuration:
    push ebx
    push ecx
    push edx
    push esi
    mov ecx, eax
    call get_audio_level_a
    mov [frame_state_13b4d], eax
    call get_audio_level_b
    xor esi, esi
    mov [frame_state_13b51], eax
    call get_audio_flag_a
    mov [frame_state_13b55], eax
    call get_audio_flag_b
    mov [frame_state_13b59], eax
    test ecx, ecx
    jnz short .branch_382f7
    push strict dword 0x180
    push strict dword 0x222
    push strict dword configuration_filename
    mov esi, 0x1
    call open
    add esp, 0xc
    mov ecx, eax
    cmp eax, -1
    jz near .branch_3839b
    xor ebx, ebx
    xor edx, edx
    call lseek
    mov edx, eax

.branch_382f7:
    cmp edx, -1
    jnz short .branch_3830a
    mov eax, ecx
    call close
    mov eax, edx
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

.branch_3830a:
    mov ebx, 0x19
    mov edx, key_forward
    mov eax, ecx
    call write
    cmp eax, 0x19
    jz short .branch_38331

.branch_38320:
    mov eax, ecx
    call close
    mov eax, 0xffffffff
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

.branch_38331:
    mov ebx, 0x3
    mov edx, frame_state_139f4
    mov eax, ecx
    call write
    cmp eax, 0x3
    jnz short .branch_38320
    mov ebx, 0x10
    mov edx, frame_state_13b4d
    mov eax, ecx
    call write
    cmp eax, 0x10
    jnz short .branch_38320
    mov ebx, 0x8
    mov edx, scale_x
    mov eax, ecx
    call write
    cmp eax, 0x8
    jnz short .branch_38320
    mov edx, strafe_limit
    mov ebx, eax
    mov eax, ecx
    call write
    cmp eax, 0x8
    jnz short .branch_38320
    test esi, esi
    jz short .branch_38396
    mov eax, ecx
    call close
    call flushall

.branch_38396:
    mov eax, 0x1

.branch_3839b:
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

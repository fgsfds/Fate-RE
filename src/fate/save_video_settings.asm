; Save video settings.
BITS 32
ORG 0x36a16

video_settings_filename equ 0x9c1
frame_state_12d70 equ 0x12d70
frame_state_12d74 equ 0x12d74
frame_state_12d78 equ 0x12d78
open equ 0x61368
lseek equ 0x615b6
close equ 0x6219a
write equ 0x62a97
flushall equ 0x62e83
frame_state_173d38 equ 0x173d38
frame_state_173d3c equ 0x173d3c
frame_state_173d40 equ 0x173d40

save_video_settings:
    push ebx
    push ecx
    push edx
    push esi
    mov ecx, eax
    mov eax, [frame_state_12d74]
    mov [frame_state_173d38], eax
    mov eax, [frame_state_12d78]
    mov [frame_state_173d3c], eax
    mov eax, [frame_state_12d70]
    xor esi, esi
    mov [frame_state_173d40], eax
    test ecx, ecx
    jnz short .branch_36a6e
    push strict dword 0x180
    push strict dword 0x222
    push strict dword video_settings_filename
    mov esi, 0x1
    call open
    add esp, 0xc
    mov ecx, eax
    cmp eax, -1
    jz short .branch_36abd
    xor ebx, ebx
    xor edx, edx
    call lseek
    mov edx, eax

.branch_36a6e:
    cmp edx, -1
    jnz short .branch_36a81
    mov eax, ecx
    call close
    mov eax, edx
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

.branch_36a81:
    mov ebx, 0xc
    mov edx, frame_state_173d38
    mov eax, ecx
    call write
    cmp eax, 0xc
    jz short .branch_36aa8
    mov eax, ecx
    call close
    mov eax, 0xffffffff
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

.branch_36aa8:
    test esi, esi
    jz short .branch_36ab8
    mov eax, ecx
    call close
    call flushall

.branch_36ab8:
    mov eax, 0x1

.branch_36abd:
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

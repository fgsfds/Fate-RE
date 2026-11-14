; Detect cd drives.
BITS 32
ORG 0x376bb

simulate_real_mode_interrupt equ 0x375e9
memset equ 0x61350
real_mode_registers equ 0x173f56
frame_state_173f66 equ 0x173f66
frame_state_173f6e equ 0x173f6e
frame_state_173f72 equ 0x173f72
frame_state_173fa2 equ 0x173fa2

detect_cd_drives:
    push ebx
    push edx
    mov ebx, 0x32
    mov eax, real_mode_registers
    xor edx, edx
    call memset
    mov edx, 0x1500
    mov eax, 0x2f
    xor ebx, ebx
    mov [frame_state_173f72], edx
    mov edx, real_mode_registers
    mov [frame_state_173f66], ebx
    call simulate_real_mode_interrupt
    cmp dword [frame_state_173f66], 0x0
    jz short .branch_37715
    mov ax, [frame_state_173f6e]
    add eax, strict dword 0x41
    mov [frame_state_173fa2], ax
    mov eax, [frame_state_173f6e]
    add eax, 0x41
    pop edx
    pop ebx
    ret

.branch_37715:
    xor eax, eax
    pop edx
    pop ebx
    ret

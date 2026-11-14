; Stop cd driver playback.
BITS 32
ORG 0x37a85

active_cd_track equ 0x12d80
simulate_real_mode_interrupt equ 0x375e9
memset equ 0x61350
real_mode_registers equ 0x173f56
frame_state_173f66 equ 0x173f66
frame_state_173f6e equ 0x173f6e
frame_state_173f72 equ 0x173f72
frame_state_173f78 equ 0x173f78
frame_state_173f94 equ 0x173f94
cd_request_segment equ 0x173f9e
frame_state_173fa2 equ 0x173fa2
frame_state_173faa equ 0x173faa

stop_cd_driver_playback:
    push ebx
    push ecx
    push edx
    push esi
    xor ecx, ecx
    mov cx, [cd_request_segment]
    mov ebx, 0x16
    shl ecx, byte 0x4
    xor edx, edx
    mov eax, ecx
    mov esi, ds
    call memset
    mov gs, esi
    mov ebx, 0x32
    mov byte [gs:ecx], 0x16
    mov eax, real_mode_registers
    mov byte [gs:ecx + 0x1], 0x0
    xor edx, edx
    mov byte [gs:ecx + 0x2], 0x85
    call memset
    mov cx, [cd_request_segment]
    mov [frame_state_173f78], cx
    xor ecx, ecx
    mov edx, 0x1510
    mov cx, [frame_state_173f94]
    mov eax, 0x2f
    mov [frame_state_173f66], ecx
    movsx ecx, word [frame_state_173fa2]
    mov [frame_state_173f72], edx
    sub ecx, 0x41
    mov edx, real_mode_registers
    mov [frame_state_173f6e], ecx
    call simulate_real_mode_interrupt
    xor edx, edx
    mov [active_cd_track], dx
    mov [frame_state_173faa], dx
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

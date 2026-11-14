; Send cd driver request.
BITS 32
ORG 0x377a7

simulate_real_mode_interrupt equ 0x375e9
memset equ 0x61350
real_mode_registers equ 0x173f56
frame_state_173f66 equ 0x173f66
frame_state_173f6a equ 0x173f6a
frame_state_173f6e equ 0x173f6e
frame_state_173f72 equ 0x173f72
frame_state_173f7a equ 0x173f7a
frame_state_173f94 equ 0x173f94
cd_request_segment equ 0x173f9e

send_cd_driver_request:
    push ecx
    push esi
    push edi
    mov ecx, eax
    mov esi, edx
    mov edi, ebx
    mov ebx, 0x32
    mov eax, real_mode_registers
    xor edx, edx
    call memset
    movsx eax, cx
    mov [frame_state_173f66], eax
    mov ax, [cd_request_segment]
    mov [frame_state_173f7a], ax
    xor eax, eax
    mov ax, [frame_state_173f94]
    mov [frame_state_173f6a], eax
    movsx eax, si
    mov [frame_state_173f6e], eax
    movsx eax, di
    mov edx, real_mode_registers
    mov [frame_state_173f72], eax
    mov eax, 0x21
    call simulate_real_mode_interrupt
    pop edi
    pop esi
    pop ecx
    ret

; Read cd track info.
BITS 32
ORG 0x3786d

send_cd_driver_request equ 0x377a7
frame_state_173f8e equ 0x173f8e
frame_state_173f9a equ 0x173f9a
cd_request_segment equ 0x173f9e
frame_state_173fb5 equ 0x173fb5
frame_state_173fb6 equ 0x173fb6
frame_state_173fb7 equ 0x173fb7
frame_state_173fb8 equ 0x173fb8

read_cd_track_info:
    push ebx
    push ecx
    push edx
    push esi
    mov ebx, 0x4402
    mov edx, 0x8
    xor ecx, ecx
    mov esi, ds
    mov cx, [cd_request_segment]
    mov gs, esi
    shl ecx, byte 0x4
    cwde
    mov byte [gs:ecx], 0xa
    call send_cd_driver_request
    mov gs, esi
    xor eax, eax
    mov al, [gs:ecx + 0x1]
    mov [frame_state_173f8e], ax
    xor eax, eax
    mov al, [gs:ecx + 0x2]
    mov [frame_state_173f9a], ax
    mov al, [gs:ecx + 0x3]
    mov [frame_state_173fb5], al
    mov al, [gs:ecx + 0x4]
    mov [frame_state_173fb6], al
    mov al, [gs:ecx + 0x5]
    mov [frame_state_173fb7], al
    mov al, [gs:ecx + 0x6]
    mov [frame_state_173fb8], al
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

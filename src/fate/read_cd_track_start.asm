; Read cd track start.
BITS 32
ORG 0x378d8

send_cd_driver_request equ 0x377a7
frame_state_173ee8 equ 0x173ee8
frame_state_173ee9 equ 0x173ee9
frame_state_173eea equ 0x173eea
frame_state_173eeb equ 0x173eeb
frame_state_173eec equ 0x173eec
cd_request_segment equ 0x173f9e

read_cd_track_start:
    push ebx
    push ecx
    push esi
    sub esp, 0x4
    mov [esp], dl
    mov ebx, 0x4402
    xor ecx, ecx
    mov esi, ds
    mov cx, [cd_request_segment]
    mov gs, esi
    shl ecx, byte 0x4
    cwde
    mov [gs:ecx + 0x1], dl
    mov edx, 0x8
    mov byte [gs:ecx], 0xb
    call send_cd_driver_request
    xor edx, edx
    mov dl, [esp]
    mov eax, edx
    shl eax, byte 0x2
    mov gs, esi
    add eax, edx
    mov dl, [gs:ecx + 0x2]
    mov [eax + frame_state_173ee8], dl
    mov dl, [gs:ecx + 0x3]
    mov [eax + frame_state_173ee9], dl
    mov dl, [gs:ecx + 0x4]
    mov [eax + frame_state_173eea], dl
    mov dl, [gs:ecx + 0x5]
    mov [eax + frame_state_173eeb], dl
    mov dl, [gs:ecx + 0x6]
    mov [eax + frame_state_173eec], dl
    add esp, 0x4
    pop esi
    pop ecx
    pop ebx
    ret

; Play cd track.
BITS 32
ORG 0x37b22

selected_cd_track equ 0x12d7c
simulate_real_mode_interrupt equ 0x375e9
stop_cd_driver_playback equ 0x37a85
memset equ 0x61350
frame_state_173ee8 equ 0x173ee8
frame_state_173ee9 equ 0x173ee9
frame_state_173eea equ 0x173eea
frame_state_173eec equ 0x173eec
real_mode_registers equ 0x173f56
frame_state_173f66 equ 0x173f66
frame_state_173f6e equ 0x173f6e
frame_state_173f72 equ 0x173f72
frame_state_173f78 equ 0x173f78
frame_state_173f94 equ 0x173f94
last_cd_track equ 0x173f9a
cd_request_segment equ 0x173f9e
frame_state_173fa2 equ 0x173fa2
frame_state_173fb5 equ 0x173fb5
frame_state_173fb6 equ 0x173fb6
frame_state_173fb7 equ 0x173fb7

play_cd_track:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    sub esp, 0x4
    mov dx, [last_cd_track]

.branch_37b31:
    movzx esi, al
    mov ecx, esi
    shl ecx, byte 0x2
    add ecx, esi
    mov ah, [ecx + frame_state_173eec]
    and ah, 0x40
    movzx edi, ah
    cmp edi, 0x40
    jnz short .branch_37b5e
    inc al
    xor ecx, ecx
    mov cl, al
    cmp cx, dx
    jl short .branch_37b31
    xor eax, eax
    jmp near .branch_37ccc

.branch_37b5e:
    xor edi, edi
    call stop_cd_driver_playback
    mov di, [cd_request_segment]
    mov ebx, 0x16
    shl edi, byte 0x4
    xor edx, edx
    mov eax, edi
    mov word [esp], ds
    call memset
    mov gs, word [esp]
    mov byte [gs:edi], 0x16
    mov byte [gs:edi + 0x1], 0x0
    mov byte [gs:edi + 0x2], 0x84
    xor edx, edx
    mov byte [gs:edi + 0xd], 0x0
    mov dl, [ecx + frame_state_173eea]
    mov eax, edx
    shl eax, byte 0x5
    sub eax, edx
    shl eax, byte 0x2
    add eax, edx
    shl eax, byte 0x2
    xor ebx, ebx
    mov edx, eax
    shl eax, byte 0x3
    mov bl, [ecx + frame_state_173ee9]
    add eax, edx
    mov edx, ebx
    shl edx, byte 0x2
    add edx, ebx
    mov ebx, edx
    shl edx, byte 0x4
    sub edx, ebx
    add edx, eax
    xor eax, eax
    mov al, [ecx + frame_state_173ee8]
    add eax, edx
    lea edx, [eax-0x96]
    mov eax, edx
    sar eax, byte 0x8
    mov [gs:edi + 0xf], al
    mov eax, edx
    sar eax, byte 0x10
    mov [gs:edi + 0x10], al
    mov eax, edx
    mov [gs:edi + 0xe], dl
    sar eax, byte 0x18
    mov [gs:edi + 0x11], al
    xor eax, eax
    mov al, [frame_state_173fb7]
    mov ecx, eax
    shl ecx, byte 0x5
    sub ecx, eax
    shl ecx, byte 0x2
    add ecx, eax
    shl ecx, byte 0x2
    xor ebx, ebx
    mov eax, ecx
    shl ecx, byte 0x3
    mov bl, [frame_state_173fb6]
    add ecx, eax
    mov eax, ebx
    shl eax, byte 0x2
    add eax, ebx
    mov ebx, eax
    shl eax, byte 0x4
    sub eax, ebx
    xor ebx, ebx
    add eax, ecx
    mov bl, [frame_state_173fb5]
    add eax, ebx
    sub eax, strict dword 0x96
    sub eax, edx
    mov edx, eax
    sar edx, byte 0x8
    mov [gs:edi + 0x13], dl
    mov edx, eax
    mov [gs:edi + 0x12], al
    sar edx, byte 0x10
    sar eax, byte 0x18
    mov [gs:edi + 0x14], dl
    mov ebx, 0x32
    mov [gs:edi + 0x15], al
    mov eax, real_mode_registers
    xor edx, edx
    call memset
    mov ax, [cd_request_segment]
    mov [frame_state_173f78], ax
    xor eax, eax
    mov ax, [frame_state_173f94]
    mov edx, 0x1510
    mov [frame_state_173f66], eax
    movsx eax, word [frame_state_173fa2]
    mov [frame_state_173f72], edx
    sub eax, 0x41
    mov edx, real_mode_registers
    mov [frame_state_173f6e], eax
    mov eax, 0x2f
    call simulate_real_mode_interrupt
    mov gs, word [esp]
    mov al, [gs:edi + 0x4]
    and al, 0x1
    and eax, strict dword 0xff
    jz short .branch_37ccc
    mov eax, 0x1
    mov [selected_cd_track], esi

.branch_37ccc:
    add esp, 0x4
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

; Setup sprite horizontal reverse.
BITS 32
ORG 0x752b0

frame_state_65335 equ 0x65335
frame_state_6533c equ 0x6533c
frame_state_65342 equ 0x65342
frame_state_65362 equ 0x65362
frame_state_65368 equ 0x65368
frame_state_6536e equ 0x6536e
frame_state_65374 equ 0x65374
frame_state_6537a equ 0x6537a
frame_state_65388 equ 0x65388
frame_state_6538e equ 0x6538e
frame_state_65394 equ 0x65394
frame_state_6539a equ 0x6539a
frame_state_653a0 equ 0x653a0

setup_sprite_horizontal_reverse:
    mov [frame_state_65335], ebx
    mov [frame_state_6533c], ecx
    db 0x33, 0xff  ; xor edi, edi, register-destination encoding
    db 0x2b, 0xf9  ; sub edi, ecx, register-destination encoding
    mov [frame_state_65362], edi
    mov [frame_state_65388], edi
    db 0x03, 0xdb  ; add ebx, ebx, register-destination encoding
    db 0x13, 0xc9  ; adc ecx, ecx, register-destination encoding
    mov [frame_state_65368], ebx
    mov [frame_state_6538e], ebx
    mov [frame_state_6536e], ecx
    mov [frame_state_65394], ecx
    mov [frame_state_65374], edx
    mov [frame_state_6537a], edx
    mov [frame_state_6539a], edx
    mov [frame_state_653a0], edx
    mov [frame_state_65342], edx
    ret

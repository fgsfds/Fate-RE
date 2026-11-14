; Setup sprite horizontal masked.
BITS 32
ORG 0x75230

frame_state_65274 equ 0x65274
frame_state_6527c equ 0x6527c
frame_state_65282 equ 0x65282
frame_state_65288 equ 0x65288
frame_state_65293 equ 0x65293

setup_sprite_horizontal_masked:
    mov [frame_state_65274], eax
    mov [frame_state_6527c], ebx
    mov [frame_state_65282], ecx
    mov [frame_state_65293], edx
    mov [frame_state_65288], esi
    ret

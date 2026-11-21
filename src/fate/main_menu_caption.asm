; Retained loading-caption argument setup.
BITS 32
ORG 0x3a25c
frame_state_12df8 equ 0x12df8
frame_state_d7c equ 0xd7c

main_menu_caption:
    mov edx, [frame_state_12df8]
    mov eax, edx
    shl eax, byte 0x3
    mov ecx, frame_state_d7c
    sub eax, edx
    mov edx, 0xa0
    sar eax, 1
    mov ebx, 0xffffffff
    sub edx, eax
    push esi
    mov eax, edx
    mov edx, 0x4e

; Setup sprite horizontal unrolled.
BITS 32
ORG 0x75080

frame_state_65154 equ 0x65154
frame_state_6515c equ 0x6515c
frame_state_65162 equ 0x65162
frame_state_65168 equ 0x65168
frame_state_6516e equ 0x6516e
frame_state_6518f equ 0x6518f
frame_state_65197 equ 0x65197
frame_state_6519d equ 0x6519d
frame_state_651a3 equ 0x651a3
frame_state_651ab equ 0x651ab
frame_state_651b3 equ 0x651b3
frame_state_651bb equ 0x651bb
frame_state_651c1 equ 0x651c1
frame_state_651c7 equ 0x651c7
frame_state_651cd equ 0x651cd
frame_state_651da equ 0x651da
frame_state_651e2 equ 0x651e2
frame_state_651e8 equ 0x651e8
frame_state_651ee equ 0x651ee
frame_state_651f6 equ 0x651f6
frame_state_651fe equ 0x651fe
frame_state_65206 equ 0x65206
frame_state_6520c equ 0x6520c
frame_state_65212 equ 0x65212
frame_state_65218 equ 0x65218

setup_sprite_horizontal_unrolled:
    mov [frame_state_6518f], eax
    mov [frame_state_651ab], eax
    mov [frame_state_651da], eax
    mov [frame_state_651f6], eax
    mov [frame_state_65154], eax
    mov [frame_state_65197], ebx
    mov [frame_state_651bb], ebx
    mov [frame_state_651e2], ebx
    mov [frame_state_65206], ebx
    mov [frame_state_6515c], ebx
    mov [frame_state_6519d], ecx
    mov [frame_state_651c1], ecx
    mov [frame_state_651e8], ecx
    mov [frame_state_6520c], ecx
    mov [frame_state_65162], ecx
    mov [frame_state_651b3], edx
    mov [frame_state_651cd], edx
    mov [frame_state_651fe], edx
    mov [frame_state_65218], edx
    mov [frame_state_65168], edx
    mov [frame_state_651a3], esi
    mov [frame_state_651c7], esi
    mov [frame_state_651ee], esi
    mov [frame_state_65212], esi
    mov [frame_state_6516e], esi
    ret

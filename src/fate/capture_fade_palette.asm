; Capture fade palette.
BITS 32
ORG 0x3658e

build_palette_fade_tables equ 0x36305
memmove equ 0x62d49
saved_palette equ 0x172e14
frame_state_173d2c equ 0x173d2c
brightness_palette equ 0x27c0a0
totalclock equ 0x287e88

capture_fade_palette:
    push ebx
    push edx
    mov ebx, 0x300
    mov edx, brightness_palette
    mov eax, saved_palette
    call memmove
    call build_palette_fade_tables
    mov eax, [totalclock]
    mov [frame_state_173d2c], eax
    pop edx
    pop ebx
    ret

; Switch clipping between the saved rectangle and full-screen bounds.
BITS 32
ORG 0x71689

recalculate_coordinate_scales equ 0x7351c

clipping_enabled equ 0x16c70
screen_width equ 0x2891fc
screen_height equ 0x2891fe
clip_left equ 0x289216
clip_right equ 0x289218
clip_top equ 0x28921a
clip_bottom equ 0x28921c
saved_clip_left equ 0x28921e
saved_clip_right equ 0x289220
saved_clip_top equ 0x289222
saved_clip_bottom equ 0x289224

set_graphics_clipping:
    push edx
    movzx dx, byte [clipping_enabled]
    mov byte [clipping_enabled], al
    test al, al
    je short .full_screen
    mov ax, word [saved_clip_left]
    mov word [clip_left], ax
    mov ax, word [saved_clip_right]
    mov word [clip_right], ax
    mov ax, word [saved_clip_top]
    mov word [clip_top], ax
    mov ax, word [saved_clip_bottom]
    jmp short .refresh_scales
.full_screen:
    mov ax, word [screen_width]
    dec eax
    mov word [clip_right], ax
    mov ax, word [screen_height]
    mov word [clip_left], 0
    dec eax
    mov word [clip_top], 0
.refresh_scales:
    mov word [clip_bottom], ax
    call recalculate_coordinate_scales
    mov eax, edx
    pop edx
    ret

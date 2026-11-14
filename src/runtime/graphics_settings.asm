BITS 32
ORG 0x7162c

graphics_word_a7 equ 0x16ca7
graphics_word_a9 equ 0x16ca9
graphics_word_a1 equ 0x16ca1
graphics_word_a3 equ 0x16ca3
graphics_error equ 0x16c66
graphics_word_a5 equ 0x16ca5
graphics_word_ab equ 0x16cab
graphics_word_ad equ 0x16cad
graphics_word_af equ 0x16caf

set_absolute_graphics_pair:
    push ebx
    mov ebx, edx
    cwde
    cdq
    xor eax, edx
    sub eax, edx
    mov word [graphics_word_a7], ax
    movsx eax, bx
    cdq
    xor eax, edx
    sub eax, edx
    mov word [graphics_word_a9], ax
    pop ebx
    ret

set_nonzero_graphics_pair:
    test ax, ax
    jne short .store
    test dx, dx
    je short .invalid
.store:
    mov word [graphics_word_a1], ax
    mov word [graphics_word_a3], dx
    ret
.invalid:
    mov word [graphics_error], 0xfffc
    ret

set_graphics_word_a5:
    mov word [graphics_word_a5], ax
    ret

set_graphics_word_ab:
    mov word [graphics_word_ab], ax
    ret

set_graphics_pair_ad:
    mov word [graphics_word_ad], ax
    mov word [graphics_word_af], dx
    ret

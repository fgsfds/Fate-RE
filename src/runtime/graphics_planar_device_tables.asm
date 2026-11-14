; Watcom graphics device records in original callback order.
BITS 32
ORG 0x16ec8

code_base equ 0x10000

device_16ec8:
    dd 0x7037c - code_base
    dd 0x704d5 - code_base
    dd 0x704d6 - code_base
    dd 0x70508 - code_base
    dd 0x70539 - code_base
    dd 0x7222a - code_base
    dd 0x72234 - code_base
    dd 0x7222f - code_base
    dd 0x7223b - code_base
    dd 0x72242 - code_base
    dd 0x72242 - code_base
    dd 0x72242 - code_base
    dd 0x72242 - code_base
    dd 0x72271 - code_base
    dd 0x724d4 - code_base
    dd 0x72547 - code_base
    dd 0x7231e - code_base
    dd 0x72476 - code_base
    dd 0x72646 - code_base
    dd 0x726f9 - code_base

device_16f18:
    dd 0x7037c - code_base
    dd 0x704d5 - code_base
    dd 0x704d6 - code_base
    dd 0x70508 - code_base
    dd 0x7058e - code_base
    dd 0x72220 - code_base
    dd 0x72234 - code_base
    dd 0x72225 - code_base
    dd 0x7223b - code_base
    dd 0x72242 - code_base
    dd 0x72242 - code_base
    dd 0x72242 - code_base
    dd 0x72242 - code_base
    dd 0x72271 - code_base
    dd 0x724d4 - code_base
    dd 0x72547 - code_base
    dd 0x7231e - code_base
    dd 0x72476 - code_base
    dd 0x72646 - code_base
    dd 0x726f9 - code_base

device_16f68:
    dd 0x7037c - code_base
    dd 0x704d5 - code_base
    dd 0x704d6 - code_base
    dd 0x70508 - code_base
    dd 0x7059a - code_base
    dd 0x72220 - code_base
    dd 0x72234 - code_base
    dd 0x72225 - code_base
    dd 0x7223b - code_base
    dd 0x72242 - code_base
    dd 0x72242 - code_base
    dd 0x72242 - code_base
    dd 0x72242 - code_base
    dd 0x72257 - code_base
    dd 0x724cd - code_base
    dd 0x7253e - code_base
    dd 0x72307 - code_base
    dd 0x7245e - code_base
    dd 0x72642 - code_base
    dd 0x726f5 - code_base

device_16fb8:
    dd 0x7037c - code_base
    dd 0x704d5 - code_base
    dd 0x704d6 - code_base
    dd 0x70508 - code_base
    dd 0x7058e - code_base
    dd 0x72220 - code_base
    dd 0x72234 - code_base
    dd 0x72225 - code_base
    dd 0x7223b - code_base
    dd 0x72242 - code_base
    dd 0x72242 - code_base
    dd 0x72242 - code_base
    dd 0x72242 - code_base
    dd 0x72271 - code_base
    dd 0x724d4 - code_base
    dd 0x72547 - code_base
    dd 0x7231e - code_base
    dd 0x72476 - code_base
    dd 0x72646 - code_base
    dd 0x726f9 - code_base

device_17008:
    dd 0x704d5 - code_base
    dd 0x704d5 - code_base
    dd 0x704fb - code_base
    dd 0x7052c - code_base
    dd 0x7059a - code_base
    dd 0x72220 - code_base
    dd 0x72234 - code_base
    dd 0x72225 - code_base
    dd 0x7223b - code_base
    dd 0x72242 - code_base
    dd 0x72242 - code_base
    dd 0x72242 - code_base
    dd 0x72242 - code_base
    dd 0x7225f - code_base
    dd 0x724cd - code_base
    dd 0x7253e - code_base
    dd 0x7229f - code_base
    dd 0x72422 - code_base
    dd 0x725f7 - code_base
    dd 0x72683 - code_base

device_17058:
    dd 0x705f7 - code_base
    dd 0x706a1 - code_base
    dd 0x706a1 - code_base
    dd 0x706a1 - code_base
    dd 0x706a2 - code_base
    dd 0x72220 - code_base
    dd 0x71dff - code_base
    dd 0x72225 - code_base
    dd 0x71ded - code_base
    dd 0x71dd3 - code_base
    dd 0x71dc5 - code_base
    dd 0x71dca - code_base
    dd 0x71ddf - code_base
    dd 0x71e47 - code_base
    dd 0x71ebb - code_base
    dd 0x71ecb - code_base
    dd 0x71e67 - code_base
    dd 0x71e7f - code_base
    dd 0x72059 - code_base
    dd 0x72085 - code_base

device_170a8:
    dd 0x705f7 - code_base
    dd 0x706a1 - code_base
    dd 0x704d6 - code_base
    dd 0x70508 - code_base
    dd 0x7058e - code_base
    dd 0x72220 - code_base
    dd 0x72234 - code_base
    dd 0x72225 - code_base
    dd 0x7223b - code_base
    dd 0x72242 - code_base
    dd 0x72242 - code_base
    dd 0x72242 - code_base
    dd 0x72242 - code_base
    dd 0x72271 - code_base
    dd 0x724d4 - code_base
    dd 0x72547 - code_base
    dd 0x7231e - code_base
    dd 0x72476 - code_base
    dd 0x72646 - code_base
    dd 0x726f9 - code_base

device_170f8:
    dd 0x705f7 - code_base
    dd 0x706a1 - code_base
    dd 0x706a1 - code_base
    dd 0x706a1 - code_base
    dd 0x70708 - code_base
    dd 0x7276f - code_base
    dd 0x7277f - code_base
    dd 0x72777 - code_base
    dd 0x72782 - code_base
    dd 0x7276a - code_base
    dd 0x71dc5 - code_base
    dd 0x72765 - code_base
    dd 0x71ddf - code_base
    dd 0x72784 - code_base
    dd 0x7279a - code_base
    dd 0x727b8 - code_base
    dd 0x727fa - code_base
    dd 0x72828 - code_base
    dd 0x72831 - code_base
    dd 0x72854 - code_base

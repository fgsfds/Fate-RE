; Watcom Hercules video device callback table.
BITS 32
ORG 0x16e70

code_base equ 0x10000
    dd 0x70293 - code_base
    dd 0x702fb - code_base
    dd 0x702fb - code_base
    dd 0x702fb - code_base
    dd 0x702fc - code_base
    dd 0x721f8 - code_base
    dd 0x71dff - code_base
    dd 0x7220a - code_base
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

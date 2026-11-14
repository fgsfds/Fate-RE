; CODE-relative entries for video mode dispatch.
BITS 32
ORG 0x4b02e

code_base equ 0x10000
case_4b1f3 equ 0x4b1f3
case_4b275 equ 0x4b275
case_4b295 equ 0x4b295
case_4b2aa equ 0x4b2aa
case_4b2b9 equ 0x4b2b9
case_4b320 equ 0x4b320

video_mode_dispatch:
    dd case_4b1f3 - code_base
    dd case_4b275 - code_base
    dd case_4b295 - code_base
    dd case_4b2aa - code_base
    dd case_4b2aa - code_base
    dd case_4b2aa - code_base
    dd case_4b2b9 - code_base
    dd case_4b320 - code_base

; HMI output mixer entries indexed by the flags in audio_service.asm.
BITS 32
ORG 0x6dcfd

code_base equ 0x10000

audio_output_dispatch:
    dd 0x6e0fd - code_base, 0x6e10b - code_base, 0x6e11a - code_base, 0x6e12d - code_base
    dd 0x6e141 - code_base, 0x6e155 - code_base, 0x6e16b - code_base, 0x6e18a - code_base
    dd 0x6e1ab - code_base, 0x6e1b9 - code_base, 0x6e1c8 - code_base, 0x6e1db - code_base
    dd 0x6e1ef - code_base, 0x6e203 - code_base, 0x6e219 - code_base, 0x6e238 - code_base
    dd 0x6e259 - code_base, 0x6e283 - code_base, 0x6e2ae - code_base, 0x6e2dd - code_base
    dd 0x6e30d - code_base, 0x6e35b - code_base, 0x6e3ab - code_base, 0x6e404 - code_base
    dd 0x6e45f - code_base, 0x6e489 - code_base, 0x6e4b4 - code_base, 0x6e4e3 - code_base
    dd 0x6e513 - code_base, 0x6e561 - code_base, 0x6e5b1 - code_base, 0x6e60a - code_base

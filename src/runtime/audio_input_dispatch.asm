; HMI input mixer entries indexed by the flags in audio_service.asm.
BITS 32
ORG 0x6bdb9

code_base equ 0x10000

audio_input_dispatch:
    dd 0x6c1b9 - code_base, 0x6c1d7 - code_base, 0x6c1fa - code_base, 0x6c219 - code_base
    dd 0x6c23d - code_base, 0x6c25e - code_base, 0x6c284 - code_base, 0x6c2a6 - code_base
    dd 0x6c2cd - code_base, 0x6c2ee - code_base, 0x6c31a - code_base, 0x6c33d - code_base
    dd 0x6c36b - code_base, 0x6c392 - code_base, 0x6c3c4 - code_base, 0x6c3ed - code_base
    dd 0x6c421 - code_base, 0x6c448 - code_base, 0x6c474 - code_base, 0x6c4a1 - code_base
    dd 0x6c4d3 - code_base, 0x6c4fd - code_base, 0x6c52c - code_base, 0x6c55c - code_base
    dd 0x6c591 - code_base, 0x6c5c0 - code_base, 0x6c5fa - code_base, 0x6c62b - code_base
    dd 0x6c667 - code_base, 0x6c69c - code_base, 0x6c6dc - code_base, 0x6c713 - code_base
    dd 0x6c755 - code_base, 0x6c77f - code_base, 0x6c7ae - code_base, 0x6c7d9 - code_base
    dd 0x6c809 - code_base, 0x6c847 - code_base, 0x6c88a - code_base, 0x6c8c9 - code_base
    dd 0x6c90d - code_base, 0x6c93a - code_base, 0x6c972 - code_base, 0x6c9a1 - code_base
    dd 0x6c9db - code_base, 0x6ca1a - code_base, 0x6ca64 - code_base, 0x6caa5 - code_base
    dd 0x6caf1 - code_base, 0x6cb24 - code_base, 0x6cb5c - code_base, 0x6cb95 - code_base
    dd 0x6cbd3 - code_base, 0x6cc1a - code_base, 0x6cc66 - code_base, 0x6ccb3 - code_base
    dd 0x6cd05 - code_base, 0x6cd40 - code_base, 0x6cd86 - code_base, 0x6cdc3 - code_base
    dd 0x6ce0b - code_base, 0x6ce58 - code_base, 0x6ceb0 - code_base, 0x6ceff - code_base
    dd 0x6cf59 - code_base, 0x6cf77 - code_base, 0x6cf9a - code_base, 0x6cfb9 - code_base
    dd 0x6cfdd - code_base, 0x6cffe - code_base, 0x6d024 - code_base, 0x6d046 - code_base
    dd 0x6d06d - code_base, 0x6d08e - code_base, 0x6d0ba - code_base, 0x6d0dd - code_base
    dd 0x6d10b - code_base, 0x6d132 - code_base, 0x6d164 - code_base, 0x6d18d - code_base
    dd 0x6d1c1 - code_base, 0x6d1e8 - code_base, 0x6d214 - code_base, 0x6d241 - code_base
    dd 0x6d273 - code_base, 0x6d29d - code_base, 0x6d2cc - code_base, 0x6d2fc - code_base
    dd 0x6d331 - code_base, 0x6d360 - code_base, 0x6d39a - code_base, 0x6d3cb - code_base
    dd 0x6d407 - code_base, 0x6d43c - code_base, 0x6d47c - code_base, 0x6d4b3 - code_base
    dd 0x6d4f5 - code_base, 0x6d51f - code_base, 0x6d54e - code_base, 0x6d579 - code_base
    dd 0x6d5a9 - code_base, 0x6d5e7 - code_base, 0x6d62a - code_base, 0x6d669 - code_base
    dd 0x6d6ad - code_base, 0x6d6da - code_base, 0x6d712 - code_base, 0x6d741 - code_base
    dd 0x6d77b - code_base, 0x6d7ba - code_base, 0x6d804 - code_base, 0x6d845 - code_base
    dd 0x6d891 - code_base, 0x6d8c4 - code_base, 0x6d8fc - code_base, 0x6d935 - code_base
    dd 0x6d973 - code_base, 0x6d9ba - code_base, 0x6da06 - code_base, 0x6da53 - code_base
    dd 0x6daa5 - code_base, 0x6dae0 - code_base, 0x6db26 - code_base, 0x6db63 - code_base
    dd 0x6dbab - code_base, 0x6dbf8 - code_base, 0x6dc50 - code_base, 0x6dc9f - code_base

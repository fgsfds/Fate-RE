; Stored video modes, keyboard bindings, audio rates and interaction defaults.
BITS 32
ORG 0x3bec

    dd -2
    dd 256, 320, 360, 400
    dd 200, 240, 256, 270, 300, 350, 360, 400, 480, 512, 540

vesa_dimensions:
    dd 320, 200, 360, 200, 320, 240, 360, 240, 320, 400, 360, 400
    dd 640, 350, 640, 400, 640, 480, 800, 600, 1024, 768, 1280, 1024, 1600, 1200

    times 6 db 0
    dw 1
    db 0xc8, 0xd0, 0xcb, 0xcd, 0x2a, 0x9d, 0x1d, 0x39, 0x1e, 0x2c
    db 0xd1, 0xc9, 0x33, 0x34, 0x9c, 0x1c, 0x0d, 0x0c, 0x0f

sample_rates:
    dd 6000, 8000, 11025, 16000, 22050, 32000, 44100

    db 0xff, 0, 0xff, 0, 0, 0, 1, 3, 0, 3, 15, 1
    times 5 db 0
    times 0x3d04 - 0x3cdc db 0     ; Event indices, clocks and input state.

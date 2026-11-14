; EGA component encoding and the sixteen legacy colors stored as R, G, B, 0.
BITS 32

ega_component_bits:
    db 0, 8, 1, 9

legacy_rgb_palette:
    db 0, 0, 0, 0
    db 0, 0, 42, 0
    db 0, 42, 0, 0
    db 0, 42, 42, 0
    db 42, 0, 0, 0
    db 42, 0, 42, 0
    db 42, 21, 0, 0
    db 42, 42, 42, 0
    db 21, 21, 21, 0
    db 21, 21, 63, 0
    db 21, 63, 21, 0
    db 21, 63, 63, 0
    db 63, 21, 21, 0
    db 63, 21, 63, 0
    db 63, 63, 21, 0
    db 63, 63, 63, 0

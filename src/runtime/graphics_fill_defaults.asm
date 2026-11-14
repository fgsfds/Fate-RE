; Both the active and reset fill patterns start solid.
BITS 32

fill_pattern:
    times 8 db 0xff
default_fill_pattern:
    times 8 db 0xff
fill_pattern_enabled:
    db 0
pattern_transparent:
    dw 1

; VBE controller signatures and mode-selection diagnostics.
BITS 32
ORG 0x19e2

    db 'VBE2', 0
    db 'VESA', 0
    db 'VESA not found!', 10, 0
    db 'VESA says that %ld*%ld is not currently supported.', 10, 0

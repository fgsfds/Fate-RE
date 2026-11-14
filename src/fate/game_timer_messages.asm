; Timer initialization and shutdown diagnostics.
BITS 32
ORG 0x61c

    db 'inittimer() : Failed to init timer system!', 0
    db 'inittimer() : Failed to register game timer!', 0
    db 'uninittimer() : Failed to remove game timer!', 0
    db 'uninittimer() : Failed to uninit SOS timer system!', 0

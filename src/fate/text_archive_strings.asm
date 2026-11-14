; Archive filename and read diagnostics.
BITS 32
ORG 0xbbc

    db 'text.dat', 0
    db 'textprint: lseek text.dat failed', 0
    db 'textprint: read text.dat failed', 0

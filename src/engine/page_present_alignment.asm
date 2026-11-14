; Two-byte alignment before the page presentation dispatch table.
BITS 32
ORG 0x4b47c

    db 0x8b, 0xc0  ; mov eax, eax, with the original register-load encoding

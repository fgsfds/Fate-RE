; Startup diagnostics for the IPX transport.
BITS 32
ORG 0x18cc

    db 'IPX driver not found', 10, 0
    db 'Socket could not be opened', 10, 0
    db "Can't allocate memory for IPX", 10, 0

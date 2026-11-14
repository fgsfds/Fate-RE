; Allocation diagnostics used by engine video setup.
BITS 32
ORG 0x1af9

    db 'OUT OF MEMORY', 10, 0
    times 5 db 'Not enough memory for screen allocation', 10, 0

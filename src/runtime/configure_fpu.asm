; Distinguish x87 infinity semantics and load the requested control word.
BITS 32
ORG 0x6ad8e

configure_fpu equ 0x6ad8e
    times 39 db 0    ; configure_fpu is supplied by C.

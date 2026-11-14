; Initial HMI driver exchange and software mixer workspace.
BITS 32
ORG 0x16b0c

    dd 0
    times 0x50 db 0             ; Local copy of a driver record.
    times 0x10 db 0             ; Driver record and callback far pointers.
    times 0x30 db 0             ; DPMI memory information.
    times 0x50 db 0             ; Real-mode register exchange.
    times 0x4c db 0             ; Driver parameters, selector and mixer state.
    dd 0x1fff, 0x1fff           ; Left and right gain.
    times 3 dd 0                ; Remaining mixer state.

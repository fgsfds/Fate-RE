; HMI interrupt stack, saved context and driver path storage.
BITS 32
ORG 0x1450e

    dd dispatch_stack          ; Initial ESP in the LSS operand.
    dw 0                       ; Selector filled by timer installation.
    dw 0                       ; Reserved word.
    dd 0                       ; Saved ESP.
    dw 0                       ; Saved SS.
    dw 0                       ; Reserved word.

    times 8192 db 0
dispatch_stack:
    dd 0                       ; Current dispatch ESP.
    dd 0                       ; EAX saved while chaining.
    dw 0                       ; IRQ reentrancy flag.
    dd 0, 0                    ; PIT programming and DPMI vector flags.
    dd 0, 0                    ; Audio backend state.
    dd 0                       ; Audio system flags.
    times 128 db 0             ; Driver directory.
    times 128 db 0             ; Complete driver path.
    times 5 dd 0               ; Loaded driver slots.

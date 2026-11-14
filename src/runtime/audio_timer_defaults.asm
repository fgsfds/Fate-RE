; HMI driver image state and the timer callback tables.
BITS 32
ORG 0x16650

    times 4 dd -1              ; DPMI exchange fields.
    times 0x5c db 0            ; Driver header and entry scratch space.
    dd 0, 0                    ; Allocation and release hooks.
    dd 0                       ; Timer flags.
    dd -1                      ; PIT divisor before initialization.
    times 16 dd 0              ; Timer callbacks.
    times 4 * 16 dd -1         ; Frequencies, increments, accumulators and contexts.
    dd -1                      ; Current timer context.

; Return from the disabled positioned sound entry.
BITS 32
ORG 0x34f71

    ; The observed callers enter directly at the stack-cleaning return.
    mov eax, -1

disabled_positioned_sound:
    ret word 0x8

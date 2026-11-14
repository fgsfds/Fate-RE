; Increment the game clock and acknowledge the timer interrupt.
BITS 32
ORG 0x347f7

outp equ 0x6039a
totalclock equ 0x287e88

advance_timer_clock:
    push edx
    mov eax, [totalclock]
    inc dword [totalclock]
    mov edx, 0x20
    mov eax, edx
    call outp
    pop edx
    ret

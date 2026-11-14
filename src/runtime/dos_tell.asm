; Query the current DOS descriptor position with a zero relative seek.
BITS 32
ORG 0x6adb5

lseek_ equ 0x615b6

tell_:
    push ebx
    push edx
    mov ebx, 1
    xor edx, edx
    call lseek_
    pop edx
    pop ebx
    ret

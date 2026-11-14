; Wait vertical retrace.
BITS 32
ORG 0x40b81


    db 0 ; alignment before the retrace routine

wait_vertical_retrace:
    xor edx, edx
    xor eax, eax
    xor dx, 0x3da

.branch_40b8b:
    in al, dx
    test al, 0x8
    jnz short .branch_40b8b

.branch_40b90:
    in al, dx
    test al, 0x8
    jz short .branch_40b90
    loop .branch_40b8b
    cld
    ret

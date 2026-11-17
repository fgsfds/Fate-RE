; Save and restore the x87 state around a DOS child launch.
BITS 32
ORG 0x645f7

save_fpu_state:
    wait
    fnsave [eax]
    wait
    ret

restore_fpu_state:
    frstor [eax]
    wait
    ret

BITS 32
ORG 0x602c3

labs_:
    test eax, eax
    jge short .done
    neg eax
.done:
    ret

BITS 32
ORG 0x602ca

random_seed equ 0x141a4

initrandnext_:
    mov eax, random_seed
    ret

rand_:
    push edx
    call initrandnext_
    test eax, eax
    je short .restore
    imul edx, [eax], 0x41c64e6d
    add edx, 0x3039
    mov [eax], edx
    mov eax, edx
    shr eax, 16
    and eax, 0x7fff
.restore:
    pop edx
    ret

srand_:
    push edx
    mov edx, eax
    call initrandnext_
    test eax, eax
    je short .restore
    mov [eax], edx
.restore:
    pop edx
    ret

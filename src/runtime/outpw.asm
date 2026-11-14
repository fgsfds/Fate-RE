; Independently reconstructed word port output from pinned FATE.
; EAX port, EDX value; returns the full original value in EAX.
; EBX is preserved, EDX becomes the original port; OUT uses low 16 bits.
BITS 32
outpw_:
    push ebx
    mov ebx, edx
    mov edx, eax
    mov eax, ebx
    out dx, ax
    pop ebx
    ret

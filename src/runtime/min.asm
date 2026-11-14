; Independently reconstructed signed minimum from pinned FATE, Watcom register ABI.
; EAX and EDX inputs, EAX result; other registers unchanged.
BITS 32
min_:
    cmp eax, edx
    jl short done
    mov eax, edx
done:
    ret

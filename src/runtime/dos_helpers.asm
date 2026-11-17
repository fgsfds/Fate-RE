; Runtime initialization and shutdown thunks, string and DOS helpers.
BITS 32
ORG 0x60322

    times 10 db 0   ; The runtime init and fini thunks are placed here from C.
    times 7 db 0    ; abs is placed here from C.

strcpy_:
    push ecx
    push eax

.copy_byte_pair:
    mov cl, byte [edx]
    mov byte [eax], cl
    cmp cl, 0
    je short .return_destination
    mov cl, byte [edx + 1]
    add edx, 2
    mov byte [eax + 1], cl
    add eax, 2
    cmp cl, 0
    jne short .copy_byte_pair

.return_destination:
    pop eax
    pop ecx
    ret

    db 0             ; The default exit hook is placed here from C.

    times 46 db 0    ; exit and _exit are placed here from C.

    times 25 db 0    ; strlen is supplied by C.

    times 14 db 0    ; outp is supplied by C.

    times 52 db 0    ; _dos_getvect is supplied by C.

    times 2 db 0    ; _disable is placed here from C.

    times 43 db 0    ; _dos_setvect is supplied by C.

_enable_:
    sti
    ret

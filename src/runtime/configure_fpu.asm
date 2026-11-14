; Distinguish x87 infinity semantics and load the requested control word.
BITS 32
ORG 0x6ad8e

configure_fpu:
    push ax
    finit
    fld1
    fldz
    fdivp st1
    fld st0
    fchs
    fcompp
    fnstsw ax
    mov al, 2
    sahf
    je short .load_control_word
    mov al, 3
.load_control_word:
    finit
    fldcw [esp]
    xchg [esp], ax
    pop ax
    ret

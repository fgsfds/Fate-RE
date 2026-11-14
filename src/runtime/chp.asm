; Watcom-style x87 truncation. Leave the caller's control word intact.
BITS 32
ORG 0x60304

__CHP:
    push eax
    wait
    fnstcw [esp]
    wait
    push dword [esp]
    mov byte [esp+1],0x1f
    fldcw [esp]
    frndint
    fldcw [esp+4]
    wait
    lea esp,[esp+8]
    ret

; Independently reconstructed runtime DS reload helper from pinned FATE.
; The selector word is populated by external startup code, not emitted here.
; Address is CODE-object-relative; the LE loader relocates its absolute field.
BITS 32
runtime_data_selector equ 0x501dd
__GETDS:
    ; NASM orders segment before operand-size prefixes; original orders 66 first.
    ; Spell only this architectural prefix explicitly, keeping MOV symbolic.
    db 0x66 ; operand-size override
    mov ds, [cs:runtime_data_selector]
    ret

; "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
; Ken Silverman's official web site: "http://www.advsys.net/ken"
; See the included license file "BUILDLIC.TXT" for license info.
; This file has been modified from Ken Silverman's original release
; NASM transcription of A_WASM/A.ASM tvlineasm1. Setup routines patch the
; shift, translucency pointer, bank direction and pitch before drawing.
; Original DS-relative code location; the self-write operand needs LE relocation.
; NASM chooses the other legal register/register direction by default.
; Encode the r32,r/m32 form explicitly from opcode and named register numbers.
%assign R_EAX 0
%assign R_ECX 1
%assign R_EDX 2
%assign R_EBX 3
%assign R_ESP 4
%assign R_EBP 5
%assign R_ESI 6
%assign R_EDI 7
%macro LOAD_FORM32 3
    db %1, 0xc0 | (%2 << 3) | %3
%endmacro
BITS 32
ORG 0x644d0

tvlineasm1_:
    push ebp
    LOAD_FORM32 0x8b, R_EBP, R_EAX ; MOV
    LOAD_FORM32 0x33, R_EAX, R_EAX ; XOR
    inc ecx
    mov dword [transmach3c+2], ebx
    jmp short begintvline
    ; Original ALIGN 16 uses a two-byte register-neutral instruction. NASM's
    ; ALIGN fill argument counts bytes, so express the two-byte repeat count.
    times ((16-(($-$$) % 16)) % 16)/2 xchg ebx, ebx
begintvline:
    LOAD_FORM32 0x8b, R_EBX, R_EDX ; MOV
transmach3a:
    shr ebx, 32
    mov bl, byte [esi+ebx]
    cmp bl, 255
    je short skiptrans1
transmach3c:
    mov al, [ebx+0x88888888]
transrev1:
    mov ah, byte [edi]
transmach4:
    mov al, byte [eax+0x88888888]
    mov byte [edi], al
skiptrans1:
    LOAD_FORM32 0x03, R_EDX, R_EBP ; ADD
fixchain1t:
    add edi, strict dword 320
    dec ecx
    jnz short begintvline
    pop ebp
    LOAD_FORM32 0x8b, R_EAX, R_EDX ; MOV
    ret

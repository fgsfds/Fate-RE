; "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
; Ken Silverman's official web site: "http://www.advsys.net/ken"
; See the included license file "BUILDLIC.TXT" for license info.
; This file has been modified from Ken Silverman's original release
; NASM transcription of historical A_MASM single-column raster routines.
; Explicit ModR/M encoding selects the original legal load-direction form.
%macro LOAD_FORM32 3
 db %1, 0xc0 | (%2 << 3) | %3
%endmacro
BITS 32
ORG 0x64340

vlineasm1_:
	push ebp
	LOAD_FORM32 0x8b, 5, 3 ; MOV EBP,EBX
	inc ecx
fixchain1a: sub edi, 320
beginvline:
	LOAD_FORM32 0x8b, 3, 2 ; MOV EBX,EDX
mach3a: shr ebx, 32
fixchain1b: add edi, 320
	mov bl, byte [esi+ebx]
	LOAD_FORM32 0x03, 2, 0 ; ADD EDX,EAX
	dec ecx
	mov bl, byte [ebp+ebx]
	mov byte [edi], bl
	jnz short beginvline
	pop ebp
	LOAD_FORM32 0x8b, 0, 2 ; MOV EAX,EDX
	ret

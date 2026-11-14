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
ORG 0x64320
vlineasm1_ equ 0x64340

prevlineasm1_:
	test ecx, ecx
	jnz near vlineasm1_

	LOAD_FORM32 0x03, 0, 2 ; ADD EAX,EDX
premach3a: shr edx, 32
	mov dl, byte [esi+edx]
	mov cl, byte [ebx+edx]
	mov byte [edi], cl
	ret

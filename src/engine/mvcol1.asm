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
ORG 0x64370

mvlineasm1_:
	push ebp
	LOAD_FORM32 0x8b, 5, 3 ; MOV EBP,EBX
beginmvline:
	LOAD_FORM32 0x8b, 3, 2 ; MOV EBX,EDX
maskmach3a: shr ebx, 32
	mov bl, byte [esi+ebx]
	cmp bl, 255
	je short skipmask1
maskmach3c: mov bl, [ebp+ebx]
	mov byte [edi], bl
skipmask1:
	LOAD_FORM32 0x03, 2, 0 ; ADD EDX,EAX
fixchain1m: add edi, 320
	sub ecx, 1
	jnc short beginmvline

	pop ebp
	LOAD_FORM32 0x8b, 0, 2 ; MOV EAX,EDX
	ret

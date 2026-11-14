; "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
; Ken Silverman's official web site: "http://www.advsys.net/ken"
; See the included license file "BUILDLIC.TXT" for license info.
; This file has been modified from Ken Silverman's original release
; NASM transcription of historical A_MASM translucent sprite column.
; Explicit ModR/M encoding selects the original legal load-direction form.
%macro LOAD_FORM32 3
 db %1, 0xc0 | (%2 << 3) | %3
%endmacro
BITS 32
ORG 0x649c0
tspal equ 0x64a14
tsmach1 equ 0x64a00
tsmach4 equ 0x64a33
tsmach2 equ 0x64a08
tsmach5 equ 0x64a3b
tsmach3 equ 0x64a28

tsetupspritevline_:
	mov dword [tspal+2], eax

	LOAD_FORM32 0x8b, 0, 6 ; MOV EAX,ESI                      ;xinc's
	shl eax, 16
	mov dword [tsmach1+2], eax
	mov dword [tsmach4+2], eax
	LOAD_FORM32 0x8b, 0, 6 ; MOV EAX,ESI
	sar eax, 16
	LOAD_FORM32 0x03, 0, 3 ; ADD EAX,EBX                      ;watch out with ebx - it's passed
	mov dword [tsmach2+2], eax
	LOAD_FORM32 0x03, 0, 2 ; ADD EAX,EDX
	mov dword [tsmach5+2], eax

	mov dword [tsmach3+2], ecx  ;yinc's
	ret

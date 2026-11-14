; "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
; Ken Silverman's official web site: "http://www.advsys.net/ken"
; See the included license file "BUILDLIC.TXT" for license info.
; This file has been modified from Ken Silverman's original release
; NASM transcription of historical A_MASM opaque/masked sprite columns.
; Explicit ModR/M encoding selects the original legal load-direction form.
%macro LOAD_FORM32 3
 db %1, 0xc0 | (%2 << 3) | %3
%endmacro
BITS 32
ORG 0x64950
mspal equ 0x64992
msmach1 equ 0x64980
msmach4 equ 0x649ab
msmach2 equ 0x64988
msmach5 equ 0x649b3
msmach3 equ 0x649a0

msetupspritevline_:
	mov dword [mspal+2], eax

	LOAD_FORM32 0x8b, 0, 6 ; MOV EAX,ESI                      ;xinc's
	shl eax, 16
	mov dword [msmach1+2], eax
	mov dword [msmach4+2], eax
	LOAD_FORM32 0x8b, 0, 6 ; MOV EAX,ESI
	sar eax, 16
	LOAD_FORM32 0x03, 0, 3 ; ADD EAX,EBX                      ;watch out with ebx - it's passed
	mov dword [msmach2+2], eax
	LOAD_FORM32 0x03, 0, 2 ; ADD EAX,EDX
	mov dword [msmach5+2], eax

	mov dword [msmach3+2], ecx  ;yinc's
	ret

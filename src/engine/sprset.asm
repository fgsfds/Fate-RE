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
ORG 0x648e0
spal equ 0x6491e
smach1 equ 0x64910
smach4 equ 0x64937
smach2 equ 0x64918
smach5 equ 0x6493f
smach3 equ 0x6492c

setupspritevline_:
	mov dword [spal+2], eax

	LOAD_FORM32 0x8b, 0, 6 ; MOV EAX,ESI                      ;xinc's
	shl eax, 16
	mov dword [smach1+2], eax
	mov dword [smach4+2], eax
	LOAD_FORM32 0x8b, 0, 6 ; MOV EAX,ESI
	sar eax, 16
	LOAD_FORM32 0x03, 0, 3 ; ADD EAX,EBX                      ;watch out with ebx - it's passed
	mov dword [smach2+2], eax
	LOAD_FORM32 0x03, 0, 2 ; ADD EAX,EDX
	mov dword [smach5+2], eax

	mov dword [smach3+2], ecx  ;yinc's
	ret

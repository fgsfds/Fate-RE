; "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
; Ken Silverman's official web site: "http://www.advsys.net/ken"
; See the included license file "BUILDLIC.TXT" for license info.
; This file has been modified from Ken Silverman's original release
; NASM transcription of historical A_MASM dual packed-coordinate slope raster.
; Explicit ModR/M encoding selects the original legal load-direction form.
%macro LOAD_FORM32 3
 db %1, 0xc0 | (%2 << 3) | %3
%endmacro
BITS 32
ORG 0x64e70
_asm1 equ 0x286aa4
_asm2 equ 0x286aa8
_asm3 equ 0x286aac
_asm4 equ 0x286ab0
slop1 equ 0x64ec5
slop2 equ 0x64ecb
slop3 equ 0x64eda
slop4 equ 0x64ee2
slop5 equ 0x64ee8
slop6 equ 0x64eee
slop7 equ 0x64ef7
slop8 equ 0x64f03
slop9 equ 0x64f0e

setupslopevlin2_:
	mov dword [slop3+2], edx ;ptr
	mov dword [slop7+2], edx ;ptr
	mov dword [slop4+2], esi ;tptr
	mov dword [slop8+2], esi ;tptr
	mov byte [slop2+2], ah   ;ybits
	mov byte [slop6+2], ah   ;ybits
	mov dword [slop9+2], edi ;pinc

	mov edx, 1
	LOAD_FORM32 0x8a, 1, 0 ; MOV CL, AL
	LOAD_FORM32 0x2, 1, 4 ; ADD CL, AH
	shl edx, cl
	dec edx
	LOAD_FORM32 0x8a, 1, 4 ; MOV CL, AH
	ror edx, cl

	mov dword [slop1+2], edx   ;ybits...xbits
	mov dword [slop5+2], edx   ;ybits...xbits

	ret

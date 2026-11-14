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
ORG 0x64ec0
_asm1 equ 0x286aa4
_asm2 equ 0x286aa8
_asm3 equ 0x286aac
_asm4 equ 0x286ab0

slopevlin2_:
	push ebp
	LOAD_FORM32 0x33, 1, 1 ; XOR ECX, ECX

slopevlin2begin:
	LOAD_FORM32 0x8b, 5, 2 ; MOV EBP, EDX
slop1: and ebp, 0x88000088                ;ybits...xbits
slop2: rol ebp, 6                        ;ybits
	add eax, [_asm1]                        ;xinc1<<xbits
	adc edx, [_asm2]                        ;(yinc1&0xffffff00)+(xinc1>>(32-xbits))
slop3: mov cl, byte [ebp+0x88888888]  ;bufplc

	LOAD_FORM32 0x8b, 5, 6 ; MOV EBP, ESI
slop4: mov al, byte [ecx+0x88888888]  ;paloffs
slop5: and ebp, 0x88000088                ;ybits...xbits
slop6: rol ebp, 6                        ;ybits
	add ebx, [_asm3]                        ;xinc2<<xbits
slop7: mov cl, byte [ebp+0x88888888]  ;bufplc
	adc esi, [_asm4]                        ;(yinc2&0xffffff00)+(xinc2>>(32-xbits))
slop8: mov ah, byte [ecx+0x88888888]  ;paloffs

	dec bl
	mov word [edi], ax
slop9: lea edi, [edi+0x88888888]          ;pinc
	jnz short slopevlin2begin

	pop ebp
	LOAD_FORM32 0x8b, 0, 7 ; MOV EAX, EDI
	ret

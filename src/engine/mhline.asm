; "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
; Ken Silverman's official web site: "http://www.advsys.net/ken"
; See the included license file "BUILDLIC.TXT" for license info.
; This file has been modified from Ken Silverman's original release
; NASM transcription of historical A_MASM mhline/mhlineskipmodify.
; Explicit ModR/M encoding selects the original legal load-direction form.
%macro LOAD_FORM32 3
 db %1, 0xc0 | (%2 << 3) | %3
%endmacro
%macro ALIGN_XCHG16 0
 %assign pad ((16-(($-$$) % 16)) % 16)
 times pad/2 xchg ebx,ebx
 times (pad % 2) nop
%endmacro
; The observed original encoding is a short forward jump plus three NOPs.
; A five-byte branch reservation is inferred, not a recovered assembler claim.
; This explicit lowering retains that observed semantic instruction slot.
%macro JMP_FORWARD_SLOT 1
 jmp short %1
 times 3 nop
%endmacro
BITS 32
ORG 0x64a80
_asm1 equ 0x286aa4
_asm2 equ 0x286aa8
_asm3 equ 0x286aac

mhline_:
	;_asm1 = bxinc
	;_asm2 = byinc
	;_asm3 = shadeoffs
	;eax = picoffs
	;ebx = bx
	;ecx = cnt
	;edx = ?
	;esi = by
	;edi = p

	mov dword [mmach1d+2], eax
	mov dword [mmach5d+2], eax
	mov dword [mmach9d+2], eax
	mov eax, [_asm3]
	mov dword [mmach2d+2], eax
	mov dword [mmach2da+2], eax
	mov dword [mmach2db+2], eax
	mov dword [mmach6d+2], eax
	mov dword [mmach10d+2], eax
	mov eax, [_asm1]
	mov dword [mmach3d+2], eax
	mov dword [mmach7d+2], eax
	mov eax, [_asm2]
	mov dword [mmach4d+2], eax
	mov dword [mmach8d+2], eax
	jmp short mhlineskipmodify_

ALIGN_XCHG16

mhlineskipmodify_:

	push ebp

	LOAD_FORM32 0x33, 0, 0 ; XOR EAX,EAX
	LOAD_FORM32 0x8b, 5, 3 ; MOV EBP,EBX

	test ecx, 0x00010000
	jnz short mbeghline

msh1d: shr ebx, 26
msh2d: shld ebx, esi, 6
	add ebp, [_asm1]
mmach9d: mov al, byte [ebx+0x88888888]    ;picoffs
	add esi, [_asm2]
	cmp al, 255
	je near mskip5

	mmach10d: mov cl, byte [eax+0x88888888]    ;shadeoffs
	mov byte [edi], cl
mskip5:
	inc edi
	sub ecx, 65536
	jc near mendhline
	jmp short mbeghline

ALIGN_XCHG16
mpreprebeghline:                                            ;1st only
	LOAD_FORM32 0x8a, 0, 1 ; MOV AL,CL
mmach2d: mov al, byte [eax+0x88888888]    ;shadeoffs
	mov byte [edi], al

mprebeghline:
	add edi, 2
	sub ecx, 131072
	jc short mendhline
mbeghline:
mmach3d: lea ebx, [ebp+0x88888888]            ;bxinc
msh3d: shr ebp, 26
msh4d: shld ebp, esi, 6
mmach4d: add esi, 0x88888888                  ;byinc
mmach1d: mov cl, byte [ebp+0x88888888]    ;picoffs
mmach7d: lea ebp, [ebx+0x88888888]            ;bxinc

msh5d: shr ebx, 26
msh6d: shld ebx, esi, 6
mmach8d: add esi, 0x88888888                  ;byinc
mmach5d: mov ch, byte [ebx+0x88888888]    ;picoffs

	cmp cl, 255
	je short mskip1
	cmp ch, 255
	je short mpreprebeghline

	LOAD_FORM32 0x8a, 0, 1 ; MOV AL,CL                                                  ;BOTH
mmach2da: mov bl, byte [eax+0x88888888]    ;shadeoffs
	LOAD_FORM32 0x8a, 0, 5 ; MOV AL,CH
mmach2db: mov bh, byte [eax+0x88888888]    ;shadeoffs
	mov word [edi], bx
	add edi, 2
	sub ecx, 131072
	jnc short mbeghline
	JMP_FORWARD_SLOT mendhline
mskip1:                                                     ;2nd only
	cmp ch, 255
	je short mprebeghline

	LOAD_FORM32 0x8a, 0, 5 ; MOV AL,CH
mmach6d: mov al, byte [eax+0x88888888]    ;shadeoffs
	mov byte [edi+1], al
	add edi, 2
	sub ecx, 131072
	jnc short mbeghline
mendhline:

	pop ebp
	ret

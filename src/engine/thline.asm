; "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
; Ken Silverman's official web site: "http://www.advsys.net/ken"
; See the included license file "BUILDLIC.TXT" for license info.
; This file has been modified from Ken Silverman's original release
; NASM transcription of historical A_MASM thline/thlineskipmodify.
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
ORG 0x64bf0
_asm1 equ 0x286aa4
_asm2 equ 0x286aa8
_asm3 equ 0x286aac

thline_:
	;[_asm1] = bxinc
	;[_asm2] = byinc
	;[_asm3] = shadeoffs
	;eax = picoffs
	;ebx = bx
	;ecx = cnt
	;edx = ?
	;esi = by
	;edi = p

	mov dword [tmach1d+2], eax
	mov dword [tmach5d+2], eax
	mov dword [tmach9d+2], eax
	mov eax, [_asm3]
	mov dword [tmach2d+2], eax
	mov dword [tmach6d+2], eax
	mov dword [tmach10d+2], eax
	mov eax, [_asm1]
	mov dword [tmach3d+2], eax
	mov dword [tmach7d+2], eax
	mov eax, [_asm2]
	mov dword [tmach4d+2], eax
	mov dword [tmach8d+2], eax
	JMP_FORWARD_SLOT thlineskipmodify_

ALIGN_XCHG16
thlineskipmodify_:

	push ebp

	LOAD_FORM32 0x33, 0, 0 ; XOR EAX,EAX
	LOAD_FORM32 0x33, 2, 2 ; XOR EDX,EDX
	LOAD_FORM32 0x8b, 5, 3 ; MOV EBP,EBX

	test ecx, 0x00010000
	jnz short tbeghline

tsh1d: shr ebx, 26
tsh2d: shld ebx, esi, 6
	add ebp, [_asm1]
tmach9d: mov al, byte [ebx+0x88888888]    ;picoffs
	add esi, [_asm2]
	cmp al, 255
	je near tskip5

transrev4:
tmach10d: mov dl, byte [eax+0x88888888]   ;shadeoffs
transrev5:
	mov dh, byte [edi]
tmach1: mov al, byte [edx+0x88888888]     ;_transluc
	mov byte [edi], al
tskip5:
	inc edi
	sub ecx, 65536
	jc near tendhline
	jmp short tbeghline

ALIGN_XCHG16
tprebeghline:
	add edi, 2
	sub ecx, 131072
	jc short tendhline
tbeghline:
tmach3d: lea ebx, [ebp+0x88888888]            ;bxinc
tsh3d: shr ebp, 26
tsh4d: shld ebp, esi, 6
tmach4d: add esi, 0x88888888                  ;byinc
tmach1d: mov cl, byte [ebp+0x88888888]    ;picoffs
tmach7d: lea ebp, [ebx+0x88888888]            ;bxinc

tsh5d: shr ebx, 26
tsh6d: shld ebx, esi, 6
tmach8d: add esi, 0x88888888                  ;byinc
tmach5d: mov ch, byte [ebx+0x88888888]    ;picoffs

	cmp cx, 0x0ffff
	je short tprebeghline

	mov bx, word [edi]

	cmp cl, 255
	je short tskip1
	LOAD_FORM32 0x8a, 0, 1 ; MOV AL,CL
transrev6:
tmach2d: mov dl, byte [eax+0x88888888]    ;shadeoffs
transrev7:
	LOAD_FORM32 0x8a, 6, 3 ; MOV DH,BL
tmach2: mov al, byte [edx+0x88888888]     ;_transluc
	mov byte [edi], al

	cmp ch, 255
	je short tskip2
tskip1:
	LOAD_FORM32 0x8a, 0, 5 ; MOV AL,CH
transrev8:
tmach6d: mov dl, byte [eax+0x88888888]    ;shadeoffs
transrev9:
	LOAD_FORM32 0x8a, 6, 7 ; MOV DH,BH
tmach3: mov al, byte [edx+0x88888888]     ;_transluc
	mov byte [edi+1], al
tskip2:

	add edi, 2
	sub ecx, 131072
	jnc tbeghline
tendhline:

	pop ebp
	ret

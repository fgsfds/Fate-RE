; "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
; Ken Silverman's official web site: "http://www.advsys.net/ken"
; See the included license file "BUILDLIC.TXT" for license info.
; This file has been modified from Ken Silverman's original release
; NASM transcription of historical A_MASM tvlineasm2.
; Explicit ModR/M encoding selects the original legal load-direction form.
%macro LOAD_FORM32 3
 db %1, 0xc0 | (%2 << 3) | %3
%endmacro
%macro ALIGN_XCHG16 0
 %assign pad ((16-(($-$$) % 16)) % 16)
 times pad/2 xchg ebx,ebx
 times (pad % 2) nop
%endmacro
BITS 32
ORG 0x64d50
_asm1 equ 0x286aa4
_asm2 equ 0x286aa8

tvlineasm2_:
	push ebp

	LOAD_FORM32 0x8b, 5, 0 ; MOV EBP,EAX

	mov dword [tran2inca+2], ebx
	mov eax, [_asm1]
	mov dword [tran2incb+2], eax

	mov dword [tran2bufa+2], ecx         ;bufplc1
	mov dword [tran2bufb+2], edx         ;bufplc2

	mov eax, [_asm2]
	LOAD_FORM32 0x2b, 7, 0 ; SUB EDI,EAX
	mov dword [tran2edia+3], eax
	mov dword [tran2edic+2], eax
	inc eax
	mov dword [tran2edie+2], eax
fixchaint2a: sub eax, 320
	mov dword [tran2edif+2], eax
	dec eax
	mov dword [tran2edib+3], eax
	mov dword [tran2edid+2], eax

	LOAD_FORM32 0x33, 1, 1 ; XOR ECX,ECX
	LOAD_FORM32 0x33, 2, 2 ; XOR EDX,EDX
	jmp short begintvline2

		;eax 0000000000  temp  temp
		;ebx 0000000000 odat2 odat1
		;ecx 0000000000000000 ndat1
		;edx 0000000000000000 ndat2
		;esi          vplc1
		;edi videoplc--------------
		;ebp          vplc2

ALIGN_XCHG16
		;LEFT ONLY
skipdraw2:
transrev10:
tran2edic: mov ah, byte [edi+0x88888888]      ;getpixel
transrev11:
tran2palc: mov al, byte [ecx+0x88888888]      ;palookup1
fixchaint2d: add edi, 320
tran2trac: mov bl, byte [eax+0x88888888]      ;_transluc
tran2edid: mov byte [edi+0x88888888-320], bl  ;drawpixel
	jnc short begintvline2
	jmp near endtvline2

skipdraw1:
	cmp dl, 255
	jne short skipdraw3
fixchaint2b: add edi, 320
	jc short endtvline2

begintvline2:
	LOAD_FORM32 0x8b, 0, 6 ; MOV EAX,ESI
tran2shra: shr eax, 0x88                      ;globalshift
	LOAD_FORM32 0x8b, 3, 5 ; MOV EBX,EBP
tran2shrb: shr ebx, 0x88                      ;globalshift
tran2inca: add esi, 0x88888888                ;vinc1
tran2incb: add ebp, 0x88888888                ;vinc2
tran2bufa: mov cl, byte [eax+0x88888888]  ;bufplc1
	cmp cl, 255
tran2bufb: mov dl, byte [ebx+0x88888888]  ;bufplc2
	je short skipdraw1
	cmp dl, 255
	je short skipdraw2

	;mov ax        The transluscent reverse of both!
	;mov bl, ah
	;mov ah
	;mov bh

		;BOTH
transrev12:
tran2edia: mov bx, word [edi+0x88888888]      ;getpixels
transrev13:
	LOAD_FORM32 0x8a, 4, 3 ; MOV AH,BL
transrev14:
tran2pala: mov al, byte [ecx+0x88888888]      ;palookup1
transrev15:
tran2palb: mov bl, byte [edx+0x88888888]      ;palookup2
fixchaint2c: add edi, 320
tran2traa: mov al, byte [eax+0x88888888]      ;_transluc
tran2trab: mov ah, byte [ebx+0x88888888]      ;_transluc
tran2edib: mov word [edi+0x88888888-320], ax  ;drawpixels
	jnc short begintvline2
	jmp short endtvline2

	;RIGHT ONLY
skipdraw3:
transrev16:
tran2edie: mov ah, byte [edi+0x88888889]      ;getpixel
transrev17:
tran2pald: mov al, byte [edx+0x88888888]      ;palookup2
fixchaint2e: add edi, 320
tran2trad: mov bl, byte [eax+0x88888888]      ;_transluc
tran2edif: mov byte [edi+0x88888889-320], bl  ;drawpixel
	jnc short begintvline2

endtvline2:
	mov [_asm1], esi
	mov [_asm2], ebp

	pop ebp
	ret

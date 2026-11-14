; "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
; Ken Silverman's official web site: "http://www.advsys.net/ken"
; See the included license file "BUILDLIC.TXT" for license info.
; This file has been modified from Ken Silverman's original release
; NASM transcription of historical A_MASM pre-19960319 vlineasm4.
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
ORG 0x64510
_vince equ 0x199020
_bufplce equ 0x199040
_palookupoffse equ 0x199010
_vplce equ 0x199030
_ylookup equ 0x286bb0

vlineasm4_:
	push ebp

	mov eax, dword [_vince+0]
	mov ebx, dword [_vince+4]
	mov dword [machvinc1+2], eax
	mov dword [machvinc2+2], ebx
	mov eax, dword [_vince+8]
	mov ebx, dword [_vince+12]
	mov dword [machvinc4+2], eax
	mov dword [machvinc3+2], ebx

	mov eax, dword [_bufplce+0]
	mov ebx, dword [_bufplce+4]
	mov dword [machvbuf2+2], eax
	mov dword [machvbuf1+2], ebx
	mov eax, dword [_bufplce+8]
	mov ebx, dword [_bufplce+12]
	mov dword [machvbuf4+2], eax
	mov dword [machvbuf3+2], ebx

	mov eax, dword [_palookupoffse+0]
	mov ebx, dword [_palookupoffse+4]
	mov dword [machvpal2+2], eax
	mov dword [machvpal1+2], ebx
	mov eax, dword [_palookupoffse+8]
	mov ebx, dword [_palookupoffse+12]
	mov dword [machvpal4+2], eax
	mov dword [machvpal3+2], ebx

	LOAD_FORM32 0x8b, 0, 7 ; MOV EAX,EDI
	LOAD_FORM32 0x33, 7, 7 ; XOR EDI,EDI
	sub edi, dword [_ylookup+ecx*4]
	LOAD_FORM32 0x2b, 0, 7 ; SUB EAX,EDI
	mov dword [machvline4end+2], eax

	mov ecx, dword [_vplce+0]
	mov edx, dword [_vplce+4]
	mov esi, dword [_vplce+8]
	mov ebp, dword [_vplce+12]
	LOAD_FORM32 0x8b, 0, 2 ; MOV EAX,EDX
	jmp short beginvlineasm4
ALIGN_XCHG16
beginvlineasm4:
machvsh1: shr eax, 32
	LOAD_FORM32 0x8b, 3, 1 ; MOV EBX,ECX
machvsh2: shr ebx, 32
machvinc1: add ecx, 0x88888888
machvbuf1: mov al, [eax+0x88888888]
machvinc2: add edx, 0x88888888
machvbuf2: mov bl, [ebx+0x88888888]
machvpal1: mov dl, [eax+0x88888888]
	LOAD_FORM32 0x8b, 0, 5 ; MOV EAX,EBP
machvsh3: shr eax, 32
machvpal2: mov cl, [ebx+0x88888888]
	LOAD_FORM32 0x8b, 3, 6 ; MOV EBX,ESI
machvsh4: shr ebx, 32
machvbuf3: mov al, [eax+0x88888888]
machvinc3: add ebp, 0x88888888
machvinc4: add esi, 0x88888888
machvbuf4: mov bl, [ebx+0x88888888]
machvpal3: mov ah, [eax+0x88888888]
machvpal4: mov al, [ebx+0x88888888]
	shl eax, 16
	LOAD_FORM32 0x8a, 0, 1 ; MOV AL,CL
	LOAD_FORM32 0x8a, 4, 2 ; MOV AH,DL
machvline4end: mov [edi+0x88888888], eax
	LOAD_FORM32 0x8b, 0, 2 ; MOV EAX,EDX
fixchain2a: add edi, 320
	jnc short beginvlineasm4

	mov dword [_vplce+0], ecx
	mov dword [_vplce+4], edx
	mov dword [_vplce+8], esi
	mov dword [_vplce+12], ebp

	pop ebp
	ret

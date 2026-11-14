; "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
; Ken Silverman's official web site: "http://www.advsys.net/ken"
; See the included license file "BUILDLIC.TXT" for license info.
; This file has been modified from Ken Silverman's original release
; NASM transcription of historical A_MASM mvlineasm4.
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
ORG 0x64660
_vince equ 0x199020
_bufplce equ 0x199040
_palookupoffse equ 0x199010
_vplce equ 0x199030
_asm3 equ 0x286aac

mvlineasm4_:
	push ebp

	mov eax, dword [_bufplce+0]
	mov ebx, dword [_bufplce+4]
	mov dword [machmv1+2], eax
	mov dword [machmv4+2], ebx
	mov eax, dword [_bufplce+8]
	mov ebx, dword [_bufplce+12]
	mov dword [machmv7+2], eax
	mov dword [machmv10+2], ebx

	mov eax, dword [_palookupoffse+0]
	mov ebx, dword [_palookupoffse+4]
	mov dword [machmv2+2], eax
	mov dword [machmv5+2], ebx
	mov eax, dword [_palookupoffse+8]
	mov ebx, dword [_palookupoffse+12]
	mov dword [machmv8+2], eax
	mov dword [machmv11+2], ebx

	mov eax, dword [_vince+0]        ;vince
	mov ebx, dword [_vince+4]
	LOAD_FORM32 0x32, 0, 0 ; XOR AL,AL
	LOAD_FORM32 0x32, 3, 3 ; XOR BL,BL
	mov dword [machmv3+2], eax
	mov dword [machmv6+2], ebx
	mov eax, dword [_vince+8]
	mov ebx, dword [_vince+12]
	mov dword [machmv9+2], eax
	mov dword [machmv12+2], ebx

	LOAD_FORM32 0x8b, 3, 1 ; MOV EBX,ECX
	mov ecx, dword [_vplce+0]
	mov edx, dword [_vplce+4]
	mov esi, dword [_vplce+8]
	mov ebp, dword [_vplce+12]
	LOAD_FORM32 0x8a, 1, 3 ; MOV CL,BL
	inc cl
	inc bh
	mov byte [_asm3+0], bh
fixchain2ma: sub edi, 320

	jmp short beginmvlineasm4
ALIGN_XCHG16
beginmvlineasm4:
	dec cl
	jz near endmvlineasm4
beginmvlineasm42:
	LOAD_FORM32 0x8b, 0, 5 ; MOV EAX,EBP
	LOAD_FORM32 0x8b, 3, 6 ; MOV EBX,ESI
machmv16: shr eax, 32
machmv15: shr ebx, 32
machmv12: add ebp, 0x88888888 ;vince[3]
machmv9: add esi, 0x88888888 ;vince[2]
machmv10: mov al, byte [eax+0x88888888] ;bufplce[3]
machmv7: mov bl, byte [ebx+0x88888888] ;bufplce[2]
	cmp al, 255
	LOAD_FORM32 0x12, 2, 2 ; ADC DL,DL
	cmp bl, 255
	LOAD_FORM32 0x12, 2, 2 ; ADC DL,DL
machmv8: mov bl, byte [ebx+0x88888888] ;palookupoffs[2]
machmv11: mov bh, byte [eax+0x88888888] ;palookupoffs[3]

	LOAD_FORM32 0x8b, 0, 2 ; MOV EAX,EDX
machmv14: shr eax, 32
	shl ebx, 16
machmv4: mov al, byte [eax+0x88888888] ;bufplce[1]
	cmp al, 255
	LOAD_FORM32 0x12, 2, 2 ; ADC DL,DL
machmv6: add edx, 0x88888888 ;vince[1]
machmv5: mov bh, byte [eax+0x88888888] ;palookupoffs[1]

	LOAD_FORM32 0x8b, 0, 1 ; MOV EAX,ECX
machmv13: shr eax, 32
machmv3: add ecx, 0x88888888 ;vince[0]
machmv1: mov al, byte [eax+0x88888888] ;bufplce[0]
	cmp al, 255
	LOAD_FORM32 0x12, 2, 2 ; ADC DL,DL
machmv2: mov bl, byte [eax+0x88888888] ;palookupoffs[0]

	shl dl, 4
	LOAD_FORM32 0x33, 0, 0 ; XOR EAX,EAX
fixchain2mb: add edi, 320
	LOAD_FORM32 0x8a, 0, 2 ; MOV AL,DL
	add eax, mvcase0
	jmp eax       ;16 byte cases

ALIGN_XCHG16
endmvlineasm4:
	dec byte [_asm3+0]
	jnz near beginmvlineasm42

	mov dword [_vplce+0], ecx
	mov dword [_vplce+4], edx
	mov dword [_vplce+8], esi
	mov dword [_vplce+12], ebp
	pop ebp
	ret

	;5,7,8,8,11,13,12,14,11,13,14,14,12,14,15,7
ALIGN_XCHG16
mvcase0:
	jmp beginmvlineasm4
ALIGN_XCHG16
mvcase1:
	mov byte [edi], bl
	jmp beginmvlineasm4
ALIGN_XCHG16
mvcase2:
	mov byte [edi+1], bh
	jmp beginmvlineasm4
ALIGN_XCHG16
mvcase3:
	mov word [edi], bx
	jmp beginmvlineasm4
ALIGN_XCHG16
mvcase4:
	shr ebx, 16
	mov byte [edi+2], bl
	jmp beginmvlineasm4
ALIGN_XCHG16
mvcase5:
	mov byte [edi], bl
	shr ebx, 16
	mov byte [edi+2], bl
	jmp beginmvlineasm4
ALIGN_XCHG16
	mvcase6:
	shr ebx, 8
	mov word [edi+1], bx
	jmp beginmvlineasm4
ALIGN_XCHG16
mvcase7:
	mov word [edi], bx
	shr ebx, 16
	mov byte [edi+2], bl
	jmp beginmvlineasm4
ALIGN_XCHG16
mvcase8:
	shr ebx, 16
	mov byte [edi+3], bh
	jmp beginmvlineasm4
ALIGN_XCHG16
mvcase9:
	mov byte [edi], bl
	shr ebx, 16
	mov byte [edi+3], bh
	jmp beginmvlineasm4
ALIGN_XCHG16
mvcase10:
	mov byte [edi+1], bh
	shr ebx, 16
	mov byte [edi+3], bh
	jmp beginmvlineasm4
ALIGN_XCHG16
mvcase11:
	mov word [edi], bx
	shr ebx, 16
	mov byte [edi+3], bh
	jmp beginmvlineasm4
ALIGN_XCHG16
mvcase12:
	shr ebx, 16
	mov word [edi+2], bx
	jmp beginmvlineasm4
ALIGN_XCHG16
mvcase13:
	mov byte [edi], bl
	shr ebx, 16
	mov word [edi+2], bx
	jmp beginmvlineasm4
ALIGN_XCHG16
mvcase14:
	mov byte [edi+1], bh
	shr ebx, 16
	mov word [edi+2], bx
	jmp beginmvlineasm4
ALIGN_XCHG16
mvcase15:
	mov dword [edi], ebx
	jmp beginmvlineasm4

; "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
; Ken Silverman's official web site: "http://www.advsys.net/ken"
; See the included license file "BUILDLIC.TXT" for license info.
; This file has been modified from Ken Silverman's original release
; NASM transcription of historical A_MASM early horizontal raster module block.
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
ORG 0x63ff0
_asm1 equ 0x286aa4
_asm2 equ 0x286aa8
fixchain1a equ 0x64344
fixchain1b equ 0x6434f
fixchain1m equ 0x64388
fixchain1t equ 0x644ff
fixchain1s equ 0x64926
mfixchain1s equ 0x6499a
tfixchain1s equ 0x64a22
fixchain2a equ 0x64639
fixchain2ma equ 0x6470f
fixchain2mb equ 0x6479d
fixchaint2a equ 0x64d86
fixchaint2b equ 0x64dda
fixchaint2c equ 0x64e23
fixchaint2d equ 0x64dbc
fixchaint2e equ 0x64e4c

sethlinesizes_:
	mov byte [machxbits1+2], al
	mov byte [machxbits2+2], al
	mov byte [machxbits3+2], al
	neg al
	mov byte [hxsiz1+2], al
	mov byte [hxsiz2+2], al
	mov byte [hxsiz3+2], al
	mov byte [machnegxbits1+2], al

	mov byte [hysiz1+3], bl
	mov byte [hysiz2+3], bl
	mov byte [hysiz3+3], bl
	mov byte [hmach3a+2], bl
	mov byte [hmach3b+2], bl
	mov byte [hmach3c+2], bl
	mov byte [hmach3d+2], bl

	mov dword [hoffs1+2], ecx
	mov dword [hoffs2+2], ecx
	mov dword [hoffs3+2], ecx
	mov dword [hoffs4+2], ecx
	mov dword [hoffs5+2], ecx
	mov dword [hoffs6+2], ecx
	mov dword [hoffs7+2], ecx

	mov edx, -1
	LOAD_FORM32 0x8a, 1, 0 ; MOV CL, AL
	LOAD_FORM32 0x2a, 1, 3 ; SUB CL, BL
	shr edx, cl
	mov dword [hmach2a+1], edx
	mov dword [hmach2b+1], edx
	mov dword [hmach2c+1], edx
	mov dword [hmach2d+1], edx

	ret

ALIGN_XCHG16
setvlinebpl_:
	mov dword [fixchain1a+2], eax
	mov dword [fixchain1b+2], eax
	mov dword [fixchain1m+2], eax
	mov dword [fixchain1t+2], eax
	mov dword [fixchain1s+2], eax
	mov dword [mfixchain1s+2], eax
	mov dword [tfixchain1s+2], eax
	mov dword [fixchain2a+2], eax
	mov dword [fixchain2ma+2], eax
	mov dword [fixchain2mb+2], eax
	mov dword [fixchaint2a+1], eax
	mov dword [fixchaint2b+2], eax
	mov dword [fixchaint2c+2], eax
	mov dword [fixchaint2d+2], eax
	mov dword [fixchaint2e+2], eax
	ret

ALIGN_XCHG16
setpalookupaddress_:
	mov dword [pal1+2], eax
	mov dword [pal2+2], eax
	mov dword [pal3+2], eax
	mov dword [pal4+2], eax
	mov dword [pal5+2], eax
	mov dword [pal6+2], eax
	mov dword [pal7+2], eax
	ret

ALIGN_XCHG16
setuphlineasm4_:
machxbits3: rol eax, 6                     ;xbits
	mov dword [hmach4a+2], eax
	mov dword [hmach4b+2], eax
	LOAD_FORM32 0x8a, 3, 0 ; MOV BL, AL
	mov dword [hmach4c+2], eax
	mov dword [hmach4d+2], eax
	mov dword [hmach1a+2], ebx
	mov dword [hmach1b+2], ebx
	mov dword [hmach1c+2], ebx
	mov dword [hmach1d+2], ebx
	ret

	;Non-256-stuffed ceiling&floor method with NO SHLD!:
	;yinc&0xffffff00   lea eax, [edx+0x88888800]           1     1/2
	;ybits...xbits     and edx, 0x88000088                 1     1/2
	;ybits             rol edx, 6                         2     1/2
	;xinc<<xbits       add esi, 0x88888888                 1     1/2
	;xinc>>(32-xbits)  adc al, 0x88                        1     1/2
	;bufplc            mov cl, byte [edx+0x88888888]   1     1/2
	;paloffs&255       mov bl, byte [ecx+0x88888888]   1     1/2
ALIGN_XCHG16
hlineasm4_:
	push ebp

	lea ebp, [eax+1]

	shr ebp, 1
	jnc short skipthe1byte

	LOAD_FORM32 0x8b, 0, 6 ; MOV EAX, ESI
hxsiz1: shr eax, 26
hysiz1: shld eax, edx, 6
hoffs1: mov cl, byte [eax+0x88888888]
pal1: mov bl, byte [ecx+0x88888888]
	add esi, [_asm1]
	add edx, [_asm2]
	mov byte [edi], bl
	inc edi

skipthe1byte:
	shr ebp, 1
	jnc short skipthe2byte

	LOAD_FORM32 0x8b, 0, 6 ; MOV EAX, ESI
hxsiz2: shr eax, 26
hysiz2: shld eax, edx, 6
hoffs2: mov cl, byte [eax+0x88888888]
pal2: mov bl, byte [ecx+0x88888888]
	add esi, [_asm1]
	add edx, [_asm2]

	LOAD_FORM32 0x8b, 0, 6 ; MOV EAX, ESI
hxsiz3: shr eax, 26
hysiz3: shld eax, edx, 6
hoffs3: mov cl, byte [eax+0x88888888]
pal3: mov bh, byte [ecx+0x88888888]
	add esi, [_asm1]
	add edx, [_asm2]
	mov word [edi], bx
	add edi, 2

skipthe2byte:
	test ebp, ebp
	jz near skipthe4byte

	LOAD_FORM32 0x8b, 0, 6 ; MOV EAX, ESI
machxbits1: shl esi, 6                     ;xbits
machnegxbits1: shr eax, 32-6               ;32-xbits
	LOAD_FORM32 0x8a, 2, 0 ; MOV DL, AL

	sub edi, 4

	LOAD_FORM32 0x3, 3, 3 ; ADD EBX, EBX
	LOAD_FORM32 0x8b, 0, 2 ; MOV EAX, EDX
	jc near beginhline64

	mov eax, [_asm1]
machxbits2: rol eax, 6                     ;xbits
	mov dword [hmach4a+2], eax
	mov dword [hmach4b+2], eax
	mov dword [hmach4c+2], eax
	mov dword [hmach4d+2], eax
	LOAD_FORM32 0x8b, 3, 0 ; MOV EBX, EAX
	mov eax, [_asm2]
	LOAD_FORM32 0x8a, 0, 3 ; MOV AL, BL
	mov dword [hmach1a+2], eax
	mov dword [hmach1b+2], eax
	mov dword [hmach1c+2], eax
	mov dword [hmach1d+2], eax

	LOAD_FORM32 0x8b, 0, 2 ; MOV EAX, EDX
	JMP_FORWARD_SLOT beginhline64
ALIGN_XCHG16
beginhline64:

hmach3a: rol eax, 6
hmach2a: and eax, 0x00008888
hmach4a: add esi, 0x88888888
hmach1a: adc edx, 0x88888888
	add edi, 4
hoffs4: mov cl, byte [eax+0x88888888]
	LOAD_FORM32 0x8b, 0, 2 ; MOV EAX, EDX

hmach3b: rol eax, 6
hmach2b: and eax, 0x00008888
hmach4b: add esi, 0x88888888
hmach1b: adc edx, 0x88888888
pal4: mov bl, byte [ecx+0x88888888]
hoffs5: mov cl, byte [eax+0x88888888]
	LOAD_FORM32 0x8b, 0, 2 ; MOV EAX, EDX

hmach3c: rol eax, 6
pal5: mov bh, byte [ecx+0x88888888]
hmach2c: and eax, 0x00008888
	shl ebx, 16
hmach4c: add esi, 0x88888888
hmach1c: adc edx, 0x88888888
hoffs6: mov cl, byte [eax+0x88888888]

	LOAD_FORM32 0x8b, 0, 2 ; MOV EAX, EDX
	;(

hmach3d: rol eax, 6
hmach2d: and eax, 0x00008888
hmach4d: add esi, 0x88888888
hmach1d: adc edx, 0x88888888
pal6: mov bl, byte [ecx+0x88888888]
hoffs7: mov cl, byte [eax+0x88888888]
	LOAD_FORM32 0x8b, 0, 2 ; MOV EAX, EDX
pal7: mov bh, byte [ecx+0x88888888]
	rol ebx, 16
	mov dword [edi], ebx
	dec ebp
	jnz near beginhline64
skipthe4byte:
	pop ebp
	ret

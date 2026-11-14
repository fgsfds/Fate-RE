; "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
; Ken Silverman's official web site: "http://www.advsys.net/ken"
; See the included license file "BUILDLIC.TXT" for license info.
; This file has been modified from Ken Silverman's original release
; NASM transcription of historical A_MASM translucent sprite column.
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
ORG 0x649f0

tspritevline_:
	;eax = 0, ebx = x, ecx = cnt, edx = y, esi = yplc, edi = p
	push ebp
	LOAD_FORM32 0x8b, 5, 3 ; MOV EBP,EBX
	LOAD_FORM32 0x33, 3, 3 ; XOR EBX,EBX
	JMP_FORWARD_SLOT tenterspritevline
ALIGN_XCHG16
tprestartsvline:
tsmach1: add ebp, 0x88888888              ;xincshl16
	mov al, byte [esi]
tsmach2: adc esi, 0x88888888              ;xincshr16+yalwaysinc

tstartsvline:
	cmp al, 255
	je short tskipsvline
transrev2:
	mov bh, byte [edi]
transrev3:
tspal: mov bl, [eax+0x88888888]               ;palookup
tmach4: mov al, byte [ebx+0x88888888]     ;_transluc
	mov byte [edi], al
tskipsvline:
tfixchain1s: add edi, 320

tenterspritevline:
tsmach3: add edx, 0x88888888              ;dayinc
	dec ecx
	ja short tprestartsvline     ;jump if (no carry (add)) and (not zero (dec))!
	jz short tendsvline
tsmach4: add ebp, 0x88888888              ;xincshl16
	mov al, byte [esi]
tsmach5: adc esi, 0x88888888              ;xincshr16+yalwaysinc+daydime
	jmp short tstartsvline
tendsvline:
	pop ebp
	ret

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
ORG 0x64910

prestartsvline:
smach1: add ebx, 0x88888888              ;xincshl16
	mov al, byte [esi]
smach2: adc esi, 0x88888888              ;xincshr16+yalwaysinc

startsvline:
spal: mov al, [eax+0x88888888]           ;palookup
	mov byte [edi], al
fixchain1s: add edi, 320

spritevline_:
smach3: add edx, 0x88888888              ;dayinc
	dec ecx
	ja short prestartsvline     ;jump if (no carry (add)) and (not zero (dec))!
	jz short endsvline
smach4: add ebx, 0x88888888              ;xincshl16
	mov al, byte [esi]
smach5: adc esi, 0x88888888              ;xincshr16+yalwaysinc+daydime
	jmp short startsvline
endsvline:
	ret

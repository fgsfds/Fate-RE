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
ORG 0x64980

mprestartsvline:
msmach1: add ebx, 0x88888888              ;xincshl16
	mov al, byte [esi]
msmach2: adc esi, 0x88888888              ;xincshr16+yalwaysinc

mstartsvline:
	cmp al, 255
	je short mskipsvline
mspal: mov al, [eax+0x88888888]           ;palookup
	mov byte [edi], al
mskipsvline:
mfixchain1s: add edi, 320

mspritevline_:
msmach3: add edx, 0x88888888              ;dayinc
	dec ecx
	ja short mprestartsvline     ;jump if (no carry (add)) and (not zero (dec))!
	jz short mendsvline
msmach4: add ebx, 0x88888888              ;xincshl16
	mov al, byte [esi]
msmach5: adc esi, 0x88888888              ;xincshr16+yalwaysinc+daydime
	jmp short mstartsvline
mendsvline:
	ret

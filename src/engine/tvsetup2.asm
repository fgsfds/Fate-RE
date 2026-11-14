; "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
; Ken Silverman's official web site: "http://www.advsys.net/ken"
; See the included license file "BUILDLIC.TXT" for license info.
; This file has been modified from Ken Silverman's original release
; NASM transcription of historical A_MASM setuptvlineasm2.
BITS 32
ORG 0x64d20
setuptvlineasm2_:
 mov byte [0x64de6],al
 mov byte [0x64deb],al
 mov dword [0x64e19],ebx
 mov dword [0x64e1f],ecx
 mov dword [0x64db8],ebx
 mov dword [0x64e48],ecx
 ret

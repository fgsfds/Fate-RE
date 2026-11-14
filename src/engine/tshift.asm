; "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
; Ken Silverman's official web site: "http://www.advsys.net/ken"
; See the included license file "BUILDLIC.TXT" for license info.
; This file has been modified from Ken Silverman's original release
; NASM transcription of historical tsethlineshift.
BITS 32
ORG 0x64bc0
tsethlineshift_:
 neg al
 mov byte [0x64c51], al
 mov byte [0x64c55], bl
 mov byte [0x64ca3], al
 mov byte [0x64ca7], bl
 mov byte [0x64cbc], al
 mov byte [0x64cc0], bl
 ret

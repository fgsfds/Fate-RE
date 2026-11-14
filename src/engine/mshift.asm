; "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
; Ken Silverman's official web site: "http://www.advsys.net/ken"
; See the included license file "BUILDLIC.TXT" for license info.
; This file has been modified from Ken Silverman's original release
; NASM transcription of historical msethlineshift.
BITS 32
ORG 0x64a50
msethlineshift_:
 neg al
 mov byte [0x64adf], al
 mov byte [0x64ae3], bl
 mov byte [0x64b3d], al
 mov byte [0x64b41], bl
 mov byte [0x64b56], al
 mov byte [0x64b5a], bl
 ret

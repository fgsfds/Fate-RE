; "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
; Ken Silverman's official web site: "http://www.advsys.net/ken"
; See the included license file "BUILDLIC.TXT" for license info.
; This file has been modified from Ken Silverman's original release
; NASM transcription of historical A_MASM single-column raster routines.
; Explicit ModR/M encoding selects the original legal load-direction form.
BITS 32
ORG 0x64310
setuptvlineasm_:
 mov byte [0x644e4],al
 ret
